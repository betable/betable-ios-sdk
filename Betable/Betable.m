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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "Betable.h"
#import "BetableCredentials.h"
#import "BetableHandlers.h"
#import "BetableProfile.h"
#import "BetableWebViewController.h"
#import "BetableTracking.h"
#import "NSString+Betable.h"
#import "NSDictionary+Betable.h"
#import "BetableUtils.h"
#import "STKeychain.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

NSString *BetablePasteBoardUserIDKey = @"com.Betable.BetableSDK.sharedData:UserID";
NSString *BetablePasteBoardName = @"com.Betable.BetableSDK.sharedData";

#define SERVICE_KEY @"com.betable.SDK"
#define USERNAME_KEY @"com.betable.Credentials"
#define FIRSTSTORE_KEY @"com.betable.FirstStore"

// int disguied as enum used in place of double disguied as NSTimeInterval.
typedef enum heartbeatPeriods {
    NOW = 0,
    HEALTHY_PERIOD = 60,
    UNHEALTHY_PERIOD = 5
} HeartBeatPeriods;

@interface Betable () {
    NSMutableOrderedSet  *_deferredRequests;
    BetableProfile *_profile;
    // This holds the value of the betable auth cookie when we precache the page. If the
    // value of this cookie changes before then and the showing of the page, we need to
    // load the page again.
    NSString *_preCacheAuthToken;
    BetableTracking *_tracking;
    BOOL _launched;
    NSDictionary *_launchOptions;
}

- (NSString *)urlEncode:(NSString*)string;
- (NSURL*)getAPIWithURL:(NSString*)urlString;
+ (NSString*)base64forData:(NSData*)theData;

-(void) performCredentialSuccess;
-(void) performCredentialFailure:(NSURLResponse*) response withBody:(NSString*) responseBody orError:(NSError*) error;

@end

@implementation Betable

@synthesize credentials, clientID, clientSecret, redirectURI, queue, currentWebView, onLogout;

- (Betable*)init {
    self = [super init];
    if (self) {
        clientID = nil;
        clientSecret = nil;
        redirectURI = nil;
        _launched = NO;
        _launchOptions = nil;
        _deferredRequests = [[NSMutableOrderedSet alloc] init];
        _profile = [[BetableProfile alloc] init];
        currentWebView = [[BetableWebViewController alloc] init];
        self.currentWebView.forcedOrientationWithNavController = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8");
        // If there is a testing profile, we need to verify it before we make
        // requests or set the URL for the authorize web view.
        queue = [[NSOperationQueue alloc] init];
    }
    return self;
}
- (Betable*)initWithClientID:(NSString*)aClientID clientSecret:(NSString*)aClientSecret redirectURI:(NSString*)aRedirectURI {
    self = [self init];
    if (self) {
        clientID = aClientID;
        clientSecret = aClientSecret;
        redirectURI = aRedirectURI;
        _tracking = [[BetableTracking alloc] initWithClientID:aClientID andEnvironment:BetableEnvironmentProduction];
        [_tracking trackSession];
        [self fireDeferredRequests];
        [self setupAuthorizeWebView];
    }
    return self;
}


- (void)launchWithOptions:(NSDictionary*)launchOptions {
    _launched = YES;
    _launchOptions = launchOptions;
}

- (BOOL)loadStoredAccessToken {
    // Depricated, just return false
    return NO;
}


- (void)checkCredentials:(id<BetableCredentialCallbacks> _Nonnull) callbacks
 {
    [self checkLaunchStatus];
     _credentialCallbacks = callbacks;

    // If a user deletes the app, their keychain item still exists.
    // If it hasn't been stored then delete it and don't retrieve it
    NSNumber* hasBeenStoredSinceInstall = (NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:FIRSTSTORE_KEY];
    NSError* error;
    BetableCredentials* newCredentials;
    if ([hasBeenStoredSinceInstall boolValue]) {
        NSString* serialisedCredentials = [STKeychain getPasswordForUsername:USERNAME_KEY andServiceName:SERVICE_KEY error:&error];
        if (error) {
            NSLog(@"Error retrieving credentials <%@>: %@", serialisedCredentials, error);
        } else if ( nil != serialisedCredentials) {
            newCredentials = [[BetableCredentials alloc] initWithSerialised:serialisedCredentials];
            if ( newCredentials ) {
                [self beginSessionWithCredentials:newCredentials];
                return;
            } else {
                NSLog(@"Error interpreting serialized credentials <%@>", serialisedCredentials);
            }
        }
    } else {
        [STKeychain deleteItemForUsername:USERNAME_KEY andServiceName:SERVICE_KEY error:&error];
        if (error) {
            NSLog(@"Error removing credentials: %@", error);
        }
    }
    
    [self authorizeInViewController:[_credentialCallbacks currentGameView]
                              login:YES
            onAuthorizationComplete:^(NSString *accessToken) {}
                          onFailure:^(NSURLResponse *response, NSString *responseBody, NSError *error) {}
                           onCancel:^{ [self performCredentialFailure:nil withBody:nil orError:nil];}
     ];
}

- (void)storeAccessToken {
    // Depricated, just proxy to storeCredentials
    [self storeCredentials];
}

- (void)storeCredentials {
    [self checkAccessToken:@"storeCredentials"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:FIRSTSTORE_KEY];
    [defaults synchronize];
    
    NSError *error;
    NSString* password = [credentials description];
    [STKeychain storeUsername:USERNAME_KEY andPassword:password forServiceName:SERVICE_KEY updateExisting:YES error:&error];
    if (error) {
        NSLog(@"Error storing credentials <%@>: %@", password, error);
    }
}


- (void)setupAuthorizeWebView {
    //It will be inside of a navcontroller to protect its alignment.
    [self.currentWebView resetView];
    self.currentWebView.forcedOrientationWithNavController = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8");
    _preCacheAuthToken = [self getBetableAuthCookie].value;
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString *UUID = [NSString stringWithFormat:@"%@", UUIDSRef];
    CFRelease(UUIDRef);
    CFRelease(UUIDSRef);
    
    NSDictionary *authorizeParameters = @{
                                          @"redirect_uri":self.redirectURI,
                                          @"state":UUID,
                                          @"load":@"ext.nux.deposit"
                                          };
    NSString *authURL = [_profile decorateURL:@"/ext/precache" forClient:self.clientID withParams:authorizeParameters];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentWebView.url = authURL;
    });
}

- (NSHTTPCookie*)getBetableAuthCookie {
    //Get the cookie jar
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [cookieJar cookies]) {
#ifdef USE_LOCALHOST
        BOOL isBetableCookie = [cookie.domain rangeOfString:@"127.0.0.1"].location != NSNotFound;
#else
        BOOL isBetableCookie = [cookie.domain rangeOfString:@"betable.com"].location != NSNotFound;
#endif
        BOOL isAuthCookie = [cookie.name isEqualToString:@"betable-players"];
        if (isBetableCookie && isAuthCookie) {
            return cookie;
        }
    }
    return nil;
}

- (void)token:(NSString*)code {
    NSURL *apiURL = [NSURL URLWithString:[self getTokenURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:apiURL];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", clientID, clientSecret];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [Betable base64forData:authData]];
    [request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:authValue forKey:@"Authorization"]];
    
    [request setHTTPMethod:METHOD_POST];
    NSString *body = [NSString stringWithFormat:@"grant_type=authorization_code&redirect_uri=%@&code=%@",
                      [self urlEncode:redirectURI],
                      code];
    
    void (^onComplete)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        if (error) {
            [self performCredentialFailure:response withBody:responseBody orError:error];
        } else {
            NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
            NSString *accessToken = [data objectForKey:@"access_token"];
            NSString *sessionID = [data objectForKey:@"session_id"];
            
            BetableCredentials* newCredentials = [[BetableCredentials alloc] initWithAccessToken:accessToken andSessionID:sessionID];
            [self beginSessionWithCredentials:newCredentials];

            [self userAccountOnComplete:^(NSDictionary *data) {
                NSString *userID = data[@"id"];
                [[self sharedData] setValue:userID forPasteboardType:BetablePasteBoardUserIDKey];
            } onFailure:^(NSURLResponse *response, NSString *responseBody, NSError *error) {
                NSLog( @"Failed call to %@ with response:%@\nresponseBody:%@\nerror:%@", request, response, responseBody, error );
            }];
        }
    };
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.queue
                           completionHandler:onComplete
     ];
}

-(void) performCredentialSuccess {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Runtime selector doesn't spew unnecessary warnings
        if( [_credentialCallbacks respondsToSelector:NSSelectorFromString(@"onCredentialsSuccess:")] ) {
            [_credentialCallbacks onCredentialsSuccess:credentials];
        }
        
        if( self.onAuthorize ) {
            self.onAuthorize( credentials.accessToken );
        }
    });
}

-(void) performCredentialFailure:(NSURLResponse*) response withBody:(NSString*) responseBody orError:(NSError*) error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if( [_credentialCallbacks respondsToSelector:NSSelectorFromString(@"onCredentialsFailure")] ) {
            [_credentialCallbacks onCredentialsFailure];
        }
        if( self.onFailure ) {
            self.onFailure(response, responseBody, error );
        }
    });
}


- (void)unbackedToken:(NSString*)clientUserID onComplete:(BetableAccessTokenHandler)onComplete onFailure:(BetableFailureHandler)onFailure {
    NSURL *apiURL = [NSURL URLWithString:[self getTokenURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:apiURL];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", clientID, clientSecret];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [Betable base64forData:authData]];
    [request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:authValue forKey:@"Authorization"]];
    
    [request setHTTPMethod:METHOD_POST];
    NSString *body = [NSString stringWithFormat:@"grant_type=client_credentials&redirect_uri=%@&client_user_id=%@",
                      [self urlEncode:redirectURI],
                      clientUserID];
    
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSString *responseBody = [[NSString alloc] initWithData:data
                                                                              encoding:NSUTF8StringEncoding];
                               if (error) {
                                   onFailure(response, responseBody, error);
                               } else {
                                   NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
                                   NSString* accessToken = [data objectForKey:@"access_token"];
                                   NSString* sessionID = [data objectForKey:@"session_id"];
                                   BetableCredentials* newCredentials = [[BetableCredentials alloc] initWithAccessToken:accessToken andSessionID:sessionID];
                                   [self beginSessionWithCredentials:newCredentials];
                                   
                                   onComplete(accessToken);
                               }
                           }
     ];
}

#pragma mark - External Methods

// Translates betable-id's 302 response (including the query param "code") from GET /authorize to running app
- (void)handleAuthorizeURL:(NSURL*)url{
    NSURL *redirect = [NSURL URLWithString:self.redirectURI];
    
    //First check that we should be handling this
    BOOL schemeSame = [[[redirect scheme] lowercaseString] isEqualToString:[[url scheme] lowercaseString]];
    BOOL hostSame = [[[redirect host] lowercaseString] isEqualToString:[[url host] lowercaseString]];
    BOOL fragmentSame = ((![redirect fragment] && ![url fragment]) || [[[redirect fragment] lowercaseString] isEqualToString:[[url fragment] lowercaseString]]);
    if (schemeSame && hostSame && fragmentSame) {
        //If the command is the same as the redirect, then do the authorize.
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        for (NSString *param in [[url query] componentsSeparatedByString:@"&"]) {
            NSArray *elts = [param componentsSeparatedByString:@"="];
            if([elts count] < 2) continue;
            [params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
        }
        if (params[@"code"]) {
            [self token:[params objectForKey:@"code"]];
            [self.currentWebView.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            
        } else if (params[@"error"]) {
            NSError *error = [[NSError alloc] initWithDomain:@"BetableAuthorization" code:-1 userInfo:params];
            [self performCredentialFailure: nil withBody: nil orError:error];
        }
    }
}

- (void)authorizeInViewController:(UIViewController*)viewController onAuthorizationComplete:(BetableAccessTokenHandler)onAuthorize onFailure:(BetableFailureHandler)onFailure onCancel:(BetableCancelHandler)onCancel {
    [self authorizeInViewController:viewController login:NO onAuthorizationComplete:onAuthorize onFailure:onFailure onCancel:onCancel];
}

- (void)authorizeLoginInViewController:(UIViewController*)viewController onAuthorizationComplete:(BetableAccessTokenHandler)onAuthorize onFailure:(BetableFailureHandler)onFailure onCancel:(BetableCancelHandler)onCancel {
    [self authorizeInViewController:viewController login:YES onAuthorizationComplete:onAuthorize onFailure:onFailure onCancel:onCancel];
}

- (void)authorizeInViewController:(UIViewController*)viewController login:(BOOL)goToLogin onAuthorizationComplete:(BetableAccessTokenHandler)onAuthorize onFailure:(BetableFailureHandler)onFailure onCancel:(BetableCancelHandler)onCancel {
    [self checkLaunchStatus];
    if (![_preCacheAuthToken isEqualToString:[self getBetableAuthCookie].value]) {
        self.currentWebView = [[BetableWebViewController alloc] init];
        [self setupAuthorizeWebView];
    }
    self.currentWebView.onCancel = onCancel;
    
    // Depricated fields and parameters can stay a while longer...
    self.onAuthorize = onAuthorize;
    self.onFailure = onFailure;
    
    self.currentWebView.portraitOnly = YES;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8")) {
        UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:self.currentWebView];
        nvc.navigationBarHidden = YES;
        self.currentWebView.modalPresentationStyle = UIModalPresentationFullScreen;
        [viewController presentViewController:nvc animated:YES completion:nil];
    } else {
        [viewController presentViewController:self.currentWebView animated:YES completion:nil];
    }
    if (goToLogin) {
        self.currentWebView.onLoadState = @"ext.nux.play";
    }
    if(self.currentWebView.finishedLoading) {
        // This is a method in the webview's JS
        [self.currentWebView loadCachedState];
    } else {
        self.currentWebView.loadCachedStateOnFinish = YES;
    }
}

- (void)openGame:(NSString*)gameSlug withEconomy:(NSString*)economy inViewController:(UIViewController*)viewController onHome:(BetableCancelHandler)onHome onFailure:(BetableFailureHandler)onFaiure{
    //TODO Make request to get url
    [self gameManifestForSlug:gameSlug economy:economy onComplete:^(NSDictionary *data) {
        NSString* url = [NSString stringWithFormat:@"https://prospecthallcasino.com%@", data[@"url"]];
        BetableWebViewController *webController = [[BetableWebViewController alloc]initWithURL:url onCancel:onHome showInternalCloseButton:NO];
        [viewController presentViewController:webController animated:YES completion:nil];
    } onFailure:onFaiure];
}

- (void)depositInViewController:(UIViewController*)viewController onClose:(BetableCancelHandler)onClose {
    BetableWebViewController *webController = [[BetableWebViewController alloc] initWithURL:[_profile decorateTrackURLForClient:self.clientID withAction:@"deposit"] onCancel:onClose];
    [viewController presentViewController:webController animated:YES completion:nil];
}


- (void)supportInViewController:(UIViewController*)viewController onClose:(BetableCancelHandler)onClose {
    BetableWebViewController *webController = [[BetableWebViewController alloc] initWithURL:[_profile decorateTrackURLForClient:self.clientID withAction:@"support"] onCancel:onClose];
    [viewController presentViewController:webController animated:YES completion:nil];
}

- (void)withdrawInViewController:(UIViewController*)viewController onClose:(BetableCancelHandler)onClose {
    BetableWebViewController *webController = [[BetableWebViewController alloc] initWithURL:[_profile decorateTrackURLForClient:self.clientID withAction:@"withdraw"] onCancel:onClose];
    [viewController presentViewController:webController animated:YES completion:nil];
}

- (void)redeemPromotion:(NSString*)promotionURL inViewController:(UIViewController*)viewController onClose:(BetableCancelHandler)onClose {
    NSDictionary *params = @{@"promotion": promotionURL};
    NSString *url = [_profile decorateTrackURLForClient:self.clientID withAction:@"redeem" andParams:params];
    BetableWebViewController *webController = [[BetableWebViewController alloc] initWithURL:url onCancel:onClose];
    [viewController presentViewController:webController animated:YES completion:nil];
}

- (void)walletInViewController:(UIViewController*)viewController onClose:(BetableCancelHandler)onClose {
    BetableWebViewController *webController = [[BetableWebViewController alloc] initWithURL:[_profile decorateTrackURLForClient:self.clientID withAction:@"wallet"] onCancel:onClose];
    [viewController presentViewController:webController animated:YES completion:nil];
}

- (void)loadBetablePath:(NSString*)path inViewController:(UIViewController*)viewController withParams:(NSDictionary*)params onClose:(BetableCancelHandler)onClose {
    BetableWebViewController *webController = [[BetableWebViewController alloc] initWithURL:[_profile decorateURL:path forClient:self.clientID withParams:params] onCancel:onClose];
    [viewController presentViewController:webController animated:YES completion:nil];
}

- (void)checkAccessToken:(NSString*)method {
    if (self.credentials == nil) {
        [NSException raise:[NSString stringWithFormat:@"User is not authorized %@", method]
                    format:@"User must have an access token to use this feature"];
    }
    [self checkLaunchStatus];
}

- (void)checkLaunchStatus {
    if (!_launched) {
        [NSException raise:@"Betable not launched properly"
                    format:@"You must call -launchWithOptions: on the betable object when the app launches and pass in the application's launchOptions"];
    }
}

#pragma mark - API Calls
- (void)gameManifestForSlug:(NSString*)gameSlug
                    economy:(NSString*)economy
                 onComplete:(BetableCompletionHandler)onComplete
                  onFailure:(BetableFailureHandler)onFailure {
    //TODO use right path
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    if (economy) {
        data[@"economy"] = economy;
        data[@"currency"] = @"GPB";
    } else {
        data[@"unbacked"] = @"true";
    }
    data[@"type"] = @"mobile";
    data[@"sdk"] = @"true";
    [self checkAccessToken:@"Load Game"];
    [self fireGenericAsynchronousRequestWithPath:[Betable getGameURLPath:gameSlug] method:METHOD_GET data:data onSuccess:onComplete onFailure:onFailure];
}

- (void)betForGame:(NSString*)gameID
          withData:(NSDictionary*)data
        onComplete:(BetableCompletionHandler)onComplete
         onFailure:(BetableFailureHandler)onFailure {
    [self checkAccessToken:@"Bet"];
    
    BetableCompletionHandler onBetComplete = ^(NSDictionary* data){
        if (! [credentials isUnbacked]) {
            [self resetSessionAndOnComplete:^(NSDictionary* data){}
                               andOnFailure:^(NSURLResponse *response, NSString *responseBody, NSError *error) {}
             ];
        }
        onComplete(data);

    };
    
    [self fireGenericAsynchronousRequestWithPath:[Betable getBetPath:gameID] method:METHOD_POST data:data onSuccess:onBetComplete onFailure:onFailure];
}

- (void)unbackedBetForGame:(NSString*)gameID
                  withData:(NSDictionary*)data
                onComplete:(BetableCompletionHandler)onComplete
                 onFailure:(BetableFailureHandler)onFailure {
    [self checkAccessToken:@"Unbacked Bet"];
    [self fireGenericAsynchronousRequestWithPath:[Betable getUnbackedBetPath:gameID] method:METHOD_POST data:data onSuccess:onComplete onFailure:onFailure];
}

- (void)creditBetForGame:(NSString*)gameID
              creditGame:(NSString*)creditGameID
                withData:(NSDictionary*)data
              onComplete:(BetableCompletionHandler)onComplete
               onFailure:(BetableFailureHandler)onFailure {
    [self checkAccessToken:@"Credit Bet"];
    NSString *gameAndBonusID = [NSString stringWithFormat:@"%@/%@", gameID, creditGameID];
    [self betForGame:gameAndBonusID withData:data onComplete:onComplete onFailure:onFailure];
}

- (void)unbackedCreditBetForGame:(NSString*)gameID
                      creditGame:(NSString*)creditGameID
                        withData:(NSDictionary*)data
                      onComplete:(BetableCompletionHandler)onComplete
                       onFailure:(BetableFailureHandler)onFailure {
    [self checkAccessToken:@"Unbacked Credit Bet"];
    NSString *gameAndBonusID = [NSString stringWithFormat:@"%@/%@", gameID, creditGameID];
    [self unbackedBetForGame:gameAndBonusID withData:data onComplete:onComplete onFailure:onFailure];
}

- (void)userAccountOnComplete:(BetableCompletionHandler)onComplete
                    onFailure:(BetableFailureHandler)onFailure{
    [self checkAccessToken:@"Account"];
    [self fireGenericAsynchronousRequestWithPath:[Betable getAccountPath] method:METHOD_GET onSuccess:onComplete onFailure:onFailure];
}

- (void)userWalletOnComplete:(BetableCompletionHandler)onComplete
                   onFailure:(BetableFailureHandler)onFailure {
    [self checkAccessToken:@"Wallet"];
    [self fireGenericAsynchronousRequestWithPath:[Betable getWalletPath] method:METHOD_GET onSuccess:onComplete onFailure:onFailure];
}

- (void)logout {
    //Get the cookie jar
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSHTTPCookie *cookie = [self getBetableAuthCookie];
    if (cookie) {
        [cookieJar deleteCookie:cookie];
    }
    //Remove any stored tokens
    NSError *error;
    [STKeychain deleteItemForUsername:USERNAME_KEY andServiceName:SERVICE_KEY error:&error];
    if (error) {
        NSLog(@"Error removing accessToken: %@", error);
    }
    //After the cookies are destroyed, reload the webpage
    self.currentWebView = [[BetableWebViewController alloc] init];
    [self setupAuthorizeWebView];
    
    // clear user's live credentials
    credentials = nil;
    
    // Stop heartbeats
    [self extendSessionIn:NOW withBehaviour:FORGET];
    
    // Notify game
    if( [_credentialCallbacks respondsToSelector:NSSelectorFromString(@"onCredentialsRevoked" )] ) {
        [_credentialCallbacks onCredentialsRevoked];
    }
}

#pragma mark - Path getters

+ (NSString*) getGameURLPath:(NSString*)gameSlug {
    return [NSString stringWithFormat:@"/application_manifests/slug/%@/play", gameSlug];
}

+ (NSString*) getBetPath:(NSString*)gameID {
    return [NSString stringWithFormat:@"/games/%@/bet", gameID];
}

+ (NSString*) getUnbackedBetPath:(NSString*)gameID {
    return [NSString stringWithFormat:@"/games/%@/unbacked-bet", gameID];
}

+ (NSString*) getWalletPath{
    return [NSString stringWithFormat:@"/account/wallet"];
}

+ (NSString*) getAccountPath{
    return [NSString stringWithFormat:@"/account"];
}

+ (NSString*) getHeartbeatPath {
    return [NSString stringWithFormat:@"/sessions/alive"];
}

+ (NSString*) getResetSessionPath {
    return [NSString stringWithFormat:@"/sessions/keep-alive"];
}

#pragma mark - URL getters

- (NSString*) getTokenURL {
    return [NSString stringWithFormat:@"%@/token", [_profile apiURL]];
}


- (NSURL*)getAPIWithURL:(NSString*)urlString {
    return [self getAPIWithURL:urlString withQuery:nil];
}

- (NSURL*)getAPIWithURL:(NSString*)urlString withQuery:(NSDictionary*)query {
    NSMutableDictionary *mutQuery = [NSMutableDictionary dictionary];
    if (query) {
        mutQuery = [query mutableCopy];
    }
    mutQuery[@"access_token"] = credentials.accessToken;
    urlString = [NSString stringWithFormat:@"%@?%@", urlString, [mutQuery urlEncodedString]];
    return [NSURL URLWithString:urlString];
}


#pragma mark - Utilities
- (NSString*)urlEncode:(NSString*)string {
    NSString *encoded = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                             (CFStringRef)string,
                                                                                             NULL,
                                                                                             (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                             CFStringConvertNSStringEncodingToEncoding(NSASCIIStringEncoding)));
    return encoded;
}

- (NSString*)urldecode:(NSString*)string {
    NSString *encoded = (NSString*)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                                                             NULL,
                                                                                                             (CFStringRef)string,
                                                                                                             NULL,
                                                                                                             CFStringConvertNSStringEncodingToEncoding(NSASCIIStringEncoding)));
    return encoded;
}

+ (NSString*)base64forData:(NSData*)theData {
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

#pragma mark - Request Handling

- (void)fireDeferredRequests {
    for (NSDictionary* deferredRequest in _deferredRequests) {
        [self fireGenericAsynchronousRequestWithPath:NILIFY(deferredRequest[@"path"])
                                              method:NILIFY(deferredRequest[@"method"])
                                                data:NILIFY(deferredRequest[@"data"])
                                           onSuccess:NILIFY(deferredRequest[@"onShccess"])
                                           onFailure:NILIFY(deferredRequest[@"onFailure"])];
    }
    [_deferredRequests removeAllObjects];
}

- (void)fireGenericAsynchronousRequestWithPath:(NSString*)path method:(NSString*)method onSuccess:(BetableCompletionHandler)onSuccess onFailure:(BetableFailureHandler)onFailure {
    [self fireGenericAsynchronousRequestWithPath:path method:method data:nil onSuccess:onSuccess onFailure:onFailure];
}

- (void)fireGenericAsynchronousRequestWithPath:(NSString*)path method:(NSString*)method data:(NSDictionary*)data onSuccess:(BetableCompletionHandler)onSuccess onFailure:(BetableFailureHandler)onFailure {
    if (!_profile.hasProfile) {
        NSString *urlString = [NSString stringWithFormat:@"%@%@", _profile.apiURL, path];
        NSURL *url = [self getAPIWithURL:urlString];
        if (data && [method isEqualToString:METHOD_GET]) {
            url = [self getAPIWithURL:urlString withQuery:data];
        }
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url];
        
        [request setHTTPMethod:method];
        if (data) {
            if ([method isEqualToString:METHOD_POST]) {
                [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                [request setHTTPBody:[data JSONData]];
            }
        }
        [self fireGenericAsynchronousRequest:request onSuccess:onSuccess onFailure:onFailure];
    } else {
        NSDictionary *deferredRequest = @{
                                          @"path": NULLIFY(path),
                                          @"method": NULLIFY(method),
                                          @"data": NULLIFY(data),
                                          @"onSuccess": NULLIFY(onSuccess),
                                          @"onFailure": NULLIFY(onFailure)
                                          };
        [_deferredRequests addObject:deferredRequest];
    }
}

- (void)fireGenericAsynchronousRequest:(NSMutableURLRequest*)request onSuccess:(BetableCompletionHandler)onSuccess onFailure:(BetableFailureHandler)onFailure{
    
    void (^onComplete)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        if (error) {
            if (onFailure) {
                if (![NSThread isMainThread]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        onFailure(response, responseBody, error);
                    });
                } else {
                    onFailure(response, responseBody, error);
                }
            }
        } else {
            if (onSuccess) {
                if (![NSThread isMainThread]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
                        onSuccess(data);
                    });
                } else {
                    NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
                    onSuccess(data);
                }
            }
        }
    };
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:onComplete];
}

#pragma mark - Shared Data

- (UIPasteboard *)sharedData {
    UIPasteboard *sharedData = [UIPasteboard pasteboardWithName:BetablePasteBoardName create:YES];
    sharedData.persistent = YES;
    return sharedData;
}

- (NSString*)stringFromSharedDataWithKey:(NSString*)key {
    NSData *valueData = [[self sharedData] dataForPasteboardType:BetablePasteBoardUserIDKey];
    return [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
}

#pragma mark - Hearbeat / Reality Checks

// TODO this enum would be better served by a counter of outstanding heartbeats instead of asynchronous state
// As session calls are made back to betable ID's differnt emergent behaviours should occur
typedef enum heartbeatBehaviour
{
    // simple "is alive" check
    HEARTBEAT,
    // don't request another heartbeat
    FORGET,
} HeartbeatBehaviour;


// Marker that next heartbeats
HeartbeatBehaviour nextHeartbeatBehaviour = FORGET;

// Maintains a healthy relationship with game while reality checks take control
id <BetableCredentialCallbacks> _credentialCallbacks;


- (void)beginSessionWithCredentials:(BetableCredentials*)newCredentials {
    credentials = newCredentials;
    [self storeCredentials];
    [self performCredentialSuccess];
    
    if( [credentials isUnbacked] ) {
        // we're done for unbacked credentials--no session extensions or heartbeats
        return;
    }

    [self resetSessionAndOnComplete:^(NSDictionary* data) { [self extendSessionIn:HEALTHY_PERIOD withBehaviour:HEARTBEAT]; }
                       andOnFailure:^(NSURLResponse *response, NSString *responseBody, NSError *error) {
                           // TODO explicit "session has expired" check instead of implicit assumption here
                           [self logout];
                           [self checkCredentials:_credentialCallbacks];
   }];
}

- (void)extendSessionIn:(NSTimeInterval)seconds withBehaviour:(HeartbeatBehaviour) behavior {
    nextHeartbeatBehaviour = behavior;

    // Selectors in 0 seconds do nothing, so increment by nominal amount
    [self performSelector:@selector(onHeartbeat) withObject:self afterDelay:seconds + 0.1];
}

- (void)resetSessionAndOnComplete:(BetableCompletionHandler) onSuccess andOnFailure:(BetableFailureHandler) onFailure {
    NSString* path = [Betable getResetSessionPath];
    NSString* method = METHOD_POST;
    if ( nil == credentials ) {
        NSLog( @"faulty credentials--this shouldn't happen" );
        return;
    } else if ( [credentials isUnbacked] ) {
        NSLog( @"unbacked credentials--should not get reset" );
        // TODO consider this might be a failure and report, or a detectable success for the given credentials and report
        return;
    }
    NSDictionary* data = @{ @"keep_alive": @YES, @"reality_checked": @YES, @"session_id" : credentials.sessionID };
    [self fireGenericAsynchronousRequestWithPath:path method:method data:data onSuccess:onSuccess onFailure:onFailure ];

}

- (void)onHeartbeat{
    if ( FORGET == nextHeartbeatBehaviour ) {
        // User was explicitly logged out and heartbeats shouldn't resume until logged in again
        nextHeartbeatBehaviour = HEARTBEAT;
        return;
    }
    
    if( nil == credentials ) {
        [self extendSessionIn:UNHEALTHY_PERIOD withBehaviour:nextHeartbeatBehaviour];
        return;
    }
    
    if( [credentials isUnbacked] ) {
        // No heartbeats for unbacked access credentials
        return;
    }
    
    NSString* path = [Betable getHeartbeatPath];
    NSString* method = METHOD_GET;
    NSDictionary* data = @{ @"session_id": credentials.sessionID };
   
    BetableCompletionHandler onSuccess = ^(NSDictionary* data) {
        if( ! [data[@"alive"] boolValue] ) {
            // Session is no longer alive
            [self logout];
            return;
        }

        NSDictionary* realityCheck = data[@"reality_check"];
        
        if( ! [realityCheck[@"enabled"] boolValue] ) {
            [self extendSessionIn:HEALTHY_PERIOD withBehaviour:nextHeartbeatBehaviour];
            return;
        }

        double msRemainingTime = [realityCheck[@"remaining_time"] doubleValue ];

        // Lets not be pedantic--if a reality check is due in the next second, don't waste cycles and bandwidth
        double msRemainingEpsilon = 1000;
        if ( msRemainingTime < msRemainingEpsilon ) {
            
            // Time's up, let user decide how to proceed
            // Note that right here, heartbeats have stopped and will not resume until user decides to continue
            dispatch_async(dispatch_get_main_queue(), ^{
                [self fireRealityCheck];
            });
        } else {
            // cap number of seconds to a healthy period before next check
            NSTimeInterval nextHeartbeatPeriod = MIN( msRemainingTime / 1000.0, HEALTHY_PERIOD);
            [self extendSessionIn:nextHeartbeatPeriod withBehaviour:nextHeartbeatBehaviour];
            
        }
    };
    
    BetableFailureHandler onFailure = ^(NSURLResponse *response, NSString *responseBody, NSError *error) {
        NSLog( @"Logging out after error on heartbeat:\nresponse: %@\nresponseBody: %@\nerror: %@", response, responseBody, error );
        [self logout];
    };
    
    [self fireGenericAsynchronousRequestWithPath:path method:method data:data onSuccess:onSuccess onFailure:onFailure ];
    
}

- (void)performPostRealityCheck {
    // Runtime selector doesn't spew unnecessary warnings
    if( [_credentialCallbacks respondsToSelector:NSSelectorFromString(@"onPostRealityCheck")] ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_credentialCallbacks onPostRealityCheck];
        });
    }
    
}

- (void)performPreRealityCheck {
    // Runtime selector doesn't spew unnecessary warnings
    if( [_credentialCallbacks respondsToSelector:NSSelectorFromString(@"onPreRealityCheck")] ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_credentialCallbacks onPreRealityCheck];
        });
    }
}


- (void)fireRealityCheck {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Reality Check" message:@"You've been playing a while" preferredStyle:UIAlertControllerStyleAlert ];
    
    // Propose player's decision to logout after reality check interval
    void (^onRealityCheckLogout)(UIAlertAction*) = ^(UIAlertAction* action){
        [self logout];
        if( onLogout ) {
            onLogout();
        }
        [self performPostRealityCheck];
    };
    UIAlertAction* logoutAction = [UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDefault handler:onRealityCheckLogout ];
    [alertController addAction:logoutAction];
    
    // Propose player's decision to continue playing after reality check interval
    void (^onRealityCheckContinue)(UIAlertAction*) = ^(UIAlertAction* action){
        // reset reality checks on next heartbeat
        [self resetSessionAndOnComplete:^(NSDictionary* data){
            [self performPostRealityCheck];
            [self extendSessionIn:NOW withBehaviour:HEARTBEAT];

        }
                           andOnFailure:^(NSURLResponse *response, NSString *responseBody, NSError *error) {}
         ];
        
    };
    UIAlertAction* continueAction = [UIAlertAction actionWithTitle:@"Continue Playing" style:UIAlertActionStyleDefault handler:onRealityCheckContinue ];
    [alertController addAction:continueAction];
    
    // Propose player's decision to check their wallet balance after reality check interval
    void (^onRealityCheckWallet)(UIAlertAction*) = ^(UIAlertAction* action){
        // reset reality checks on next heartbeat, once session is extended, open the player's wallet
        [self resetSessionAndOnComplete:^(NSDictionary* data){
            [self walletInViewController:[_credentialCallbacks currentGameView] onClose:^{
                // User must decide whether to logout or continue; regardless of wallet experience
                [self fireRealityCheck];
            }];
            [self extendSessionIn:NOW withBehaviour:HEARTBEAT];
        }
                           andOnFailure:^(NSURLResponse *response, NSString *responseBody, NSError *error) {}
         ];
    };
    UIAlertAction* walletAction = [UIAlertAction actionWithTitle:@"Check Balance" style:UIAlertActionStyleDefault handler:onRealityCheckWallet ];
    [alertController addAction:walletAction];
    
    [self performPreRealityCheck];
    
    // TODO --should probably provide a timeout on this that explicitly logs player out
    [[_credentialCallbacks currentGameView] presentViewController:alertController animated:YES completion:nil];
}


@end
