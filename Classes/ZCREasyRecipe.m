//
//  ZCREasyRecipe.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/24/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import "ZCREasyRecipe.h"

#import "ZCREasyError.h"

@interface _ZCREasyRecipeMaker : NSObject <ZCREasyRecipeMaker>
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSDictionary *ingredientMapping;
@property (copy, nonatomic) NSDictionary *ingredientTransformers;

- (ZCREasyRecipe *)makeRecipe;
@end


#pragma mark - ZCREasyRecipe

@implementation ZCREasyRecipe
@synthesize propertyNames = _propertyNames;

#pragma mark Public API

- (instancetype)initWithName:(NSString *)name
           ingredientMapping:(NSDictionary *)ingredientMapping
      ingredientTransformers:(NSDictionary *)ingredientTransformers
                       error:(NSError *__autoreleasing *)error {
    if (!(self = [super init])) { return nil; }
    
    _name = [name copy];
    
    if (!ingredientMapping) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing ingredient mapping!");
        }
        return nil;
    }
    _ingredientMapping = [ingredientMapping copy];
    
    NSDictionary *ingredientComponents = [self _breakDownMapping:_ingredientMapping error:error];
    if (!ingredientComponents) { return nil; }
    _ingredientMappingComponents = ingredientComponents;
    
    ingredientTransformers = [self _normalizeTransformers:ingredientTransformers
                                                            error:error];
    if (!ingredientTransformers) { return nil; }
    _ingredientTransformers = ingredientTransformers;
    
    return self;
}

+ (instancetype)makeWith:(void (^)(id<ZCREasyRecipeMaker>))constructionBlock {
    if (!constructionBlock) { return nil; }
    
    _ZCREasyRecipeMaker *maker = [[_ZCREasyRecipeMaker alloc] init];
    constructionBlock(maker);
    
    return [maker makeRecipe];
}

- (instancetype)modifyWith:(void (^)(id<ZCREasyRecipeMaker>))modificationBlock {
    if (!modificationBlock) { return self; }
    
    _ZCREasyRecipeMaker *maker = [[_ZCREasyRecipeMaker alloc] init];
    maker.name = self.name;
    maker.ingredientMapping = self.ingredientMapping;
    maker.ingredientTransformers = self.ingredientTransformers;
    modificationBlock(maker);
    
    return [maker makeRecipe];
}

- (NSDictionary *)processIngredients:(id)ingredients
                               error:(NSError *__autoreleasing *)error {
    // We treat no ingredients as success
    if (!ingredients) { return [NSDictionary dictionary]; }
    
    id ingredientValue;
    NSMutableDictionary *processedIngredients = [NSMutableDictionary dictionary];
    
    @try {
        for (NSString *propertyName in self.propertyNames) {
            ingredientValue = [self _valueForProperty:propertyName ingredients:ingredients];
            if (ingredientValue) {
                processedIngredients[propertyName] = ingredientValue;
            }
        }
    }
    @catch (NSException *exception) {
        if (error) {
            *error = ZCREasyBakeExceptionError(exception);
        }
        return nil;
    }
    
    return [processedIngredients copy];
}

- (id)_valueForProperty:(NSString *)propertyName ingredients:(id)ingredients {
    id currentValue = ingredients;
    
    NSArray *components = self.ingredientMappingComponents[propertyName];
    for (id piece in components) {
        if ([piece isKindOfClass:[NSString class]]) {
            currentValue = [currentValue objectForKey:piece];
        } else {
            currentValue = [currentValue objectAtIndex:[piece unsignedIntegerValue]];
        }
    }
    
    if (currentValue) {
        NSValueTransformer *transformer = self.ingredientTransformers[propertyName];
        if (transformer) {
            if (currentValue == [NSNull null]) {
                currentValue = nil;
            }
            currentValue = [transformer transformedValue:currentValue];
            if (!currentValue) {
                currentValue = [NSNull null];
            }
        }
    }
    
    return currentValue;
}

- (void)enumerateInstructionsWith:(void (^)(NSString *, NSString *, NSValueTransformer *, BOOL *))block {
    if (!block) { return; }
    
    NSDictionary *ingredientTransformers = self.ingredientTransformers;
    __block NSValueTransformer *transformer;
    [self.ingredientMapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        transformer = ingredientTransformers[key];
        block(key, obj, transformer, stop);
    }];
}

- (NSSet *)propertyNames {
    if (!_propertyNames) {
        _propertyNames = [NSSet setWithArray:[self.ingredientMapping allKeys]];
    }
    
    return _propertyNames;
}


#pragma mark NSObject

+ (BOOL)accessInstanceVariablesDirectly {
    // To ensure immutability we prevent any KVO hijinks!
    return NO;
}

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"<%@:%p>",
                             NSStringFromClass([self class]), self];
    
    if (self.name) {
        description = [description stringByAppendingFormat:@" name:%@", self.name];
    }
    
    NSMutableArray *instructions = [NSMutableArray array];
    [self enumerateInstructionsWith:^(NSString *propertyName, NSString *ingredientPath, NSValueTransformer *transformer, BOOL *shouldStop) {
        NSString *instruction = nil;
        if (!transformer) {
            instruction = [NSString stringWithFormat:@"%@ ==> %@", ingredientPath, propertyName];
        } else {
            NSString *annotation = [NSString stringWithFormat:@"(%@:%p)",
                                    NSStringFromClass([transformer class]), transformer];
            if ([[transformer class] allowsReverseTransformation]) {
                instruction = [NSString stringWithFormat:@"%@ <=%@=> %@",
                                      ingredientPath, annotation, propertyName];
            } else {
                instruction = [NSString stringWithFormat:@"%@ =%@=> %@",
                               ingredientPath, annotation, propertyName];
            }
        }
        [instructions addObject:instruction];
    }];
    
    return [description stringByAppendingFormat:@" instructions:%@",
            [instructions sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
}

- (NSUInteger)hash {
    return [self.name hash] ^ [self.ingredientMapping hash] ^ [self.ingredientTransformers hash];
}

- (BOOL)isEqual:(id)object {
    if (object == self) { return YES; }
    if (![object isKindOfClass:[self class]]) { return NO; }
    
    ZCREasyRecipe *other = object;
    BOOL equalNames = (!self.name && !other.name) || [self.name isEqualToString:other.name];
    BOOL equalMapping = [self.ingredientMapping isEqualToDictionary:other.ingredientMapping];
    BOOL equalTransformers = (!self.ingredientTransformers && !other.ingredientTransformers) ||
                             [self.ingredientTransformers isEqualToDictionary:other.ingredientTransformers];
    
    return equalNames && equalMapping && equalTransformers;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark Private utilities

- (NSDictionary *)_breakDownMapping:(NSDictionary *)ingredientMapping
                              error:(NSError * __autoreleasing *)error {
    NSParameterAssert(ingredientMapping);
    
    __block NSMutableDictionary *ingredientComponents = [NSMutableDictionary dictionary];
    [ingredientMapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSArray *components = [self _breakDownIngredientPath:obj error:error];
        if (components) {
            ingredientComponents[key] = components;
        } else { // There was an error
            *stop = YES;
            ingredientComponents = nil;
        }
    }];
    
    // We need to make sure that all mappings share the same root object, either a dictionary if
    // all the first pieces are strings, or an array if they are all numbers.
    NSArray *allComponents = [ingredientComponents allValues];
    Class rootClass;
    for (NSArray *components in allComponents) {
        if (!rootClass) {
            id testPiece = [components firstObject];
            rootClass = [testPiece isKindOfClass:[NSString class]] ? [NSString class] : [NSNumber class];
        } else if (![[components firstObject] isKindOfClass:rootClass]) {
            if (error) {
                *error = ZCREasyBakeParameterError(@"Invalid ingredient mapping. The mapping must "
                                                   @"share the same root object, represented as a "
                                                   @"dictionary or array.");
            }
            return nil;
        }
    }
    
    return [ingredientComponents copy];
}

- (NSArray *)_breakDownIngredientPath:(NSString *)ingredientPath
                                error:(NSError * __autoreleasing *)error {
    NSParameterAssert(ingredientPath);
    
    NSMutableArray *components = [NSMutableArray array];
    NSArray *splitPath = [ingredientPath componentsSeparatedByString:@"."];
    for (NSString *piece in splitPath) {
        NSString *keyPath;
        NSScanner *scanner = [NSScanner scannerWithString:piece];
        if ([scanner scanUpToString:@"[" intoString:&keyPath] && keyPath) {
            [components addObject:keyPath];
        }
        
        NSInteger arrayIndex;
        while (!scanner.isAtEnd) {
            if ([scanner scanString:@"[" intoString:NULL] &&
                [scanner scanInteger:&arrayIndex] &&
                [scanner scanString:@"]" intoString:NULL]) {
                [components addObject:[NSNumber numberWithInteger:arrayIndex]];
            } else {
                if (error) {
                    *error = ZCREasyBakeParameterError(@"Invalid ingredient path: %@. Arrays must "
                                                       @"be reference in the format: [<index>]",
                                                       ingredientPath);
                }
                components = nil;
                break;
            }
        }
    }
    
    return [components copy];
}

- (NSDictionary *)_normalizeTransformers:(NSDictionary *)ingredientTransformers
                                   error:(NSError * __autoreleasing *)error {
    // Ingredient transformers are optional, so if they are absent we treat it as a success.
    if (!ingredientTransformers) {
        return [NSDictionary dictionary];
    }
    
    NSSet *propertyKeys = [NSSet setWithArray:[_ingredientMapping allKeys]];
    NSSet *transformedKeys = [NSSet setWithArray:[ingredientTransformers allKeys]];
    
    // If the ingredient transformers have unmapped keys we treat it as a failure.
    if (![transformedKeys isSubsetOfSet:propertyKeys]) {
        if (error) {
            NSMutableSet *unknownKeys = [transformedKeys mutableCopy];
            [unknownKeys minusSet:propertyKeys];
            *error = ZCREasyBakeParameterError(@"The ingredient transformers have unmapped keys: %@",
                                               unknownKeys);
        }
        return nil;
    }
    
    __block NSMutableDictionary *mutableTransformers = [ingredientTransformers mutableCopy];
    [ingredientTransformers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:obj];
            if (transformer) {
                mutableTransformers[key] = transformer;
            } else {
                if (error) {
                    *error = ZCREasyBakeParameterError(@"No registered transformer was found under "
                                                       @"the name (%@) for property (%@)", obj, key);
                }
                mutableTransformers = nil;
                *stop = YES;
            }
        } else if (![obj isKindOfClass:[NSValueTransformer class]]) {
            if (error) {
                *error = ZCREasyBakeParameterError(@"Object (%@) for key (%@) is not an "
                                                   @"NSValueTransformer.", obj, key);
            }
            mutableTransformers = nil;
            *stop = YES;
        }
    }];
    
    return [mutableTransformers copy];
}

@end


#pragma mark - ZCREasyRecipeBox

@interface ZCREasyRecipeBox ()
@property (copy, atomic) NSDictionary *recipes;
@end

@implementation ZCREasyRecipeBox
@dynamic recipeNames;

#pragma mark Public API

+ (instancetype)defaultBox {
    static ZCREasyRecipeBox *sharedBox;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBox = [[ZCREasyRecipeBox alloc] init];
    });
    return sharedBox;
}

- (instancetype)init {
    if (!(self = [super init])) { return nil; }
    
    _recipes = [NSDictionary dictionary];
    
    return self;
}

- (NSSet *)recipeNames {
    return [NSSet setWithArray:[self.recipes allKeys]];
}

+ (NSSet *)keyPathsForValuesAffectingRecipeNames {
    return [NSSet setWithObject:NSStringFromSelector(@selector(recipes))];
}

- (BOOL)addRecipe:(ZCREasyRecipe *)recipe error:(NSError *__autoreleasing *)error {
    if (!recipe) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing a recipe to add!");
        }
        return NO;
    }
    
    if (!recipe.name) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Recipe is missing a name!");
        }
        return NO;
    }
    
    @synchronized(self) {
        if ([self.recipeNames containsObject:recipe.name]) {
            if (error) {
                *error = ZCREasyBakeParameterError(@"The recipe is already added to this box!");
            }
            return NO;
        }
        
        NSMutableDictionary *recipes = [self.recipes mutableCopy];
        recipes[recipe.name] = recipe;
        self.recipes = recipes;
    }
    return YES;
}

- (ZCREasyRecipe *)addRecipeWith:(void (^)(id<ZCREasyRecipeMaker>))block {
    ZCREasyRecipe *recipe = [ZCREasyRecipe makeWith:block];
    
    // If no name was provided, we create one from a UUID
    if (!recipe.name) {
        NSString *name;
        if ([NSUUID class]) {
            name = [[NSUUID UUID] UUIDString];
        } else {
            CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
            name = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
            CFRelease(uuid);
        }
        recipe = [recipe modifyWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
            recipeMaker.name = name;
        }];
    }
    
    return ([self addRecipe:recipe error:NULL]) ? recipe : nil;
}

- (BOOL)removeRecipeNamed:(NSString *)recipeName error:(NSError *__autoreleasing *)error {
    if (!recipeName) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing recipe name to remove!");
        }
        return NO;
    }
    
    ZCREasyRecipe *recipe = [self recipeWithName:recipeName];
    if (!recipe) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing a recipe to remove!");
        }
        return NO;
    }
    
    @synchronized(self) {
        if (![self.recipeNames containsObject:recipe.name]) {
            if (error) {
                *error = ZCREasyBakeParameterError(@"Recipe to remove was not added to this box!");
            }
            return NO;
        }
        
        NSMutableDictionary *recipes = [self.recipes mutableCopy];
        [recipes removeObjectForKey:recipe.name];
        self.recipes = recipes;
    }
    return YES;
}

- (ZCREasyRecipe *)recipeWithName:(NSString *)recipeName {
    return self.recipes[recipeName];
}

#pragma mark NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:%p> recipeNames:%@",
            NSStringFromClass([self class]), self, self.recipeNames];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end


#pragma mark - _ZCREasyRecipeMaker

@implementation _ZCREasyRecipeMaker

- (BOOL)addInstructionForProperty:(NSString *)propertyName ingredientPath:(NSString *)ingredientPath
                      transformer:(id)transformer error:(NSError *__autoreleasing *)error {
    if (!propertyName) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing a property to add to the recipe.");
        }
        return NO;
    }
    
    if ([[self.ingredientMapping allKeys] containsObject:propertyName]) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Instruction for property (%@) already exists!",
                                               propertyName);
        }
        return NO;
    }
    
    if (!ingredientPath) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing an ingredient path to map the property.");
        }
        return NO;
    }
    
    if (transformer) {
        if ([transformer isKindOfClass:[NSString class]]) {
            NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:transformer];
            if (!valueTransformer) {
                if (error) {
                    *error = ZCREasyBakeParameterError(@"No registered transformer was found for "
                                                       @"the name (%@)", transformer);
                }
                return NO;
            }
            transformer = valueTransformer;
        } else if (![transformer isKindOfClass:[NSValueTransformer class]]) {
            if (error) {
                *error = ZCREasyBakeParameterError(@"Object (%@) is not an NSValueTransformer.",
                                                   transformer);
            }
            return NO;
        }
    }
    
    NSMutableDictionary *mutableMapping = [NSMutableDictionary dictionaryWithDictionary:self.ingredientMapping];
    mutableMapping[propertyName] = ingredientPath;
    self.ingredientMapping = mutableMapping;
    
    if (transformer) {
        NSMutableDictionary *mutableTransformers = [NSMutableDictionary dictionaryWithDictionary:self.ingredientTransformers];
        mutableTransformers[propertyName] = transformer;
        self.ingredientTransformers = mutableTransformers;
    }
    
    return YES;
}

- (BOOL)removeInstructionForProperty:(NSString *)propertyName error:(NSError *__autoreleasing *)error {
    if (!propertyName) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing a property name to remove!");
        }
        return NO;
    }
    
    if (![[self.ingredientMapping allKeys] containsObject:propertyName]) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"No instruction for (%@) has been added!",
                                               propertyName);
        }
        return NO;
    }
    
    NSMutableDictionary *mutableMapping = [self.ingredientMapping mutableCopy];
    [mutableMapping removeObjectForKey:propertyName];
    self.ingredientMapping = mutableMapping;
    
    if (self.ingredientTransformers &&
        [[self.ingredientTransformers allKeys] containsObject:propertyName]) {
        NSMutableDictionary *mutableTransformers = [self.ingredientTransformers mutableCopy];
        [mutableTransformers removeObjectForKey:propertyName];
        self.ingredientTransformers = mutableTransformers;
    }
    
    return YES;
}

- (BOOL)validateRecipe:(NSError *__autoreleasing *)error {
    if (!self.ingredientMapping) {
        if (error) {
            *error = ZCREasyBakeParameterError(@"Missing ingredient mapping!");
        }
        return NO;
    }
    
    if (self.ingredientTransformers.count == 0) { return YES; }
    
    NSSet *propertyNames = [NSSet setWithArray:[self.ingredientMapping allKeys]];
    NSSet *transformerKeys = [NSSet setWithArray:[self.ingredientTransformers allKeys]];
    if (![transformerKeys isSubsetOfSet:propertyNames]) {
        if (error) {
            NSMutableSet *unknownKeys = [transformerKeys mutableCopy];
            [unknownKeys minusSet:propertyNames];
            *error = ZCREasyBakeParameterError(@"The ingredient transformers have unknown keys: %@",
                                               unknownKeys);
        }
        return NO;
    }
    
    __block BOOL transformersValid = YES;
    [self.ingredientTransformers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![obj isKindOfClass:[NSString class]] &&
            ![obj isKindOfClass:[NSValueTransformer class]]) {
            if (error) {
                *error = ZCREasyBakeParameterError(@"Object (%@) is not an NSString or "
                                                   @"NSValueTransformer instance!", obj);
            }
            transformersValid = NO;
            *stop = YES;
        }
    }];
    
    return transformersValid;
}

- (ZCREasyRecipe *)makeRecipe {
    if (![self validateRecipe:NULL]) { return nil; }
    
    return [[ZCREasyRecipe alloc] initWithName:self.name ingredientMapping:self.ingredientMapping
                        ingredientTransformers:self.ingredientTransformers error:NULL];
}

@end
