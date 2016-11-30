//
//  BetableTrackingHistory.h
//  Betable.framework
//
//  Created by Tony hauber on 6/10/14.
//  Copyright (c) 2014 Tony hauber. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BetableTrackingHistory : NSObject

// persistent data
@property (nonatomic, copy) NSString* uuid;
@property (nonatomic) BOOL enabled;

// global counters
@property (nonatomic) int eventCount;
@property (nonatomic) int sessionCount;

// session attributes
@property (nonatomic) int subsessionCount;
@property (nonatomic) double sessionLength; // all durations in seconds
@property (nonatomic) double timeSpent;
@property (nonatomic) double lastActivity;  // all times in seconds since 1970
@property (nonatomic) double createdAt;

// last ten transaction identifiers
@property (nonatomic, strong) NSMutableArray* transactionIds;

// not persisted, only injected
@property (nonatomic) double lastInterval;

- (id)initWithNow:(double)now;
- (NSMutableDictionary*)getParameters;
@end
