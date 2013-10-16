//
//  BetableRouletteTable.h
//  Betable.framework
//
//  Created by Tony hauber on 9/19/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import <Betable/Betable.h>

@protocol BetableRouletteTableDelegate <BetableTableDelegate>

// User actions

- (BOOL)betableTable:(BetableTable *)betableTable createdBet:(NSDictionary *)betInfo withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable destroyedBet:(NSDictionary *)betInfo withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable finishedBetting:(NSDictionary *)info withNonce:(NSString*)nonce;

// Other actions:
//    Other Bet Created
//    Other Bet Destroyed
//    Other Betting Done
- (BOOL)betableTable:(BetableTable *)betableTable otherCreatedBet:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherDestroyedBet:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherFinishedBetting:(NSDictionary *)info;


@end

@interface BetableRouletteTable : BetableTable

@property (weak, nonatomic) id<BetableRouletteTableDelegate> delegate;

- (NSString*)createBet:(NSString*)wager onSpaces:(NSArray*)spaces withCurrency:(NSString*)currency inEconomy:(NSString*)economy;
- (NSString*)destroyBet:(NSString*)betID;
- (NSString*)finishBetting;

@end
