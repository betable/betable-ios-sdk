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
#import "BetableWebViewController.h"

NSString *BetablePasteBoardUserIDKey = @"com.Betable.BetableSDK.sharedData:UserID";
NSString *BetablePasteBoardName = @"com.Betable.BetableSDK.sharedData";
NSString const *BetableAPIURL = @"https://api.betable.com/";
NSString const *BetableAuthorizeURL = @"https://www.betable.com/authorize";
NSString const *BetableVersion = @"1.0";
NSString const *BetableNativeAuthorizeURL = @"betable-ios://authorize";


@interface NSDictionary (BetableJSON)


- (NSData*)JSONData;

@end
@implementation NSDictionary (BetableJSON)
- (NSData*)JSONData {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:0
                                                         error:&error];
    if (!jsonData) {
        return nil;
    } else if (!error) {
        return jsonData;
    }
    [NSException raise:@"JSON is not formated correctly"
                format:@"The JSON returned from the server was improperly formated"];
    return nil;
}

@end
@interface NSString (BetableJSON)


- (NSObject*)objectFromJSONString;

@end
@implementation NSString (BetableJSON)

- (NSObject*)objectFromJSONString {
    NSData *JSONdata = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError = nil;
    if (JSONdata != nil) {
        NSObject *object = [NSJSONSerialization JSONObjectWithData:JSONdata options:0 error:&jsonError];
        if (jsonError == nil) {
            return object;
        }
        [NSException raise:@"JSON is not formated correctly"
                    format:@"The JSON returned from the server was improperly formated"];
    }
    return nil;
}

@end

@interface Betable ()
- (NSString *)urlEncode:(NSString*)string;
- (NSURL*)getAPIWithURL:(NSString*)urlString;
- (void)checkAccessToken;
+ (NSString*)base64forData:(NSData*)theData;

@end

@implementation Betable

@synthesize accessToken, clientID, clientSecret, redirectURI, queue, currentWebView;

- (Betable*)init {
    self = [super init];
    if (self) {
        clientID = nil;
        clientSecret = nil;
        redirectURI = nil;
        accessToken = nil;
        self.queue = [[NSOperationQueue alloc] init];
    }
    return self;
}
- (Betable*)initWithClientID:(NSString*)aClientID clientSecret:(NSString*)aClientSecret redirectURI:(NSString*)aRedirectURI {
    self = [self init];
    if (self) {
        self.clientID = aClientID;
        self.clientSecret = aClientSecret;
        self.redirectURI = aRedirectURI;
        [self setupAuthorizeWebView];
    }
    return self;
}

- (UIPasteboard *)sharedData {
        UIPasteboard *sharedData = [UIPasteboard pasteboardWithName:BetablePasteBoardName create:YES];
      sharedData.persistent = YES;
    return sharedData;
}

- (NSString*)stringFromSharedDataWithKey:(NSString*)key {
    NSData *valueData = [[self sharedData] dataForPasteboardType:BetablePasteBoardUserIDKey];
    return [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
}

- (void)setupAuthorizeWebView {
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString* UUID = [NSString stringWithFormat:@"%@", UUIDSRef];
    NSString* urlFormat = @"%@?client_id=%@&redirect_uri=%@&state=%@&response_type=code";
    NSString *authURL = [NSString stringWithFormat:urlFormat,
                         BetableAuthorizeURL,
                         [self urlEncode:clientID],
                         [self urlEncode:redirectURI],
                         UUID];
    NSString *nativeAuthURL = [NSString stringWithFormat:urlFormat,
                               BetableNativeAuthorizeURL,
                               [self urlEncode:clientID],
                               [self urlEncode:redirectURI],
                               UUID];
    
    
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:nativeAuthURL]] == YES) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nativeAuthURL]];
    } else {
        self.currentWebView = [[BetableWebViewController alloc] initWithURL:authURL onCancel:nil];
    }
    CFRelease(UUIDRef);
    CFRelease(UUIDSRef);
}

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
        [self token:[params objectForKey:@"code"]];
        [self.currentWebView.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)token:(NSString*)code {
    NSURL *apiURL = [NSURL URLWithString:[Betable getTokenURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:apiURL];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", clientID, clientSecret];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [Betable base64forData:authData]];
    [request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:authValue forKey:@"Authorization"]];
    
    [request setHTTPMethod:@"POST"]; 
    NSString *body = [NSString stringWithFormat:@"grant_type=authorization_code&redirect_uri=%@&code=%@",
                      [self urlEncode:redirectURI],
                      code];

    void (^onComplete)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        
        if (error) {
            if (self.onFailure) {
                if (![NSThread isMainThread]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.onFailure(response, responseBody, error);
                    });
                } else {
                    self.onFailure(response, responseBody, error);
                }
            }
        } else {
            NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
            NSString *newAccessToken = [data objectForKey:@"access_token"];
            self.accessToken = newAccessToken;
            if (self.onAuthorize) {
                if (![NSThread isMainThread]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.onAuthorize(accessToken);
                    });
                }
            }
            [self userAccountOnComplete:^(NSDictionary *data) {
                NSString *userID = data[@"id"];
                [[self sharedData] setValue:userID forPasteboardType:BetablePasteBoardUserIDKey];
            } onFailure:^(NSURLResponse *response, NSString *responseBody, NSError *error) {
                
            }];
        }
    };
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.queue
                           completionHandler:onComplete
    ];
}

- (void)unbackedToken:(NSString*)clientUserID onComplete:(BetableAccessTokenHandler)onComplete onFailure:(BetableFailureHandler)onFailure {
    NSURL *apiURL = [NSURL URLWithString:[Betable getTokenURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:apiURL];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", clientID, clientSecret];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [Betable base64forData:authData]];
    [request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:authValue forKey:@"Authorization"]];
    
    [request setHTTPMethod:@"POST"];
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
                                   self.accessToken = [data objectForKey:@"access_token"];
                                   onComplete(self.accessToken);
                               }
                           }
     ];
}


#pragma mark - External Methods

- (void)authorizeInViewController:(UIViewController*)viewController onAuthorizationComplete:(BetableAccessTokenHandler)onAuthorize onFailure:(BetableFailureHandler)onFailure onCancel:(BetableCancelHandler)onCancel {
    self.currentWebView.onCancel = onCancel;
    self.onAuthorize = onAuthorize;
    self.onFailure = onFailure;
    [viewController presentViewController:self.currentWebView animated:YES completion:nil];
}
- (void)checkAccessToken {
    if (self.accessToken == nil) {
        [NSException raise:@"User is not authorized"
                    format:@"User must have an access token to use this feature"];
    }
}
- (void)betForGame:(NSString*)gameID
          withData:(NSDictionary*)data
        onComplete:(BetableCompletionHandler)onComplete
         onFailure:(BetableFailureHandler)onFailure {
    [self checkAccessToken];
    NSURL *apiURL = [self getAPIWithURL:[Betable getBetURL:gameID]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:apiURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[data JSONData]];
    [self fireGenericAsynchronousRequest:request onSuccess:onComplete onFailure:onFailure];
}
- (void)unbackedBetForGame:(NSString*)gameID
          withData:(NSDictionary*)data
        onComplete:(BetableCompletionHandler)onComplete
         onFailure:(BetableFailureHandler)onFailure {
    [self checkAccessToken];
    NSURL *apiURL = [self getAPIWithURL:[Betable getUnbackedBetURL:gameID]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:apiURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[data JSONData]];
    [self fireGenericAsynchronousRequest:request onSuccess:onComplete onFailure:onFailure];
}
- (void)userAccountOnComplete:(BetableCompletionHandler)onComplete
                    onFailure:(BetableFailureHandler)onFailure{
    [self checkAccessToken];
    NSURL *apiURL = [self getAPIWithURL:[Betable getAccountURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:apiURL];
    [request setHTTPMethod:@"GET"];
    [self fireGenericAsynchronousRequest:request onSuccess:onComplete onFailure:onFailure];
}
- (void)userWalletOnComplete:(BetableCompletionHandler)onComplete
                   onFailure:(BetableFailureHandler)onFailure {
    [self checkAccessToken];
    NSURL *apiURL = [self getAPIWithURL:[Betable getWalletURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:apiURL];
    [request setHTTPMethod:@"GET"];
    [self fireGenericAsynchronousRequest:request onSuccess:onComplete onFailure:onFailure];
}

- (void)logout {
    //Get the cookie jar
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [cookieJar cookies]) {
        [cookie.domain rangeOfString:@"betable.com"];
        [cookieJar deleteCookie:cookie];
    }
    //After the cookies are destroyed, reload the webpage
    [self setupAuthorizeWebView];
}
                         
#pragma mark - URL getters
                         
+ (NSString*) getAuthURL {
    return [NSString stringWithFormat:@"%@", BetableAuthorizeURL];
}
+ (NSString*) getTokenURL {
    return [NSString stringWithFormat:@"%@%@/token", BetableAPIURL, BetableVersion];
}
+ (NSString*) getBetURL:(NSString*)gameID {
    return [NSString stringWithFormat:@"%@%@/games/%@/bet", BetableAPIURL, BetableVersion, gameID];
}
+ (NSString*) getWalletURL{
    return [NSString stringWithFormat:@"%@%@/account/wallet", BetableAPIURL, BetableVersion];
}
+ (NSString*) getAccountURL{
    return [NSString stringWithFormat:@"%@%@/account", BetableAPIURL, BetableVersion];
}
+ (NSString*) getUnbackedBetURL:(NSString*)gameID {
    return [NSString stringWithFormat:@"%@%@/games/%@/unbacked-bet", BetableAPIURL, BetableVersion, gameID];
}
- (NSString*)urlEncode:(NSString*)string {
    NSString *encoded = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)string,
                                                               NULL,
                                                               (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                               CFStringConvertNSStringEncodingToEncoding(NSASCIIStringEncoding)));
    return encoded;
}
- (NSURL*)getAPIWithURL:(NSString*)urlString {
    urlString = [NSString stringWithFormat:@"%@?access_token=%@", urlString, self.accessToken];
    return [NSURL URLWithString:urlString];
}
                         
                         
#pragma mark - Utilities
                         
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

- (void)fireGenericAsynchronousRequest:(NSURLRequest*)request onSuccess:(BetableCompletionHandler)onSuccess onFailure:(BetableFailureHandler)onFailure{
    
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
                }
            }
        }
    };
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:onComplete];
}
@end
