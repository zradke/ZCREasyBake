//
//  ZCREasyPropertyTests.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/11/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZCREasyProperty.h"

@interface ZCREasyPropertyTestsModel : NSObject

@property (copy, nonatomic, readonly) NSString *readOnlyProperty;
@property (strong, atomic) NSString *dynamicProperty;
@property (assign, nonatomic, getter = hasCustomGetter) BOOL customGetter;
@property (assign, nonatomic, setter = setCustom:) BOOL customSetter;
@property (weak, nonatomic) id<NSCopying> weakProperty;
@property (weak, nonatomic) NSString<NSCoding> *weakDefinedProperty;

@end

@implementation ZCREasyPropertyTestsModel
@dynamic dynamicProperty;
@end


@interface ZCREasyPropertyTests : XCTestCase {
    NSDictionary *propertiesByName;
}
@end

@implementation ZCREasyPropertyTests

- (void)setUp
{
    [super setUp];
    
    NSArray *properties = [[ZCREasyProperty propertiesForClass:[ZCREasyPropertyTestsModel class]] allObjects];
    propertiesByName = [NSDictionary dictionaryWithObjects:properties
                                                   forKeys:[properties valueForKey:NSStringFromSelector(@selector(name))]];
}

- (void)tearDown
{
    propertiesByName = nil;
    [super tearDown];
}

- (void)testPropertiesByName
{
    XCTAssertTrue(propertiesByName.count == 6, @"There should be six properties");
    
    NSSet *expectedNames = [NSSet setWithArray:@[@"readOnlyProperty",
                                                 @"dynamicProperty",
                                                 @"customGetter",
                                                 @"customSetter",
                                                 @"weakProperty",
                                                 @"weakDefinedProperty"]];
    NSSet *actualNames = [NSSet setWithArray:propertiesByName.allKeys];
    
    XCTAssertEqualObjects(expectedNames, actualNames, @"The defined property names should be used");
}

- (void)testName {
    ZCREasyProperty *property = propertiesByName[@"readOnlyProperty"];
    XCTAssertEqualObjects(property.name, @"readOnlyProperty", @"The name should be set");
}

- (void)testAttributes {
    ZCREasyProperty *property = propertiesByName[@"readOnlyProperty"];
    XCTAssertNotNil(property.attributes, @"The attributes should not be nil.");
}

- (void)testIVarNamePresent {
    ZCREasyProperty *property = propertiesByName[@"readOnlyProperty"];
    XCTAssertEqualObjects(property.iVarName, @"_readOnlyProperty", @"The iVar name should match");
}

- (void)testIVarNameMissing {
    ZCREasyProperty *property = propertiesByName[@"dynamicProperty"];
    XCTAssertNil(property.iVarName, @"The iVar name should be nil.");
}

- (void)testIsReadOnly {
    ZCREasyProperty *property = propertiesByName[@"readOnlyProperty"];
    XCTAssertTrue(property.isReadOnly, @"The property should be read-only");
}

- (void)testIsNotReadOnly {
    ZCREasyProperty *property = propertiesByName[@"dynamicProperty"];
    XCTAssertFalse(property.isReadOnly, @"The property should not be read-only");
}

- (void)testIsWeak {
    ZCREasyProperty *property = propertiesByName[@"weakProperty"];
    XCTAssertTrue(property.isWeak, @"The property should be weak");
}

- (void)testIsNotWeak {
    ZCREasyProperty *property = propertiesByName[@"readOnlyProperty"];
    XCTAssertFalse(property.isWeak, @"The property should not be weak");
}

- (void)testIsObject {
    ZCREasyProperty *property = propertiesByName[@"readOnlyProperty"];
    XCTAssertTrue(property.isObject, @"The property should be an object");
}

- (void)testIsNotObject {
    ZCREasyProperty *property = propertiesByName[@"customGetter"];
    XCTAssertFalse(property.isObject, @"The property should not be an object");
}

- (void)testTypeClass {
    ZCREasyProperty *property = propertiesByName[@"readOnlyProperty"];
    XCTAssertEqual(property.typeClass, [NSString class], @"The type class should be parsed");
}

- (void)testTypeClassWithProtocol {
    ZCREasyProperty *property = propertiesByName[@"weakDefinedProperty"];
    XCTAssertEqual(property.typeClass, [NSString class], @"The type class should be parsed");
}

- (void)testTypeClassPrimitive {
    ZCREasyProperty *property = propertiesByName[@"customGetter"];
    XCTAssertNil(property.typeClass, @"The type class should be NULL");
}

- (void)testTypeClassProtocolOnly {
    ZCREasyProperty *property = propertiesByName[@"weakProperty"];
    XCTAssertNil(property.typeClass, @"The type class should be NULL");
}

- (void)testCustomGetter {
    ZCREasyProperty *property = propertiesByName[@"customGetter"];
    XCTAssertEqual(property.customGetter, @selector(hasCustomGetter), @"The custom getter should be set");
}

- (void)testWithoutCustomGetter {
    ZCREasyProperty *property = propertiesByName[@"readOnlyProperty"];
    XCTAssertTrue(property.customGetter == NULL, @"The custom getter should be NULL");
}

- (void)testCustomSetter {
    ZCREasyProperty *property = propertiesByName[@"customSetter"];
    XCTAssertEqual(property.customSetter, @selector(setCustom:), @"The custom setter should be set");
}

- (void)testWithoutCustomSetter {
    ZCREasyProperty *property = propertiesByName[@"readOnlyProperty"];
    XCTAssertTrue(property.customSetter == NULL, @"The custom setter should be NULL");
}

- (void)testHasAttributeDynamic {
    ZCREasyProperty *property = propertiesByName[@"dynamicProperty"];
    XCTAssertTrue([property hasAttribute:ZCREasyPropertyAttrDynamic], @"The property should have the dynamic attribute");
}

@end
