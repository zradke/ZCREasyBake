//
//  ZCREasyOvenTests.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 6/26/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ZCREasyOven.h"
#import "ZCREasyBlockTransformer.h"

@interface ZCREasyOvenTests : XCTestCase {
    ZCREasyRecipe *dictionaryRecipe;
    ZCREasyRecipe *arrayRecipe;
}
@end

@implementation ZCREasyOvenTests

- (void)setUp {
    [super setUp];
    
    ZCREasyBlockTransformer *uppercaseTransformer = [ZCREasyBlockTransformer oneWayTransformerWithForwardBlock:^id(id value) {
        return [value uppercaseString];
    }];
    
    dictionaryRecipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker addInstructionForProperty:@"key1" ingredientPath:@"key_1" transformer:uppercaseTransformer error:NULL];
        [recipeMaker addInstructionForProperty:@"key2" ingredientPath:@"key_2" transformer:nil error:NULL];
    }];
    
    arrayRecipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker addInstructionForProperty:@"key1" ingredientPath:@"[0]" transformer:uppercaseTransformer error:NULL];
        [recipeMaker addInstructionForProperty:@"key2" ingredientPath:@"[1]" transformer:nil error:NULL];
    }];
}

- (void)tearDown {
    dictionaryRecipe = nil;
    arrayRecipe = nil;
    
    [super tearDown];
}

- (void)testPopulateModelWithDictionaryRecipe {
    NSDate *date = [NSDate date];
    NSMutableDictionary *model = [NSMutableDictionary dictionary];
    model[@"key1"] = @"TEST";
    model[@"key2"] = date;
    
    NSDictionary *ingredients = @{@"key_1": @"update"};
    NSError *error;
    [ZCREasyOven populateModel:model ingredients:ingredients recipe:dictionaryRecipe error:&error];
    
    XCTAssertNil(error, @"The error should be nil.");
    
    NSDictionary *expectedModel = @{@"key1": @"UPDATE",
                                    @"key2": date};
    XCTAssertEqualObjects(model, expectedModel, @"The model should be updated.");
}

- (void)testPopulateModelWithArrayRecipe {
    NSDate *date = [NSDate date];
    NSMutableDictionary *model = [NSMutableDictionary dictionary];
    model[@"key1"] = @"TEST";
    model[@"key2"] = date;
    
    NSArray *ingredients = @[@"update"];
    NSError *error;
    [ZCREasyOven populateModel:model ingredients:ingredients recipe:arrayRecipe error:&error];
    
    XCTAssertNil(error, @"The error should be nil.");
    
    NSDictionary *expectedModel = @{@"key1": @"UPDATE",
                                    @"key2": date};
    XCTAssertEqualObjects(model, expectedModel, @"The model should be updated.");
}

- (void)testIsEqualToIngredientsWithDictionaryRecipe {
    NSDate *date = [NSDate date];
    NSMutableDictionary *model = [NSMutableDictionary dictionary];
    model[@"key1"] = @"TEST";
    model[@"key2"] = date;
    
    NSDictionary *ingredients = @{@"key_1": @"test"};
    NSError *error;
    BOOL isEqual = [ZCREasyOven isModel:model equalToIngredients:ingredients recipe:dictionaryRecipe error:&error];
    
    XCTAssertNil(error, @"The error should be nil");
    XCTAssertTrue(isEqual, @"The model should be equal to the materials.");
}

- (void)testIsEqualToIngredientsWithArrayRecipe {
    NSDate *date = [NSDate date];
    NSMutableDictionary *model = [NSMutableDictionary dictionary];
    model[@"key1"] = @"TEST";
    model[@"key2"] = date;
    
    NSArray *ingredients = @[@"test"];
    NSError *error;
    BOOL isEqual = [ZCREasyOven isModel:model equalToIngredients:ingredients recipe:arrayRecipe error:&error];
    
    XCTAssertNil(error, @"The error should be nil");
    XCTAssertTrue(isEqual, @"The model should be equal to the materials.");
}

- (void)testDeconstructIncompeteModelWithDictionaryRecipe {
    NSDate *date = [NSDate date];
    NSMutableDictionary *model = [NSMutableDictionary dictionaryWithObject:date forKey:@"key2"];
    
    NSError *error;
    id ingredients = [ZCREasyOven decomposeModel:model withRecipe:dictionaryRecipe error:&error];
    
    XCTAssertNil(error, @"The error should be nil.");
    
    NSDictionary *expectedIngredients = @{@"key_1": [NSNull null],
                                          @"key_2": date};
    XCTAssertEqualObjects(ingredients, expectedIngredients, @"The model should be decomposed.");
}

- (void)testDeconstructModelWithDictionaryRecipe {
    NSDate *date = [NSDate date];
    NSMutableDictionary *model = [NSMutableDictionary dictionary];
    model[@"key1"] = @"TEST";
    model[@"key2"] = date;
    
    NSError *error;
    id ingredients = [ZCREasyOven decomposeModel:model withRecipe:dictionaryRecipe error:&error];
    
    XCTAssertNil(error, @"The error should be nil.");
    
    NSDictionary *expectedIngredients = @{@"key_1": @"TEST",
                                          @"key_2": date};
    XCTAssertEqualObjects(ingredients, expectedIngredients, @"The model should be decomposed.");
}


- (void)testDeconstructIncompeteModelWithArrayRecipe {
    NSDate *date = [NSDate date];
    NSMutableDictionary *model = [NSMutableDictionary dictionaryWithObject:date forKey:@"key2"];
    
    NSError *error;
    id ingredients = [ZCREasyOven decomposeModel:model withRecipe:arrayRecipe error:&error];
    
    XCTAssertNil(error, @"The error should be nil.");
    
    NSArray *expectedIngredients = @[[NSNull null], date];
    XCTAssertEqualObjects(ingredients, expectedIngredients, @"The model should be decomposed.");
}

- (void)testModelWithArrayRecipe {
    NSDate *date = [NSDate date];
    NSMutableDictionary *model = [NSMutableDictionary dictionary];
    model[@"key1"] = @"TEST";
    model[@"key2"] = date;
    
    NSError *error;
    id ingredients = [ZCREasyOven decomposeModel:model withRecipe:arrayRecipe error:&error];
    
    XCTAssertNil(error, @"The error should be nil.");
    
    NSArray *expectedIngredients = @[@"TEST", date];
    XCTAssertEqualObjects(ingredients, expectedIngredients, @"The model should be decomposed.");
}

@end
