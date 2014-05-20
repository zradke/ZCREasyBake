//
//  ZCREasyRecipeBoxTests.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/24/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZCREasyRecipe.h"

@interface ZCREasyRecipeBoxTests : XCTestCase
{
    ZCREasyRecipeBox *box;
    ZCREasyRecipe *recipe;
}
@end

@implementation ZCREasyRecipeBoxTests

- (void)setUp {
    [super setUp];
    
    recipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        recipeMaker.name = @"TestRecipe1";
        recipeMaker.ingredientMapping = @{@"key1": @"key_1"};
    }];
    box = [[ZCREasyRecipeBox alloc] init];
}

- (void)tearDown {
    recipe = nil;
    box = nil;
    
    [super tearDown];
}

- (void)testInit {
    XCTAssertNotNil(box, @"The box should be initialized.");
}

- (void)testSharedBox {
    XCTAssertNotNil([ZCREasyRecipeBox defaultBox], @"The shared box should be initialized");
    XCTAssertEqual([ZCREasyRecipeBox defaultBox], [ZCREasyRecipeBox defaultBox], @"The shared box should always be the same.");
}

- (void)testAddRecipe {
    NSError *error;
    XCTAssertTrue([box addRecipe:recipe error:&error], @"The recipe should be added.");
    XCTAssertNil(error, @"There should be no error adding the recipe.");
}

- (void)testRecipeNames {
    [box addRecipe:recipe error:NULL];
    XCTAssertEqualObjects(box.recipeNames, [NSSet setWithObject:@"TestRecipe1"], @"The recipe's name should be exposed.");
}

- (void)testGetRecipe {
    [box addRecipe:recipe error:NULL];
    ZCREasyRecipe *fetchedRecipe = [box recipeWithName:@"TestRecipe1"];
    XCTAssertEqual(fetchedRecipe, recipe, @"The fetched recipe should be the same as the recipe.");
}

- (void)testRemoveRecipeWithName {
    [box addRecipe:recipe error:NULL];
    NSError *error;
    XCTAssertTrue([box removeRecipeNamed:@"TestRecipe1" error:&error], @"The recipe should be removed.");
    XCTAssertNil(error, @"There should be no error removing the recipe");
    XCTAssertTrue(box.recipeNames.count == 0, @"The recipe name should be removed");
}

- (void)testMakeAndAddRecipe {
    recipe = [box addRecipeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        recipeMaker.name = @"TestRecipe2";
        recipeMaker.ingredientMapping = @{@"key2": @"key_2"};
    }];
    
    XCTAssertNotNil(recipe, @"The recipe should be returned.");
    
    ZCREasyRecipe *fetchedRecipe = [box recipeWithName:@"TestRecipe2"];
    XCTAssertEqual(fetchedRecipe, recipe, @"The fetched recipe should be the same as the returned recipe.");
}

- (void)testMakeAndAddWithoutSettingName {
    recipe = [box addRecipeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        recipeMaker.name = nil;
        recipeMaker.ingredientMapping = @{@"key1": @"key_1"};
    }];
    XCTAssertNotNil(recipe, @"There should be a recipe.");
    XCTAssertNotNil(recipe.name, @"The recipe should have a name set.");
    XCTAssert([box.recipeNames containsObject:recipe.name], @"The recipe should be in the box.");
}

#pragma mark - Errors

- (void)testErrorAddNilRecipe {
    NSError *error;
    XCTAssertFalse([box addRecipe:nil error:&error], @"The recipe should not be added.");
    XCTAssertNotNil(error, @"There should be an error returned.");
}

- (void)testErrorAddRecipeWithoutName {
    ZCREasyRecipe *unnamedRecipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        recipeMaker.ingredientMapping = @{@"key3": @"key_3"};
    }];
    
    NSError *error;
    XCTAssertFalse([box addRecipe:unnamedRecipe error:&error],
                   @"The unnamed recipe should not be added.");
    XCTAssertNotNil(error, @"The error should be populated.");
}

- (void)testGetNilRecipe {
    [box addRecipe:recipe error:NULL];
    ZCREasyRecipe *fetchedRecipe = [box recipeWithName:nil];
    XCTAssertNil(fetchedRecipe, @"There should be no fetched recipe");
}

- (void)testGetUnknownRecipe {
    [box addRecipe:recipe error:NULL];
    ZCREasyRecipe *fetchedRecipe = [box recipeWithName:@"UnknownRecipe"];
    XCTAssertNil(fetchedRecipe, @"There should be no fetched recipe");
}

- (void)testErrorRemoveRecipeWithoutName {
    [box addRecipe:recipe error:NULL];
    NSError *error;
    XCTAssertFalse([box removeRecipeNamed:nil error:&error], @"The recipe should not be removed.");
    XCTAssertNotNil(error, @"The error should be populated.");
}

- (void)testErrorRemoveRecipeWithUnknownName {
    [box addRecipe:recipe error:NULL];
    NSError *error;
    XCTAssertFalse([box removeRecipeNamed:@"UnknownRecipe" error:&error], @"The recipe should not be removed.");
    XCTAssertNotNil(error, @"The error should be populated.");
}

@end
