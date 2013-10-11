//
//  BetableBlackjackHand.h
//  Betable.framework
//
//  Created by Tony hauber on 10/3/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BetableBlackjackSpot : NSObject

@property (nonatomic, strong) NSMutableArray *hands;
@property (nonatomic, strong) NSDictionary *activeHand;
@property (nonatomic, strong) NSDictionary *spotData;

@property (readonly) NSInteger spotIndex;
@property (readonly) NSInteger activeHandIndex;

- (id)initWithSpotData:(NSDictionary*)data;
- (NSInteger)handIndexForHand:(NSDictionary*)newHand;

@end
