//
//  ZCREasyDough.h
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/9/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

@import Foundation;

extern NSString *const ZCREasyDoughErrorDomain;
extern NSInteger const ZCREasyDoughErrorInvalidParameters;
extern NSInteger const ZCREasyDoughErrorExceptionRaised;

extern NSString *const ZCREasyDoughExceptionAlreadyBaked;

extern NSString *const ZCREasyDoughUpdatedNotification;

@protocol ZCREasyChef;
@class ZCREasyProperty, ZCREasyRecipe;

/**
 *  Semi-abstract and doughy class designed for immutable model subclassing.
 *
 *  ZCREasyDough introspects it's properties, and uses a provided recipe (with property names mapped
 *  to their corresponding values in the data) and ingredients (the data, in NSDictionary form) to
 *  prepare an instance, or update an existing instance. Uniqueness is determined solely by the
 *  identifier passed during initialization, and regardless of what ingredients or recipe were used
 *  to prepare it. This can make maintaining a canonical set of ZCREasyDough subclassed instances
 *  easier. To determine if an instance is represented by a given blob of ingredients and recipe,
 *  the method isEqualToIngredients:withRecipe:error: can be used.
 *
 *  Ingredients are typically provided by an external service, meaning their ingredient names cannot
 *  be controlled. For example, ingredients may be a serialized JSON dictionary from a web service.
 *  These ingredients must be remapped to property names using a recipe dictionary. A valid recipe
 *  must have keys that are existing property names. For a starting point on recipes, the
 *  genericRecipe can be used, which simply maps all introspected property names to themselves.
 *
 *  Subclasses will typically define properties which ZCREasyDough can introspect. These properties
 *  should be read-only when possible. ZCREasyDough will raise an exception if the setValue:forKey:
 *  method is invoked as a way to access read-only property iVars directly outside of the designated
 *  initializer. No restrictions are placed on read-write properies, but they also go against the
 *  spirit of ZCREasyDough, so use them with caution!
 *
 *  If an unique instance needs to be updated, it should use the updateWithIngredients:recipe:error:
 *  method, which will generate a new instance with the same identifier as the original instance.
 *  This method also has the benefit of posting notifications that can be observed to track changes
 *  to these immutable instances. To receive all update notifications, the
 *  ZCREasyDoughUpdateNotification can be subbscribed to. For notifications specific to a subclass,
 *  the class's updateNotificationName property can be used for subscribing.
 *
 *  If subclasses need finer grained control, they can override any of the public methods, though
 *  they are encouraged to invoke the super implementation when possible.
 */
@interface ZCREasyDough : NSObject {
    @protected
    BOOL _allowsSettingValues;
    id<NSObject,NSCopying> _uniqueIdentifier;
}

/**
 *  @name Generating new instances
 */

/**
 *  This is the designated initializer for this class. This method will generate a new instance with
 *  the passed unique identifier, and hydrate that instance with the passed ingredients using the
 *  passed recipe. The ingredients should be mapped from ingredient names as NSStrings to ingredient
 *  values. The recipe maps those ingredient names to property names of this class. Only keys in
 *  both the recipe and ingredients will be populated. To unset a property, NSNull can be passed as
 *  the ingredient value, which will automatically be remapped to nil.
 *
 *  @param identifier  The unique identifier of this instance. This will be used to determine
 *                     equality for this instance, and should not be nil.
 *  @param ingredients The ingredients to use to populate this instance. The ingredients are a
 *                     dictionary of ingredient names as NSStrings to the ingredient value. This may
 *                     be nil.
 *  @param recipe      The recipe to follow while populating the instance. The recipe is represented
 *                     as a dictionary with property names as NSStrings mapped to ingredient names
 *                     as NSStrings. If the ingredients are not nil, this must also not be nil.
 *  @param error       An optional pointer to an error which may be populated during the course of
 *                     initializing and populating the instance.
 *
 *  @return A new populated instance or nil if an error occurs.
 */
- (instancetype)initWithIdentifier:(id<NSObject,NSCopying>)identifier
                       ingredients:(NSDictionary *)ingredients
                            recipe:(NSDictionary *)recipe
                             error:(NSError **)error;

/**
 *  Convenience builder for generating fresh instances. This method takes a block and passes it an
 *  object conforming to the ZCREasyChef protocol. Recipes, ingredients, and an identifier can be
 *  set on this chef object, and after the block executes an instance will be constructed using the
 *  designated initializer initWithIdentiifer:ingredients:recipe:error:. Configurations on the chef
 *  can be validated with the validateKitchen: method on the chef. Similar to the standard init
 *  method, if no identifier is set on the chef in the block, one will be constructed.
 *
 *  @param preparationBlock The block that will configure the ZCREasyChef object to create a new
 *                          instance. This block will only be executed once, and will not be
 *                          retained. This must not be nil.
 *
 *  @return A new populated instance using the chef or nil if an error occurs.
 */
+ (instancetype)prepareWith:(void (^)(id<ZCREasyChef> chef))preparationBlock;


/**
 *  @name Updating instances
 */

/**
 *  Attempts to update an instance with the passed ingredients and recipe. This method will check
 *  to see if the ingredients are already represented by this instance using the
 *  isEqualToIngredients:withRecipe:error: method. If the ingredients are not equal, a new instance
 *  will be generated using the designated initializer, passing the current instance's identifier,
 *  and notfications will be posted to the updateNotificationName and
 *  ZCREasyDoughUpdateNotification. If the ingredients *are* equal, this method will simply return
 *  self and no notfications will be posted.
 *
 *  @param ingredients The ingredients to update this instance with. The ingredients are a
 *                     dictionary of ingredient names as NSStrings for ingredient values. This must
 *                     not be nil.
 *  @param recipe      The recipe to follow for updating this instance. The recipe is represented as
 *                     a dictionary with property names as NSStrings mapped to ingredient names as
 *                     NSStrings. This must not be nil.
 *  @param error       An optional pointer to an error which may be populated during the course of
 *                     updating the instance.
 *
 *  @return A new instance with updated properties and a matching identifier, the same instance if
 *  no changes were found, or nil if an error occured.
 */
- (instancetype)updateWithIngredients:(NSDictionary *)ingredients
                               recipe:(NSDictionary *)recipe
                                error:(NSError **)error;

/**
 *  Returns a notification name which can be observed through the NSNotificationCenter. To observe
 *  all notifications, the ZCREasyDoughUpdatedNotification can be observed. However, this method
 *  will provide a notification specific to an individual subclass for filtering the notifications.
 *
 *  @see updateWithIngredients:recipe:error:
 *
 *  @return A notification name for this class.
 */
+ (NSString *)updateNotificationName;


/**
 *  @name Recipe utilities
 */

/**
 *  Attempts to convert an instance into an NSDictionary of ingredients using a passed recipe. The
 *  recipe determines what ingredient keys are used, as well as what properties are decomposed. All
 *  keys in the recipe will be populated in the resulting dictionary, with nil values converted to
 *  NSSNull values.
 *
 *  @param recipe The recipe to follow for decomposing this instance. The recipe is represented as
 *                a dictionary with property names as NSStrings mapped to ingredient names as
 *                NSStrings. Only property names present will be populated in the returned object.
 *  @param error  An optional error pointer which may be populated during the course of decomposing
 *                the instance.
 *
 *  @return A dictionary of ingredient names mapped to corresponding values, or nil if an error
 *  occurs.
 */
- (NSDictionary *)decomposeWithRecipe:(NSDictionary *)recipe error:(NSError **)error;

/**
 *  Checks if the ingredients and recipe passed are represented by the current instance.
 *
 *  @note This method does *not* determine full equality. Only property names in the recipe will be
 *  checked with the ingredients. For canonical equality, the isEqual: method should be used, which
 *  checks the uniqueIdentifier.
 *
 *  @param ingredients The ingredients to check. The ingredients are a dictionary of ingredient
 *                     names as NSStrings for ingredient values. NSNull values will be remapped to
                       nil when comparing with the actual instance values. This must not be nil.
 *  @param recipe      The recipe to use for checking the ingredients. The recipe is represented as
 *                     a dictionary with property names as NSStrings mapped to ingredient names as
 *                     NSStrings. Only property names present will be checked in the ingredients and
 *                     the isntance. This must not be nil.
 *  @param error       An optional error pointer which may be populated while checking the equality
 *                     of the instance.
 *
 *  @return YES if the ingredients are represented by the instance, NO if they are not or an error
 *  occured.
 */
- (BOOL)isEqualToIngredients:(NSDictionary *)ingredients
                  withRecipe:(NSDictionary *)recipe
                       error:(NSError **)error;

/**
 *  A generic recipe which can be a starting point for developing other recipes, or as an easy
 *  recipe for getting a dictionary representation of the class.
 *
 *  @see allPropertyNames
 *
 *  @return A dictionary with all property names mapped to themselves.
 */
+ (NSDictionary *)genericRecipe;


/**
 *  @name Introspection
 */

/**
 *  Gets a set of all property names for this class, including inherited properties but not
 *  including those properties present in the superclass of ZCREasyDough.
 *
 *  @return An NSSet of property names in this class.
 */
+ (NSSet *)allPropertyNames;

/**
 *  Enumerates all the properties of this class, including inherited properties but not including
 *  those properties present in the superclass of ZCREasyDough.
 *
 *  @param block The block to enumerate the properties with. This must not be nil.
 */
+ (void)enumeratePropertiesUsingBlock:(void (^)(ZCREasyProperty *property, BOOL *shouldStop))block;

@end


/**
 *  Protocol adopted by the builder used in the ZCREasyDough factory method. This protocol is not
 *  designed to be manually adopted, and instead should just be treated as an abstract interface
 *  for the builder object.
 *
 *  Values can be set using the defined properties to configure the resulting ZCREasyDough instance.
 *  Validation can be performed using the validateKitchen: method.
 */
@protocol ZCREasyChef <NSObject>
@required

/**
 *  The identifier to use for the new instance. If not set by the time the ZCREasyDough instance is
 *  built, one will be automatically constructed.
 */
@property (copy, nonatomic) NSString *identifier;

/**
 *  The ingredients to hydrate the new instance with. This may be nil, but if not, the recipe must
 *  also be set.
 */
@property (copy, nonatomic) NSDictionary *ingredients;

/**
 *  The recipe to follow for populating the new instance with ingredients. If the ingredients are
 *  not nil, this must also be set.
 */
@property (copy, nonatomic) NSDictionary *recipe;

/**
 *  Checks the current set properties for potential errors prior to building the new instance.
 *
 *  @param error An optional error pointer which may be populated if the properties do not validate.
 *
 *  @return YES if the settings are valid, NO if there is an error.
 */
- (BOOL)validateKitchen:(NSError **)error;

@end


