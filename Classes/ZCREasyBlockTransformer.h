//
//  ZCREasyBlockTransformer.h
//  ZCREasyBake
//
//  Created by Zachary Radke on 6/26/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Class for creating block-based value transformers. This class functions as a class cluster and
 *  instances should not be created outside of the explicitly provided class constructors. Because
 *  the class of the returned value is unknown, the transformedValueClass method returns a generic
 *  NSObject, though that may be inaccurate at runtime.
 */
@interface ZCREasyBlockTransformer : NSValueTransformer

/**
 *  Creates a one-way transformer which uses the given block to transform values. Value transformers
 *  created using this method will return NO for allowsReverseTransformation.
 *
 *  @param forwardBlock The block to transform values with. The block is passed the raw value and
 *                      must return a transformed value. This must not be nil.
 *
 *  @return A new one-way transformer configured with the given block.
 */
+ (instancetype)oneWayTransformerWithForwardBlock:(id (^)(id value))forwardBlock __attribute__((nonnull));

/**
 *  Creates a reversible transformer which uses the given blocks to transform values. Value
 *  transformers created using this method will return YES for allowsReverseTransformation. If both
 *  a forward and reverse block are provided, the forward block will be used for regular calls to
 *  transformedValue: and the reverse block will be used for calls to reverseTransformedValue:. If
 *  only a forward block is provided, it will be used for both.
 *
 *  @param forwardBlock The block to transform values with. This block is passed the raw value and
 *                      must return a transformed value. This must not be nil.
 *  @param reverseBlock The block to reverse transform values with. This block is passed a raw value
 *                      and must return a transformed value.
 *
 *  @return A new reversible transformer configured with the given blocks.
 */
+ (instancetype)reversibleTransformerWithForwardBlock:(id (^)(id value))forwardBlock
                                         reverseBlock:(id (^)(id value))reverseBlock __attribute__((nonnull (1)));

- (instancetype)init __unavailable;

@end
