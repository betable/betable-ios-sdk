//
//  BetableHandlers.h
//  Betable.framework
//
//  Created by Tony hauber on 7/11/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//
#import <Betable/BetableCredentials.h>

typedef void (^ BetableAccessTokenHandler)(NSString* accessToken);
typedef void (^ BetableCompletionHandler)(NSDictionary* data);
typedef void (^ BetableFailureHandler)(NSURLResponse* response, NSString* responseBody, NSError* error);
typedef void (^ BetableCancelHandler)();
typedef void (^ BetableLogoutHandler)();

// Game pust provide an implementation of this to betable to facilitate proper game event interactions
@protocol BetableCredentialCallbacks<NSObject>

@optional
// Game is notified player has API credentials, and SDK calls can be made to Betable
- (void)onCredentialsSuccess:(BetableCredentials*)credentials;

// Game is notified player has lost API credentials, and ceratain SDK calls should not be made
// until game recieves another call to checkCredentails
- (void)onCredentialsRevoked;

// Game is notified betable was not able to get API credentials, and ceratain SDK calls should not be made
// until game recieves another call to checkCredentails
- (void)onCredentialsFailure;

// Game is given an opportunity for housekeeping prior to handing control to betable when reality checks engage
- (void)onPreRealityCheck;

// Game is given an opportunity for housekeeping prior to handing control from betable back to game after reality checks have finished
- (void)onPostRealityCheck;
@end
