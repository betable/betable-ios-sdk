//
//  Betable.m
//  TestApp
//
//  Created by Tony Hauber on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "Betable.h"
#import "JSONKit.h"
NSString const *BetableAPIURL = @"https://api.betable.com/";
NSString const *BetableAuthorizeURL = @"https://www.betable.com/authorize";
NSString const *BetableVersion = @"1.0";

@interface Betable ()
- (NSString *)urlEncode:(NSString*)string;
- (NSURL*)getAPIWithURL:(NSString*)urlString;
- (void)checkAccessToken;
+ (NSString*)base64forData:(NSData*)theData;

@end

@implementation Betable

@synthesize accessToken, clientID, clientSecret, redirectURI, queue;

- (Betable*)init {
    self = [super init];
    if (self) {
        clientID = nil;
        clientSecret = nil;
        redirectURI = nil;
        accessToken = nil;
        self.queue = [[[NSOperationQueue alloc] init] autorelease];
    }
    return self;
}
- (Betable*)initWithClientID:(NSString*)aClientID clientSecret:(NSString*)aClientSecret redirectURI:(NSString*)aRedirectURI {
    self = [self init];
    if (self) {
        self.clientID = aClientID;
        self.clientSecret = aClientSecret;
        self.redirectURI = aRedirectURI;
    }
    return self;
}
- (void)authorize {
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString* UUID = [NSString stringWithFormat:@"%@", UUIDSRef];
    NSString* urlFormat = @"%@?client_id=%@&redirect_uri=%@&state=%@&response_type=code";
    NSString *authURL = [NSString stringWithFormat:urlFormat,
                         BetableAuthorizeURL,
                         [self urlEncode:clientID],
                         [self urlEncode:redirectURI],
                         UUID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:authURL]];
    
    CFRelease(UUIDRef);
    CFRelease(UUIDSRef);
}
- (void)token:(NSString*)code onComplete:(BetableAccessTokenHandler)onComplete onFailure:(BetableFailureHandler)onFailure {
    NSURL *apiURL = [NSURL URLWithString:[Betable getTokenURL]];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:apiURL] autorelease];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", clientID, clientSecret];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [Betable base64forData:authData]];
    [request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:authValue forKey:@"Authorization"]];
    
    [request setHTTPMethod:@"POST"]; 
    NSString *body = [NSString stringWithFormat:@"grant_type=authorization_code&redirect_uri=%@&code=%@",
                      [self urlEncode:redirectURI],
                      code];

    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSString *responseBody = [[NSString alloc] initWithData:data
                                                                              encoding:NSUTF8StringEncoding];
                               [responseBody autorelease];
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
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:apiURL] autorelease];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[data JSONData]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSString *responseBody = [[NSString alloc] initWithData:data
                                                                              encoding:NSUTF8StringEncoding];
                               [responseBody autorelease];
                               if (error) {
                                   onFailure(response, responseBody, error);
                               } else {
                                   NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
                                   onComplete(data);
                               }
                           }];
}
- (void)userAccountOnComplete:(BetableCompletionHandler)onComplete
                    onFailure:(BetableFailureHandler)onFailure{
    [self checkAccessToken];
    NSURL *apiURL = [self getAPIWithURL:[Betable getAccountURL]];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:apiURL] autorelease];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSString *responseBody = [[NSString alloc] initWithData:data
                                                                              encoding:NSUTF8StringEncoding];
                               [responseBody autorelease];
                               if (error) {
                                   onFailure(response, responseBody, error);
                               } else {
                                   NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
                                   onComplete(data);
                               }
                           }];
}
- (void)userWalletOnComplete:(BetableCompletionHandler)onComplete
                   onFailure:(BetableFailureHandler)onFailure {
    [self checkAccessToken];
    NSURL *apiURL = [self getAPIWithURL:[Betable getWalletURL]];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:apiURL] autorelease];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSString *responseBody = [[NSString alloc] initWithData:data
                                                                              encoding:NSUTF8StringEncoding];
                               [responseBody autorelease];
                               if (error) {
                                   onFailure(response, responseBody, error);
                               } else {
                                   NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
                                   onComplete(data);
                               }
                           }];
}

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
- (NSString*)urlEncode:(NSString*)string {
    NSString *encoded = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)string,
                                                               NULL,
                                                               (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                               CFStringConvertNSStringEncodingToEncoding(NSASCIIStringEncoding));
    return [encoded autorelease];
}
- (NSURL*)getAPIWithURL:(NSString*)urlString {
    urlString = [NSString stringWithFormat:@"%@?access_token=%@", urlString, self.accessToken];
    return [NSURL URLWithString:urlString];
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
    
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

- (void)dealloc {
    self.accessToken = nil;
    self.clientSecret = nil;
    self.clientID = nil;
    self.redirectURI = nil;
    self.queue = nil;
    [super dealloc];
}
@end
