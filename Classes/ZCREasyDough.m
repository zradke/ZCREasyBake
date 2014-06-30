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
#import "ZCREasyOven.h"

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
    
    if (!(self = [super init])) { return nil; }
    
    _uniqueIdentifier = [(id)identifier copy];
    
    if (![self _setIngredients:ingredients recipe:recipe error:error]) { return nil; }
    
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
        id updatedDough = [self copy];
        if (![updatedDough _setIngredients:ingredients recipe:recipe error:error]) {
            return nil;
        }
        
        // Since we don't rely on pointers to determine equality, we pass the identifier and updated
        // model in the user-info to identify the model.
        NSDictionary *userInfo = @{ZCREasyDoughIdentifierKey: [(id)_uniqueIdentifier copy],
                                   ZCREasyDoughUpdatedDoughKey: updatedDough};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ZCREasyDoughUpdateNotification
                                                            object:self userInfo:userInfo];
        
        NSString *classUpdateNotification = [[self class] updateNotificationName];
        if (classUpdateNotification && ![classUpdateNotification isEqualToString:ZCREasyDoughUpdateNotification]) {
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
    return [ZCREasyOven decomposeModel:self withRecipe:recipe error:error];
}

- (BOOL)isEqualToIngredients:(id)ingredients
                  withRecipe:(ZCREasyRecipe *)recipe
                       error:(NSError *__autoreleasing *)error {
    return [ZCREasyOven isModel:self equalToIngredients:ingredients recipe:recipe error:error];
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


#pragma mark Private utilities

- (BOOL)_setIngredients:(id)ingredients recipe:(ZCREasyRecipe *)recipe error:(NSError *__autoreleasing *)error {
    if (!ingredients) { return YES; }
    
    BOOL didAllowSettingReadonlyIVars = _allowsSettingReadonlyIVars;
    _allowsSettingReadonlyIVars = YES;
    
    BOOL success = [ZCREasyOven populateModel:self ingredients:ingredients recipe:recipe error:error];
    
    _allowsSettingReadonlyIVars = didAllowSettingReadonlyIVars;
    
    return success;
}


#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] initWithIdentifier:_uniqueIdentifier ingredients:nil recipe:nil
                                                 error:NULL];
    ZCREasyRecipe *recipe = [[self class] genericRecipe];
    id ingredients = [ZCREasyOven decomposeModel:self withRecipe:recipe error:NULL];
    if ([copy _setIngredients:ingredients recipe:recipe error:NULL]) {
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
    } else {
        [super setValue:value forKey:key];
    }
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
    NSDictionary *ingredients = [self decomposeWithRecipe:[[self class] genericRecipe] error:NULL];
    NSMutableDictionary *mutableIngredients = [ingredients mutableCopy];
    [ingredients enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        // To avoid potential infinite recursion bugs, we abbreviate other model descriptions
        if ([obj isKindOfClass:[ZCREasyDough class]]) {
            mutableIngredients[key] = [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([obj class]), obj];
        } else if (obj == [NSNull null]) {
            [mutableIngredients removeObjectForKey:key];
        }
    }];
    
    NSString *baseDescription = [NSString stringWithFormat:@"<%@:%p>", [self class], self];
    if (mutableIngredients.count > 0) {
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
    NSSet *currentProperties;
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
    NSParameterAssert(block);
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

