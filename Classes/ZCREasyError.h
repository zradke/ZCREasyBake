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

enum {
    /**
     *  Error when an unexpected exception is raised.
     */
    ZCREasyBakeExceptionRaisedError = 1969,
    
    /**
     *  Error when an invalid recipe is provided.
     */
    ZCREasyBakeInvalidRecipeError = 1970,
    
    /**
     *  Error when an invalid identifier is provided.
     */
    ZCREasyBakeInvalidIdentifierError = 1971,
    
    /**
     *  Error when invalid raw ingredients are provided.
     */
    ZCREasyBakeInvalidIngredientsError = 1972,
    
    /**
     *  Error when a recipe's ingredient mapping is invalid.
     */
    ZCREasyBakeInvalidMappingError = 1973,
    
    /**
     *  Error when a specific ingredient path of a recipe's ingredient mapping is invalid.
     */
    ZCREasyBakeInvalidIngredientPathError = 1974,
    
    /**
     *  Error when a recipe's value transformer is invalid.
     */
    ZCREasyBakeInvalidTransformerError = 1975,
    
    /**
     *  Error when a requested recipe cannot be found.
     */
    ZCREasyBakeUnknownRecipeError = 1976,
    
    /**
     *  Error when an invalid model is provided.
     */
    ZCREasyBakeInvalidModelError = 1977
};

/**
 *  Key in a ZCREasyBakeErrorExceptionRaised error's userInfo for getting the exception's name.
 */
FOUNDATION_EXPORT NSString *const ZCREasyBakeExceptionNameKey;

/**
 *  Key in a ZCREasyBakeErrorExceptionRaised error's userInfo for getting the exception's user info.
 */
FOUNDATION_EXPORT NSString *const ZCREasyBakeExceptionUserInfoKey;


/**
 *  Function for getting error descriptions from ZCREasyBake error codes.
 *
 *  @param errorCode The error code to get a desciption of.
 *
 *  @return A string describing the error, or nil if the error code is unknown.
 */
FOUNDATION_EXPORT NSString *ZCREasyBakeErrorDescriptionForCode(NSInteger errorCode) __attribute__((const));

/**
 *  Function for generating errors with ZCREasyBake codes.
 *
 *  @param errorCode     The error code of the returned error. This must not be nil
 *  @param failureReason A detailed description of the error. This can be a formatted string. This
 *                       must not be nil.
 *
 *  @return A parameter error configured for the ZCREasyBake error space.
 */
FOUNDATION_EXPORT NSError *ZCREasyBakeError(NSInteger errorCode, NSString *failureReason, ...) NS_FORMAT_FUNCTION(2,3) __attribute__((nonnull (2)));

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
