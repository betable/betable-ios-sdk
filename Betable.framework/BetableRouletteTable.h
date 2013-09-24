//
//  BetableRouletteTable.h
//  Betable.framework
//
//  Created by Tony hauber on 9/19/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import <Betable/Betable.h>

@interface BetableRouletteTable : BetableTable

- (NSString*)createBet:(NSString*)wager onSpaces:(NSArray*)spaces withCurrency:(NSString*)currency inEconomy:(NSString*)economy;
- (NSString*)destroyBet:(NSString*)betID;
- (NSString*)finishBetting;

@end
