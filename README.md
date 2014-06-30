# ZCREasyBake

[![Build Status for Master](https://travis-ci.org/zradke/ZCREasyBake.svg?branch=master)](https://travis-ci.org/zradke/ZCREasyBake) on [master](https://github.com/zradke/ZCREasyBake/tree/master)

[![Build Status for Develop](https://travis-ci.org/zradke/ZCREasyBake.svg?branch=develop)](https://travis-ci.org/zradke/ZCREasyBake) on [develop](https://github.com/zradke/ZCREasyBake/tree/develop)

A lightweight modeling framework.

===

## What's the point?

Making models is a pain. Updating models is a pain. **ZCREasyBake** aims to ease some of that pain.

Looking to quickly serialize data from an external source (like a web API) into existing model classes? Take a look at **ZCREasyOven**.

Looking to build immutable models to help with thread safety while also allowing updates? Take a look at **ZCREasyDough**.

Annoyed at having multiple models that represent the same basic data, just because they come from different external sources? Merge them into one model and create specific **ZCREasyRecipes** to serialize them.

## Can I use it?

To use **ZCREasyBake**, your project should have a minimum deployment target of iOS 6.0+ or OSX 10.8+ and be running with ARC. However, this project is only unit tested on iOS 7.0+ and OSX 10.9+.

## How do I install it?

ZCREasyBake can be installed a variety of ways depending on your preference:

* Drag-n-drop files from the `Classes` folder into your project.
* Add `pod "ZCREasyBake"` to your Podfile for Cocoapods.

However you get the framework into your project, you can import the main header where needed:

```
#import <ZCREasyBake/ZCREasyBake.h> // Or #import "ZCREasyBake.h"
```

## Terms

Throughout the ZCREasyBake project, you'll encounter some jargon:

* **Model**: A container for application data that is reusable and serializable. Think of this as a baked good.
* **Property**: An Objective-C property which controls access to a model's underlying data. ZCREasyBake prefers `readonly` properties when they expose a model's underlying application data.
* **Identifier**: An arbitrary object which conforms to the `NSObject` and `NSCopying` protocols that can uniquely identify a model across instances.
* **Ingredients**: The raw data that makes up a model, represented as a tree of `NSDictionary` or `NSArray` instances. This data is typically produced by an external service, such as a web API, and can be processed into models after some work.
* **Ingredient path**: The steps to traverse an ingredient tree of dictionaries and/or arrays to access an ingredient value.
* **Recipe**: Instructions for preparing ingredients for baking into a model, represented as a `ZCREasyRecipe`. Recipes let us decouple ingredient sources from their final model representations. Recipes are usually model and ingredient-source dependent, but otherwise reusable.

===

## How do I create a model?

### If you already have a model class

Assuming you have an existing key-value-coding compliant object...

```
// Valid model
@interface OldProduct : NSObject
@property (strong, nonatomic) NSString *baseSKU;
@property (strong, nonatomic) NSString *name;
@end

// Also valid model
NSMutableDictionary *product = [NSMutableDictionary dictionary];
```

... you are ready to start working with **ZCREasyOven** and **ZCREasyRecipe**. Just initialize it however you normally do.


### If you don't have a model

Consider **ZCREasyDough**:

```
// Immutable model class
@interface Product : ZCREasyDough
@property (strong, nonatomic, readonly) NSString *name;
@end
```

You'll want to use the designated initializers:

```
- (instancetype)initWithIdentifier:(id<NSObject,NSCopying>)identifier
                       ingredients:(id)ingredients
                            recipe:(ZCREasyRecipe *)recipe
                             error:(NSError **)error;
+ (instancetype)makeWith:(void (^)(id<ZCREasyBaker> baker))constructionBlock;
```

## How do I create a recipe?

Recipes are used throughout the framework.


### Identify ingredient sources

Start by identifying the ingredient sources for the models. For example, the `Product` model defined above can be backed by a web service returning JSON:

```
{
	"base_sku": "1209-3r47-4482-9rj4-93iu-324s",
	"attributes":
	{
		"name": "Test Product"
	}
}
```

Whatever the ingredient source, the raw ingredient tree must be either an `NSDictionary` or `NSArray` before they can be processed.

### Define the recipe

To process raw ingredients into a model, a **ZCREasyRecipe** is used. These recipes are usually model and ingredient-source dependent. For example, we would create a single recipe for the `Product` model and JSON ingredient source defined above.

All recipes begin with an `NSDictionary` mapping, which is required. The keys are property keys of the model to populate, and the values are the corresponding ingredient paths from the ingredient-source.

```
NSDictionary *mapping = @{@"name": @"attributes.name"};
```

The recipe can then be created with one of the designated initializers.

```
ZCREasyRecipe *productJSONRecipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
	[recipeMaker setIngredientMapping:mapping];
}];
```

Recipes can also have transformers, and other attributes. For more details, see the documentation for **ZCREasyRecipe**.

Since recipes are typically reused throughout a class, they can be stored in **ZCREasyRecipeBox** instances, as long as they have a name set.

```
// Product.m
+ (ZCREasyRecipe *)JSONRecipe {
    return [[ZCREasyRecipeBox defaultBox] recipeWithName:@"ProductJSONRecipe"];
}
```

## How do I populate an instance?

### With an existing model class

If you are using a custom model, just create one and then populate it using **ZCREasyOven**.

```
ZCREasyRecipe *productRecipe = ...;
NSDictionary *ingredients = ...;
OldProduct *product = [OldProduct new];
[ZCREasyOven populateModel:product ingredients:ingredients recipe:productRecipe error:NULL];
```


### With a subclass of ZCREasyDough

If your model is a subclass of **ZCREasyDough**, you'll use the designated initializers

Your model will inherit the designated initializers from **ZCREasyDough**:
	
```
Product *product = [Product makeWith:^(id<ZCREasyBaker> baker) {
    [baker setIdentifier:ingredients[@"base_sku"]];
    [baker setIngredients:ingredients];
    [baker setRecipe:productRecipe];
}];
```

To update an instance you'll use the update methods inherited from **ZCREasyDough**. 

```
NSDictionary *ingredients = @{@"attributes": @{@"name": @"Updated name"}};
Product *updatedProduct = [user updateWithIngredients:ingredients
                                               recipe:productRecipe
                                                error:NULL];
```

The updated instance will share the same unique identifier as it's parent, and will generate notifications that can be observed:

```
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(productUpdated:)
                                             name:[Product updateNotificationName]
                                           object:nil];
```

For a more generic notification, the `ZCREasyDoughUpdatedNotification` can be observed, which will be triggered for updates to all **ZCREasyDough** subclasses. Notifications will be posted from the original instance. However, since equality isn't pointer specific (more on that in the next section), it's advisable to observe the notification without an object, and filter the notifications based on the user-info.

The user-info of these notifications will contain the `ZCREasyDoughIdentifierKey`, which points to the unique identifier of the updated instance, and `ZCREasyDoughUpdatedDoughKey` which points to the updated instance.

## Tips

Running into difficulties with your models? Maybe these tips can help:

### ZCREasyRecipe
* Ingredient mapping keys **must** be settable on the receiving model via `setValue:forKey:`.
* Ingredient paths **must** be consistent in their inferred objects. For example:

```
// Invalid mapping since the root is suggested to be a dictionary and array
NSDictionary *invalidMapping = @{@"key1": @"key_1",
                                 @"key2": @"[0]"};
                                 
// Invalid mapping since "key" points to both a dictionary and array
NSDictionary *alsoInvalid = @{@"key1": @"key[0]",
                              @"key2": @"key.two"};
```

* Ingredient keys **do not** all need to be represented in a recipe.
* Model property names **do not** all need to be represented in a recipe.
* If ingredient transformers are provided, the keys **must** be present in the ingredient mapping.
* `NSNull` values are converted to `nil` for transformers.
* If a transformer returns `nil` it will be converted to `NSNull` in the processed ingredients.
* A recipe box can only hold one recipe per name. Adding another recipe with the same name will fail.

### ZCREasyDough
* `NSNull` ingredient values are converted to `nil`.
* After initialization, `readonly` properties **cannot** be set via `setValue:forKey:`. Attempts to do so will raise a `ZCREasyDoughExceptionAlreadyBaked` exception.
* When `updateWithIngredients:recipe:error` is called with ingredients that are already part of the model, no notifications will be posted, and the same object will be returned rather than a new instance.
* Updating a model will post a notification from the original model, with the updated model in the user info. However, because equality is not determined by pointers, you should typically observe the notification without specifying an object, and rely on the user info to provide context.
* Most of the methods have an optional error pointer parameter. If you aren't receiving the expected output, make sure you're passing something in there to help you debug what's happening!
* The **ZCREasyDough** class introspects your model's properties at runtime and caches them, so avoid dynamically creating properties on your model class at runtime.