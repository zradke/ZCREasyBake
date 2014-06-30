//
//  ZCREasyOven.h
//  ZCREasyBake
//
//  Created by Zachary Radke on 6/24/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZCREasyRecipe.h"

/**
 *  The ZCREasyOven class provides class methods for populating, comparing, and decomposing models.
 *  Models are constructed from raw ingredient trees represented by NSDictionary and NSArray
 *  instances. The given ZCREasyRecipe is used to process the raw ingredient tree for mapping onto
 *  the model, or decomposing an existing model back into an ingredient tree.
 *
 *  The class relies on key-value setting and retrieving to work with models, so any objects which
 *  support key-value interactions can be used as a model.
 */
@interface ZCREasyOven : NSObject

/**
 *  Populates the given model with a raw ingredient tree using the given recipe.
 *
 *  @param model          The model to update.
 *  @param rawIngredients The raw ingredient tree to update the model with.
 *  @param recipe         The recipe to follow for processing and mapping the ingredient tree to the
 *                        given model.
 *  @param error          An optional error pointer which will be populated if an error occurs while
 *                        populating the model.
 *
 *  @return YES if the model was successfully populated, NO if an error occured.
 */
+ (BOOL)populateModel:(id)model ingredients:(id)rawIngredients recipe:(ZCREasyRecipe *)recipe error:(NSError **)error;

/**
 *  Compares the given model's properties to corresponding values in the ingredient tree, processed
 *  using the given recipe. Only property keys present in both the recipe and the ingredient tree
 *  are compared. The values are compared with the isEqual: method, or if both values are 'nil'.
 *
 *  @note This method returns NO if the model's properties do not match those in the ingredient tree
 *        but also if an error occurs. Therefore, for the most accuracy both the error pointer and
 *        the return value should be considered.
 *
 *  @param model          The model whose properties should be compared.
 *  @param rawIngredients The ingredient tree to compare the model's properties against.
 *  @param recipe         The recipe to process the ingredient tree for comparison.
 *  @param error          An optional error pointer which will be populated if an error occurs while
 *                        comparing the model.
 *
 *  @return YES if the ingredient tree's values match those in the model, or NO if the values do not
 *          match or an error occurs.
 */
+ (BOOL)isModel:(id)model equalToIngredients:(id)rawIngredients recipe:(ZCREasyRecipe *)recipe error:(NSError **)error;

/**
 *  Breaks down the model into an ingredient tree following the given recipe. Only property keys in
 *  the recipe will be decomposed into the ingredient tree. Furthermore, if transformers are given
 *  by the recipe, they are only applied if they support reverse-transformations.
 *
 *  @note The completeness and validity of the resulting material tree depends on the thoroughness
 *        of the given recipe. If the ingredient paths point to a dictionary branch, only those path
 *        keys will be populated. Similarly, if the paths point to an array branch, only specified
 *        indicies will be populated, with prior indicies being stubbed with NSNull.
 *
 *  @param model  The model to decompose into an ingredient tree.
 *  @param recipe The recipe to follow for decomposing the model.
 *  @param error  An optional error pointer which wil be populated if an error occurs while
 *                decomposing the model.
 *
 *  @return An ingredient tree, represented as an NSDictionary or NSArray, or nil if an error occurs.
 */
+ (id)decomposeModel:(id)model withRecipe:(ZCREasyRecipe *)recipe error:(NSError **)error;

- (instancetype)init __unavailable;

@end
