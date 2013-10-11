//
//  BetableBlackjackHand.m
//  Betable.framework
//
//  Created by Tony hauber on 10/3/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import "BetableBlackjackSpot.h"

@implementation BetableBlackjackSpot

- (id)initWithSpotData:(NSDictionary*)data {
    self = [super init];
    if (self) {
        self.spotData = data;
    }
    return self;
}

- (NSInteger)spotIndex {
    return [self.spotData[@"spot"] integerValue];
}

- (NSInteger)activeHandIndex {
    return [self.hands indexOfObject:self.activeHand];
}

- (NSInteger)handIndexForHand:(NSDictionary*)newHand {
    for (NSDictionary *hand in self.hands) {
        if ([hand[@"id"] isEqualToString:newHand[@"id"]]) {
            return [self.hands indexOfObject:hand];
        }
    }
    return NSNotFound;
}
@end
