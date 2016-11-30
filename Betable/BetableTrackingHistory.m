//
//  BetableTrackingHistory.m
//  Betable.framework
//
//  Created by Tony hauber on 6/10/14.
//  Copyright (c) 2014 Tony hauber. All rights reserved.
//

#import "BetableTrackingHistory.h"
#import "BetableTrackingUtil.h"
#import "UIDevice+BetableTracking.h"
#import "NSDictionary+BetableTracking.h"

@interface NSMutableDictionary (Private)


- (void)setRealObject:(id)value forKey:(NSString*)key;
@end

@implementation NSMutableDictionary (private)

- (void)setRealObject:(id)object forKey:(NSString*)key {
    if (object != nil) {
        [self setObject:object forKey:key];
    }
}

@end

@implementation BetableTrackingHistory

- (id)init {
    self = [self initWithNow:[NSDate.date timeIntervalSince1970]];
    if (self == nil) return nil;
    return self;
}

- (id)initWithNow:(double)now {
    self = [super init];
    if (self == nil) return nil;

    self.eventCount = 1;
    self.sessionCount = 1;
    self.subsessionCount = 1;
    self.sessionLength = 0;
    self.timeSpent = 0;
    self.lastActivity = now;
    self.createdAt = now;
    self.lastInterval = -1;
    self.lastInterval = -1;
    self.enabled = YES;
    self.uuid = [UIDevice.currentDevice aiCreateUuid];

    return self;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"ec:%d sc:%d ssc:%d sl:%.1f ts:%.1f la:%.1f",
            self.eventCount, self.sessionCount, self.subsessionCount, self.sessionLength,
            self.timeSpent, self.lastActivity];
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder*)decoder {
    self = [self init];
    if (self == nil) return nil;

    self.eventCount = [decoder decodeIntForKey:@"eventCount"];
    self.sessionCount = [decoder decodeIntForKey:@"sessionCount"];
    self.subsessionCount = [decoder decodeIntForKey:@"subsessionCount"];
    self.sessionLength = [decoder decodeDoubleForKey:@"sessionLength"];
    self.timeSpent = [decoder decodeDoubleForKey:@"timeSpent"];
    self.createdAt = [decoder decodeDoubleForKey:@"createdAt"];
    self.lastActivity = [decoder decodeDoubleForKey:@"lastActivity"];
    NSString* uuid = [decoder decodeObjectForKey:@"uuid"];
    if (uuid) {
        self.uuid = uuid;
    }
    self.transactionIds = [decoder decodeObjectForKey:@"transactionIds"];
    self.enabled = [decoder decodeBoolForKey:@"enabled"];

    // create UUID for migrating devices
    if (self.uuid == nil) {
        self.uuid = [UIDevice.currentDevice aiCreateUuid];
    }

    if (![decoder containsValueForKey:@"enabled"]) {
        self.enabled = YES;
    }

    self.lastInterval = -1;

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeInt:self.eventCount forKey:@"eventCount"];
    [encoder encodeInt:self.sessionCount forKey:@"sessionCount"];
    [encoder encodeInt:self.subsessionCount forKey:@"subsessionCount"];
    [encoder encodeDouble:self.sessionLength forKey:@"sessionLength"];
    [encoder encodeDouble:self.timeSpent forKey:@"timeSpent"];
    [encoder encodeDouble:self.createdAt forKey:@"createdAt"];
    [encoder encodeDouble:self.lastActivity forKey:@"lastActivity"];
    [encoder encodeObject:self.uuid forKey:@"uuid"];
    [encoder encodeObject:self.transactionIds forKey:@"transactionIds"];
    [encoder encodeBool:self.enabled forKey:@"enabled"];
}

- (NSMutableDictionary*)getParameters {
    NSMutableDictionary* parameters = [[NSMutableDictionary alloc] initWithCapacity:16];
    [parameters parameterizeInt:self.sessionCount forKey:@"session_count"];
    [parameters parameterizeInt:self.subsessionCount forKey:@"subsession_count"];
    [parameters parameterizeDuration:self.sessionLength forKey:@"session_length"];
    [parameters parameterizeDuration:self.timeSpent forKey:@"time_spent"];
    [parameters parameterizeDate:self.createdAt forKey:@"created_at"];
    [parameters parameterizeDuration:self.lastInterval forKey:@"last_interval"];
    [parameters parameterizeString:self.uuid forKey:@"ios_uuid"];
    return parameters;
}

@end
