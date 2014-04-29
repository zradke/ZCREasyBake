//
//  ZCREasyError.h
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/24/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Error domain for all ZCREasyBake generated errors.
 */
FOUNDATION_EXPORT NSString *const ZCREasyBakeErrorDomain;

/**
 *  Generic error when one of the required parameters for a method is either missing or invalid.
 */
FOUNDATION_EXPORT NSInteger const ZCREasyBakeErrorInvalidParameters;

/**
 *  Generic error when a method catches an unexpected exception.
 */
FOUNDATION_EXPORT NSInteger const ZCREasyBakeErrorExceptionRaised;

/**
 *  Key in a ZCREasyBakeErrorExceptionRaised error's userInfo for getting the exception's name.
 */
FOUNDATION_EXPORT NSString *const ZCREasyBakeExceptionNameKey;

/**
 *  Key in a ZCREasyBakeErrorExceptionRaised error's userInfo for getting the exception's user info.
 */
FOUNDATION_EXPORT NSString *const ZCREasyBakeExceptionUserInfoKey;

/**
 *  Function for generating ZCREasyBakeErrorInvalidParameters errors.
 *
 *  @param failureReason A detailed description of the invalid parameters. This can be a formatted
 *                       string. This must not be nil.
 *
 *  @return A parameter error configured for the ZCREasyBake error space.
 */
FOUNDATION_EXPORT NSError *ZCREasyBakeParameterError(NSString *failureReason, ...) NS_FORMAT_FUNCTION(1,2) __attribute__((nonnull (1)));

/**
 *  Function for generating ZCREasyBakeErrorExceptionRaised errors. The user info of the error may
 *  contain the ZCREasyBakeExceptionNameKey and ZCREasyBakeExceptionUserInfoKey for more context.
 *
 *  @param exception The exception that was raised and should be converted into an error. This must
 *                   not be nil.
 *
 *  @return An exception error configured for the ZCREasyBake error space.
 */
FOUNDATION_EXPORT NSError *ZCREasyBakeExceptionError(NSException *exception) __attribute__((nonnull));
