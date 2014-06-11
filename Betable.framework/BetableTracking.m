//
//  BetableTracking.m
//  Betable.framework
//
//  Created by Tony hauber on 6/9/14.
//  Copyright (c) 2014 Tony hauber. All rights reserved.
//

#import "BetableTracking.h"
#import "BetableTrackingUtil.h"
#import "BetableTrackingHistory.h"
#import "NSData+BetableTracking.h"
#import "NSString+BetableTracking.h"
#import "UIDevice+BetableTracking.h"
#import "NSDictionary+BetableTracking.h"
#if !BETABLE_NO_IDA
#import <iAd/iAd.h>
#endif

static NSString   * const kHistoryFileName = @"BetableTrackingHistory";
static NSString   * const kBaseURL = @"https://api.next.betable.com/1.0/adjust/";
static const double kRequestTimeout = 60;


@interface BetableTracking()

@property (nonatomic, copy) NSString *appToken;
@property (nonatomic, copy) NSString *macSha1;
@property (nonatomic, copy) NSString *macShortMd5;
@property (nonatomic, copy) NSString *idForAdvertisers;
@property (nonatomic, copy) NSString *fbAttributionId;
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, copy) NSString *clientSdk;
@property (nonatomic, assign) BOOL trackingEnabled;
@property (nonatomic, assign) BOOL internalEnabled;
@property (nonatomic, assign) BOOL isIad;
@property (nonatomic, copy) NSString *vendorId;

@end

@implementation BetableTracking


/*
- (void)injectGeneralAttributes:()builder {
    builder.userAgent        = self.userAgent;
    builder.clientSdk        = self.clientSdk;
    builder.appToken         = self.appToken;
    builder.macSha1          = self.macSha1;
    builder.trackingEnabled  = self.trackingEnabled;
    builder.idForAdvertisers = self.idForAdvertisers;
    builder.fbAttributionId  = self.fbAttributionId;
    builder.environment      = self.environment;
    builder.isIad            = self.isIad;
    builder.vendorId         = self.vendorId;
    
    if (self.trackMacMd5) {
        builder.macShortMd5 = self.macShortMd5;
    }
}
*/


#pragma mark - internal
- (id)initWithClientID:(NSString *)clientID andEnvironment:(NSString*)environment {
    self = [self init];
    if (!self) return nil;
    NSString *macAddress = UIDevice.currentDevice.aiMacAddress;
    NSString *macShort = macAddress.aiRemoveColons;
    
    self.appToken         = clientID;
    self.macSha1          = macAddress.aiSha1;
    self.macShortMd5      = macShort.aiMd5;
    self.trackingEnabled  = UIDevice.currentDevice.aiTrackingEnabled;
    self.idForAdvertisers = UIDevice.currentDevice.aiIdForAdvertisers;
    self.fbAttributionId  = UIDevice.currentDevice.aiFbAttributionId;
    self.userAgent        = BetableTrackingUtil.userAgent;
    self.vendorId         = UIDevice.currentDevice.aiVendorId;
    
#if !BETABLE_NO_IDA
    if (NSClassFromString(@"ADClient")) {
        [ADClient.sharedClient determineAppInstallationAttributionWithCompletionHandler:^(BOOL appInstallationWasAttributedToiAd) {
            self.isIad = appInstallationWasAttributedToiAd;
        }];
    }
#endif
    return self;
}

- (BetableTrackingHistory*)loadHistory {
    NSString *filename = kHistoryFileName;
    id object = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
    if ([object isKindOfClass:[BetableTrackingHistory class]]) {
        return (BetableTrackingHistory*)object;
    }
    return nil;
}

- (void)writeHistory:(BetableTrackingHistory*)history {
    NSString *filename = kHistoryFileName;
    BOOL result = [NSKeyedArchiver archiveRootObject:history toFile:filename];
    if (result == YES) {
        [BetableTrackingUtil excludeFromBackup:filename];
    }
}

- (void)trackSession {
    double now = [NSDate.date timeIntervalSince1970];
    BetableTrackingHistory *history = [self loadHistory];
    if (history) {
        history.sessionCount++;
        history.createdAt = now;
        history.lastInterval = now - history.lastActivity;
    } else {
        history = [[BetableTrackingHistory alloc] initWithNow:now];
    }

    NSMutableDictionary *parameters = [history getParameters];
    [parameters parameterizeString:self.userAgent forKey:@"userAgent"];
    [parameters parameterizeString:self.clientSdk forKey:@"clientSdk"];
    [parameters parameterizeString:self.appToken forKey:@"appToken"];
    [parameters parameterizeString:self.macSha1 forKey:@"macSha1"];
    [parameters parameterizeBool:self.trackingEnabled forKey:@"trackingEnabled"];
    [parameters parameterizeString:self.idForAdvertisers forKey:@"idForAdvertisers"];
    [parameters parameterizeString:self.fbAttributionId forKey:@"fbAttributionId"];
    [parameters parameterizeString:self.environment forKey:@"environment"];
    [parameters parameterizeBool:self.isIad forKey:@"isIad"];
    [parameters parameterizeString:self.vendorId forKey:@"vendorId"];
}


- (NSMutableURLRequest *)sessionRequestWithParameters:(NSDictionary*)parameters{
    NSURL *url = [NSURL URLWithString:@"/startup" relativeToURL:[NSURL URLWithString:kBaseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = kRequestTimeout;
    request.HTTPMethod = @"POST";
    
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:self.clientSdk forHTTPHeaderField:@"Client-Sdk"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    [request setHTTPBody:[self bodyForParameters:parameters]];
    
    return request;
}

- (NSData *)bodyForParameters:(NSDictionary *)parameters {
    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *key in parameters) {
        NSString *value = [parameters objectForKey:key];
        NSString *escapedValue = [value aiUrlEncode];
        NSString *pair = [NSString stringWithFormat:@"%@=%@", key, escapedValue];
        [pairs addObject:pair];
    }
    
    double now = [NSDate.date timeIntervalSince1970];
    NSString *dateString = [BetableTrackingUtil dateFormat:now];
    NSString *escapedDate = [dateString aiUrlEncode];
    NSString *sentAtPair = [NSString stringWithFormat:@"%@=%@", @"sent_at", escapedDate];
    [pairs addObject:sentAtPair];
    
    NSString *bodyString = [pairs componentsJoinedByString:@"&"];
    NSData *body = [NSData dataWithBytes:bodyString.UTF8String length:bodyString.length];
    return body;
}



@end
