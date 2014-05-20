//
//  ZCREasyDoughTransformerTests.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 5/14/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ZCREasyBake.h"

@interface _ZCREasyDoughTransformerModel : ZCREasyDough
@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSURL *link;
@end

@implementation _ZCREasyDoughTransformerModel
@end

@interface _ZCRURLTransformer : NSValueTransformer
@end

@implementation _ZCRURLTransformer

+ (BOOL)allowsReverseTransformation {
    return YES;
}

+ (Class)transformedValueClass {
    return [NSURL class];
}

- (id)transformedValue:(id)value {
    return [NSURL URLWithString:value];
}

- (id)reverseTransformedValue:(id)value {
    return [value absoluteString];
}

@end

@interface ZCREasyDoughTransformerTests : XCTestCase {
    NSDictionary *ingredients;
    ZCREasyRecipe *recipe;
    ZCREasyDoughTransformer *transformer;
}
@end

@implementation ZCREasyDoughTransformerTests

- (void)setUp {
    [super setUp];
    
    ingredients = @{@"id": @"test-id",
                    @"name": @"Test Name",
                    @"link": @"http://www.google.com"};
    recipe = [ZCREasyRecipe makeWith:^(id<ZCREasyRecipeMaker> recipeMaker) {
        [recipeMaker addInstructionForProperty:@"name" ingredientPath:@"name" transformer:nil error:nil];
        [recipeMaker addInstructionForProperty:@"link" ingredientPath:@"link" transformer:[_ZCRURLTransformer new] error:nil];
    }];
    transformer = [[ZCREasyDoughTransformer alloc] initWithDoughClass:[_ZCREasyDoughTransformerModel class] recipe:recipe identifierBlock:^id<NSObject,NSCopying>(id rawIngredients) {
        return rawIngredients[@"id"];
    }];
}

- (void)tearDown {
    transformer = nil;
    recipe = nil;
    ingredients = nil;
    
    [super tearDown];
}

- (void)testTransformedValue {
    _ZCREasyDoughTransformerModel *model = [transformer transformedValue:ingredients];
    XCTAssertNotNil(model, @"The model should be created.");
    XCTAssertNil(transformer.error, @"The error should be nil.");
    
    XCTAssertEqualObjects(model.name, ingredients[@"name"], @"The name should be set.");
    XCTAssertEqualObjects(model.link, [NSURL URLWithString:ingredients[@"link"]], @"The link should be set.");
}

- (void)testReverseTransformedValue {
    _ZCREasyDoughTransformerModel *model = [transformer transformedValue:ingredients];
    NSDictionary *madeIngredients = [transformer reverseTransformedValue:model];
    XCTAssertNotNil(madeIngredients, @"The ingredients should be created.");
    XCTAssertNil(transformer.error, @"The error should be nil.");
    
    XCTAssertEqualObjects(madeIngredients[@"name"], ingredients[@"name"], @"The names should match.");
    XCTAssertEqualObjects(madeIngredients[@"link"], ingredients[@"link"], @"The links should match.");
}

- (void)testTransformedIdentifier {
    _ZCREasyDoughTransformerModel *model = [transformer transformedValue:ingredients];
    _ZCREasyDoughTransformerModel *otherModel = [transformer transformedValue:@{@"id": @"test-id"}];
    
    XCTAssertEqualObjects(model, otherModel, @"The models should share the same identifier.");
}

- (void)testTransformerWithoutIdentifierBlock {
    transformer = [[ZCREasyDoughTransformer alloc] initWithDoughClass:[_ZCREasyDoughTransformerModel class] recipe:recipe identifierBlock:nil];
    _ZCREasyDoughTransformerModel *model = [transformer transformedValue:ingredients];
    XCTAssertNotNil(model, @"The model should be set.");
    XCTAssertNil(transformer.error, @"There should be no error.");
    
    _ZCREasyDoughTransformerModel *otherModel = [transformer transformedValue:ingredients];
    XCTAssertNotEqualObjects(model, otherModel, @"The models should always be unique.");
}

- (void)testTransformerWithInvalidIdentiiferBlock {
    transformer = [[ZCREasyDoughTransformer alloc] initWithDoughClass:[_ZCREasyDoughTransformerModel class] recipe:recipe identifierBlock:^id<NSObject,NSCopying>(id rawIngredients) {
        return nil;
    }];
    _ZCREasyDoughTransformerModel *model = [transformer transformedValue:ingredients];
    XCTAssertNil(model, @"There should be no model serialized.");
    XCTAssertNotNil(transformer.error, @"There should be an error without an identifier.");
}

@end
