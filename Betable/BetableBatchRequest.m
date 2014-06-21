//
//  BetableBatchRequest.m
//  Betable.framework
//
//  Created by Tony hauber on 7/18/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import "BetableBatchRequest.h"
#import "Betable.h"
#import "NSDictionary+Betable.h"
#import "NSString+Betable.h"

@implementation BetableBatchRequest

NSString const *BetableBatchURL = @"https://api.betable.com";
NSString const *BetableBatchVersion = @"1.0";

- (id)initWithBetable:(Betable*)betable {
    self = [self init];
    if (self) {
        self.betable = betable;
        self.requests = [NSMutableArray array];
    }
    return self;
}
- (NSMutableDictionary* )betForGame:(NSString*)gameID
          withData:(NSDictionary*)data
          withName: (NSString*)name {
    NSString *path = [Betable getBetPath:gameID];
    NSMutableDictionary *request = [self createRequestWithPath:path method:@"POST" name:name dependencies:nil data:data];
    [self addRequest:request];
    return request;
}
- (NSMutableDictionary* )unbackedBetForGame:(NSString*)gameID
                  withData:(NSDictionary*)data
                  withName: (NSString*)name {
    NSString *path = [Betable getUnbackedBetPath:gameID];
    NSMutableDictionary *request = [self createRequestWithPath:path method:@"POST" name:name dependencies:nil data:data];
    [self addRequest:request];
    return request;
}
- (NSMutableDictionary* )creditBetForGame:(NSString*)gameID
                                creditGame:(NSString*)creditGameID
                                 withData:(NSDictionary*)data
                                 withName: (NSString*)name {
    NSString *gameAndBonusID = [NSString stringWithFormat:@"%@/%@", gameID, creditGameID];
    return [self betForGame:gameAndBonusID withData:data withName:name];
}
- (NSMutableDictionary* )unbackedCreditBetForGame:(NSString*)gameID
                                        creditGame:(NSString*)creditGameID
                                         withData:(NSDictionary*)data
                                         withName: (NSString*)name {
    NSString *gameAndBonusID = [NSString stringWithFormat:@"%@/%@", gameID, creditGameID];
    return [self unbackedBetForGame:gameAndBonusID withData:data withName:name];
}
- (NSMutableDictionary* )getUserWalletWithName:(NSString*)name {
    NSString *path = [Betable getWalletPath];
    NSMutableDictionary *request = [self createRequestWithPath:path method:@"GET" name:name dependencies:nil data:nil];
    [self addRequest:request];
    return request;
}

- (NSMutableDictionary* )getUserAccountWithName:(NSString*)name {
    NSString *path = [Betable getAccountPath];
    NSMutableDictionary *request = [self createRequestWithPath:path method:@"GET" name:name dependencies:nil data:nil];
    [self addRequest:request];
    return request;
}

- (NSMutableDictionary* )createRequestWithPath:(NSString*)path method:(NSString*)method name:(NSString*)name dependencies:(NSArray*)dependnecies data:(NSDictionary*)data {
    NSMutableDictionary *request = [NSMutableDictionary dictionaryWithCapacity:5];
    request[@"url"] = path;
    request[@"method"] = method;
    if (name) {
        request[@"name"] = name;
    }
    if (dependnecies && [dependnecies count]) {
        request[@"depends_on"] = dependnecies;
    }
    if (data) {
        request[@"body"] = data;
    }
    return request;
}

- (void)addRequest:(NSDictionary*)request {
    [self.requests addObject:request];
}

- (void)runBatchOnComplete:(BetableCompletionHandler)onSuccess onFailure:(BetableFailureHandler)onFailure{
    [self.betable checkAccessToken:@"Run Batch"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[BetableBatchRequest betableBatchURL:self.betable.accessToken]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[@{@"requests": self.requests} JSONData]];
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
                        for (NSMutableDictionary *response in data[@"responses"]) {
                            response[@"body"] = [response[@"body"] objectFromJSONString];
                        }
                        onSuccess(data);
                    });
                } else {
                    NSDictionary *data = (NSDictionary*)[responseBody objectFromJSONString];
                    for (NSMutableDictionary *response in data[@"responses"]) {
                        response[@"body"] = [response[@"body"] objectFromJSONString];
                    }
                    onSuccess(data);
                }
            }
        }
    };
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.betable.queue completionHandler:onComplete];
}

+ (NSURL*)betableBatchURL:(NSString*)accessToken {
    NSString *stringURL = [NSString stringWithFormat:@"%@/%@/batch?access_token=%@", BetableBatchURL, BetableBatchVersion, accessToken];
    return [NSURL URLWithString:stringURL];
}
@end
