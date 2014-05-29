//
//  ZCREasyProperty.h
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/9/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/**
 *  Enumeration of possible attributes a property may have.
 *
 *  @see [ZCREasyProperty hasAttribute:]
 */
typedef NS_ENUM(NSInteger, ZCREasyPropertyAttribute) {
    /**
     *  The type encoding attribute. This is always present.
     */
    ZCREasyPropertyAttrType = 0,
    /**
     *  The backing iVar name attribute.
     */
    ZCREasyPropertyAttrIVarName,
    /**
     *  Attribute indicating if the property is read-only.
     */
    ZCREasyPropertyAttrReadOnly,
    /**
     *  Attribute indicating if the property copies.
     */
    ZCREasyPropertyAttrCopy,
    /**
     *  Attribute indicating if the property retains.
     */
    ZCREasyPropertyAttrRetain,
    /**
     *  Attribute indicating if the property is non-atomic.
     */
    ZCREasyPropertyAttrNonAtomic,
    /**
     *  Attribute present if the property has a custom getter selector.
     */
    ZCREasyPropertyAttrCustomGetter,
    /**
     *  Attribute present if the property has a custom setter selector.
     */
    ZCREasyPropertyAttrCustomSetter,
    /**
     *  Attribute indicating if the property is dynamic.
     */
    ZCREasyPropertyAttrDynamic,
    /**
     *  Attribute indicating if the property is weak.
     */
    ZCREasyPropertyAttrWeak,
    /**
     *  Attribute indicating if the property is garbage-collectable.
     */
    ZCREasyPropertyAttrGarbageCollectable,
    /**
     *  Deprecated attribute for the old type encoding.
     */
    ZCREasyPropertyAttrOldTypeEncoding
};

/**
 *  Object oriented interface for dealing with property introspection!
 *
 *  Instances initialized with an objc_property_t will parse out information about the property for
 *  future acccess. The objc_property_t is *not* retained by this class, and it is the job of the
 *  class which passes the property to free it. Some of the more commonly queried attributes are
 *  exposed as read-only properties on the ZCREasyProperty class, and are cached for fast access.
 *  For querying other properties, the hasAttribute: method can be used passing one of the attribute
 *  constants. For a list of the attribute constants, see the header of this class.
 */
@interface ZCREasyProperty : NSObject <NSCopying>

/**
 *  Creates a new instance representing the passed property. This is the designated initializer
 *  for this class.
 *
 *  @param property The property to gather information on. This must not be nil, or an exception
 *                  will be thrown.
 *
 *  @return A populated instance of the receiver.
 */
- (instancetype)initWithProperty:(objc_property_t)property __attribute__((nonnull));

/**
 *  The name of the property. If a valid property was passed during creation, this is guaranteed
 *  to be present.
 */
@property (strong, nonatomic, readonly) NSString *name;

/**
 *  The type string of the property, which can be used to determine the property's type. If a valid
 *  property is passed during creation, this is guaranteed to be present.
 */
@property (strong, nonatomic, readonly) NSString *type;

/**
 *  The attributes of the property parsed into a set. If a valid property is passed during creation,
 *  this is guaranteed to be present.
 */
@property (strong, nonatomic, readonly) NSSet *attributes;

/**
 *  The name of the raw iVar backing the property, if present.
 */
@property (strong, nonatomic, readonly) NSString *iVarName;

/**
 *  Returns YES if the property is read-only, or NO if it is not.
 */
@property (assign, nonatomic, readonly) BOOL isReadOnly;

/**
 *  Returns YES if the property is weakly retained, or NO if it is not.
 */
@property (assign, nonatomic, readonly) BOOL isWeak;

/**
 *  Returns YES if the property represents an object, or NO if it represents a primitive type.
 */
@property (assign, nonatomic, readonly) BOOL isObject;

/**
 *  The parsed class of object properties. This will return NULL for primitive types or if the type
 *  is id or could not be parsed. Thus to check if a property represents an object, the isObject
 *  flag should be referenced instead.
 *
 *  @see isObject
 */
@property (assign, nonatomic, readonly) Class typeClass;

/**
 *  The parsed custom getter for the property, if present.
 */
@property (assign, nonatomic, readonly) SEL customGetter;

/**
 *  The parsed custom setter for the property, if present.
 */
@property (assign, nonatomic, readonly) SEL customSetter;

/**
 *  Queries the cached property attributes to see if the passed attribute exists.
 *
 *  @param attribute The attribute to query.
 *
 *  @return YES if the attribute is present in the property, NO if it is not.
 */
- (BOOL)hasAttribute:(ZCREasyPropertyAttribute)attribute;

/**
 *  Composes a set of properties for a given class. Only properties explicitly defined in the class
 *  are included, not those inherited from subclasses.
 *
 *  @param aClass The class to introspect.
 *
 *  @return A set of properties defined in the given class.
 */
+ (NSSet *)propertiesForClass:(Class)aClass __attribute__((nonnull));

@end
