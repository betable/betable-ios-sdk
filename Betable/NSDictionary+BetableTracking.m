//
//  NSDictionary+BetableTracking.m
//  Betable.framework
//
//  Created by Tony hauber on 6/11/14.
//  Copyright (c) 2014 Tony hauber. All rights reserved.
//

#import "NSDictionary+BetableTracking.h"
#import "BetableTrackingUtil.h"
#import "LoadableCategory.h"

MAKE_CATEGORIES_LOADABLE(NSDictionary_BetableTracking);

@implementation NSMutableDictionary (BetableTracking)


- (void)parameterizeString:(NSString *)value forKey:(NSString *)key {
    if (value == nil || [value isEqualToString:@""]) return;
    [self setObject:value forKey:key];
}

- (void)parameterizeInt:(int)value forKey:(NSString *)key {
    if (value < 0) return;
    
    NSString *valueString = [NSString stringWithFormat:@"%d", value];
    [self parameterizeString:valueString forKey:key];
}

- (void)parameterizeDate:(double)value forKey:(NSString *)key {
    if (value < 0) return;
    
    NSString *dateString = [BetableTrackingUtil dateFormat:value];
    [self parameterizeString:dateString forKey:key];
}

- (void)parameterizeDuration:(double)value forKey:(NSString *)key {
    if (value < 0) return;
    
    int intValue = round(value);
    [self parameterizeInt:intValue forKey:key];
}

- (void)parameterizeBool:(BOOL)value forKey:(NSString *)key {
    int valueInt = [[NSNumber numberWithBool:value] intValue];
    
    [self parameterizeInt:valueInt forKey:key];
}
@end
