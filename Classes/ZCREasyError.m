//
//  ZCREasyError.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/24/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import "ZCREasyError.h"

NSString *const ZCREasyBakeErrorDomain = @"com.zachradke.easyBake.errorDomain";

NSString *const ZCREasyBakeExceptionNameKey = @"ZCREasyBakeExceptionNameKey";
NSString *const ZCREasyBakeExceptionUserInfoKey = @"ZCREasyBakeExceptionUserInfoKey";


NSString *ZCREasyBakeErrorDescriptionForCode(NSInteger errorCode) {
    switch (errorCode) {
        case ZCREasyBakeExceptionRaisedError:
            return @"Unexpected exception raised.";
        case ZCREasyBakeInvalidRecipeError:
            return @"Invalid recipe.";
        case ZCREasyBakeInvalidIdentifierError:
            return @"Invalid unique identifier.";
        case ZCREasyBakeInvalidIngredientsError:
            return @"Invalid raw ingredients.";
        case ZCREasyBakeInvalidMappingError:
            return @"Invalid ingredient mapping.";
        case ZCREasyBakeInvalidIngredientPathError:
            return @"Invalid ingredient path.";
        case ZCREasyBakeInvalidTransformerError:
            return @"Invalid ingredient transformer.";
        case ZCREasyBakeUnknownRecipeError:
            return @"Unknown recipe.";
        case ZCREasyBakeInvalidModelError:
            return @"Invalid model.";
        default:
            return nil;
    }
}

NSError *ZCREasyBakeError(NSInteger errorCode, NSString *failureReason, ...) {
    NSCParameterAssert(failureReason);
    
    NSString *description = ZCREasyBakeErrorDescriptionForCode(errorCode);
    NSCAssert(description, @"Unknown error code (%ld).", (long)errorCode);
    
    va_list arguments;
    va_start(arguments, failureReason);
    failureReason = [[NSString alloc] initWithFormat:failureReason arguments:arguments];
    va_end(arguments);
    
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description,
                               NSLocalizedFailureReasonErrorKey: failureReason};
    
    return [NSError errorWithDomain:ZCREasyBakeErrorDomain code:errorCode userInfo:userInfo];
}

NSError *ZCREasyBakeExceptionError(NSException *exception) {
    NSCParameterAssert(exception);
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = ZCREasyBakeErrorDescriptionForCode(ZCREasyBakeExceptionRaisedError);
    userInfo[NSLocalizedFailureReasonErrorKey] = exception.reason ?: @"An unexpected exception was raised.";
    if (exception.name) {
        userInfo[ZCREasyBakeExceptionNameKey] = exception.name;
    }
    if (exception.userInfo) {
        userInfo[ZCREasyBakeExceptionUserInfoKey] = exception.userInfo;
    }
    
    return [NSError errorWithDomain:ZCREasyBakeErrorDomain code:ZCREasyBakeExceptionRaisedError userInfo:userInfo];
}
