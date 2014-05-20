//
//  ZCREasyRecipe.h
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/24/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZCREasyRecipeMaker;

/**
 *  A ZCREasyRecipe represents a set of instructions to follow for converting raw ingredients
 *  supplied by an external source into a cannonical dictionary of processed ingredients suitable
 *  for creating ZCREasyDough subclass instances. Initialization must be done through the
 *  designated initializer or factory methods defined in this class. Using the standard init method
 *  will throw an exception.
 *
 *  Ingredients are represented as dictionaries or arrays or combinations of the two. When creating
 *  the ingredient mapping, the ingredient string can use dot notation to indicate dictionary key
 *  traversal or the form "[<index>]" to indicate an array index to traverse. These may also be
 *  combined, for example: "user.updates[0]". Upon creation, the ingredient paths are broken down
 *  into components, and these are then validated to ensure there are no inconsistencies with the
 *  inferred ingredient class. For example, a path to "user.updates[0]" is inconsistent with another
 *  path to "user[1]", since the object for the "user" key is assumed to be a dictionary in the
 *  first path, and an array in the second.
 *
 *  Recipes are immutable, so invoking copy on one will simply return self. Modifications can be
 *  made, but will produce new recipes. These recipes often only need to be created once and reused
 *  for a given ZCREasyDough subclass. To aid in this process, please see ZCREasyRecipeBox.
 *
 *  To use a recipe outside of ZCREasyDough, the processIngredients: method can be used to follow
 *  the mapping and transformation instructions of a recipe to process raw ingredients.
 *
 *  It shouldn't be required to subclass ZCREasyRecipe, though it is entirely possible to do so.
 */
@interface ZCREasyRecipe : NSObject

/**
 *  @name Creating recipes
 */

/**
 *  The designated initializer for this class which creates an immutable recipe.
 *
 *  @param name                   An optional name to give this recipe. This is mostly for developer
 *                                convenience, but also a requirement for adding recipes to a
 *                                ZCREasyRecipeBox.
 *  @param ingredientMapping      An NSDictionary mapping canonical property names to their
 *                                corresponding ingredient path. This must not be nil.
 *  @param ingredientTransformers An NSDictionary of transformers to use when processing raw
 *                                ingredients. The keys are property names and the values may be
 *                                either NSValueTransformer instances, or NSStrings that have
 *                                been registered as NSValueTransformer names. This is optional, but
 *                                if present the property names must all exist in the ingredient
 *                                mapping, and all values be valid.
 *  @param error                  An error pointer which may be populated upon a failure.
 *
 *  @return An immutable recipe for use by a ZCREasyDough subclass, or nil if an error occured.
 */
- (instancetype)initWithName:(NSString *)name
           ingredientMapping:(NSDictionary *)ingredientMapping
      ingredientTransformers:(NSDictionary *)ingredientTransformers error:(NSError **)error;

/**
 *  Builder for generating recipes.
 *
 *  @see initWithName:ingredientMapping:ingredientTransformers:error:, ZCREasyRecipeMaker
 *
 *  @param constructionBlock A block which takes an object conforming to the ZCREasyRecipeMaker
 *                           protocol. This block will be executed once and then a recipe will be
 *                           constructed. This must not be nil.
 *
 *  @return A new immutable recipe, or nil if an error occured.
 */
+ (instancetype)makeWith:(void (^)(id<ZCREasyRecipeMaker> recipeMaker))constructionBlock __attribute__((nonnull));

/**
 *  Builds a new recipe from an existing recipe, with modifications.
 *
 *  @param modificationBlock A block which takes an object conforming to the ZCREasyRecipeMaker
 *                           protocol. This object will be pre-populated with attributes from the
 *                           existing recipe. This block must not be nil.
 *
 *  @return A new immutable recipe based off the receiver, or nil if an error occured.
 */
- (instancetype)modifyWith:(void (^)(id<ZCREasyRecipeMaker> recipeMaker))modificationBlock __attribute__((nonnull));


/**
 *  @name Accessing recipe instructions
 */

/**
 *  The name of the recipe, if present. This is used by ZCREasyRecipeBox instances to recognize
 *  unique recipes, but is optional outside of recipe boxes.
 */
@property (strong, nonatomic, readonly) NSString *name;

/**
 *  An NSDictionary mapping canonical property names to their corresponding ingredient paths. This
 *  is required for all recipes.
 */
@property (strong, nonatomic, readonly) NSDictionary *ingredientMapping;

/**
 *  An NSDictionary mapping canonical property names to arrays of decomposed ingredient paths. These
 *  path components may be either NSStrings indicating a dictionary key to traverse, or NSNumbers
 *  indicating an array index to traverse. This is automatically generated from the provided
 *  ingredientMapping.
 */
@property (strong, nonatomic, readonly) NSDictionary *ingredientMappingComponents;

/**
 *  An NSDictionary of NSValueTransformers mapped to property names which should be applied when
 *  processing raw ingredients. This is optional, but when present the property names must exist
 *  in the ingredientMapping.
 */
@property (strong, nonatomic, readonly) NSDictionary *ingredientTransformers;

/**
 *  A convenience accessor for the property names registered in the ingredientMapping.
 */
@property (strong, nonatomic, readonly) NSSet *propertyNames;

/**
 *  Convenience method for enumerating through the recipe's instructions through a block.
 *
 *  @param block A block which takes a property name, the corresponding ingredient path, and a value
 *               transformer if it exists. This block is executed for each property name in the
 *               ingredientMapping. This must not be nil.
 */
- (void)enumerateInstructionsWith:(void (^)(NSString *propertyName, NSString *ingredientPath, NSValueTransformer *transformer, BOOL *shouldStop))block __attribute__((nonnull));

/**
 *  @name Using a recipe
 */

/**
 *  Takes a dictionary or array of raw ingredients and processes them using the 
 *  ingredientMappingComponents and ingredientTransformers. Only ingredients which have canonical
 *  property names in the propertyNames will be present in the resulting dictionary, and only if
 *  their ingredient path leads to an object. NSNull values are converted into nil when being pased
 *  to an ingredient transformer, and if the ingredient transformer returns nil it will be converted
 *  to NSNull in the response.
 *
 *  @param ingredients The raw ingredients to process.
 *
 *  @return An NSDictionary where the keys are cannonical property names mapped from the ingredient
 *          paths and the values are ingredient values run through the registered NSValueTransformer
 *          if present.
 */
- (NSDictionary *)processIngredients:(id)ingredients error:(NSError **)error;

@end

/**
 *  ZCREasyRecipeBox instances are containers for reusing ZCREasyRecipe instances without the pain
 *  of repeated dispatch_once blocks. Recipes are added and removed atomically, ensuring that each
 *  box is thread safe. Because the boxes are designed for reusing recipes, all recipes must have
 *  their name set so that recipes can be distinguished and retrieved via the recipeWithName:
 *  method. A recipe name can only be registered once in a single box. Attempts to add multiple
 *  recipes with the same name will result in only the first recipe being added and subsequent
 *  recipes being ignored. To re-register a name, the registered recipe must first be removed.
 *
 *  For convenience, a singleton box is exposed which can be used throughout an app. However, it is
 *  completely reasonable to intialize an instance and maintain multiple boxes.
 *
 *  It shouldn't be necessary to subclass ZCREasyRecipeBox, though it is entirely possible to do so.
 */
@interface ZCREasyRecipeBox : NSObject <NSCopying>

/**
 *  Singleton box.
 *
 *  @return The default box that can be shared throughout an app.
 */
+ (instancetype)defaultBox;

/**
 *  A set of registered recipe names. This is KVO compliant.
 */
@property (strong, nonatomic, readonly) NSSet *recipeNames;

/**
 *  Adds the given recipe to the box if it has a name and that name has not already been registered.
 *
 *  @param recipe The recipe to add to this box. This must not be nil, must have a name, and that
 *                name must not already be registered in this box.
 *  @param error  An error pointer that will be populated if a failure occurs.
 *
 *  @return YES if the recipe was added, NO if it could not be added.
 */
- (BOOL)addRecipe:(ZCREasyRecipe *)recipe error:(NSError **)error;

/**
 *  Creates a recipe using a builder block and adds it to the box.
 *
 *  @see [ZCREasyRecipe makeWith:]
 *
 *  @param block The block to build the new recipe from. This block is passed an object conforming
 *               to the ZCREasyRecipeMaker protocol. If no name is provided for the recipe in this
 *               block, one will be created and can be observed in the returned recipe.
 *
 *  @return A new recipe that has been added to the box, or nil if an error occured.
 */
- (ZCREasyRecipe *)addRecipeWith:(void (^)(id<ZCREasyRecipeMaker> recipeMaker))block __attribute__((nonnull));

/**
 *  Removes the recipe registered under the given name.
 *
 *  @param recipeName The name of the recipe to remove. This must not be nil, and should represent
 *                    a registered recipe.
 *  @param error      An error pointer that may be populated if the removal fails.
 *
 *  @return YES if the recipe was removed, NO if it could not be.
 */
- (BOOL)removeRecipeNamed:(NSString *)recipeName error:(NSError **)error;

/**
 *  Finds the recipe registered under the given name.
 *
 *  @param recipeName The name of the recipe to find. This must not be nil.
 *
 *  @return The recipe registered under the given name, or nil if no recipe could be found.
 */
- (ZCREasyRecipe *)recipeWithName:(NSString *)recipeName;

@end


/**
 *  Protocol adopted by the builder used to construct ZCREasyRecipe instances. This protocol is not
 *  designed to be manually adopted, and instead should be treated as an abstract interface for the
 *  private builder class. Builder instances are not thread safe, so they should only be manipulated
 *  on one thread at a time.
 */
@protocol ZCREasyRecipeMaker <NSObject>
@required

/**
 *  A name to use for the new instance. This may be nil. In ZCREasyRecipeBox, the builder method
 *  will automaticaly provide a name if one is not set at the end of the builder block.
 */
@property (copy, nonatomic) NSString *name;

/**
 *  An NSDictionary of canonical property names as keys with ingredient paths as values. This must
 *  not be nil.
 */
@property (copy, nonatomic) NSDictionary *ingredientMapping;

/**
 *  The NSDictionary of value transformers to process raw ingredients with. The keys are canonical
 *  property names and the values must be NSValueTransformer instances or NSString instances that
 *  are registered to NSValueTransformer instances. This property is optional, but if it is set all
 *  the keys must also be present in the ingredientMapping keys.
 */
@property (copy, nonatomic) NSDictionary *ingredientTransformers;

/**
 *  Adds an entry to the ingredientMapping and ingredientTransformer dictionaries.
 *
 *  @param propertyName   The canonical property name. This must not be nil and must not already be
 *                        registered in the ingredientMapping.
 *  @param ingredientPath The raw ingredient name. This must not be nil.
 *  @param transformer    An NSValueTransformer or NSString instance. If this is an NSString, it
 *                        must be registered with NSValueTransformer. This is optional.
 *  @param error          An error pointer which will be populated if an error occurs.
 *
 *  @return YES if the instruction could be added. NO if it could not.
 */
- (BOOL)addInstructionForProperty:(NSString *)propertyName ingredientPath:(NSString *)ingredientPath
                      transformer:(id)transformer error:(NSError **)error;

/**
 *  Removes an entry from the ingredientMapping and ingredientTransformer dictionaries.
 *
 *  @param propertyName The canonical property name to remove. This must not be nil and must be
 *                      one of the ingredientMapping keys.
 *  @param error        An error which will be populated if an error occurs.
 *
 *  @return YES if the instruction was removed, NO if it was not.
 */
- (BOOL)removeInstructionForProperty:(NSString *)propertyName error:(NSError **)error;

/**
 *  Checks the current properties for potential errors prior to building the new instance.
 *
 *  @param error An optional error pointer which may be populated if an error occurs.
 *
 *  @return YES if the properties are all valid, NO if they are not.
 */
- (BOOL)validateRecipe:(NSError **)error;

@end

