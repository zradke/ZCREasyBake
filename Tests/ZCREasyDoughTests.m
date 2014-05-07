//
//  ZCREasyDoughTests.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/11/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ZCREasyDough.h"
#import "ZCREasyRecipe.h"

@interface ZCRDateTransformer : NSValueTransformer
@end

@implementation ZCRDateTransformer

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    });
    return formatter;
}

+ (Class)transformedValueClass {
    return [NSDate class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if (![value isKindOfClass:[NSString class]]) { return nil; }
    return [[[self class] dateFormatter] dateFromString:value];
}

- (id)reverseTransformedValue:(id)value {
    if (![value isKindOfClass:[NSDate class]]) { return nil; }
    return [[[self class] dateFormatter] stringFromDate:value];
}

@end

@interface ZCREasyDoughTestsModel : ZCREasyDough

@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSDate *updatedAt;
@property (assign, nonatomic, readonly) NSUInteger badgeCount;

+ (ZCREasyRecipe *)simpleRecipe;
+ (ZCREasyRecipe *)complicatedRecipe;
+ (ZCREasyRecipe *)arrayBasedRecipe;

@end

@implementation ZCREasyDoughTestsModel

+ (ZCREasyRecipe *)simpleRecipe {
    ZCREasyRecipe *recipe = [[ZCREasyRecipeBox defaultBox] recipeWithName:@"simpleRecipe"];
    if (recipe) { return recipe; }

    return [[ZCREasyRecipeBox defaultBox] addRecipeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker setName:@"simpleRecipe"];
        [recipeMaker setIngredientMapping:@{@"name": @"user_name",
                                            @"updatedAt": @"updated_at",
                                            @"badgeCount": @"badge_count"}];
        [recipeMaker setIngredientTransformers:@{@"updatedAt": [[ZCRDateTransformer alloc] init]}];
    }];
}

+ (ZCREasyRecipe *)complicatedRecipe {
    ZCREasyRecipe *recipe = [[ZCREasyRecipeBox defaultBox] recipeWithName:@"complicatedRecipe"];
    if (recipe) { return recipe; }
    
    return [[ZCREasyRecipeBox defaultBox] addRecipeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker setName:@"complicatedRecipe"];
        [recipeMaker setIngredientMapping:@{@"name": @"user.name",
                                            @"updatedAt": @"updates[0]",
                                            @"badgeCount": @"user.count"}];
        [recipeMaker setIngredientTransformers:@{@"updatedAt": [[ZCRDateTransformer alloc] init]}];
    }];
}

+ (ZCREasyRecipe *)arrayBasedRecipe {
    ZCREasyRecipe *recipe = [[ZCREasyRecipeBox defaultBox] recipeWithName:@"arrayBasedRecipe"];
    if (recipe) { return recipe; }
    
    return [[ZCREasyRecipeBox defaultBox] addRecipeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker setName:@"arrayBasedRecipe"];
        [recipeMaker setIngredientMapping:@{@"name": @"[1].name",
                                            @"updatedAt": @"[0][0]",
                                            @"badgeCount": @"[1].badge_count"}];
        [recipeMaker setIngredientTransformers:@{@"updatedAt": [[ZCRDateTransformer alloc] init]}];
    }];
}

@end

@interface ZCREasyDoughTests : XCTestCase {
    ZCREasyDoughTestsModel *model;
    NSDictionary *JSON;
    ZCRDateTransformer *dateTransformer;
    
}
@end

@implementation ZCREasyDoughTests

- (void)setUp {
    [super setUp];
    
    dateTransformer = [[ZCRDateTransformer alloc] init];
    
    JSON = @{@"server_id": @"4839028431382930",
             @"user_name": @"Test User",
             @"updated_at": @"2014-04-07 13:45:29",
             @"badge_count": @90};
    
    model = [[ZCREasyDoughTestsModel alloc] initWithIdentifier:JSON[@"server_id"]
                                                   ingredients:JSON
                                                        recipe:[ZCREasyDoughTestsModel simpleRecipe]
                                                         error:NULL];
}

- (void)tearDown {
    model = nil;
    JSON = nil;
    dateTransformer = nil;
    
    [super tearDown];
}

- (void)testInitializer {
    XCTAssertNotNil(model, @"The model should have serialized successfully");
    XCTAssertEqualObjects(model.name, JSON[@"user_name"], @"The name should be set");
    XCTAssertEqualObjects(model.updatedAt, [dateTransformer transformedValue:JSON[@"updated_at"]], @"The updated date should be set");
    XCTAssertTrue(model.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue], @"The badge count should be set");
}

- (void)testPrepareWithChef {
    __block BOOL isValid = NO;
    __block NSError *error = nil;
    
    model = [ZCREasyDoughTestsModel makeWith:^(id<ZCREasyBaker> chef) {
        chef.identifier = JSON[@"server_id"];
        chef.ingredients = JSON;
        chef.recipe = [ZCREasyDoughTestsModel simpleRecipe];
        
        isValid = [chef validateKitchen:&error];
    }];
    
    XCTAssertTrue(isValid, @"The chef should validate");
    XCTAssertNil(error, @"The error should be nil");
    XCTAssertNotNil(model, @"The model should be built");
    XCTAssertEqualObjects(model.name, JSON[@"user_name"], @"The name should be set");
    XCTAssertEqualObjects(model.updatedAt, [dateTransformer transformedValue:JSON[@"updated_at"]],
                          @"The updated date should be set");
    XCTAssertTrue(model.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue],
                  @"The badge count should be set");
}

- (void)testUpdate {
    NSDictionary *updatedJSON = @{@"user_name": @"Updated User"};
    
    NSError *error;
    ZCREasyDoughTestsModel *updatedModel = [model updateWithIngredients:updatedJSON
                                                                 recipe:[ZCREasyDoughTestsModel simpleRecipe]
                                                                  error:&error];
    
    XCTAssertNotNil(updatedModel, @"The updated model should not be nil");
    XCTAssertNil(error, @"There should be no error");
    XCTAssertEqualObjects(model, updatedModel, @"Technically the two models should be equal");
    XCTAssertFalse(model == updatedModel, @"The two pointers should be different");
    
    XCTAssertEqualObjects(model.name, JSON[@"user_name"],
                          @"The original model's name should still be set");
    XCTAssertEqualObjects(updatedModel.name, updatedJSON[@"user_name"],
                          @"The updated model's name should be updated");
    XCTAssertEqualObjects(updatedModel.updatedAt, [dateTransformer transformedValue:JSON[@"updated_at"]],
                          @"The updated model's date should be unchanged");
    XCTAssertTrue(updatedModel.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue],
                  @"The updated model's badge count should be unchanged");
}

- (void)testUpdatePostsNotification {
    __block BOOL didNotifyClass = NO;
    __block BOOL didNotifyGeneric = NO;
    
    __block id classNotifier = [[NSNotificationCenter defaultCenter] addObserverForName:[ZCREasyDoughTestsModel updateNotificationName] object:model queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        didNotifyClass = YES;
        [[NSNotificationCenter defaultCenter] removeObserver:classNotifier];
    }];
    
    __block id genericNotifier = [[NSNotificationCenter defaultCenter] addObserverForName:ZCREasyDoughUpdatedNotification object:model queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        didNotifyGeneric = YES;
        [[NSNotificationCenter defaultCenter] removeObserver:genericNotifier];
    }];
    
    NSDictionary *updatedJSON = @{@"user_name": @"Updated User"};
    
    NSError *error;
    ZCREasyDoughTestsModel *updatedModel = [model updateWithIngredients:updatedJSON
                                                                 recipe:[ZCREasyDoughTestsModel simpleRecipe]
                                                                  error:&error];
    
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:10.0];
    while (!(didNotifyClass && didNotifyGeneric) &&
           [timeoutDate timeIntervalSinceNow] > 0.0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    
    XCTAssertTrue([timeoutDate timeIntervalSinceNow] > 0.0, @"The operation should not time out");
    XCTAssertTrue(didNotifyClass, @"The class should be notified");
    XCTAssertTrue(didNotifyGeneric, @"The generic notification should be posted");
    
    XCTAssertNotNil(updatedModel, @"The updated model should not be nil");
    XCTAssertNil(error, @"There should be no error");
}

- (void)testUpdateUnchanged {
    NSDictionary *updatedJSON = @{@"user_name": JSON[@"user_name"]};
    
    NSError *error;
    ZCREasyDoughTestsModel *updatedModel = [model updateWithIngredients:updatedJSON
                                                                 recipe:[ZCREasyDoughTestsModel simpleRecipe]
                                                                  error:&error];
    
    XCTAssertNotNil(updatedModel, @"The updated model should not be nil");
    XCTAssertNil(error, @"There should be no error");
    XCTAssertTrue(model == updatedModel, @"The models should be identical");
    XCTAssertEqualObjects(updatedModel.name, JSON[@"user_name"],
                          @"The updated model's name should be unchanged");
    XCTAssertEqualObjects(updatedModel.updatedAt, [dateTransformer transformedValue:JSON[@"updated_at"]],
                          @"The updated model's date should be unchanged");
    XCTAssertTrue(updatedModel.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue],
                  @"The updated model's badge count should be unchanged");
}

- (void)testUpdateUnchangedNoNotification {
    __block BOOL didNotifyClass = NO;
    __block BOOL didNotifyGeneric = NO;
    
    __block id classNotifier = [[NSNotificationCenter defaultCenter] addObserverForName:[ZCREasyDoughTestsModel updateNotificationName] object:model queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        didNotifyClass = YES;
        [[NSNotificationCenter defaultCenter] removeObserver:classNotifier];
    }];
    
    __block id genericNotifier = [[NSNotificationCenter defaultCenter] addObserverForName:ZCREasyDoughUpdatedNotification object:model queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        didNotifyGeneric = YES;
        [[NSNotificationCenter defaultCenter] removeObserver:genericNotifier];
    }];
    
    NSDictionary *updatedJSON = @{@"user_name": JSON[@"user_name"]};
    
    NSError *error;
    ZCREasyDoughTestsModel *updatedModel = [model updateWithIngredients:updatedJSON
                                                                 recipe:[ZCREasyDoughTestsModel simpleRecipe]
                                                                  error:&error];
    
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
    while (!(didNotifyClass && didNotifyGeneric) &&
           [timeoutDate timeIntervalSinceNow] > 0.0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    
    XCTAssertFalse([timeoutDate timeIntervalSinceNow] > 0.0, @"The operation should time out");
    XCTAssertFalse(didNotifyClass, @"The class should not be notified");
    XCTAssertFalse(didNotifyGeneric, @"The generic notification should not be posted");
    
    XCTAssertNotNil(updatedModel, @"The updated model should not be nil");
    XCTAssertNil(error, @"There should be no error");
}

- (void)testManualUpdateRaisesException {
    XCTAssertThrowsSpecificNamed([model setValue:@"Zachary Radke" forKey:@"name"],
                                 NSException, ZCREasyDoughExceptionAlreadyBaked,
                                 @"Manually accessing the iVar should throw an exception");
}

- (void)testDecomposeWithGenericRecipe {
    NSError *error;
    NSDictionary *ingredients = [model decomposeWithRecipe:[ZCREasyDoughTestsModel genericRecipe]
                                                     error:&error];
    
    XCTAssertNotNil(ingredients, @"There should be decomposed ingredients");
    XCTAssertNil(error, @"There should be no error");
    
    XCTAssertEqualObjects(ingredients[@"name"], model.name, @"The names should match");
    XCTAssertEqualObjects(ingredients[@"updatedAt"], model.updatedAt,
                          @"The updated dates should match");
    XCTAssertTrue(model.badgeCount == [ingredients[@"badgeCount"] unsignedIntegerValue],
                  @"The badge counts should match");
}

- (void)testDecomposeWithSimpleRecipe {
    NSError *error;
    NSDictionary *ingredients = [model decomposeWithRecipe:[ZCREasyDoughTestsModel simpleRecipe]
                                                     error:&error];
    
    XCTAssertNotNil(ingredients, @"There should be decomposed ingredients");
    XCTAssertNil(error, @"There should be no error");
    
    XCTAssertEqualObjects(ingredients[@"user_name"], model.name, @"The names should match");
    XCTAssertEqualObjects(ingredients[@"updated_at"], [dateTransformer reverseTransformedValue:model.updatedAt],
                          @"The updated dates should match");
    XCTAssertTrue(model.badgeCount == [ingredients[@"badge_count"] unsignedIntegerValue],
                  @"The badge counts should match");
}

- (void)testDecomposeWithComplexRecipe {
    NSError *error;
    NSDictionary *ingredients = [model decomposeWithRecipe:[ZCREasyDoughTestsModel complicatedRecipe]
                                                     error:&error];
    
    XCTAssertNotNil(ingredients, @"There should be decomposed ingredients");
    XCTAssertNil(error, @"There should be no error");
    
    XCTAssertEqualObjects([ingredients valueForKeyPath:@"user.name"], model.name,
                          @"The names should match.");
    XCTAssertEqualObjects(ingredients[@"updates"][0],
                          [dateTransformer reverseTransformedValue:model.updatedAt],
                          @"The updated dates should match.");
    XCTAssertEqual([[ingredients valueForKeyPath:@"user.count"] unsignedIntegerValue],
                   model.badgeCount, @"the badge counts should match.");
}

- (void)testDecomposeWithArrayRecipe {
    NSError *error;
    NSArray *ingredients = [model decomposeWithRecipe:[ZCREasyDoughTestsModel arrayBasedRecipe]
                                                     error:&error];
    
    XCTAssertNotNil(ingredients, @"There should be ingredients");
    XCTAssertNil(error, @"There should be no error");
    
    XCTAssertEqualObjects(ingredients[1][@"name"], model.name, @"The names should match.");
    XCTAssertEqualObjects(ingredients[0][0],
                          [dateTransformer reverseTransformedValue:model.updatedAt],
                          @"The updated dates should match.");
    XCTAssertEqual([ingredients[1][@"badge_count"] unsignedIntegerValue], model.badgeCount,
                    @"The badge counts should match.");
}

- (void)testIsEqualToIngredients {
    NSDictionary *ingredients = @{@"user_name": JSON[@"user_name"]};
    
    NSError *error;
    BOOL isEqual = [model isEqualToIngredients:ingredients
                                    withRecipe:[ZCREasyDoughTestsModel simpleRecipe]
                                         error:&error];
    
    XCTAssertNil(error, @"There should be no error");
    XCTAssertTrue(isEqual, @"The ingredients should be equal");
}

- (void)testIsInequalToIngredients {
    NSDictionary *ingredients = @{@"user_name": @"Updated Name"};
    
    NSError *error;
    BOOL isEqual = [model isEqualToIngredients:ingredients
                                    withRecipe:[ZCREasyDoughTestsModel simpleRecipe]
                                         error:&error];
    
    XCTAssertNil(error, @"There should be no error");
    XCTAssertFalse(isEqual, @"The ingredients should be inequal");
}

- (void)testGenericRecipe {
    NSArray *propertyNames = @[@"name", @"updatedAt", @"badgeCount"];
    NSDictionary *expectedMapping = [NSDictionary dictionaryWithObjects:propertyNames
                                                                forKeys:propertyNames];
    
    ZCREasyRecipe *recipe = [ZCREasyDoughTestsModel genericRecipe];
    XCTAssertEqualObjects(expectedMapping, recipe.ingredientMapping
                          , @"The generic recipes ingredient maps should match");
    XCTAssertTrue(recipe.ingredientTransformers.count == 0,
                  @"There should be no transformers registered.");
}

- (void)testAllPropertyNames {
    NSSet *propertyNames = [NSSet setWithArray:@[@"name", @"updatedAt", @"badgeCount"]];
    XCTAssertEqualObjects(propertyNames, [ZCREasyDoughTestsModel allPropertyNames],
                          @"The property names should match");
}

@end
