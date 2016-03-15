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

// Game pust provide an implementation of interface to Betable to facilitate wallet features.
@interface BetableGameCallbacks
// Betable needs to know what the current view controller before game is backgrounded or foregrounded
- (UIViewController*) currentGameView;

// Game is given an opportunity for housekeeping prior to handing control to betable
- (void)onGameBackgrounded;

// Game is given an opportunity for housekeeping prior to handing control from betable back to game
- (void)onGameForegrounded;
@end
