//
//  ZCREasyProperty.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/9/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import "ZCREasyProperty.h"

static inline NSString *_ZCRStringForPropertyAttribute(ZCREasyPropertyAttribute attribute) {
    switch (attribute) {
        case ZCREasyPropertyAttrType:
            return @"T";
        case ZCREasyPropertyAttrIVarName:
            return @"V";
        case ZCREasyPropertyAttrReadOnly:
            return @"R";
        case ZCREasyPropertyAttrCopy:
            return @"C";
        case ZCREasyPropertyAttrRetain:
            return @"&";
        case ZCREasyPropertyAttrNonAtomic:
            return @"N";
        case ZCREasyPropertyAttrCustomGetter:
            return @"G";
        case ZCREasyPropertyAttrCustomSetter:
            return @"S";
        case ZCREasyPropertyAttrDynamic:
            return @"D";
        case ZCREasyPropertyAttrWeak:
            return @"W";
        case ZCREasyPropertyAttrGarbageCollectable:
            return @"P";
        case ZCREasyPropertyAttrOldTypeEncoding:
            return @"t";
        default:
            return nil;
    }
}


@implementation ZCREasyProperty {
    NSString *_attributeString;
}

- (instancetype)initWithProperty:(objc_property_t)property {
    NSParameterAssert(property);
    
    if (!(self = [super init])) { return nil; }
    
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
    NSAssert(NO, @"This class cannot be initialized with this method. "
                 @"Please use the designated initializer (%@) instead.",
                 NSStringFromSelector(@selector(initWithProperty:)));
    return nil;
}

- (BOOL)hasAttribute:(ZCREasyPropertyAttribute)attribute {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@",
                              _ZCRStringForPropertyAttribute(attribute)];
    return ([[_attributes filteredSetUsingPredicate:predicate] count] > 0);
}

- (NSString *)_contextStringForAttribute:(ZCREasyPropertyAttribute)attribute {
    NSString *attributeIdentifier = _ZCRStringForPropertyAttribute(attribute);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", attributeIdentifier];
    NSString *fullAttribute = [[_attributes filteredSetUsingPredicate:predicate] anyObject];
    return [fullAttribute substringFromIndex:attributeIdentifier.length];
}

- (Class)_parseTypeClassFromString:(NSString *)typeString {
    if (typeString.length == 0) { return NULL; }
    
    NSString *typeClassName = nil;
    NSScanner *scanner = [NSScanner scannerWithString:typeString];
    
    // Objects with no protocol and a class appear as: @"ClassName"
    // Objects with a protocol and class appear as: @"ClassName<ProtocolName>"
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
    BOOL equalAttributes = (!_attributeString && !other->_attributeString) ||
                           [_attributeString isEqualToString:other->_attributeString];
    
    return equalNames && equalAttributes;
}

- (NSUInteger)hash {
    return [self.name hash] ^ [_attributeString hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:%p> name:%@ attributes:%@",
            NSStringFromClass([self class]), self, _name, _attributeString];
}

+ (NSSet *)propertiesForClass:(Class)aClass {
    NSParameterAssert(aClass);
    
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
