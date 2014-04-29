# ZCREasyBake

[![Build Status](https://travis-ci.org/zradke/ZCREasyBake.svg?branch=master)](https://travis-ci.org/zradke/ZCREasyBake)

A lightweight immutable model framework disguised by friendly food metaphors.

===

## Equipment

To use ZCREasyBake, your project should have a minimum deployment target of iOS 5.1+ and be running with ARC. This hasn't been tested with OSX, but should work in theory…

## Preparing your kitchen

ZCREasyBake can be installed a variety of ways depending on your preference:

* Drag-n-drop files from the `Classes` folder into your project.
* Add `pod "ZCREasyBake"` to your Podfile for Cocoapods.
* Build a framework by downloading the project and building the `Framework` target.

However you get the framework into your project, you can import the main header where needed:

```
#import <ZCREasyBake/ZCREasyBake.h> // Or #import "ZCREasyBake.h"
```

## Terms

Throughout the ZCREasyBake project, you'll encounter some jargon:

* **Model**: A container for application data that is reusable and serializable. Think of this as a baked good.
* **Property**: An Objective-C property which controls access to a model's underlying data. ZCREasyBake prefers `readonly` properties when they expose a model's underlying application data.
* **Identifier**: An arbitrary object which conforms to the `NSObject` and `NSCopying` protocols that can uniquely identify a model across instances.
* **Ingredients**: The raw data that makes up a model, represented as an `NSDictionary`. This data is typically produced by an external service, such as a web API, and can be processed into models after some work.
* **Recipe**: Instructions for preparing ingredients for baking into a model, represented as a `ZCREasyRecipe`. Recipes let us decouple ingredient sources from their final model representations. Recipes are usually model and ingredient-source dependent, but otherwise reusable.

===

## Working in the kitchen

### Defining a new model

Start by defining your model as a subclass of `ZCREasyDough`:

```
@interface User : ZCREasyDough
@property (strong, readonly) NSString *name;
@property (assign, readonly) NSUInteger unreadMessages;
@property (strong, readonly) NSDate *updatedAt;
@end
```

Note that the properties are defined as `readonly` so the instance is effectively immutable after creation!

### Identify ingredient sources

Your models will need to be populated with ingredients from an ingredient source. For example, our `User` model defined above can be backed by a web service that returns JSON like so:

```
{
    "server_id": "1209-3r47-4482-9rj4-93iu-324s",
    "name": "Zach Radke",
    "unread_messages": 10,
    "updated_at": "2014-04-19T19:32:05Z"
}
```

Whatever the ingredient source, the ingredients must be processed into an `NSDictionary` before they can be processed. 

### Defining a recipe

To process raw ingredients into a model, a `ZCREasyRecipe` is used. These recipes are usually model and ingredient-source dependent. For example, we would create a single recipe for the `User` model and JSON ingredient source defined above.

All recipes begin with an `NSDictionary` mapping, which is required. The keys are property keys of the model to populate, and the values are the corresponding ingredient names from the ingredient-source.

```
NSDictionary *mapping = @{@"name": @"name",
                          @"unreadMessages": @"unread_messages",
                          @"updatedAt": @"updated_at"};
```

Recipes may also optionally provide a dictionary of transformers to use for processing the raw ingredients into different objects. As with the ingredient mapping, the keys are property keys on the model which should be transformed. The values are `NSValueTransformer` instances or `NSStrings`. If strings are used, they must be registered to value transformers.

```
// NSValueTransformer+DefaultTransformers.h
// Assume we have created the DateTransformer class elsewhere...
DateTransformer *dateTransformer = [[DateTransformer alloc] initWithDateFormat:@"yyyy-MM-dd'T'HH-mm-ss'Z'"];
[NSValueTransformer setValueTransformer:dateTransformer forName:@"DateTransformer"];

// ...
NSDictionary *transformers = @{@"updatedAt": @"DateTransformer"};
```

Finally, a recipe may have a name. This is useful for debugging purposes, but also for storing and reusing recipes in `ZCREasyRecipeBox` instances.

```
ZCREasyRecipe *userJSONRecipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker maker) {
    [maker setIngredientMapping:mapping];
    [maker setIngredientTransformers:transformers];
    [maker setName:@"UserJSONRecipe"];
}];
[[ZCREasyRecipeBox defaultBox] addRecipe:userJSONRecipe error:NULL];
```

Since recipes are typically model dependent, you can also provide class methods on the model for even easier recipe access.

```
// User.m
+ (ZCREasyRecipe *)JSONRecipe {
    return [[ZCREasyRecipeBox defaultBox] recipeWithName:@"UserJSONRecipe"];
}
```

`ZCREasyRecipe` and `ZCREasyRecipeBox` have many utilities that make generating and validating recipes much easier. Check their headers for more information.

### Baking a new instance

Your model will inherit the designated initializers from `ZCREasyDough`:

```
- (instancetype)initWithIdentifier:(id<NSObject,NSCopying>)identifier
                       ingredients:(NSDictionary *)ingredients
                            recipe:(ZCREasyRecipe *)recipe
                             error:(NSError **)error;
+ (instancetype)makeWith:(void (^)(id<ZCREasyBaker> baker))constructionBlock;
```

To create an instance you'll need an identifier, some ingredients, and a recipe:
	
```
NSDictionary *ingredients = @{@"server_id": @"1209-3r47-4482-9rj4-93iu-324s"
                              @"name": @"Zach Radke"
                              @"unread_messages": @10,
                              @"updated_at": @"2014-04-19T19:32:05Z"};
User *user = [User prepareWith:^(id<ZCREasyChef> chef) {
    [chef setIdentifier:ingredients[@"server_id"]];
    [chef setIngredients:ingredients];
    [chef setRecipe:[User JSONRecipe]];
}];
```

### Updating an instance

When you want to update an instance, simply use the update method on it, passing the new ingredients and the recipe to generate a new instance:

```
NSDictionary *ingredients = @{@"name": @"Zachary Radke"};
User *updatedUser = [user updateWithIngredients:ingredients
                                         recipe:[User JSONRecipe]
                                          error:NULL];
```

The updated instance will share the same unique identifier as it's parent, and will generate notifications that can be observed:

```
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(userUpdated:)
                                             name:[User updateNotificationName]
                                           object:nil];
```

For a more generic notification, the `ZCREasyDoughUpdatedNotification` can be observed, which will be triggered for updates to all `ZCREasyDough` subclasses.

### Comparing instances and ingredients

Equality between `ZCREasyDough` subclasses is determined by the identifier used when initializing an instance. This means that calls to `isEqual:` will return `YES` between a model and an updated model:

```
[user isEqual:updatedUser]; // YES
(user == updatedUser); // NO
```

A subclass can also report whether it already contains given ingredients with a given recipe:

```
NSDictionary *ingredients = @{@"name": @"Zachary Radke"};
[user isEqualToIngredients:ingredients withRecipe:[User JSONRecipe] error:NULL]; // NO
[updatedUser isEqualToIngredients:ingredients withRecipe:[User JSONRecipe] error:NULL]; // YES
```

### Decomposing an instance

From ingredients it was made and to ingredients it shall return! A model can be decomposed using a given recipe into an ingredients dictionary:

```
NSDictionary *ingredients = [updatedUser decomposeWithRecipe:[User JSONRecipe] error:NULL];
```

If the recipe supplies value transformers, they will be applied to the model's value **if the transformer supports reverse transformations**.

```
[DateTransformer allowsReverseTransformation]; // YES
ingredients[@"updated_at"]; // @"2014-04-19T19:32:05Z"

```

### Tips

Running into difficulties with your models? Maybe these tips can help:

#### Recipes
* Ingredient mapping keys **must** be settable on the receiving model via `setValue:forKey:`.
* Ingredient keys **do not** all need to be represented in a recipe.
* Model property names **do not** all need to be represented in a recipe.
* If ingredient transformers are provided, the keys **must** be present in the ingredient mapping.
* `NSNull` values are converted to `nil` for transformers.
* If a transformer returns `nil` it will be converted to `NSNull` in the processed ingredients.
* A recipe box can only hold one recipe per name. Adding another recipe with the same name will fail.

#### Models
* `NSNull` ingredient values are converted to `nil`.
* After initialization, `readonly` properties **cannot** be set via `setValue:forKey:`. Attempts to do so will raise a `ZCREasyDoughExceptionAlreadyBaked` exception.
* When `updateWithIngredients:recipe:error` is called with ingredients that are already part of the model, no notifications will be posted, and the same object will be returned rather than a new instance.
* Most of the methods have an optional error pointer parameter. If you aren't receiving the expected output, make sure you're passing something in there to help you debug what's happening!
* The `ZCREasyDough` class introspects your model's properties at runtime and caches them, so avoid dynamically creating properties on your model class at runtime.