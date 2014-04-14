//
//  ZCREasyDoughTests.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/11/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

@import XCTest;

#import "ZCREasyDough.h"

@interface ZCREasyDoughTestsModel : ZCREasyDough

@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSDate *updatedAt;
@property (assign, nonatomic, readonly) NSUInteger badgeCount;

+ (NSDictionary *)JSONRecipe;

@end

@implementation ZCREasyDoughTestsModel

+ (NSDictionary *)JSONRecipe {
    static NSDictionary *JSONRecipe;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JSONRecipe = @{@"name": @"user_name",
                       @"updatedAt": @"updated_at",
                       @"badgeCount": @"badge_count"};
    });
    return JSONRecipe;
}

@end

@interface ZCREasyDoughTests : XCTestCase {
    ZCREasyDoughTestsModel *model;
    NSDictionary *JSON;
}
@end

@implementation ZCREasyDoughTests

- (void)setUp {
    [super setUp];
    
    JSON = @{@"server_id": @"4839028431382930",
             @"user_name": @"Test User",
             @"updated_at": [NSDate dateWithTimeIntervalSinceReferenceDate:9000000],
             @"badge_count": @90};

    model = [[ZCREasyDoughTestsModel alloc] initWithIdentifier:JSON[@"server_id"]
                                                   ingredients:JSON
                                                        recipe:[ZCREasyDoughTestsModel JSONRecipe]
                                                         error:NULL];
}

- (void)tearDown {
    model = nil;
    JSON = nil;
    
    [super tearDown];
}

- (void)testInitializer {
    XCTAssertNotNil(model, @"The model should have serialized successfully");
    XCTAssertEqualObjects(model.name, JSON[@"user_name"], @"The name should be set");
    XCTAssertEqualObjects(model.updatedAt, JSON[@"updated_at"], @"The updated date should be set");
    XCTAssertTrue(model.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue], @"The badge count should be set");
}

- (void)testPrepareWithChef {
    __block BOOL isValid = NO;
    __block NSError *error = nil;
    
    model = [ZCREasyDoughTestsModel prepareWith:^(id<ZCREasyChef> chef) {
        chef.identifier = JSON[@"server_id"];
        chef.ingredients = JSON;
        chef.recipe = [ZCREasyDoughTestsModel JSONRecipe];
        
        isValid = [chef validateKitchen:&error];
    }];
    
    XCTAssertTrue(isValid, @"The chef should validate");
    XCTAssertNil(error, @"The error should be nil");
    XCTAssertNotNil(model, @"The model should be built");
    XCTAssertEqualObjects(model.name, JSON[@"user_name"], @"The name should be set");
    XCTAssertEqualObjects(model.updatedAt, JSON[@"updated_at"], @"The updated date should be set");
    XCTAssertTrue(model.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue], @"The badge count should be set");
}

- (void)testUpdate {
    NSDictionary *updatedJSON = @{@"user_name": @"Updated User"};
    
    NSError *error;
    ZCREasyDoughTestsModel *updatedModel = [model updateWithIngredients:updatedJSON recipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
    XCTAssertNotNil(updatedModel, @"The updated model should not be nil");
    XCTAssertNil(error, @"There should be no error");
    XCTAssertEqualObjects(model, updatedModel, @"Technically the two models should be equal");
    XCTAssertFalse(model == updatedModel, @"The two pointers should be different");
    
    XCTAssertEqualObjects(model.name, JSON[@"user_name"], @"The original model's name should still be set");
    XCTAssertEqualObjects(updatedModel.name, updatedJSON[@"user_name"], @"The updated model's name should be updated");
    XCTAssertEqualObjects(updatedModel.updatedAt, JSON[@"updated_at"], @"The updated model's date should be unchanged");
    XCTAssertTrue(updatedModel.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue], @"The updated model's badge count should be unchanged");
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
    ZCREasyDoughTestsModel *updatedModel = [model updateWithIngredients:updatedJSON recipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
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
    ZCREasyDoughTestsModel *updatedModel = [model updateWithIngredients:updatedJSON recipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
    XCTAssertNotNil(updatedModel, @"The updated model should not be nil");
    XCTAssertNil(error, @"There should be no error");
    XCTAssertTrue(model == updatedModel, @"The models should be identical");
    XCTAssertEqualObjects(updatedModel.name, JSON[@"user_name"], @"The updated model's name should be unchanged");
    XCTAssertEqualObjects(updatedModel.updatedAt, JSON[@"updated_at"], @"The updated model's date should be unchanged");
    XCTAssertTrue(updatedModel.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue], @"The updated model's badge count should be unchanged");
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
    ZCREasyDoughTestsModel *updatedModel = [model updateWithIngredients:updatedJSON recipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
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
    XCTAssertThrowsSpecificNamed([model setValue:@"Zachary Radke" forKey:@"name"], NSException, ZCREasyDoughExceptionAlreadyBaked, @"Manually accessing the iVar should throw an exception");
}

- (void)testDecomposeWithGenericRecipe {
    NSError *error;
    NSDictionary *ingredients = [model decomposeWithRecipe:[ZCREasyDoughTestsModel genericRecipe] error:&error];
    
    XCTAssertNotNil(ingredients, @"There should be decomposed ingredients");
    XCTAssertNil(error, @"There should be no error");
    
    XCTAssertEqualObjects(ingredients[@"name"], model.name, @"The names should match");
    XCTAssertEqualObjects(ingredients[@"updatedAt"], model.updatedAt, @"The updated dates should match");
    XCTAssertTrue(model.badgeCount == [ingredients[@"badgeCount"] unsignedIntegerValue], @"The badge counts should match");
}

- (void)testDecomposeWithJSONRecipe {
    NSError *error;
    NSDictionary *ingredients = [model decomposeWithRecipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
    XCTAssertNotNil(ingredients, @"There should be decomposed ingredients");
    XCTAssertNil(error, @"There should be no error");
    
    XCTAssertEqualObjects(ingredients[@"user_name"], model.name, @"The names should match");
    XCTAssertEqualObjects(ingredients[@"updated_at"], model.updatedAt, @"The updated dates should match");
    XCTAssertTrue(model.badgeCount == [ingredients[@"badge_count"] unsignedIntegerValue], @"The badge counts should match");
}

- (void)testIsEqualToIngredients {
    NSDictionary *ingredients = @{@"user_name": JSON[@"user_name"]};
    
    NSError *error;
    BOOL isEqual = [model isEqualToIngredients:ingredients withRecipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
    XCTAssertNil(error, @"There should be no error");
    XCTAssertTrue(isEqual, @"The ingredients should be equal");
}

- (void)testIsInequalToIngredients {
    NSDictionary *ingredients = @{@"user_name": @"Updated Name"};
    
    NSError *error;
    BOOL isEqual = [model isEqualToIngredients:ingredients withRecipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
    XCTAssertNil(error, @"There should be no error");
    XCTAssertFalse(isEqual, @"The ingredients should be inequal");
}

- (void)testGenericRecipe {
    NSArray *propertyNames = @[@"name", @"updatedAt", @"badgeCount"];
    NSDictionary *expectedRecipe = [NSDictionary dictionaryWithObjects:propertyNames forKeys:propertyNames];
    
    XCTAssertEqualObjects(expectedRecipe, [ZCREasyDoughTestsModel genericRecipe], @"The generic recipes should match");
}

- (void)testAllPropertyNames {
    NSSet *propertyNames = [NSSet setWithArray:@[@"name", @"updatedAt", @"badgeCount"]];
    XCTAssertEqualObjects(propertyNames, [ZCREasyDoughTestsModel allPropertyNames], @"The property names should match");
}

@end
