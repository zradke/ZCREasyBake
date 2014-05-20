//
//  ZCREasyDoughTransformer.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 5/14/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import "ZCREasyDoughTransformer.h"

#import "ZCREasyBake.h"

@implementation ZCREasyDoughTransformer {
    Class _doughClass;
    ZCREasyRecipe *_recipe;
    id<NSObject,NSCopying> (^_identifierBlock)(id);
}

- (instancetype)initWithDoughClass:(Class)doughClass recipe:(ZCREasyRecipe *)recipe
                   identifierBlock:(id<NSObject,NSCopying> (^)(id))identifierBlock {
    NSParameterAssert(doughClass);
    NSParameterAssert(recipe);
    NSAssert([doughClass isSubclassOfClass:[ZCREasyDough class]], @"Transformed class must be a subclass of ZCREasyDough.");
    
    if (!(self = [super init])) { return nil; }
    
    _doughClass = doughClass;
    _recipe = recipe;
    _identifierBlock = [identifierBlock copy];
    
    return self;
}

- (instancetype)init {
    [NSException raise:NSInternalInconsistencyException format:@"Please use the designated initializer for this class."];
    return nil;
}

+ (Class)transformedValueClass {
    return [ZCREasyDough class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if (!value) { return nil; }
    
    id identifier;
    if (_identifierBlock) {
        identifier = _identifierBlock(value);
    } else {
        identifier = [NSUUID UUID];
    }
        
    NSError *error;
    id dough = [[_doughClass alloc] initWithIdentifier:identifier ingredients:value
                                                recipe:_recipe error:&error];
    if (!dough) {
        _error = error;
    }
    
    return dough;
}

- (id)reverseTransformedValue:(id)value {
    if (!value) { return nil; }
    
    NSError *error;
    id ingredients = [value decomposeWithRecipe:_recipe error:&error];
    if (!ingredients) {
        _error = error;
    }
    
    return ingredients;
}

@end
