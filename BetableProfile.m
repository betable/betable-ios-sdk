//
//  BetableProfile.m
//  Betable.framework
//
//  Created by Tony hauber on 8/7/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BetableProfile.h"
#import "BetableHandlers.h"
#import "Betable.h"

NSString *BetablePasteBoardAPIHostName = @"com.Betable.BetableSDK.sharedData.profile:APIHost";
NSString *BetablePasteBoardAuthHostName = @"com.Betable.BetableSDK.sharedData.profile:AuthHost";
NSString *BetablePasteBoardClientIDName = @"com.Betable.BetableSDK.sharedData.profile:ClientID";
NSString *BetablePasteBoardSignatureName = @"com.Betable.BetableSDK.sharedData.profile:Signature";
NSString *BetablePasteBoardExpiryName = @"com.Betable.BetableSDK.sharedData.profile:Expiry";
NSString const *BetableAPIURL = @"https://api.betable.com/1.0";
NSString const *BetableAuthorizeURL = @"https://betable.com/track?action=register";
NSString const *BetableVerifyURL = @"developers.betable.com";

@interface BetableProfile() {
    NSString *_apiHost;
    NSString *_authHost;
    NSString *_signature;
    NSString *_expiry;
    NSString *_clientID;
    BOOL _verified;
    BOOL _loadedVerification;
}

@end
    
@implementation BetableProfile

@synthesize loadedVerification = _loadedVerification;

- (id)init {
    self = [super init];
    if (self) {
        _signature = [self stringFromSharedDataWithKey:BetablePasteBoardSignatureName];
        _clientID = [self stringFromSharedDataWithKey:BetablePasteBoardClientIDName];
        _apiHost = [self stringFromSharedDataWithKey:BetablePasteBoardAPIHostName];
        _authHost = [self stringFromSharedDataWithKey:BetablePasteBoardAuthHostName];
        _expiry = [self stringFromSharedDataWithKey:BetablePasteBoardExpiryName];
        _verified = NO;
        _loadedVerification = NO;
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

- (void)verify:(void(^)(void))onComplete {
    if (self.hasProfile) {
        NSLog(@"Using Profile API Host:%@ Auth Host:%@", _apiHost, _authHost);
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self verifyProfileURL]];
        [self fireGenericAsynchronousRequest:request onSuccess:^(NSDictionary *data) {
            NSLog(@"Profile Verification Loaded: %@", data);
            _verified = [data[@"verified"] boolValue];
            _loadedVerification = YES;
            [[[UIAlertView alloc] initWithTitle:@"Betable Profile" message:@"You are using a betable profile. If you do not know what this means then you are likely seeing this by mistake. Please remove the profile by tapping the remove button." delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:@"Remove", nil] show];
            onComplete();
        } onFailure:^(NSURLResponse *response, NSString *responseBody, NSError *error) {
            
            NSLog(@"Verifcation Failed:%@", error);
            _verified = NO;
            _loadedVerification = YES;
            onComplete();
        }];
    } else {
        onComplete();
    }
}

- (NSURL*)apiURL {
    if (self.hasProfile) {
        if (!_loadedVerification) {
            [NSException raise:@"Verification not loaded"
                        format:@"Trying to access Auth URL before verification has been loaded"];
        } else if (_verified) {
            NSString *urlString = [NSString stringWithFormat:@"http://%@", _apiHost];
            return [NSURL URLWithString:urlString];
        }
    }
    return [NSURL URLWithString:[BetableAPIURL copy]];
}

- (NSURL*)authURL {
    if (self.hasProfile) {
        if (!_loadedVerification) {
            [NSException raise:@"Verification not loaded"
                        format:@"Trying to access Auth URL before verification has been loaded"];
        } else if (_verified) {
            NSString *urlString = [NSString stringWithFormat:@"http://%@/authorize", _authHost];
            return [NSURL URLWithString:urlString];
        }
    }
    return [NSURL URLWithString:[BetableAuthorizeURL copy]];
}

#pragma mark - Shared data stuff

- (NSString*)stringFromSharedDataWithKey:(NSString*)name {
    return [[self sharedDataWithKey:name] string];
}

- (UIPasteboard *)sharedDataWithKey:(NSString*)name {
    UIPasteboard *sharedData = [UIPasteboard pasteboardWithName:name create:YES];
    sharedData.persistent = YES;
    return sharedData;
}

- (BOOL)hasProfile {
    return [_signature length] && [_clientID length] && [_apiHost length] && [_authHost length];
}

#pragma mark - Web Stuff

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
                } else {
                    NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
                    onSuccess(data);
                }
            } else {
                NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
                onSuccess(data);
            }
        }
    };
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:onComplete];
}

- (NSURL*)verifyProfileURL {
    NSDictionary *params = @{
                             @"signature":_signature,
                             @"expiry":_expiry,
                             @"api_url":_apiHost,
                             @"auth_url":_authHost,
                             @"client_id":_clientID
                             };
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/profiles/verification/", BetableVerifyURL];
    return [self urlForDomain:urlString andQuery:params];
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

- (NSURL*)urlForDomain:(NSString*)urlString andQuery:(NSDictionary*)queryDict {
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *key in queryDict) {
        NSString *value = [queryDict objectForKey:key];
        NSString *part = [NSString stringWithFormat: @"%@=%@", [self urlEncode:key], [self urlEncode:value]];
        [parts addObject: part];
    }
    urlString = [NSString stringWithFormat:@"%@?%@", urlString, [parts componentsJoinedByString: @"&"]];
    return [NSURL URLWithString:urlString];
}

# pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 0) {
        [self removeProfile];
    }
}
@end
