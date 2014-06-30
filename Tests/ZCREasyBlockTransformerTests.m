//
//  ZCREasyBlockTransformerTests.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 6/30/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZCREasyBlockTransformer.h"

@interface ZCREasyBlockTransformerTests : XCTestCase

@end

@implementation ZCREasyBlockTransformerTests

- (void)testOneWayTransformer {
    ZCREasyBlockTransformer *transformer = [ZCREasyBlockTransformer oneWayTransformerWithForwardBlock:^id(id value) {
        return [value uppercaseString];
    }];
    
    XCTAssertFalse([[transformer class] allowsReverseTransformation], @"The transformer should not allow reverse transformations.");
    XCTAssertEqualObjects([transformer transformedValue:@"test-string"], @"TEST-STRING", @"The value should be transformed.");
}

- (void)testReversibleTransformerWithTwoBlocks {
    ZCREasyBlockTransformer *transformer = [ZCREasyBlockTransformer reversibleTransformerWithForwardBlock:^id(id value) {
        return [NSURL URLWithString:value];
    } reverseBlock:^id(id value) {
        return [value absoluteString];
    }];
    
    XCTAssertTrue([[transformer class] allowsReverseTransformation], @"The transformer should allow reverse transformations.");
    
    NSString *rawValue = @"http://www.google.com";
    XCTAssertEqualObjects([transformer transformedValue:rawValue], [NSURL URLWithString:rawValue], @"The value should be transformed.");
    XCTAssertEqualObjects([transformer reverseTransformedValue:[transformer transformedValue:rawValue]], rawValue, @"The value should be reversed.");
}

- (void)testReversibleTransformerWithOneBlock {
    ZCREasyBlockTransformer *transformer = [ZCREasyBlockTransformer reversibleTransformerWithForwardBlock:^id(id value) {
        return @(![value boolValue]);
    } reverseBlock:nil];
    
    XCTAssertTrue([[transformer class] allowsReverseTransformation], @"The transformer should allow reverse transformations.");
    XCTAssertEqualObjects(@YES, [transformer transformedValue:@NO], @"The value should be transformed.");
    XCTAssertEqualObjects(@NO, [transformer reverseTransformedValue:@YES], @"The value should be reversed.");
}

@end
