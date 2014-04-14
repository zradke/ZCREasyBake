//
//  ZCREasyProperty.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/9/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import "ZCREasyProperty.h"

NSString *const ZCREasyPropertyAttrType = @"T";
NSString *const ZCREasyPropertyAttrIVarName = @"V";
NSString *const ZCREasyPropertyAttrReadOnly = @"R";
NSString *const ZCREasyPropertyAttrCopy = @"C";
NSString *const ZCREasyPropertyAttrRetain = @"&";
NSString *const ZCREasyPropertyAttrNonAtomic = @"N";
NSString *const ZCREasyPropertyAttrCustomGetter = @"G";
NSString *const ZCREasyPropertyAttrCustomSetter = @"S";
NSString *const ZCREasyPropertyAttrDynamic = @"D";
NSString *const ZCREasyPropertyAttrWeak = @"W";
NSString *const ZCREasyPropertyAttrGarbageCollectable = @"P";
NSString *const ZCREasyPropertyAttrOldTypeEncoding = @"t";

@implementation ZCREasyProperty {
    NSString *_attributeString;
}

- (instancetype)initWithProperty:(objc_property_t)property {
    if (!(self = [super init])) { return nil; }
    if (!property) { return self; }
    
    _name = [NSString stringWithUTF8String:property_getName(property)];
    
    _attributeString = [NSString stringWithUTF8String:property_getAttributes(property)];
    _attributes = [NSSet setWithArray:[_attributeString componentsSeparatedByString:@","]];
    
    _type = [self _contextStringForAttribute:ZCREasyPropertyAttrType];
    _iVarName = [self _contextStringForAttribute:ZCREasyPropertyAttrIVarName];
    
    _isReadOnly = [self hasAttribute:ZCREasyPropertyAttrReadOnly];
    _isWeak = [self hasAttribute:ZCREasyPropertyAttrWeak];
    _isObject = [_type hasPrefix:@"@"];
    
    if (_isObject) {
        _typeClass = [self _parseTypeClassFromString:_type];
    }
    
    NSString *customGetterString = [self _contextStringForAttribute:ZCREasyPropertyAttrCustomGetter];
    if (customGetterString.length > 0) {
        _customGetter = NSSelectorFromString(customGetterString);
    }
    
    NSString *customSetterString = [self _contextStringForAttribute:ZCREasyPropertyAttrCustomSetter];
    if (customSetterString.length > 0) {
        _customSetter = NSSelectorFromString(customSetterString);
    }
    
    return self;
}

- (instancetype)init {
    return [self initWithProperty:NULL];
}

- (BOOL)hasAttribute:(NSString *)attribute {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", attribute];
    return ([[_attributes filteredSetUsingPredicate:predicate] count] > 0);
}

- (NSString *)_contextStringForAttribute:(NSString *)attribute {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", attribute];
    NSString *fullAttribute = [[_attributes filteredSetUsingPredicate:predicate] anyObject];
    return [fullAttribute substringFromIndex:attribute.length];
}

- (Class)_parseTypeClassFromString:(NSString *)typeString {
    if (typeString.length == 0) { return NULL; }
    
    NSString *typeClassName = nil;
    NSScanner *scanner = [NSScanner scannerWithString:typeString];
    
    // Object type strings appear in the following format: @"ClassName<ProtocolName>"
    // In a delegate property, the type string is often: @"<DelegateName>"
    if (![scanner scanString:@"@\"" intoString:NULL]) { return NULL; }
    [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"<\""]
                            intoString:&typeClassName];
    
    return (typeClassName.length > 0) ? NSClassFromString(typeClassName) : NULL;
}

- (BOOL)isEqual:(id)object {
    if (self == object) { return YES; }
    if (![object isKindOfClass:[self class]]) { return NO; }
    
    ZCREasyProperty *other = object;
    BOOL equalNames = (!self.name && !other.name) || [self.name isEqualToString:other.name];
    BOOL equalAttributes = (!_attributeString && !other->_attributeString) || [_attributeString isEqualToString:other->_attributeString];
    
    return equalNames && equalAttributes;
}

- (NSUInteger)hash {
    return [self.name hash] ^ [self.attributes hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:%p> name:%@ attributes:%@", NSStringFromClass([self class]), self, _name, _attributeString];
}

+ (NSSet *)propertiesForClass:(Class)aClass {
    if (!aClass) { return nil; }
    
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(aClass, &propertyCount);
    
    NSMutableSet *mutableProperties = [NSMutableSet set];
    
    if (properties) {
        for (unsigned int i = 0; i < propertyCount; i++) {
            ZCREasyProperty *property = [[ZCREasyProperty alloc] initWithProperty:properties[i]];
            if (property) {
                [mutableProperties addObject:property];
            }
        }
        
        free(properties);
    }
    
    return [mutableProperties copy];
}

@end
