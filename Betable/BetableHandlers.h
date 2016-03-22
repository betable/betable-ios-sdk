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

// Game pust provide an implementation of this to betable to facilitate proper game event interactions
@protocol BetableGameCallbacks<NSObject>

// Betable needs up-to-date insight to current view controller is should game be backgrounded and foregrounded
- (UIViewController*) currentGameView;

// Game is notified betable has API access, and SDK calls can be made
-(void) onAccessSuccess:(NSString*) accessToken;

// Game is notified betable does NOT have API access, and SDK calls (aside from further attempots to get an access token) should not be made
// until game recieves a call to onAccessTokenComplete
-(void) onAccessFailure;

// Game is given an opportunity for housekeeping prior to handing control to betable
- (void) onGameBackgrounded;

// Game is given an opportunity for housekeeping prior to handing control from betable back to game
- (void) onGameForegrounded;
@end
