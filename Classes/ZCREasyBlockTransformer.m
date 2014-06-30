//
//  ZCREasyBlockTransformer.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 6/26/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import "ZCREasyBlockTransformer.h"

@interface _ZCREasyOneWayTransformer : ZCREasyBlockTransformer
- (instancetype)initWithForwardBlock:(id (^)(id value))forwardBlock;
@end

@interface _ZCREasyReversibleTransformer : ZCREasyBlockTransformer
- (instancetype)initWithForwardBlock:(id (^)(id value))forwardBlock reverseBlock:(id (^)(id value))reverseBlock;
@end

@implementation ZCREasyBlockTransformer

+ (instancetype)oneWayTransformerWithForwardBlock:(id (^)(id))forwardBlock {
    return [[_ZCREasyOneWayTransformer alloc] initWithForwardBlock:forwardBlock];
}

+ (instancetype)reversibleTransformerWithForwardBlock:(id (^)(id))forwardBlock reverseBlock:(id (^)(id))reverseBlock {
    return [[_ZCREasyReversibleTransformer alloc] initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

+ (Class)transformedValueClass {
    return [NSObject class];
}

- (instancetype)initPrivate {
    self = [super init];
    return self;
}

- (instancetype)init {
    [NSException raise:NSInternalInconsistencyException format:@"This method is unavailable. Please use the provided class methods instead."];
    return nil;
}

@end


@implementation _ZCREasyOneWayTransformer {
    id (^_forwardBlock)(id);
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (instancetype)initWithForwardBlock:(id (^)(id))forwardBlock {
    NSParameterAssert(forwardBlock);
    if (!(self = [super initPrivate])) { return nil; }
    
    _forwardBlock = [forwardBlock copy];
    
    return self;
}

- (id)transformedValue:(id)value {
    return _forwardBlock(value);
}

@end


@implementation _ZCREasyReversibleTransformer {
    id (^_forwardBlock)(id);
    id (^_reverseBlock)(id);
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (instancetype)initWithForwardBlock:(id (^)(id))forwardBlock reverseBlock:(id (^)(id))reverseBlock {
    NSParameterAssert(forwardBlock);
    
    if (!(self = [super initPrivate])) { return nil; }
    
    _forwardBlock = [forwardBlock copy];
    _reverseBlock = [reverseBlock copy];
    
    return self;
}

- (id)transformedValue:(id)value {
    return _forwardBlock(value);
}

- (id)reverseTransformedValue:(id)value {
    if (_reverseBlock) {
        return _reverseBlock(value);
    } else {
        return _forwardBlock(value);
    }
}

@end
