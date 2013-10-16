//
//  BetableBatchRequest.h
//  Betable.framework
//
//  Created by Tony hauber on 7/18/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BetableHandlers.h"

@class Betable;

@interface BetableBatchRequest : NSObject

@property (strong, nonatomic) Betable *betable;
@property (strong, nonatomic) NSMutableArray *requests;

- (id)initWithBetable:(Betable*)betable;
- (NSMutableDictionary* )betForGame:(NSString*)gameID
                           withData:(NSDictionary*)data
                           withName: (NSString*)name;
- (NSMutableDictionary* )unbackedBetForGame:(NSString*)gameID
                                   withData:(NSDictionary*)data
                                   withName: (NSString*)name;
- (NSMutableDictionary* )createRequestWithPath:(NSString*)path
                                        method:(NSString*)method
                                          name:(NSString*)name
                                  dependencies:(NSArray*)dependnecies
                                          data:(NSDictionary*)data;
- (NSMutableDictionary* )creditBetForGame:(NSString*)gameID
                                creditGame:(NSString*)creditGameID
                                 withData:(NSDictionary*)data
                                 withName: (NSString*)name;
- (NSMutableDictionary* )unbackedCreditBetForGame:(NSString*)gameID
                                        creditGame:(NSString*)creditGameID
                                         withData:(NSDictionary*)data
                                         withName: (NSString*)name;
- (NSMutableDictionary* )getUserWalletWithName:(NSString*)name;
- (NSMutableDictionary* )getUserAccountWithName:(NSString*)name;

- (void)addRequest:(NSDictionary*)request;
+ (NSURL*)betableBatchURL:(NSString*)accessToken;
- (void)runBatchOnComplete:(BetableCompletionHandler)onSuccess onFailure:(BetableFailureHandler)onFailure;
@end
