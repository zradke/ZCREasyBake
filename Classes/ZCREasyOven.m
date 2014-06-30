//
//  ZCREasyOven.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 6/24/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import "ZCREasyOven.h"
#import "ZCREasyError.h"

static BOOL ZCREasyOvenValidateModel(id model, NSError *__autoreleasing *error) {
    if (!model) {
        if (error) {
            *error = ZCREasyBakeError(ZCREasyBakeInvalidModelError, @"Missing a model.");
        }
        
        return NO;
    }
    
    return YES;
}

static BOOL ZCREasyOvenValidateRecipe(ZCREasyRecipe *recipe, NSError *__autoreleasing *error) {
    if (!recipe) {
        if (error) {
            *error = ZCREasyBakeError(ZCREasyBakeInvalidRecipeError, @"Missing a recipe.");
        }
        
        return NO;
    }
    
    return YES;
}

static NSDictionary *ZCREasyOvenMapIngredients(id rawIngredients, ZCREasyRecipe *recipe, NSError *__autoreleasing *error) {
    if (ZCREasyOvenValidateRecipe(recipe, error)) {
        return [recipe processIngredients:rawIngredients error:error];
    } else {
        return nil;
    }
}

static BOOL ZCREasyOvenModelIsEqual(id model, id rawIngredients, ZCREasyRecipe *recipe, NSError *__autoreleasing *error) {
    if (!ZCREasyOvenValidateModel(model, error)) { return NO; }
    
    NSDictionary *mappedIngredients = ZCREasyOvenMapIngredients(rawIngredients, recipe, error);
    if (!mappedIngredients) { return NO; }
    
    id modelValue, ingredientValue;
    for (NSString *propertyKey in mappedIngredients) {
        modelValue = [model valueForKey:propertyKey];
        ingredientValue = mappedIngredients[propertyKey];
        if (ingredientValue == [NSNull null]) { ingredientValue = nil; }
        
        if (![modelValue isEqual:ingredientValue] && (modelValue || ingredientValue)) {
            return NO;
        }
    }
    
    return YES;
}

static BOOL ZCREasyOvenPopulateModel(id model, id rawIngredients, ZCREasyRecipe *recipe, NSError *__autoreleasing *error) {
    if (!ZCREasyOvenValidateModel(model, error)) { return NO; }
    
    NSDictionary *mappedIngredients = ZCREasyOvenMapIngredients(rawIngredients, recipe, error);
    if (!mappedIngredients) { return NO; }
    
    id ingredientValue;
    for (NSString *propertyKey in mappedIngredients) {
        ingredientValue = mappedIngredients[propertyKey];
        if (ingredientValue == [NSNull null]) { ingredientValue = nil; }
        
        [model setValue:ingredientValue forKey:propertyKey];
    }
    
    return YES;
}

static void ZCREasyOvenFillLocation(id location, id fillPiece, id fillValue) {
    if ([fillPiece isKindOfClass:[NSString class]]) {
        [location setObject:fillValue forKey:fillPiece];
    } else if ([fillPiece isKindOfClass:[NSNumber class]]) {
        NSUInteger valueIndex = [fillPiece unsignedIntegerValue];
        for (NSUInteger i = [location count]; i < valueIndex; i++) {
            [location setObject:[NSNull null] atIndex:i];
        }
        [location setObject:fillValue atIndex:valueIndex];
    }
}

static id ZCREasyOvenGetLocationForPiece(id piece, id currentLocation) {
    if ([piece isKindOfClass:[NSString class]]) {
        return currentLocation[piece];
    } else if ([piece isKindOfClass:[NSNumber class]]) {
        NSUInteger pieceIndex = [piece unsignedIntegerValue];
        if (pieceIndex < [currentLocation count]) {
            return currentLocation[pieceIndex];
        }
    }
    
    return nil;
}

static id ZCREasyOvenNewLocationForPiece(id piece) {
    if ([piece isKindOfClass:[NSString class]]) {
        return [NSMutableDictionary dictionary];
    } else if ([piece isKindOfClass:[NSNumber class]]) {
        return [NSMutableArray array];
    } else {
        return nil;
    }
}

static void ZCREasyOvenUpdateIngredients(id value, NSArray *components, id mutableIngredients) {
    id currentLocation = mutableIngredients;
    id newLocation, placeholderPiece;
    for (id piece in components) {
        if (placeholderPiece) {
            newLocation = ZCREasyOvenNewLocationForPiece(piece);
            ZCREasyOvenFillLocation(currentLocation, placeholderPiece, newLocation);
            currentLocation = newLocation;
            placeholderPiece = piece;
        } else {
            newLocation = ZCREasyOvenGetLocationForPiece(piece, currentLocation);
            if (newLocation && newLocation != [NSNull null]) {
                currentLocation = newLocation;
            } else  {
                placeholderPiece = piece;
            }
        }
    }
    
    ZCREasyOvenFillLocation(currentLocation, [components lastObject], value);
}

static id ZCREasyOvenDecomposeModel(id model, ZCREasyRecipe *recipe, NSError *__autoreleasing *error) {
    if (!ZCREasyOvenValidateModel(model, error) ||
        !ZCREasyOvenValidateRecipe(recipe, error)) {
        return nil;
    }
    
    NSArray *testComponents = [[recipe.ingredientMappingComponents allValues] firstObject];
    id mutableIngredients = ZCREasyOvenNewLocationForPiece([testComponents firstObject]);
    if (!mutableIngredients) {
        if (error) {
            *error = ZCREasyBakeError(ZCREasyBakeInvalidRecipeError, @"Recipe has invalid mapping components.");
        }
        
        return nil;
    }
    
    id modelValue;
    NSValueTransformer *transformer;
    for (NSString *propertyName in recipe.propertyNames) {
        modelValue = [model valueForKey:propertyName];
        transformer = recipe.ingredientTransformers[propertyName];
        if (transformer && [[transformer class] allowsReverseTransformation]) {
            modelValue = [transformer reverseTransformedValue:modelValue];
        }
        if (!modelValue) { modelValue = [NSNull null]; }
        
        ZCREasyOvenUpdateIngredients(modelValue, recipe.ingredientMappingComponents[propertyName], mutableIngredients);
    }
    
    return [mutableIngredients copy];
}


@implementation ZCREasyOven

+ (BOOL)populateModel:(id)model ingredients:(id)rawIngredients recipe:(ZCREasyRecipe *)recipe error:(NSError *__autoreleasing *)error {
    @try {
        return ZCREasyOvenPopulateModel(model, rawIngredients, recipe, error);
    }
    @catch (NSException *exception) {
        if (error) { *error = ZCREasyBakeExceptionError(exception); }
        return NO;
    }
}

+ (BOOL)isModel:(id)model equalToIngredients:(id)rawIngredients recipe:(ZCREasyRecipe *)recipe error:(NSError *__autoreleasing *)error {
    @try {
        return ZCREasyOvenModelIsEqual(model, rawIngredients, recipe, error);
    }
    @catch (NSException *exception) {
        if (error) { *error = ZCREasyBakeExceptionError(exception); }
        return NO;
    }
}

+ (id)decomposeModel:(id)model withRecipe:(ZCREasyRecipe *)recipe error:(NSError *__autoreleasing *)error {
    @try {
        return ZCREasyOvenDecomposeModel(model, recipe, error);
    }
    @catch (NSException *exception) {
        if (error) { *error = ZCREasyBakeExceptionError(exception); }
        return nil;
    }
}

- (instancetype)init {
    [NSException raise:NSInternalInconsistencyException format:@"This method is unavailable. Please use the provided class methods instead."];
    return nil;
}

@end
