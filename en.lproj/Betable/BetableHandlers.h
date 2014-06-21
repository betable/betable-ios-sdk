//
//  BetableHandlers.h
//  Betable.framework
//
//  Created by Tony hauber on 7/11/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

typedef void (^BetableAccessTokenHandler)(NSString *accessToken);
typedef void (^BetableCompletionHandler)(NSDictionary *data);
typedef void (^BetableFailureHandler)(NSURLResponse *response, NSString *responseBody, NSError *error);
typedef void (^BetableCancelHandler)();