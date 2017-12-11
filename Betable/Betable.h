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
#import <Betable/BetableBatchRequest.h>
#import <Betable/BetableCredentials.h>
#import <Betable/BetableTracking.h>
#import <Betable/BetableTrackingHistory.h>
#import <Betable/BetableTrackingUtil.h>

static NSString* const BetableEnvironmentSandbox = @"sandbox";
static NSString* const BetableEnvironmentProduction = @"production";

static NSString* const METHOD_GET = @"GET";
static NSString* const METHOD_POST = @"POST";


@class BetableWebViewController;

@interface Betable : NSObject

@property (nonatomic, strong) BetableProfile* profile;

- (Betable*)initWithClientID:(NSString*)aClientID clientSecret:(NSString*)aClientSecret redirectURI:(NSString*)aRedirectURI;

//This method is used to provide BetableSDK with the launch options for the app, it also allows betable to do install attribution for any ads that directed people to this app

//      |launchOptions| - The launch options of the application when the
//          delegate method applicationDidLaunchWithOptions: is called.
- (void)launchWithOptions:(NSDictionary*)launchOptions;

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
// It is suggested that your redirect protocol be "betable+<GAME_SLUG>"
//

// Game should call this before betting--doing so will initialize a system of time-based reality checks and proper session managment.
// Not doing so may result in undefined behaviour on other betable calls
// Setting loginOverRegister to YES should drop the player on a login page, to NO should take the user to registration
- (void)checkCredentials:(id<BetableCredentialCallbacks>)callbacks loginOverRegister:(BOOL)login;

// This method is will open a WebView containing game referenced by the passed in game slug.
// The webview will be attachd to the rootViewController of the keyWindow of the sharedApplication

//      |gameSlug| - this is the slug for the game you are trying to load
- (void)     openGame:(NSString*)gameSlug
          withEconomy:(NSString*)economy
              onClose:(BetableCloseHandler)onClose
            onFailure:(BetableFailureHandler)onFaiure
    renderUsingWebkit:(BOOL)useWebKit;

// This method will open a WebView that will take the user to the external/cobranded version of the deposit flow
// The webview will be attachd to the rootViewController of the keyWindow of the sharedApplication
//      |onClose| - this block will be called when the webview is closed,
//          it will not send any information about the nature of the deposit.
- (void)openDepositThenOnClose:(BetableCloseHandler)onClose;

// This method will open a WebView that will take the user to the external/cobranded version of the withdraw flow.
// The webview will be attachd to the rootViewController of the keyWindow of the sharedApplication
//      |onClose| - this block will be called when the webview is closed,
//          it will not send any information about the nature of the withdraw.
- (void)openWithdrawThenOnClose:(BetableCloseHandler)onClose;

// This method will open a WebView that will take the user to the external/cobranded version of the promotion redemption flow.
// The webview will be attachd to the rootViewController of the keyWindow of the sharedApplication

//      |promotionURL| - This is the url that you generated on your server
//          using your client secret for your promotion, for more details:
//
//              https://developers.betable.com/docs/api/#promotion-api
//.
//      |onClose| - this block will be called when the webview is closed,
//          it will not send any information about the nature of the
//          promotion.
//
//       NOTE: Your redirect URI will also be called.
//
- (void)openRedeemPromotion:(NSString*)promotionURL thenOnClose:(BetableCloseHandler)onClose;

// This method will open a WebView that will take the user to the external/cobranded version of the user's wallet.
// The webview will be attachd to the rootViewController of the keyWindow of the sharedApplication
//
//      |onClose| - this block will be called when the webview is closed,
//
- (void)openWalletThenOnClose:(BetableCloseHandler)onClose;

// This method will open a WebView that will take the user to the external/cobranded version of the support page.
// The webview will be attachd to the rootViewController of the keyWindow of the sharedApplication
//
//      |onClose| - this block will be called when the webview is closed,
//          it will not send any information about the nature of the
//          support ticket lodged.
//
- (void)openSupportThenOnClose:(BetableCloseHandler)onClose;

// This method will open a WebView that will take the user to a specified path on the betable site.
// The webview will be attachd to the rootViewController of the keyWindow of the sharedApplication
//
//      |path| - the path on betable.com you would like to go to
//
//      |viewController| - the ViewController in which to modally display
//          this web view
//      |onClose| - this block will be called when the webview is closed,
//          it will not send any information about the nature of the
//          promotion.
//
- (void)openBetablePath:(NSString*)path withParams:(NSDictionary*)params onClose:(BetableCloseHandler)onClose;

// Once you have your access code from the application:handleOpenURL: of your
// UIApplicationDelegate after betable redirects to your app uri you can pass
// the uri into this method with your handlers for successfully or unsuccessfully
// recieving an access token.
//
// NOTE: This is the final step of oauth.  In the onComplete handler you will
// recieve your access token for the user associated with this Betable object.
// You will want to store this with the user so you can make future calls on
// be half of said user.
- (void)handleAuthorizeURL:(NSURL*)url;

// You can create an auth token for an unbacked bet (virtual currency).  Rather,
// than calling authorize first and receiving a token back in
// application:handleOpenURL: you will receive an unbacked-bet access token in
// the onComplete callback.
- (void)unbackedToken:(NSString*)clientUserID
           onComplete:(BetableAccessTokenHandler)onComplete
            onFailure:(BetableFailureHandler)onFailure;

// This method is used to return the game manifest for a particular game in the
// betable canvas ecosystem. Using this you can load game that you have access
// to via a call to openGame. You will need to email tony [at] betable [dot] com
// if you want access to this method.
//
//      |gameSlug|: This is the slug for the game in the betable canvas ecosytem
//      |onComplete|: This is a block that will be called if the server returns
//          the request with a successful response code. It will be passed a
//          dictionary that contains all of the JSON data returned from the
//          betable server.
//      |onFailure|: This is a block that will be called if the server returns
//          with an error. It gets passed the NSURLResponse object, the string
//          reresentation of the body, and the NSError that was raised.
//          betable server.
- (void)gameManifestForSlug:(NSString*)gameSlug
                    economy:(NSString*)economy
                 onComplete:(BetableCompletionHandler)onComplete
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

// This method is used to place a bet for the user associated with this Betable
// object.
//
//      |gameID|: This is your gameID which is registered and can be checked at
//          http://developers.betable.com
//      |creditGameID|: This is the ID of the game that is being played with
//          the credits.
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
- (void)creditBetForGame:(NSString*)gameID
              creditGame:(NSString*)creditGameID
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

// This method is used to place an unbacked-bet for the user associated with this Betable
// object.
//
//      |gameID|: This is your gameID which is registered and can be checked at
//          http://developers.betable.com
//      |creditGameID|: This is the ID of the game that is being played with
//          the credits.
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
- (void)unbackedCreditBetForGame:(NSString*)gameID
                      creditGame:(NSString*)creditGameID
                        withData:(NSDictionary*)data
                      onComplete:(BetableCompletionHandler)onComplete
                       onFailure:(BetableFailureHandler)onFailure;

// This method is used to record when the user is active so that the session
// can be prolonged.
- (void)recordUserActivity;

// raises "User is not authroized" exception if credentials are missing
- (void)checkAccessToken:(NSString*)method;

// This method is used to clear a user out as the authroized user on a Betable Object. It
// also manages the state of the betable object and it's web views.
- (void)logout;

// All of the betable server endpoint urls.
- (NSString*)getTokenURL;
+ (NSString*)getGameURLPath:(NSString*)gameSlug;
+ (NSString*)getBetPath:(NSString*)gameID;
+ (NSString*)getUnbackedBetPath:(NSString*)gameID;
+ (NSString*)getWalletPath;
+ (NSString*)getAccountPath;

// For the most part, following a call to checkCredentials, Betable will callback to game about credentais,
// If this is present there is a high liklihood (but no guarantee) that the credentails are valid
@property (strong, nonatomic, readonly) BetableCredentials* credentials;

@property (strong, nonatomic) NSString* clientSecret;
@property (strong, nonatomic) NSString* clientID;
@property (strong, nonatomic) NSString* redirectURI;
@property (strong, nonatomic) NSOperationQueue* queue;
// Public callback for when player has explicitly logged out of game--doesn't report session timeouts or other invalidation
@property (strong, nonatomic) BetableLogoutHandler onLogout;


@end
