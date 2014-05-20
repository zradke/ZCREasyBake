//
//  ZCREasyDoughTransformer.h
//  ZCREasyBake
//
//  Created by Zachary Radke on 5/14/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZCREasyRecipe;

/**
 *  ZCREasyDoughTransformer provides a concrete NSValueTransformer class that can create
 *  ZCREasyDough models and decompose them into raw ingredients. The transformer should be given
 *  raw ingredients to turn into models. The class also supports reverse transformations, turning
 *  baked models back into raw ingredients.
 */
@interface ZCREasyDoughTransformer : NSValueTransformer

/**
 *  Designated initializer for this class. Creates a value transformer for the given dough class and
 *  recipe.
 *
 *  @param doughClass      The model class to serialize. This must not be nil and must be a subclass
 *                         of ZCREasyDough.
 *  @param recipe          The recipe to use for populating and decomposing models.
 *  @param identifierBlock An optional block invoked to generate a unique identifier for the new
 *                         model. To provide context, the raw ingredients are passed. If this block
 *                         is nil, each instance will be assigned a unique identifier. If set, this
 *                         block must return a value or there will be serialization errors. This
 *                         block is retained for the lifecycle of this instance, so beware retain
 *                         cycles.
 *
 *  @return A new value transformer for the given dough class and recipe.
 */
- (instancetype)initWithDoughClass:(Class)doughClass recipe:(ZCREasyRecipe *)recipe
                   identifierBlock:(id<NSObject,NSCopying> (^)(id rawIngredients))identifierBlock;

/**
 *  Stores the last serialization error, if any.
 */
@property (strong, nonatomic, readonly) NSError *error;

@end
