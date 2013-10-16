//
//  BetableBlackjackTable.h
//  Betable.framework
//
//  Created by Tony hauber on 9/24/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import <Betable/Betable.h>

@class BetableBlackjackSpot;

@protocol BetableBlackjackTableDelegate <BetableTableDelegate>

@optional

//User action
- (BOOL)betableTable:(BetableTable *)betableTable handCreated:(NSDictionary *)info withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable handUpdated:(NSDictionary *)info withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable handDestroyed:(NSDictionary *)info withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable statusDone:(NSDictionary *)info withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable insuredHand:(NSDictionary *)info withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable standHand:(NSDictionary *)info withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable hitHand:(NSDictionary *)info withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable doubledDownHand:(NSDictionary *)info withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable surrenderedHand:(NSDictionary *)info withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable *)betableTable splitHand:(NSDictionary *)info withNonce:(NSString*)nonce;


//Other actions
- (BOOL)betableTable:(BetableTable *)betableTable otherHandCreated:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherHandUpdated:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherHandDestroyed:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherStatusDone:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherInsuredHand:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherStandHand:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherHitHand:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherDoubledDownHand:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherSurrenderedHand:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherSplitHand:(NSDictionary *)info;


//Table Actions
- (BOOL)betableTable:(BetableTable *)betableTable dealingOpen:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable cardDealt:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable dealingClosed:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable insuranceOpened:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable insuranceClosed:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable blackjackCheckOpened:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable blackjackCheckClosed:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable roundActionOpened:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable handActionOpened:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable handActionClosed:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable roundActionClosed:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable dealerRoundActionOpened:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable dealerHandActionOpened:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable dealerHitHand:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable dealerStandHand:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable dealerHandActionClosed:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable dealerRoundActionClosed:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable shoeShuffled:(NSDictionary *)info;

@end

@interface BetableBlackjackTable : BetableTable

@property (nonatomic, strong) NSMutableDictionary *spots;
@property (nonatomic, weak) id<BetableBlackjackTableDelegate> delegate;

@property (nonatomic, strong) BetableBlackjackSpot *activeSpot;
@property (nonatomic, strong) BetableBlackjackSpot *userSpot;

@property (nonatomic, strong) NSMutableArray *hands;

- (NSString*)createHandAtSpot:(BetableBlackjackSpot*)spot withWager:(NSString*)wager withCurrency:(NSString*)currency;
- (NSString*)updateHandAtSpot:(BetableBlackjackSpot*)spot withWager:(NSString*)wager withCurrency:(NSString*)currency;
- (NSString*)destroyHand:(NSDictionary*)hand;


@end
