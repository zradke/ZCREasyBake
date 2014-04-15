//
//  ZCREasyDoughTests.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/11/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

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

@interface ZCREasyDoughTests : ZCRTestCase {
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
    ZCRAssertNotNil(model, @"The model should have serialized successfully");
    ZCRAssertEqualObjects(model.name, JSON[@"user_name"], @"The name should be set");
    ZCRAssertEqualObjects(model.updatedAt, JSON[@"updated_at"], @"The updated date should be set");
    ZCRAssertTrue(model.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue], @"The badge count should be set");
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
    
    ZCRAssertTrue(isValid, @"The chef should validate");
    ZCRAssertNil(error, @"The error should be nil");
    ZCRAssertNotNil(model, @"The model should be built");
    ZCRAssertEqualObjects(model.name, JSON[@"user_name"], @"The name should be set");
    ZCRAssertEqualObjects(model.updatedAt, JSON[@"updated_at"], @"The updated date should be set");
    ZCRAssertTrue(model.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue], @"The badge count should be set");
}

- (void)testUpdate {
    NSDictionary *updatedJSON = @{@"user_name": @"Updated User"};
    
    NSError *error;
    ZCREasyDoughTestsModel *updatedModel = [model updateWithIngredients:updatedJSON recipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
    ZCRAssertNotNil(updatedModel, @"The updated model should not be nil");
    ZCRAssertNil(error, @"There should be no error");
    ZCRAssertEqualObjects(model, updatedModel, @"Technically the two models should be equal");
    ZCRAssertFalse(model == updatedModel, @"The two pointers should be different");
    
    ZCRAssertEqualObjects(model.name, JSON[@"user_name"], @"The original model's name should still be set");
    ZCRAssertEqualObjects(updatedModel.name, updatedJSON[@"user_name"], @"The updated model's name should be updated");
    ZCRAssertEqualObjects(updatedModel.updatedAt, JSON[@"updated_at"], @"The updated model's date should be unchanged");
    ZCRAssertTrue(updatedModel.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue], @"The updated model's badge count should be unchanged");
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
    
    ZCRAssertTrue([timeoutDate timeIntervalSinceNow] > 0.0, @"The operation should not time out");
    ZCRAssertTrue(didNotifyClass, @"The class should be notified");
    ZCRAssertTrue(didNotifyGeneric, @"The generic notification should be posted");
    
    ZCRAssertNotNil(updatedModel, @"The updated model should not be nil");
    ZCRAssertNil(error, @"There should be no error");
}

- (void)testUpdateUnchanged {
    NSDictionary *updatedJSON = @{@"user_name": JSON[@"user_name"]};
    
    NSError *error;
    ZCREasyDoughTestsModel *updatedModel = [model updateWithIngredients:updatedJSON recipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
    ZCRAssertNotNil(updatedModel, @"The updated model should not be nil");
    ZCRAssertNil(error, @"There should be no error");
    ZCRAssertTrue(model == updatedModel, @"The models should be identical");
    ZCRAssertEqualObjects(updatedModel.name, JSON[@"user_name"], @"The updated model's name should be unchanged");
    ZCRAssertEqualObjects(updatedModel.updatedAt, JSON[@"updated_at"], @"The updated model's date should be unchanged");
    ZCRAssertTrue(updatedModel.badgeCount == [JSON[@"badge_count"] unsignedIntegerValue], @"The updated model's badge count should be unchanged");
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
    
    ZCRAssertFalse([timeoutDate timeIntervalSinceNow] > 0.0, @"The operation should time out");
    ZCRAssertFalse(didNotifyClass, @"The class should not be notified");
    ZCRAssertFalse(didNotifyGeneric, @"The generic notification should not be posted");
    
    ZCRAssertNotNil(updatedModel, @"The updated model should not be nil");
    ZCRAssertNil(error, @"There should be no error");
}

- (void)testManualUpdateRaisesException {
    ZCRAssertThrowsSpecificNamed([model setValue:@"Zachary Radke" forKey:@"name"], NSException, ZCREasyDoughExceptionAlreadyBaked, @"Manually accessing the iVar should throw an exception");
}

- (void)testDecomposeWithGenericRecipe {
    NSError *error;
    NSDictionary *ingredients = [model decomposeWithRecipe:[ZCREasyDoughTestsModel genericRecipe] error:&error];
    
    ZCRAssertNotNil(ingredients, @"There should be decomposed ingredients");
    ZCRAssertNil(error, @"There should be no error");
    
    ZCRAssertEqualObjects(ingredients[@"name"], model.name, @"The names should match");
    ZCRAssertEqualObjects(ingredients[@"updatedAt"], model.updatedAt, @"The updated dates should match");
    ZCRAssertTrue(model.badgeCount == [ingredients[@"badgeCount"] unsignedIntegerValue], @"The badge counts should match");
}

- (void)testDecomposeWithJSONRecipe {
    NSError *error;
    NSDictionary *ingredients = [model decomposeWithRecipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
    ZCRAssertNotNil(ingredients, @"There should be decomposed ingredients");
    ZCRAssertNil(error, @"There should be no error");
    
    ZCRAssertEqualObjects(ingredients[@"user_name"], model.name, @"The names should match");
    ZCRAssertEqualObjects(ingredients[@"updated_at"], model.updatedAt, @"The updated dates should match");
    ZCRAssertTrue(model.badgeCount == [ingredients[@"badge_count"] unsignedIntegerValue], @"The badge counts should match");
}

- (void)testIsEqualToIngredients {
    NSDictionary *ingredients = @{@"user_name": JSON[@"user_name"]};
    
    NSError *error;
    BOOL isEqual = [model isEqualToIngredients:ingredients withRecipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
    ZCRAssertNil(error, @"There should be no error");
    ZCRAssertTrue(isEqual, @"The ingredients should be equal");
}

- (void)testIsInequalToIngredients {
    NSDictionary *ingredients = @{@"user_name": @"Updated Name"};
    
    NSError *error;
    BOOL isEqual = [model isEqualToIngredients:ingredients withRecipe:[ZCREasyDoughTestsModel JSONRecipe] error:&error];
    
    ZCRAssertNil(error, @"There should be no error");
    ZCRAssertFalse(isEqual, @"The ingredients should be inequal");
}

- (void)testGenericRecipe {
    NSArray *propertyNames = @[@"name", @"updatedAt", @"badgeCount"];
    NSDictionary *expectedRecipe = [NSDictionary dictionaryWithObjects:propertyNames forKeys:propertyNames];
    
    ZCRAssertEqualObjects(expectedRecipe, [ZCREasyDoughTestsModel genericRecipe], @"The generic recipes should match");
}

- (void)testAllPropertyNames {
    NSSet *propertyNames = [NSSet setWithArray:@[@"name", @"updatedAt", @"badgeCount"]];
    ZCRAssertEqualObjects(propertyNames, [ZCREasyDoughTestsModel allPropertyNames], @"The property names should match");
}

@end
