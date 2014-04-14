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

* **Model**: A container for application data that is reusable and serializable. Think of this as a prepared dish.
* **Property**: An Objective-C property which controls access to a model's underlying data. ZCREasyBake prefers `readonly` properties when they expose a model's underlying application data.
* **Identifier**: An arbitrary object which conforms to the `NSObject` and `NSCopying` protocols that can uniquely identify a model across instances.
* **Ingredients**: The raw data that makes up a model, represented as an `NSDictionary`. This data is typically produced by an external service, such as a web API, and can be processed into models after some work.
* **Recipe**: Instructions for mapping ingredients to a model, represented as an `NSDictionary`. Recipes let us decouple ingredient sources from their final model representations.

===

## Working in the kitchen

### Defining a new model

Start by defining your model as a subclass of `ZCREasyDough`:

```
@interface User : ZCREasyDough
@property (strong, readonly) NSString *name;
@property (strong, readonly) NSDate *updatedAt;
@property (assign, readonly) NSUInteger unreadMessages;
@end
```

Note that the properties are defined as `readonly` so the instance is effectively immutable after creation!

### Baking a new instance

Your model will inherit the designated initializers from `ZCREasyDough`:

```
- (instancetype)initWithIdentifier:(id<NSObject,NSCopying>)identifier
                       ingredients:(NSDictionary *)ingredients
                            recipe:(NSDictionary *)recipe
                             error:(NSError **)error;
+ (instancetype)prepareWith:(void (^)(id<ZCREasyChef> chef))preparationBlock;
```

To create an instance you'll need an identifier, some ingredients, and a recipe:

```
NSDictionary *ingredients = @{@"server_id": @"12093r4744829rj493iu324"
                              @"name": @"Zach Radke",
                              @"updated_at": [NSDate date],
                              @"unread_messages": @10};
NSDictionary *recipe = @{@"name": @"name",
                         @"updatedAt": @"updated_at",
                         @"unreadMessages": @"unread_messages"};
User *user = [User prepareWith:^(id<ZCREasyChef> chef) {
    [chef setIdentifier:ingredients[@"server_id"]];
    [chef setIngredients:ingredients];
    [chef setRecipe:recipe];
}];
```

Because a recipe is usually fixed to a given ingredient source (such as a specifically formatted JSON response), a model can cache its recipes and expose them through class methods for convenience:

```
@interface User (Recipes)
+ (NSDictionary *)JSONRecipe;
@end
…
@implementation User (Recipes)
+ (NSDictionary *)JSONRecipe {
    static NSDictionary *JSONRecipe;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JSONRecipe = @{@"name": @"name",
                       @"updatedAt": @"updated_at",
                       @"unreadMessages": @"unread_messages"};
    });
    return JSONRecipe;
}
@end
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

### Gotchas

Running into difficulties with your models? Maybe these tips can help:

* Recipe keys **must** all be properties on the receiving model, or errors will be thrown.
* Ingredient keys **do not** all need to be represented in a recipe.
* Model property names **do not** all need to be represented in a recipe.
* To set `nil` on a property, in the corresponding ingredient value put `[NSNull null]`. These are automatically converted to `nil` in the initializer.
* After initialization, `readonly` properties **cannot** be set via `setValue:forKey:`. Attempts to do so will raise a `ZCREasyDoughExceptionAlreadyBaked` exception.
* When `updateWithIngredients:recipe:error` is called with ingredients that are already part of the model, no notifications will be posted, and the same object will be returned rather than a new instance.
* Most of the methods have an optional error pointer parameter. If you aren't receiving the expected output, make sure you're passing something in there to help you debug what's happening!
* The `ZCREasyDough` class introspects your model's properties at runtime and caches them, so avoid dynamically creating properties on your model class at runtime.