//
//  Betable.h
//  
//  A wrapper for the Betable betting API that simplifies the OAuth and Rest calls
//
//  Created by Tony Hauber on 7/19/12.
//  Copyright (c) 2012 Betable. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^BetableAccessTokenHandler)(NSString *accessToken);
typedef void (^BetableCompletionHandler)(NSDictionary *data);
typedef void (^BetableFailureHandler)(NSURLResponse *response, NSString *responseBody, NSError *error);

@interface Betable : NSObject {
    NSString *clientID;
    NSString *clientSecret;
    NSString *redirectURI;
    NSString *accessToken;
    NSOperationQueue *queue;
}
- (Betable*)initWithClientID:(NSString*)clientID clientSecret:(NSString*)clientSecret redirectURI:(NSString*)redirectURI;

// This method is called when no access token exists for the current user. It
// will initiate the OAuth flow. It will bounce the user to the Safari app that
// is native on the device. After the person accept betable will redirect them
// to your redirect URI which can be registered here:
//
//     http://developers.betable.com
// 
// NOTE: The redirect id should have a protocol that opens your app. See this
// Reference for more info:
// 
//     http://developer.apple.com/library/ios/#documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/AdvancedAppTricks/AdvancedAppTricks.html#//apple_ref/doc/uid/TP40007072-CH7-SW50
// 
// It is suggested that your redirect protocol be "betable+<GAME_ID>"
//
// From your UIApplicationDelegate method application:handleOpenURL: you can
// handle the response.
- (void)authorize;

// Once you have your access code from the application:handleOpenURL: of your
// UIApplicationDelegate after betable redirects to your app uri you can pass
// the token in here with your handlers for successfully or unsuccessfully
// recieving an access token.
//
// NOTE: This is the final step of oauth.  In the onComplete handler you will
// recieve your access token for the user associated with this Betable object.
// You will want to store this with the user so you can make future calls on
// be half of said user.
- (void)token:(NSString*)code
        onComplete:(BetableAccessTokenHandler)onComplete
         onFailure:(BetableFailureHandler)onFailure;

// This method is used to place a bet for the user associated with this Betable
// object.
//
//      |gameID|: This is your gameID which is registered and can be checked at 
//          http://developers.betable.com
//      |data|: This is a dictionary that will converted to JSON and added
//          request as the body. It contains all the important information about
//          the bet being made. For documentation on the format of this
//          dictionary see https://developers.betable.com/docs/api/reference/
//      |onComplete|: This is a block that will be called if the server returns
//          the request with a successful response code. It will be passed a
//          dictionary that contains all of the JSON data returned from the
//          betable server.
//      |onFailure|: This is a block that will be called if the server returns
//          with an error. It gets passed the NSURLResponse object, the string
//          reresentation of the body, and the NSError that was raised.
//          betable server.
- (void)betForGame:(NSString*)gameID
          withData:(NSDictionary*)data
        onComplete:(BetableCompletionHandler)onComplete
         onFailure:(BetableFailureHandler)onFailure;

// This method is used to retrieve information about the account of the user
// associated with this betable object.
//
//      |onComplete|: This is a block that will be called if the server returns
//          the request with a successful response code. It will be passed a
//          dictionary that contains all of the JSON data returned from the
//          betable server.
//      |onFailure|: This is a block that will be called if the server returns
//          with an error. It gets passed the NSURLResponse object, the string
//          reresentation of the body, and the NSError that was raised.
//          betable server.
- (void)userAccountOnComplete:(BetableCompletionHandler)onComplete
                    onFailure:(BetableFailureHandler)onFailure;

// This method is used to retrieve information about the wallet of the user
// associated with this betable object.
//
//      |onComplete|: This is a block that will be called if the server returns
//          the request with a successful response code. It will be passed a
//          dictionary that contains all of the JSON data returned from the
//          betable server.
//      |onFailure|: This is a block that will be called if the server returns
//          with an error. It gets passed the NSURLResponse object, the string
//          reresentation of the body, and the NSError that was raised.
//          betable server.
- (void)userWalletOnComplete:(BetableCompletionHandler)onComplete
                   onFailure:(BetableFailureHandler)onFailure;

// All of the betable server endpoint urls.
+ (NSString*)getTokenURL;
+ (NSString*)getBetURL:(NSString*)gameID;
+ (NSString*)getWalletURL;
+ (NSString*)getAccountURL;

@property (retain, nonatomic) NSString *accessToken;
@property (retain, nonatomic) NSString *clientSecret;
@property (retain, nonatomic) NSString *clientID;
@property (retain, nonatomic) NSString *redirectURI;
@property (retain, nonatomic) NSOperationQueue *queue;


@end
