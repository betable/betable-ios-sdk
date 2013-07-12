/*
 * Copyright (c) 2012, Betable Limited
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Betable Limited nor the names of its contributors
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL BETABLE LIMITED BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import <Betable/BetableWebViewController.h>
#import <Betable/BetableHandlers.h>

@class BetableWebViewController;

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
- (void)authorizeInViewController:(UIViewController*)viewController onCancel:(BetableCancelHandler)onClose;


// Once you have your access code from the application:handleOpenURL: of your
// UIApplicationDelegate after betable redirects to your app uri you can pass
// the uri into this method with your handlers for successfully or unsuccessfully
// recieving an access token.
//
// NOTE: This is the final step of oauth.  In the onComplete handler you will
// recieve your access token for the user associated with this Betable object.
// You will want to store this with the user so you can make future calls on
// be half of said user.
- (void)handleAuthorizeURL:(NSURL*)url onAuthorizationComplete:(BetableAccessTokenHandler)onComplete onFailure:(BetableFailureHandler)onFailure;

// You can create an auth token for an unbacked bet (virtual currency).  Rather,
// than calling authorize first and receiving a token back in
// application:handleOpenURL: you will receive an unbacked-bet access token in
// the onComplete callback.
- (void)unbackedToken:(NSString*)clientUserID
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

// This method is used to place an unbacked-bet for the user associated with this Betable
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
- (void)unbackedBetForGame:(NSString*)gameID
                  withData:(NSDictionary*)data
                onComplete:(BetableCompletionHandler)onComplete
                 onFailure:(BetableFailureHandler)onFailure;

// All of the betable server endpoint urls.
+ (NSString*)getTokenURL;
+ (NSString*)getBetURL:(NSString*)gameID;
+ (NSString*)getWalletURL;
+ (NSString*)getAccountURL;
+ (NSString*)getUnbackedBetURL:(NSString*)gameID;

@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *clientSecret;
@property (strong, nonatomic) NSString *clientID;
@property (strong, nonatomic) NSString *redirectURI;
@property (strong, nonatomic) NSOperationQueue *queue;
@property (strong, nonatomic) BetableWebViewController *currentWebView;


@end
