//
//  ZCREasyDough.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/9/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import "ZCREasyDough.h"

#import "ZCREasyError.h"
#import "ZCREasyProperty.h"
#import "ZCREasyDoughTransformer.h"

NSString *const ZCREasyDoughExceptionAlreadyBaked = @"com.zachradke.easyBake.easyDough.exception.alreadyBaked";

NSString *const ZCREasyDoughUpdateNotification = @"com.zachradke.easyBake.easyDough.notifications.updated";

NSString *const ZCREasyDoughIdentifierKey = @"ZCREasyDoughIdentifierKey";

NSString *const ZCREasyDoughUpdatedDoughKey = @"ZCREasyDoughUpdatedDoughKey";

@interface _ZCREasyBaker : NSObject <ZCREasyBaker>
- (instancetype)initWithClass:(Class)doughClass;
- (id)bake;
@end

#pragma mark - ZCREasyDough

@implementation ZCREasyDough

- (instancetype)initWithIdentifier:(id<NSObject,NSCopying>)identifier ingredients:(id)ingredients
                            recipe:(ZCREasyRecipe *)recipe error:(NSError *__autoreleasing *)error {
    if (!identifier) {
        if (error) {
            *error = ZCREasyBakeError(ZCREasyBakeInvalidIdentifierError, @"Missing a unique identifier!");
        }
        return nil;
    }
    
    NSDictionary *mappedIngredients = [[self class] _mappedIngredients:ingredients
                                                            withRecipe:recipe
                                                                 error:error];
    if (!mappedIngredients) { return nil; }
    if (!(self = [super init])) { return nil; }
    
    _uniqueIdentifier = [(id)identifier copy];
    
    if (![self _setMappedIngredients:mappedIngredients error:error]) {
        return nil;
    }
    
    return self;
}

- (instancetype)init {
    // Because an identifier is necessary for initializing an instance, we create one manually
    // rather than leaving a useless init method.
    return [self initWithIdentifier:[NSUUID UUID] ingredients:nil recipe:nil error:NULL];
}

+ (instancetype)makeWith:(void (^)(id<ZCREasyBaker>))preparationBlock {
    NSParameterAssert(preparationBlock);
    
    _ZCREasyBaker *chef = [[_ZCREasyBaker alloc] initWithClass:self];
    preparationBlock(chef);
    
    return [chef bake];
}

- (id)uniqueIdentifier {
    return [(id)_uniqueIdentifier copy];
}

- (instancetype)updateWithIngredients:(id)ingredients
                               recipe:(ZCREasyRecipe *)recipe
                                error:(NSError *__autoreleasing *)error {
    // We need to manually pass an error pointer to establish if there was an error while finding
    // equality rather than relying on the passed error pointer which may not exist.
    NSError *isEqualError = nil;
    BOOL isEqual = [self isEqualToIngredients:ingredients withRecipe:recipe error:&isEqualError];
    
    if (isEqualError) {
        if (error) { *error = isEqualError; }
        return nil;
    }
    
    if (isEqual) {
        // If the ingredients are already represented by this instance, we simply return self.
        return self;
    } else {
        // We use the passed recipe to determine the remapped keys to populate...
        NSDictionary *mappedIngredients = [[self class] _mappedIngredients:ingredients
                                                                withRecipe:recipe
                                                                     error:error];
        if (!mappedIngredients) { return nil; }
        
        id updatedDough = [self copy];
        
        if (![updatedDough _setMappedIngredients:mappedIngredients error:error]) {
            return nil;
        }
        
        // Since we don't rely on pointers to determine equality, we pass the identifier and updated
        // model in the user-info to identify the model.
        NSDictionary *userInfo = @{ZCREasyDoughIdentifierKey: [(id)_uniqueIdentifier copy],
                                   ZCREasyDoughUpdatedDoughKey: updatedDough};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ZCREasyDoughUpdateNotification
                                                            object:self userInfo:userInfo];
        
        NSString *classUpdateNotification = [[self class] updateNotificationName];
        if (classUpdateNotification &&
            ![classUpdateNotification isEqualToString:ZCREasyDoughUpdateNotification]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:classUpdateNotification
                                                                object:self userInfo:userInfo];
        }
        
        return updatedDough;
    }
}

- (instancetype)updateWith:(void (^)(id<ZCREasyBaker>))updateBlock {
    NSParameterAssert(updateBlock);
    
    _ZCREasyBaker *chef = [[_ZCREasyBaker alloc] initWithClass:[self class]];
    updateBlock(chef);
    
    return [self updateWithIngredients:chef.ingredients recipe:chef.recipe error:NULL];
}

+ (NSString *)updateNotificationName {
    if (self == [ZCREasyDough class]) {
        return ZCREasyDoughUpdateNotification;
    } else {
        return [NSString stringWithFormat:@"com.zachradke.easyBake.%@.notifications.updated", NSStringFromClass(self)];
    }
}

- (id)decomposeWithRecipe:(ZCREasyRecipe *)recipe error:(NSError *__autoreleasing *)error {
    if (![[self class] _validateRecipe:recipe error:error]) {
        return nil;
    }
    
    // We need to determine what object should be the root, either a dictionary or array.
    id ingredients;
    NSArray *testComponents = [[recipe.ingredientMappingComponents allValues] firstObject];
    if ([[testComponents firstObject] isKindOfClass:[NSString class]]) {
        ingredients = [NSMutableDictionary dictionary];
    } else {
        ingredients = [NSMutableArray array];
    }
    
    @try {
        id value;
        for (NSString *propertyName in recipe.propertyNames) {
            value = [self valueForKey:propertyName];
            
            NSValueTransformer *transformer = recipe.ingredientTransformers[propertyName];
            
            // Only reversible transformations are used during decomposition
            if (transformer && [[transformer class] allowsReverseTransformation]) {
                value = [transformer reverseTransformedValue:value];
            }
            if (!value) { value = [NSNull null]; }
            
            NSArray *components = recipe.ingredientMappingComponents[propertyName];
            [self _setValue:value forComponents:components mutableIngredients:ingredients];
        }
    }
    @catch (NSException *exception) {
        if (error) {
            *error = ZCREasyBakeExceptionError(exception);
        }
        return nil;
    }
    
    return [ingredients copy];
}

- (void)_setValue:(id)value forComponents:(NSArray *)ingredientComponents
mutableIngredients:(id)mutableIngredients {
    NSParameterAssert(value);
    NSParameterAssert(mutableIngredients);
    
    // Convenience block for filling in an arbitrary location in the ingredient tree
    void (^fillLocation)(id, id, id) = ^(id location, id fillPiece, id fillValue) {
        if ([fillPiece isKindOfClass:[NSString class]]) {
            [location setObject:fillValue forKey:fillPiece];
        } else {
            NSUInteger valueIndex = [fillPiece unsignedIntegerValue];
            for (NSUInteger i = [location count]; i < valueIndex; i++) {
                [location setObject:[NSNull null] atIndex:i];
            }
            [location setObject:fillValue atIndex:valueIndex];
        }
    };
    
    id currentLocation = mutableIngredients; // Pointer to the current container in the tree.
    id newLocation; // The next possible container in the tree
    id placeholderPiece = nil; // Container for a piece that must be resolved by the next piece
    for (id piece in ingredientComponents) {
        BOOL isDictionaryPiece = [piece isKindOfClass:[NSString class]];
        if (placeholderPiece) {
            // If there is an unresolved piece, we need to create the next location based on the
            // current piece
            newLocation = (isDictionaryPiece) ? [NSMutableDictionary dictionary] :
                                                [NSMutableArray array];
            fillLocation(currentLocation, placeholderPiece, newLocation);
            currentLocation = newLocation;
            placeholderPiece = piece;
        } else {
            // If there is no unresolved piece, we check if the next location exists, and if not
            // we defer resolution till the next piece.
            newLocation = nil;
            if (isDictionaryPiece) {
                newLocation = [currentLocation objectForKey:piece];
            } else {
                NSUInteger pieceIndex = [piece unsignedIntegerValue];
                if ([currentLocation count] > pieceIndex) {
                    newLocation = [currentLocation objectAtIndex:pieceIndex];
                }
            }
            
            if (newLocation && newLocation != [NSNull null]) {
                currentLocation = newLocation;
            } else {
                placeholderPiece = piece;
            }
        }
    }
    
    // At the very end we need to set the actual value in the last location
    id lastPiece = [ingredientComponents lastObject];
    fillLocation(currentLocation, lastPiece, value);
}

- (BOOL)isEqualToIngredients:(id)ingredients
                  withRecipe:(ZCREasyRecipe *)recipe
                       error:(NSError *__autoreleasing *)error {
    // A recipe is required in this method, otherwise it cannot be determined which keys to check
    // for equality. Similarly, ingredients should also be present.
    if (!recipe) {
        if (error) {
            *error = ZCREasyBakeError(ZCREasyBakeInvalidRecipeError, @"Missing a recipe to compare with!");
        }
        return NO;
    }
    
    if (!ingredients) {
        if (error) {
            *error = ZCREasyBakeError(ZCREasyBakeInvalidIngredientsError, @"Missing raw ingredients to compare!");
        }
        return NO;
    }
    
    NSDictionary *mappedIngredients = [[self class] _mappedIngredients:ingredients
                                                            withRecipe:recipe
                                                                 error:error];
    if (!mappedIngredients) { return NO; }
    
    __block BOOL isEqual = YES;
    
    @try {
        __block id currentValue = nil;
        [mappedIngredients enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, id ingredientValue, BOOL *stop) {
            currentValue = [self valueForKey:propertyName];
            
            // Ingredient NSNull values are remapped to nil
            if (ingredientValue == (id)[NSNull null]) { ingredientValue = nil; }
            
            isEqual = (!currentValue && !ingredientValue) || [currentValue isEqual:ingredientValue];
            if (!isEqual) { *stop = YES; }
        }];
    }
    @catch (NSException *exception) {
        if (error) {
            *error = ZCREasyBakeExceptionError(exception);
        }
        return NO;
    }
    
    return isEqual;
}

+ (ZCREasyRecipe *)genericRecipe {
    NSString *recipeName = [NSString stringWithFormat:@"%@-GenericRecipe", NSStringFromClass(self)];
    ZCREasyRecipe *recipe = [[self _sharedDoughBox] recipeWithName:recipeName];
    if (recipe) { return recipe; }
    
    return [[self _sharedDoughBox] addRecipeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker setName:recipeName];
        
        NSArray *propertyNames = [[self allPropertyNames] allObjects];
        NSDictionary *ingredientMapping = [NSDictionary dictionaryWithObjects:propertyNames
                                                                      forKeys:propertyNames];
        [recipeMaker setIngredientMapping:ingredientMapping];
    }];
}

+ (ZCREasyRecipeBox *)_sharedDoughBox {
    // ZCREasyDough has it's own private box for keeping it's precious recipes
    static ZCREasyRecipeBox *sharedBox;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBox = [[ZCREasyRecipeBox alloc] init];
    });
    return sharedBox;
}

+ (ZCREasyDoughTransformer *)transformerWithRecipe:(ZCREasyRecipe *)recipe
                                   identifierBlock:(id<NSObject,NSCopying> (^)(id))identifierBlock {
    return [[ZCREasyDoughTransformer alloc] initWithDoughClass:self recipe:recipe
                                               identifierBlock:identifierBlock];
}


#pragma mark Private utilities

+ (BOOL)_validateRecipe:(ZCREasyRecipe *)recipe error:(NSError *__autoreleasing *)error {
    if (!recipe) {
        if (error) {
            *error = ZCREasyBakeError(ZCREasyBakeInvalidRecipeError, @"Missing a recipe!");
        }
        return NO;
    }
    
    if (![recipe.propertyNames isSubsetOfSet:[self allPropertyNames]]){
        if (error) {
            NSMutableSet *unknownNames = [recipe.propertyNames mutableCopy];
            [unknownNames minusSet:[self allPropertyNames]];
            *error = ZCREasyBakeError(ZCREasyBakeInvalidRecipeError, @"The recipe contains unknown property names: %@", unknownNames);
        }
        return NO;
    }
    
    return YES;
}

+ (NSDictionary *)_mappedIngredients:(id)ingredients
                          withRecipe:(ZCREasyRecipe *)recipe
                               error:(NSError *__autoreleasing *)error {
    // If there are no ingredients or recipe, we consider the mapping a success and return an
    // empty dictionary.
    if (!ingredients && !recipe) { return [NSDictionary dictionary]; }
    
    if ([self _validateRecipe:recipe error:error]) {
        return [recipe processIngredients:ingredients error:error];
    } else {
        return nil;
    }
}

- (BOOL)_setMappedIngredients:(NSDictionary *)mappedIngredients
                        error:(NSError *__autoreleasing *)error {
    NSParameterAssert(mappedIngredients);
    
    BOOL didAllowSettingReadonlyIVars = _allowsSettingReadonlyIVars;
    _allowsSettingReadonlyIVars = YES;
    
    @try {
        [mappedIngredients enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            // NSNull ingredient values are remapped to nil for setting
            if (obj == [NSNull null]) { obj = nil; }
            [self setValue:obj forKey:key];
        }];
    }
    @catch (NSException *exception) {
        if (error) {
            *error = ZCREasyBakeExceptionError(exception);
        }
        return NO;
    }
    @finally {
        _allowsSettingReadonlyIVars = didAllowSettingReadonlyIVars;
    }
    
    return YES;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] initWithIdentifier:_uniqueIdentifier ingredients:nil recipe:nil
                                                 error:NULL];
    
    NSArray *settableKeys = [[[self class] _settablePropertyNames] allObjects];
    NSDictionary *mappedIngredients = [self dictionaryWithValuesForKeys:settableKeys];
    
    if ([copy _setMappedIngredients:mappedIngredients error:NULL]) {
        return copy;
    } else {
        return nil;
    }
}


#pragma mark NSObject

+ (BOOL)accessInstanceVariablesDirectly {
    return YES;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    // To prevent setting iVars of read-only properties outside of the initializer, we use a simple
    // flag check, and raise an exception.
    NSSet *settableReadonlyProperties = [[self class] _settableReadonlyPropertyNames];
    if (!_allowsSettingReadonlyIVars && [settableReadonlyProperties containsObject:key]) {
        [NSException raise:ZCREasyDoughExceptionAlreadyBaked format:@"Trying to set value (%@) for read-only key (%@) when the model is immutable!", value, key];
        return;
    }
    
    [super setValue:value forKey:key];
}

- (BOOL)isEqual:(id)object {
    if (self == object) { return YES; }
    if (![object isKindOfClass:[self class]]) { return NO; }
    
    ZCREasyDough *other = object;
    
    return [_uniqueIdentifier isEqual:other->_uniqueIdentifier];
}

- (NSUInteger)hash {
    return [_uniqueIdentifier hash];
}

- (NSString *)description {
    NSDictionary *ingredients = [self dictionaryWithValuesForKeys:[[[self class] allPropertyNames] allObjects]];
    NSMutableDictionary *mutableIngredients = [ingredients copy];
    
    [ingredients enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        // To avoid potential infinite recursion bugs, we abbreviate other model descriptions
        if ([obj isKindOfClass:[ZCREasyDough class]]) {
            mutableIngredients[key] = [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([obj class]), obj];
        }
    }];
    
    NSString *baseDescription = [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
    
    if (mutableIngredients) {
        return [baseDescription stringByAppendingFormat:@" %@", mutableIngredients];
    } else {
        return baseDescription;
    }
}


#pragma mark Introspection

+ (NSSet *)_properties {
    NSSet *storedProperties = objc_getAssociatedObject(self, _cmd);
    if (storedProperties) { return storedProperties; }
    
    NSMutableSet *mutableProperties = [NSMutableSet set];
    
    // We expose properties up till ZCREasyDough to prevent exposing non-user defined properties.
    Class rootClass = [ZCREasyDough class];
    Class currentClass = self;
    NSSet *currentProperties = nil;
    
    while (currentClass != rootClass) {
        currentProperties = [ZCREasyProperty propertiesForClass:currentClass];
        if (currentProperties) {
            [mutableProperties unionSet:currentProperties];
        }
        currentClass = [currentClass superclass];
    }
    objc_setAssociatedObject(self, _cmd, mutableProperties, OBJC_ASSOCIATION_COPY);
    
    return [mutableProperties copy];
}

+ (NSSet *)_settablePropertyNames {
    NSSet *storedProperties = objc_getAssociatedObject(self, _cmd);
    if (storedProperties) { return storedProperties; }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == YES AND %K == nil", NSStringFromSelector(@selector(isReadOnly)), NSStringFromSelector(@selector(iVarName))];
    NSSet *invalidProperties = [[self _properties] filteredSetUsingPredicate:predicate];
    
    NSMutableSet *mutableProperties = [[self _properties] mutableCopy];
    [mutableProperties minusSet:invalidProperties];
    
    storedProperties = [mutableProperties valueForKey:NSStringFromSelector(@selector(name))];
    
    objc_setAssociatedObject(self, _cmd, storedProperties, OBJC_ASSOCIATION_RETAIN);
    return storedProperties;
}

+ (NSSet *)_settableReadonlyPropertyNames {
    NSSet *storedProperties = objc_getAssociatedObject(self, _cmd);
    if (storedProperties) { return storedProperties; }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == YES AND %K != nil", NSStringFromSelector(@selector(isReadOnly)), NSStringFromSelector(@selector(iVarName))];
    storedProperties = [[self _properties] filteredSetUsingPredicate:predicate];
    storedProperties = [storedProperties valueForKey:NSStringFromSelector(@selector(name))];
    
    objc_setAssociatedObject(self, _cmd, storedProperties, OBJC_ASSOCIATION_RETAIN);
    return storedProperties;
}

+ (NSSet *)allPropertyNames {
    // We do this associated-object song and dance to cache these sets per class. It's ok if the
    // work is overriden on multiple threads because the result will always be the same!
    NSSet *storedNames = objc_getAssociatedObject(self, _cmd);
    if (storedNames) { return storedNames; }
    
    storedNames = [[self _properties] valueForKey:NSStringFromSelector(@selector(name))];
    objc_setAssociatedObject(self, _cmd, storedNames, OBJC_ASSOCIATION_RETAIN);
    
    return storedNames;
}

+ (void)enumeratePropertiesWith:(void (^)(ZCREasyProperty *, BOOL *))block {
    if (!block) { return; }
    [[self _properties] enumerateObjectsUsingBlock:block];
}

@end


#pragma mark - _ZCREasyChef

@implementation _ZCREasyBaker {
    Class _doughClass;
}
@synthesize identifier = _identifier;
@synthesize ingredients = _ingredients;
@synthesize recipe = _recipe;

- (instancetype)initWithClass:(Class)doughClass {
    NSParameterAssert(doughClass);
    NSAssert([doughClass isSubclassOfClass:[ZCREasyDough class]], @"The class must be a subclass of ZCREasyDough.");
    
    if (!(self = [super init])) { return nil; }
    
    _doughClass = doughClass;
    
    return self;
}

- (instancetype)init {
    return [self initWithClass:[ZCREasyDough class]];
}

- (id)bake {
    if (!self.identifier) {
        self.identifier = [NSUUID UUID];
    }
    
    return [[_doughClass alloc] initWithIdentifier:self.identifier
                                       ingredients:self.ingredients
                                            recipe:self.recipe
                                             error:NULL];
}

- (BOOL)validateKitchen:(NSError *__autoreleasing *)error {
    id tmpDough = [[_doughClass alloc] initWithIdentifier:self.identifier
                                              ingredients:self.ingredients
                                                   recipe:self.recipe
                                                    error:error];
    return (tmpDough != nil);
}

@end

