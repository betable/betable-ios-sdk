//
//  NSDictionary+BetableTracking.h
//  Betable.framework
//
//  Created by Tony hauber on 6/11/14.
//  Copyright (c) 2014 Tony hauber. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (BetableTracking)

- (void)parameterizeString:(NSString *)value forKey:(NSString *)key;
- (void)parameterizeInt:(int)value forKey:(NSString *)key;
- (void)parameterizeDate:(double)value forKey:(NSString *)key;
- (void)parameterizeDuration:(double)value forKey:(NSString *)key;
- (void)parameterizeBool:(BOOL)value forKey:(NSString *)key;
@end
