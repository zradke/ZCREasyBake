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

NSString *const ZCREasyDoughExceptionAlreadyBaked = @"com.zachradke.easyBake.easyDough.exception.alreadyBaked";

NSString *const ZCREasyDoughUpdatedNotification = @"com.zachradke.easyBake.easyDough.notifications.updated";

@interface _ZCREasyBaker : NSObject <ZCREasyBaker> {
    Class _doughClass;
}

@property (copy, nonatomic) NSString *identifier;
@property (copy, nonatomic) NSDictionary *ingredients;
@property (strong, nonatomic) ZCREasyRecipe *recipe;

- (instancetype)initWithClass:(Class)doughClass;
- (id)bake;

@end

#pragma mark - ZCREasyDough

@implementation ZCREasyDough

- (instancetype)initWithIdentifier:(id<NSObject,NSCopying>)identifier
                       ingredients:(NSDictionary *)ingredients
                            recipe:(ZCREasyRecipe *)recipe
                             error:(NSError *__autoreleasing *)error {
    if (!identifier) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing a unique identifier!");
        }
        return nil;
    }
    
    NSDictionary *mappedIngredients = [[self class] _mappedIngredients:ingredients
                                                            withRecipe:recipe
                                                                 error:error];
    if (!mappedIngredients) { return nil; }
    if (!(self = [super init])) { return nil; }
    
    _uniqueIdentifier = [(id)identifier copy];
    
    @try {
        // During the course of initialization, we temporarily allow the use of setValue:forKey: for
        // read-only properties.
        _allowsSettingValues = YES;
        [mappedIngredients enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, id ingredientValue, BOOL *stop) {
            // Null values are remapped to nil
            if (ingredientValue == (id)[NSNull null]) { ingredientValue = nil; }
            [self setValue:ingredientValue forKey:propertyName];
        }];
        _allowsSettingValues = NO;
    }
    @catch (NSException *exception) {
        if (error) {
            *error = ZCREasyBakeExceptionError(exception);
        }
        return nil;
    }
    
    return self;
}

- (instancetype)init {
    // Because an identifier is necessary for initializing an instance, we create one manually
    // rather than leaving a useless init method.
    id identifier = nil;
    if ([NSUUID class]) {
        identifier = [NSUUID UUID];
    } else {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        identifier = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
        CFRelease(uuid);
    }
    
    return [self initWithIdentifier:identifier ingredients:nil recipe:nil error:NULL];
}

+ (instancetype)makeWith:(void (^)(id<ZCREasyBaker>))preparationBlock {
    if (!preparationBlock) { return nil; }
    
    _ZCREasyBaker *chef = [[_ZCREasyBaker alloc] initWithClass:self];
    preparationBlock(chef);
    
    return [chef bake];
}

- (instancetype)updateWithIngredients:(NSDictionary *)ingredients
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
        
        // However we ultimately use our own generic recipe to merge in our existing properties and
        // then populate the new instance.
        ZCREasyRecipe *genericRecipe = [[self class] _genericRecipe];
        NSDictionary *existingIngredients = [self _decomposeWithRecipe:genericRecipe
                                                                 error:error];
        if (!existingIngredients) { return nil; }
        
        NSMutableDictionary *mergedIngredients = [existingIngredients mutableCopy];
        [mappedIngredients enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            mergedIngredients[key] = obj;
        }];
        
        ZCREasyDough *updatedDough = [[[self class] alloc] initWithIdentifier:_uniqueIdentifier
                                                                  ingredients:mergedIngredients
                                                                       recipe:genericRecipe
                                                                        error:error];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ZCREasyDoughUpdatedNotification
                                                            object:self userInfo:nil];
        
        NSString *classUpdateNotification = [[self class] updateNotificationName];
        if (classUpdateNotification) {
            [[NSNotificationCenter defaultCenter] postNotificationName:classUpdateNotification
                                                                object:self userInfo:nil];
        }
        
        return updatedDough;
    }
}

- (instancetype)updateWith:(void (^)(id<ZCREasyBaker>))updateBlock {
    if (!updateBlock) { return nil; }
    
    _ZCREasyBaker *chef = [[_ZCREasyBaker alloc] initWithClass:[self class]];
    updateBlock(chef);
    
    return [self updateWithIngredients:chef.ingredients recipe:chef.recipe error:NULL];
}

+ (NSString *)updateNotificationName {
    if (self == [ZCREasyDough class]) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"com.zachradke.easyBake.%@.notifications.updated",
                                          NSStringFromClass(self)];
    }
}

- (NSDictionary *)decomposeWithRecipe:(ZCREasyRecipe *)recipe
                                error:(NSError *__autoreleasing *)error {
    // We split this into a private method to prevent subclasses from breaking the behavior
    return [self _decomposeWithRecipe:recipe error:error];
}

- (NSDictionary *)_decomposeWithRecipe:(ZCREasyRecipe *)recipe
                                 error:(NSError * __autoreleasing *)error {
    if (!recipe) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing a recipe!");
        }
        return nil;
    }
    
    if (![recipe.propertyNames isSubsetOfSet:[[self class] allPropertyNames]]) {
        if (error) {
            NSMutableSet *unknownNames = [recipe.propertyNames mutableCopy];
            [unknownNames minusSet:[[self class] allPropertyNames]];
            *error = ZCREasyBakeParameterError(@"The recipe contains unknown property names: %@",
                                               unknownNames);
        }
        return nil;
    }
    
    NSMutableDictionary *ingredients = [NSMutableDictionary dictionary];
    @try {
        __block id value;
        [recipe enumerateInstructionsWith:^(NSString *propertyName, NSString *ingredientName, NSValueTransformer *transformer, BOOL *shouldStop) {
            value = [self valueForKey:propertyName];
            
            // We only accept reversible value transformations for decomposition
            if (transformer && [[transformer class] allowsReverseTransformation]) {
                value = [transformer reverseTransformedValue:value];
            }
            
            // Since we guarantee that all keys in the recipe will be fulfilled in the returned
            // dictionary, we convert nil values to NSNull
            if (!value) { value = [NSNull null]; }
            
            ingredients[ingredientName] = value;
        }];
    }
    @catch (NSException *exception) {
        if (error) {
            *error = ZCREasyBakeExceptionError(exception);
        }
        ingredients = nil;
    }
    
    return [ingredients copy];
}

- (BOOL)isEqualToIngredients:(NSDictionary *)ingredients
                  withRecipe:(ZCREasyRecipe *)recipe
                       error:(NSError *__autoreleasing *)error {
    // A recipe is required in this method, otherwise it cannot be determined which keys to check
    // for equality. Similarly, ingredients should also be present.
    if (!recipe || !ingredients) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing recipe and/or ingredients!");
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
        isEqual = NO;
    }
    
    return isEqual;
}

+ (ZCREasyRecipe *)genericRecipe {
    // We split this into a private method to prevent subclasses from breaking the behavior
    return [self _genericRecipe];
}

+ (ZCREasyRecipe *)_genericRecipe {
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


#pragma mark Private utilities

+ (NSDictionary *)_mappedIngredients:(NSDictionary *)ingredients
                          withRecipe:(ZCREasyRecipe *)recipe
                               error:(NSError **)error {
    // If there are no ingredients or recipe, we consider the mapping a success and return an
    // empty dictionary.
    if (!ingredients && !recipe) { return [NSDictionary dictionary]; }
    
    if (ingredients && !recipe) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing a recipe for the ingredients.");
        }
        return nil;
    }
    
    if (![recipe.propertyNames isSubsetOfSet:[self.class allPropertyNames]]) {
        if (error) {
            NSMutableSet *unknownNames = [recipe.propertyNames mutableCopy];
            [unknownNames minusSet:[[self class] allPropertyNames]];
            *error = ZCREasyBakeParameterError(@"The recipe contains unknown property names: %@",
                                               unknownNames);
        }
        return nil;
    }
    
    return [recipe processIngredients:ingredients];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    // Theoretically if this model is entirely composed of readonly properties we could just return
    // self. However, since we cannot guarantee that, we new instance.
    ZCREasyRecipe *recipe = [[self class] _genericRecipe];
    NSDictionary *ingredients = [self _decomposeWithRecipe:recipe error:NULL];
    if (ingredients) {
        return [[[self class] allocWithZone:zone] initWithIdentifier:_uniqueIdentifier
                                                         ingredients:ingredients
                                                              recipe:recipe
                                                               error:NULL];
    } else {
        return nil;
    }
}


#pragma mark NSObject

- (void)setValue:(id)value forKey:(NSString *)key {
    // To prevent setting iVars of read-only properties outside of the initializer, we use a simple
    // flag check, and raise an exception.
    if (!_allowsSettingValues) {
        if ([[self.class _readonlyPropertyNames] containsObject:key]) {
            NSString *reason = [NSString stringWithFormat:@"Trying to set value for key (%@) "
                                                          @"when the model is immutable!", key];
            NSException *exception = [NSException exceptionWithName:ZCREasyDoughExceptionAlreadyBaked
                                                             reason:reason
                                                           userInfo:nil];
            [exception raise];
            return;
        }
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
    NSDictionary *ingredients = [self _decomposeWithRecipe:[[self class] _genericRecipe] error:NULL];
    NSMutableDictionary *mutableIngredients = [ingredients copy];
    [ingredients enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        // To avoid potential infinite recursion bugs, we abbreviate other model descriptions
        if ([obj isKindOfClass:[ZCREasyDough class]]) {
            mutableIngredients[key] = [NSString stringWithFormat:@"<%@:%p>",
                                       NSStringFromClass([obj class]), obj];
        }
    }];
    
    NSString *baseDescription = [NSString stringWithFormat:@"<%@:%p>",
                                 NSStringFromClass([self class]), self];
    
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

+ (NSSet *)_readonlyPropertyNames {
    NSSet *storedProperties = objc_getAssociatedObject(self, _cmd);
    if (storedProperties) { return storedProperties; }
    
    // We are looking for read-only properties that have a backing iVar
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == YES AND %K != nil",
                              NSStringFromSelector(@selector(isReadOnly)),
                              NSStringFromSelector(@selector(iVarName))];
    storedProperties = [[[self _properties] filteredSetUsingPredicate:predicate]
                        valueForKey:NSStringFromSelector(@selector(name))];
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

+ (void)enumeratePropertiesUsingBlock:(void (^)(ZCREasyProperty *, BOOL *))block {
    if (!block) { return; }
    [[self _properties] enumerateObjectsUsingBlock:block];
}

@end


#pragma mark - _ZCREasyChef

@implementation _ZCREasyBaker

- (instancetype)initWithClass:(Class)doughClass {
    NSParameterAssert(doughClass);
    NSAssert([doughClass isSubclassOfClass:[ZCREasyDough class]],
             @"The class must be a subclass of ZCREasyDough.");
    
    if (!(self = [super init])) { return nil; }
    
    _doughClass = doughClass;
    
    return self;
}

- (instancetype)init {
    return [self initWithClass:[ZCREasyDough class]];
}

- (id)bake {
    if (!self.identifier) {
        if ([NSUUID class]) {
            self.identifier = [NSUUID UUID];
        } else {
            CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
            self.identifier = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault,
                                                                               uuid);
            CFRelease(uuid);
        }
    }
    
    return [[_doughClass alloc] initWithIdentifier:self.identifier
                                       ingredients:self.ingredients
                                            recipe:self.recipe
                                             error:NULL];
}

- (BOOL)validateKitchen:(NSError *__autoreleasing *)error {
    if (self.ingredients && !self.recipe) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing a recipe for the ingredients!");
        }
        return NO;
    }
    
    NSSet *recipePropertyNames = self.recipe.propertyNames;
    NSSet *doughPropertyNames = [_doughClass allPropertyNames];
    if (![recipePropertyNames isSubsetOfSet:doughPropertyNames]) {
        if (error) {
            NSMutableSet *unknownNames = [recipePropertyNames mutableCopy];
            [unknownNames minusSet:doughPropertyNames];
            *error = ZCREasyBakeParameterError(@"The recipe contains unknown property names: %@",
                                               unknownNames);
        }
        return NO;
    }
    
    return YES;
}

@end

