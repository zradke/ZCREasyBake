//
//  ZCREasyError.m
//  ZCREasyBake
//
//  Created by Zachary Radke on 4/24/14.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import "ZCREasyError.h"

NSString *const ZCREasyBakeErrorDomain = @"com.zachradke.easyBake.errorDomain";

NSInteger const ZCREasyBakeErrorInvalidParameters = 1969;
NSInteger const ZCREasyBakeErrorExceptionRaised = 1970;

NSString *const ZCREasyBakeExceptionNameKey = @"ZCREasyBakeExceptionNameKey";
NSString *const ZCREasyBakeExceptionUserInfoKey = @"ZCREasyBakeExceptionUserInfoKey";

NSError *ZCREasyBakeParameterError(NSString *failureReason, ...) {
    NSCAssert(failureReason != nil, @"An error failure reason is required.");
    
    va_list arguments;
    va_start(arguments, failureReason);
    failureReason = [[NSString alloc] initWithFormat:failureReason arguments:arguments];
    va_end(arguments);
    
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Invalid parameters.",
                               NSLocalizedFailureReasonErrorKey: failureReason};
    
    return [NSError errorWithDomain:ZCREasyBakeErrorDomain
                               code:ZCREasyBakeErrorInvalidParameters
                           userInfo:userInfo];
}

NSError *ZCREasyBakeExceptionError(NSException *exception) {
    NSCAssert(exception != nil, @"An exception is required.");
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = @"Exception raised.";
    userInfo[NSLocalizedFailureReasonErrorKey] = exception.reason ?: @"An unexpected exception was raised.";
    if (exception.name) {
        userInfo[ZCREasyBakeExceptionNameKey] = exception.name;
    }
    if (exception.userInfo) {
        userInfo[ZCREasyBakeExceptionUserInfoKey] = exception.userInfo;
    }
    
    return [NSError errorWithDomain:ZCREasyBakeErrorDomain
                               code:ZCREasyBakeErrorExceptionRaised
                           userInfo:userInfo];
}
