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
#import "NSString+Betable.h"
#if !BETABLE_NO_IDA
#import <iAd/iAd.h>
#endif

static NSString   * const kHistoryFileName = @"BetableTrackingHistory";

static NSString   * const kBaseURL = @"https://api.betable.com";
//static NSString   * const kBaseURL = @"https://app.adjust.io";

static const double kRequestTimeout = 60;
static NSString * const kClientSdk = @"ios3.3.2";



@interface BetableTracking() {
}

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
@property (nonatomic, copy) NSString *historyStateFileName;

@end

@implementation BetableTracking

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
    self.clientSdk        = kClientSdk;
    self.environment      = environment;
    
#if !BETABLE_NO_IDA
    if (NSClassFromString(@"ADClient")) {
        [ADClient.sharedClient determineAppInstallationAttributionWithCompletionHandler:^(BOOL appInstallationWasAttributedToiAd) {
            self.isIad = appInstallationWasAttributedToiAd;
        }];
    }
#endif
    
    return self;
}

- (NSString *)historyStateFileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filename = [path stringByAppendingPathComponent:kHistoryFileName];
    return filename;
}

- (BetableTrackingHistory*)loadHistory {
    NSString *filename = self.historyStateFileName;
    id object = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
    if ([object isKindOfClass:[BetableTrackingHistory class]]) {
        return (BetableTrackingHistory*)object;
    } else if (object) {
        NSLog(@"Loaded a bad history");
    }
    return nil;
}

- (void)writeHistory:(BetableTrackingHistory*)history {
    NSString *filename = self.historyStateFileName;
    BOOL result = [NSKeyedArchiver archiveRootObject:history toFile:filename];
    if (result == YES) {
        [BetableTrackingUtil excludeFromBackup:filename];
    } else {
        NSLog(@"Incapable of writing tracking history");
    }
}

- (void)trackSession {
    NSLog(@"Logging Session");
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:16];
    [parameters parameterizeString:self.userAgent forKey:@"user_agent"];
    [parameters parameterizeString:self.clientSdk forKey:@"client_sdk"];
    [parameters parameterizeString:self.appToken forKey:@"app_token"];
    [parameters parameterizeString:self.macSha1 forKey:@"mac_sha1"];
    [parameters parameterizeString:self.macShortMd5 forKey:@"mac_md5"];
    [parameters parameterizeBool:self.trackingEnabled forKey:@"tracking_enabled"];
    [parameters parameterizeString:self.idForAdvertisers forKey:@"idfa"];
    [parameters parameterizeString:self.fbAttributionId forKey:@"fb_id"];
    [parameters parameterizeString:self.environment forKey:@"environment"];
    [parameters parameterizeBool:self.isIad forKey:@"is_iad"];
    [parameters parameterizeString:self.vendorId forKey:@"idfv"];
    [self performSelectorInBackground:@selector(trackSessionInBackground:) withObject:parameters];
}
- (void)trackSessionInBackground:(NSMutableDictionary*)parameters {
    double now = [NSDate.date timeIntervalSince1970];
    BetableTrackingHistory *history = [self loadHistory];
    if (history) {
        history.sessionCount++;
        history.createdAt = now;
        history.lastInterval = now - history.lastActivity;
    } else {
        history = [[BetableTrackingHistory alloc] initWithNow:now];
    }
    [self writeHistory:history];
    [parameters addEntriesFromDictionary:[history getParameters]];
    NSURLResponse *response;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:[self sessionRequestWithParameters:parameters] returningResponse:&response error:&error];
    if (error) {
        NSLog(@"Error while trying to track startup:");
        NSLog(@"<Error> %@", error);
    } else {
        NSLog(@"Succesful Post");
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        NSDictionary *jsonBody = (NSDictionary*)[responseBody objectFromJSONString];
        NSLog(@"body:%@", jsonBody);
    }

}


- (NSMutableURLRequest *)sessionRequestWithParameters:(NSDictionary*)parameters{
    NSURL *url = [NSURL URLWithString:@"/1.0/adjust/startup" relativeToURL:[NSURL URLWithString:kBaseURL]];
    //NSURL *url = [NSURL URLWithString:@"startup" relativeToURL:[NSURL URLWithString:kBaseURL]];
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
