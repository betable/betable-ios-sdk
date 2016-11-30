//
//  BetableProfile.m
//  Betable.framework
//
//  Created by Tony hauber on 8/7/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AdSupport/ASIdentifierManager.h>
#import "BetableProfile.h"
#import "BetableHandlers.h"
#import "Betable.h"
#import "NSString+Betable.h"
#import "BetableUtils.h"
#import "Environment.h"

NSString* BetablePasteBoardAPIHostName = @"com.Betable.BetableSDK.sharedData.profile:APIHost";
NSString* BetablePasteBoardAuthHostName = @"com.Betable.BetableSDK.sharedData.profile:AuthHost";
NSString* BetablePasteBoardClientIDName = @"com.Betable.BetableSDK.sharedData.profile:ClientID";
NSString* BetablePasteBoardSignatureName = @"com.Betable.BetableSDK.sharedData.profile:Signature";
NSString* BetablePasteBoardExpiryName = @"com.Betable.BetableSDK.sharedData.profile:Expiry";

// If this exists it should be in Environment.h
#ifdef USE_LOCALHOST
// betable-id services
static NSString* const BetableAPIURL = @"http://localhost:8020";
// betable-players services --name matches cookie and should still resolve to localhost
static NSString* const BetableURL = @"http://players.dev.prospecthallcasino.com:8080";

#else
static NSString* const BetableAPIURL = @"https://api.betable.com/1.0";
static NSString* const BetableURL = @"https://prospecthallcasino.com";

#endif

#define SDK_VERSION @"1.0"

@interface BetableProfile (){
    NSString* _apiHost;
    NSString* _authHost;
    NSString* _signature;
    NSString* _expiry;
    NSString* _clientID;
}

@end

@implementation BetableProfile

- (id)init {
    self = [super init];
    if (self) {
        _signature = [self stringFromSharedDataWithKey:BetablePasteBoardSignatureName];
        _clientID = [self stringFromSharedDataWithKey:BetablePasteBoardClientIDName];
        _apiHost = [self stringFromSharedDataWithKey:BetablePasteBoardAPIHostName];
        _authHost = [self stringFromSharedDataWithKey:BetablePasteBoardAuthHostName];
        _expiry = [self stringFromSharedDataWithKey:BetablePasteBoardExpiryName];
    }
    return self;
}

- (void)removeProfile {
    _apiHost = nil;
    _authHost = nil;
    _signature = nil;
    _expiry = nil;
    _clientID = nil;
    [[self sharedDataWithKey:BetablePasteBoardSignatureName] setString:@""];
    [[self sharedDataWithKey:BetablePasteBoardClientIDName] setString:@""];
    [[self sharedDataWithKey:BetablePasteBoardAPIHostName] setString:@""];
    [[self sharedDataWithKey:BetablePasteBoardAuthHostName] setString:@""];
    [[self sharedDataWithKey:BetablePasteBoardExpiryName] setString:@""];
}

- (NSURL*)apiURL {
    return [NSURL URLWithString:[BetableAPIURL copy]];
}

- (NSURL*)betableURL {
    return [NSURL URLWithString:[BetableURL copy]];
}

#pragma mark - Shared data stuff

- (NSString*)stringFromSharedDataWithKey:(NSString*)name {
    return [[self sharedDataWithKey:name] string];
}

- (UIPasteboard*)sharedDataWithKey:(NSString*)name {
    UIPasteboard* sharedData = [UIPasteboard pasteboardWithName:name create:YES];
    sharedData.persistent = YES;
    return sharedData;
}

- (BOOL)hasProfile {
    return [_signature length] && [_clientID length] && [_apiHost length] && [_authHost length];
}

#pragma mark - Web Stuff

- (void)fireGenericAsynchronousRequest:(NSURLRequest*)request onSuccess:(BetableCompletionHandler)onSuccess onFailure:(BetableFailureHandler)onFailure {

    void (^ onComplete)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse* response, NSData* data, NSError* error) {
        NSString* responseBody = [[NSString alloc] initWithData:data
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
                        NSDictionary* data = (NSDictionary*)[responseBody objectFromJSONString];
                        onSuccess(data);
                    });
                } else {
                    NSDictionary* data = (NSDictionary*)[responseBody objectFromJSONString];
                    onSuccess(data);
                }
            }
        }
    };

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:onComplete];
}

#pragma mark - Utilities
- (NSString*)urlEncode:(NSString*)string {
    NSString* encoded = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                             (CFStringRef)string,
                                                                                             NULL,
                                                                                             (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                             CFStringConvertNSStringEncodingToEncoding(NSASCIIStringEncoding)));
    return encoded;
}

- (NSURL*)urlForDomain:(NSString*)urlString andQuery:(NSDictionary*)queryDict {

    NSInteger paramDelimiterIndex = [urlString rangeOfString:@"?"].location;

    NSMutableArray* parts = [NSMutableArray array];
    for (NSString* key in queryDict) {
        NSString* value = [queryDict objectForKey:key];
        NSString* part = [NSString stringWithFormat:@"%@=%@", [self urlEncode:key], [self urlEncode:value]];

        NSInteger partIndex = [urlString rangeOfString:part].location;
        if (paramDelimiterIndex != NSNotFound && partIndex != NSNotFound && paramDelimiterIndex < partIndex) {
            // skip this part--its duplicate and some parameters need to really not be an array of duplicates
            // ...looking at you client_id and session_id
            continue;
        }

        if (NILIFY(value)) {
            [parts addObject:part];
        }
    }

    // Don't bother modifying urlString if there are no parts to append
    if ([parts count] > 0) {
        // Our url/query divider may not be '?' if the url already contains a divider (and other query parameters)
        unichar divider = paramDelimiterIndex == NSNotFound ? '?' : '&';

        urlString = [NSString stringWithFormat:@"%@%C%@", urlString, divider, [parts componentsJoinedByString:@"&"]];

    }
    return [NSURL URLWithString:urlString];
}

- (NSString*)simpleURL:(NSString*)path withParams:(NSDictionary* _Nonnull)params {
    NSString* url = [NSString stringWithFormat:@"%@%@", BetableURL, path];
    NSString* fullURL = [[self urlForDomain:url andQuery:params] absoluteString];
    return fullURL;
}

- (NSString*)decorateURL:(NSString*)path forClient:(NSString*)clientID withParams:(NSDictionary*)aParams {
    NSMutableDictionary* params = [aParams mutableCopy];
    if (params == nil) {
        params = [NSMutableDictionary dictionary];
    }

    params[@"client_id"] = clientID;

    NSString* IDFA = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    if (IDFA) {
        params[@"device_identifier"] = IDFA;
    }

    params[@"sdk_version"] = SDK_VERSION;

    return [self simpleURL:path withParams:params];
}

- (NSString*)decorateTrackURLForClient:(NSString*)clientID withAction:(NSString*)action andParams:(NSDictionary*)aParams {
    NSMutableDictionary* params = [aParams mutableCopy];
    if (params == nil) {
        params = [NSMutableDictionary dictionary];
    }
    [params setObject:action forKey:@"action"];
    return [self decorateURL:@"/track" forClient:clientID withParams:params];
}

- (NSString*)decorateTrackURLForClient:(NSString*)clientID withAction:(NSString*)action {
    return [self decorateTrackURLForClient:clientID withAction:action andParams:nil];
}

# pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 0) {
        [self removeProfile];
    }
}

@end
