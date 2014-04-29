//
//  ZCREasyDoughErrorTests.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/24/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZCREasyDough.h"
#import "ZCREasyRecipe.h"

@interface ZCREasyDoughErrorModel : ZCREasyDough

@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *brokenGetter;
@property (strong, nonatomic) NSString *brokenSetter;

@end

@implementation ZCREasyDoughErrorModel

- (void)setBrokenSetter:(NSString *)brokenSetter {
    [NSException raise:NSInternalInconsistencyException format:@"Broken setter!"];
}

- (NSString *)brokenGetter {
    [NSException raise:NSInternalInconsistencyException format:@"Broken setter!"];
    return nil;
}

@end


@interface ZCREasyDoughErrorTests : XCTestCase {
    ZCREasyDoughErrorModel *model;
    NSString *identifier;
    NSDictionary *ingredients;
    ZCREasyRecipe *recipe;
}
@end

@implementation ZCREasyDoughErrorTests

- (void)setUp {
    [super setUp];
    
    recipe = [[ZCREasyDoughErrorModel genericRecipe] modifyWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker removeInstructionForProperty:@"brokenGetter" error:NULL];
    }];
    ingredients = @{@"name": @"TestName"};
    identifier = @"model1";
    model = [[ZCREasyDoughErrorModel alloc] initWithIdentifier:identifier
                                                   ingredients:ingredients
                                                        recipe:recipe error:NULL];
}

- (void)tearDown {
    model = nil;
    identifier = nil;
    ingredients = nil;
    recipe = nil;
    
    [super tearDown];
}

- (void)testInitWithoutIdentifier {
    NSError *error;
    model = [[ZCREasyDoughErrorModel alloc] initWithIdentifier:nil ingredients:ingredients
                                                        recipe:recipe error:&error];
    XCTAssertNil(model, @"The model cannot be created without an identiifer.");
    XCTAssertNotNil(error, @"There should be an error.");
}

- (void)testInitWithoutRecipe {
    NSError *error;
    model = [[ZCREasyDoughErrorModel alloc] initWithIdentifier:identifier ingredients:ingredients
                                                        recipe:nil error:&error];
    XCTAssertNil(model, @"The model cannot be created without a recipe when ingredients exist.");
    XCTAssertNotNil(error, @"There should be an error.");
}

- (void)testInitWithInvalidRecipe {
    recipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker setIngredientMapping:@{@"unknownKey": @"unknownKey"}];
    }];
    NSError *error;
    model = [[ZCREasyDoughErrorModel alloc] initWithIdentifier:identifier ingredients:ingredients
                                                        recipe:recipe error:&error];
    XCTAssertNil(model, @"The model cannot be created without a recipe when ingredients exist.");
    XCTAssertNotNil(error, @"There should be an error.");
}

- (void)testInitWithSettingException {
    ingredients = @{@"brokenSetter": @"test"};
    
    __block NSError *error;
    __block ZCREasyDoughErrorModel *blockModel = nil;
    void (^block)() = ^{
        blockModel = [[ZCREasyDoughErrorModel alloc] initWithIdentifier:identifier
                                                            ingredients:ingredients
                                                                 recipe:recipe error:&error];
    };
    
    XCTAssertNoThrow(block(), @"The exception should be caught.");
    XCTAssertNil(blockModel, @"The model should be nil.");
    XCTAssertNotNil(error, @"The error should be set.");
}

- (void)testMakeWithInvalidRecipe {
    recipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker setIngredientMapping:@{@"unknownKey": @"unknownKey"}];
    }];
    
    __block NSError *error;
    model = [ZCREasyDoughErrorModel makeWith:^(id<ZCREasyBaker> chef) {
        [chef setIngredients:ingredients];
        [chef setRecipe:recipe];
        [chef validateKitchen:&error];
    }];
    
    XCTAssertNil(model, @"The model should be nil.");
    XCTAssertNotNil(error, @"The error should be set.");
}

- (void)testMakeWithSettingException {
    ingredients = @{@"brokenSetter": @"test"};
    
    __block ZCREasyDoughErrorModel *blockModel = nil;
    void (^block)() = ^{
        blockModel = [ZCREasyDoughErrorModel makeWith:^(id<ZCREasyBaker> chef) {
            [chef setIngredients:ingredients];
            [chef setRecipe:recipe];
        }];
    };
    
    XCTAssertNoThrow(block(), @"The exception should be caught.");
    XCTAssertNil(blockModel, @"The model should be nil.");
}

- (void)testUpdateWithoutIngredients {
    NSError *error;
    model = [model updateWithIngredients:nil recipe:recipe error:&error];
    
    XCTAssertNil(model, @"The model should be nil.");
    XCTAssertNotNil(error, @"The error should be set.");
}

- (void)testUpdateWithoutRecipe {
    NSError *error;
    model = [model updateWithIngredients:ingredients recipe:nil error:&error];
    
    XCTAssertNil(model, @"The model should be nil.");
    XCTAssertNotNil(error, @"The error should be set.");
}

- (void)testUpdateWithInvalidRecipe {
    recipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker setIngredientMapping:@{@"unknownKey": @"unknownKey"}];
    }];
    
    NSError *error;
    model = [model updateWithIngredients:ingredients recipe:recipe error:&error];
    
    XCTAssertNil(model, @"The model should be nil.");
    XCTAssertNotNil(error, @"The error should be set.");
}

- (void)testUpdateWithSettingException {
    ingredients = @{@"brokenSetter": @"TestName"};
    
    __block NSError *error;
    __block ZCREasyDoughErrorModel *blockModel = nil;
    void (^block)() = ^{
        blockModel = [model updateWithIngredients:ingredients recipe:recipe error:&error];
    };
    
    XCTAssertNoThrow(block(), @"The exception should be caught.");
    XCTAssertNil(blockModel, @"The model should be nil.");
    XCTAssertNotNil(error, @"The error should be set.");
}

- (void)testUpdateWithGettingException {
    recipe = [recipe modifyWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker addInstructionForProperty:@"brokenGetter" ingredientName:@"brokenGetter"
                                   transformer:nil error:NULL];
    }];
    
    ingredients = @{@"brokenGetter": @"test"};
    
    __block NSError *error;
    __block ZCREasyDoughErrorModel *blockModel = nil;
    void (^block)() = ^{
        blockModel = [model updateWithIngredients:ingredients recipe:recipe error:&error];
    };
    
    XCTAssertNoThrow(block(), @"The exception should be caught.");
    XCTAssertNil(blockModel, @"The model should be nil.");
    XCTAssertNotNil(error, @"The error should be set.");
}

- (void)testDecomposeWithoutRecipe {
    NSError *error;
    NSDictionary *decomposed = [model decomposeWithRecipe:nil error:&error];
    
    XCTAssertNil(decomposed, @"There should be no decomposition.");
    XCTAssertNotNil(error, @"There should be an error;");
}

- (void)testDecomposeWithInvalidRecipe {
    recipe = [recipe modifyWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker setIngredientMapping:@{@"unknownKey": @"unknownKey"}];
    }];
    
    NSError *error;
    NSDictionary *decomposed = [model decomposeWithRecipe:recipe error:&error];
    
    XCTAssertNil(decomposed, @"There should be no decomposition.");
    XCTAssertNotNil(error, @"There should be an error;");
}

- (void)testDecomposeWithGettingException {
    recipe = [recipe modifyWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker addInstructionForProperty:@"brokenGetter" ingredientName:@"brokenGetter"
                                   transformer:nil error:NULL];
    }];
    
    __block NSError *error;
    __block NSDictionary *decomposed = nil;
    void (^block)() = ^{
        decomposed = [model decomposeWithRecipe:recipe error:&error];
    };
    
    XCTAssertNoThrow(block(), @"The exception should be caught.");
    XCTAssertNil(decomposed, @"There should be no decomposition.");
    XCTAssertNotNil(error, @"There should be an error;");
}

- (void)testIsEqualWithoutIngredients {
    NSError *error;
    BOOL isEqual = [model isEqualToIngredients:nil withRecipe:recipe error:&error];
    
    XCTAssertFalse(isEqual, @"If an error occus it should return NO.");
    XCTAssertNotNil(error, @"The error should be set.");
}

- (void)testIsEqualWithoutRecipe {
    NSError *error;
    BOOL isEqual = [model isEqualToIngredients:ingredients withRecipe:nil error:&error];
    
    XCTAssertFalse(isEqual, @"If an error occus it should return NO.");
    XCTAssertNotNil(error, @"The error should be set.");
}

- (void)testIsEqualWithInvalidRecipe {
    recipe = [recipe modifyWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker setIngredientMapping:@{@"unknownKey": @"unknownKey"}];
    }];
    
    NSError *error;
    BOOL isEqual = [model isEqualToIngredients:ingredients withRecipe:recipe error:&error];
    
    XCTAssertFalse(isEqual, @"If an error occus it should return NO.");
    XCTAssertNotNil(error, @"The error should be set.");
}

- (void)testIsEqualWithGettingException {
    recipe = [recipe modifyWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker addInstructionForProperty:@"brokenGetter" ingredientName:@"brokenGetter"
                                   transformer:nil error:NULL];
    }];
    
    ingredients = @{@"brokenGetter": @"test"};
    
    __block NSError *error;
    __block BOOL isEqual = YES;
    void (^block)() = ^{
        isEqual = [model isEqualToIngredients:ingredients withRecipe:recipe error:&error];
    };
    
    XCTAssertNoThrow(block(), @"The exception should be caught.");
    XCTAssertFalse(isEqual, @"If an error occus it should return NO.");
    XCTAssertNotNil(error, @"The error should be set.");
}

@end
