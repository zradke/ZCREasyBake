//
//  ZCREasyRecipeTests.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/24/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZCREasyRecipe.h"

@interface ZCROneWayTransformer : NSValueTransformer
@end

@implementation ZCROneWayTransformer

+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
    return [value uppercaseString];
}

@end

@interface ZCREasyRecipeTests : XCTestCase {
    NSString *name;
    NSDictionary *mapping;
    NSDictionary *transformers;
    ZCREasyRecipe *recipe;
}
@end

@implementation ZCREasyRecipeTests

- (void)setUp {
    [super setUp];
    
    [NSValueTransformer setValueTransformer:[ZCROneWayTransformer new]
                                    forName:@"ZCRReversibleTransformer"];
    
    name = @"TestRecipe";
    mapping = @{@"key1": @"key_1",
                @"key2": @"key_2",
                @"key3": @"key_3[0]"};
    transformers = @{@"key1": @"ZCRReversibleTransformer",
                     @"key2": [ZCROneWayTransformer new]};
    
    recipe = [[ZCREasyRecipe alloc] initWithName:name ingredientMapping:mapping
                          ingredientTransformers:transformers error:NULL];
}

- (void)tearDown {
    recipe = nil;
    transformers = nil;
    mapping = nil;
    name = nil;
    
    [super tearDown];
}

- (void)testInit {
    NSError *error;
    recipe = [[ZCREasyRecipe alloc] initWithName:name ingredientMapping:mapping
                          ingredientTransformers:transformers error:&error];
    
    XCTAssertNotNil(recipe, @"The recipe should be initialized");
    XCTAssertNil(error, @"There should be no error");
    
    XCTAssertEqualObjects(recipe.name, name, @"The names should match");
    XCTAssertEqualObjects(recipe.ingredientMapping, mapping, @"The ingredient mapping should match.");
    
    NSDictionary *normalizedTransformers = @{@"key1": [NSValueTransformer valueTransformerForName:@"ZCRReversibleTransformer"],
                                             @"key2": transformers[@"key2"]};
    XCTAssertEqualObjects(recipe.ingredientTransformers, normalizedTransformers, @"The ingredient transformers should be normalized.");
}

- (void)testInitWithMaker {
    __block BOOL validates = NO;
    __block NSError *error;
    ZCREasyRecipe *madeRecipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        recipeMaker.name = name;
        recipeMaker.ingredientMapping = mapping;
        recipeMaker.ingredientTransformers = transformers;
        
        validates = [recipeMaker validateRecipe:&error];
    }];
    
    XCTAssertNotNil(madeRecipe, @"The recipe should be made");
    XCTAssertTrue(validates, @"The recipe should validate");
    XCTAssertNil(error, @"There should be no errors");
    
    XCTAssertEqualObjects(recipe, madeRecipe, @"The made recipe should be the same as the designated initializer recipe.");
}

- (void)testIngredientMappingComponents
{
    NSArray *components = recipe.ingredientMappingComponents[@"key3"];
    NSArray *expectedComponents = @[@"key_3", @0];
    XCTAssertEqualObjects(components, expectedComponents, @"The components should be properly broken down.");
}

- (void)testPropertyNames {
    NSSet *expectedNames = [NSSet setWithArray:[mapping allKeys]];
    XCTAssertEqualObjects(recipe.propertyNames, expectedNames, @"The property names should be made from the mapping.");
}

- (void)testModifyWith {
    ZCREasyRecipe *modifiedRecipe = [recipe modifyWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker removeInstructionForProperty:@"key2" error:NULL];
        [recipeMaker addInstructionForProperty:@"key4" ingredientPath:@"key_4"
                                   transformer:nil error:NULL];
    }];
    
    XCTAssertEqualObjects(modifiedRecipe.name, recipe.name, @"The name should remain the same");
    
    NSDictionary *expectedMapping = @{@"key1": @"key_1",
                                      @"key3": @"key_3[0]",
                                      @"key4": @"key_4"};
    XCTAssertEqualObjects(modifiedRecipe.ingredientMapping, expectedMapping, @"The ingredient mapping should be modified");
    
    NSDictionary *expectedTransformers = @{@"key1": [NSValueTransformer valueTransformerForName:@"ZCRReversibleTransformer"]};
    XCTAssertEqualObjects(modifiedRecipe.ingredientTransformers, expectedTransformers, @"The ingredient transformers should be modified");
}

- (void)testProcessIngredients {
    NSDictionary *ingredients = @{@"key_1": @"test1",
                                  @"key_3": @[@"test2", @"test3"]};
    NSError *error;
    NSDictionary *processedIngredients = [recipe processIngredients:ingredients error:&error];
    
    NSDictionary *expectedIngredients = @{@"key1": @"TEST1",
                                          @"key3": @"test2"};
    XCTAssertEqualObjects(expectedIngredients, processedIngredients, @"The ingredients should be processed by the recipe");
    XCTAssertNil(error, @"There should be no error.");
}


#pragma mark - Error tests

- (void)testMissingMapping {
    NSError *error;
    recipe = [[ZCREasyRecipe alloc] initWithName:nil ingredientMapping:nil ingredientTransformers:nil error:&error];
    XCTAssertNil(recipe, @"The recipe should be nil.");
    XCTAssertNotNil(error, @"The error should be returned.");
}

- (void)testInvalidMapping {
    NSDictionary *invalidMapping = @{@"key1": @"key_1[]"};
    NSError *error;
    recipe = [[ZCREasyRecipe alloc] initWithName:nil ingredientMapping:invalidMapping ingredientTransformers:nil error:&error];
    XCTAssertNil(recipe, @"The recipe should be nil.");
    XCTAssertNotNil(error, @"The error should be returned.");
}

- (void)testInconsistentRootMapping {
    NSDictionary *invalidMapping = @{@"key1": @"key_1",
                                     @"key2": @"[2]"};
    NSError *error;
    recipe = [[ZCREasyRecipe alloc] initWithName:nil ingredientMapping:invalidMapping ingredientTransformers:nil error:&error];
    XCTAssertNil(recipe, @"The recipe should be nil.");
    XCTAssertNotNil(error, @"The error should be returned.");
}

- (void)testInconsistentMapping {
    NSDictionary *invalidMapping = @{@"key1": @"key[1]",
                                     @"key2": @"key.second"};
    NSError *error;
    recipe = [[ZCREasyRecipe alloc] initWithName:nil ingredientMapping:invalidMapping ingredientTransformers:nil error:&error];
    XCTAssertNil(recipe, @"The recipe should be nil.");
    XCTAssertNotNil(error, @"The error should be returned.");
}

- (void)testUnknownTransformerKey {
    NSDictionary *invalidTransformer = @{@"unknownKey": [ZCROneWayTransformer new]};
    NSError *error;
    recipe = [[ZCREasyRecipe alloc] initWithName:nil ingredientMapping:mapping ingredientTransformers:invalidTransformer error:&error];
    XCTAssertNil(recipe, @"The recipe should be nil.");
    XCTAssertNotNil(error, @"The error should be returned.");
}

- (void)testUnregisteredTransformer {
    NSDictionary *invalidTransformer = @{@"key1": @"UnknownTransformer"};
    NSError *error;
    recipe = [[ZCREasyRecipe alloc] initWithName:nil ingredientMapping:mapping ingredientTransformers:invalidTransformer error:&error];
    XCTAssertNil(recipe, @"The recipe should be nil.");
    XCTAssertNotNil(error, @"The error should be returned.");
}

- (void)testInvalidTransformer {
    NSDictionary *invalidTransformer = @{@"key1": [NSNull null]};
    NSError *error;
    recipe = [[ZCREasyRecipe alloc] initWithName:nil ingredientMapping:mapping ingredientTransformers:invalidTransformer error:&error];
    XCTAssertNil(recipe, @"The recipe should be nil.");
    XCTAssertNotNil(error, @"The error should be returned.");
}

@end
