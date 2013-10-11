//
//  BetableBlackjackTable.m
//  Betable.framework
//
//  Created by Tony hauber on 9/24/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import "BetableBlackjackTable.h"
#import "BetableBlackjackSpot.h"

@interface BetableBlackjackTable () {
    //Delegate checkers
    BOOL _delCreatedHand;
    BOOL _delUpdatedHand;
    BOOL _delDestroyedHand;
    BOOL _delStatusDone;
    BOOL _delInsuredHand;
    BOOL _delStandHand;
    BOOL _delHitHand;
    BOOL _delDoubledDownHand;
    BOOL _delSurrenderedHand;
    BOOL _delSplitHand;
    BOOL _delOtherCreatedHand;
    BOOL _delOtherUpdatedHand;
    BOOL _delOtherDestroyedHand;
    BOOL _delOtherStatusDone;
    BOOL _delOtherInsuredHand;
    BOOL _delOtherStandHand;
    BOOL _delOtherHitHand;
    BOOL _delOtherDoubledDownHand;
    BOOL _delOtherSurrenderedHand;
    BOOL _delOtherSplitHand;
    BOOL _delDealingOpened;
    BOOL _delCardDealt;
    BOOL _delDealingClosed;
    BOOL _delInsuranceOpened;
    BOOL _delInsuranceClosed;
    BOOL _delBlackjackOpened;
    BOOL _delBlackjackClosed;
    BOOL _delRoundActionOpened;
    BOOL _delRoundActionClosed;
    BOOL _delHandActionOpened;
    BOOL _delHandActionClosed;
    BOOL _delDealerRoundActionOpened;
    BOOL _delDealerRoundActionClosed;
    BOOL _delDealerHandActionOpened;
    BOOL _delDealerHandActionClosed;
    BOOL _delDealerStandHand;
    BOOL _delDealerHitHand;
    BOOL _delShoeShuffled;
}
@end

@implementation BetableBlackjackTable

- (NSString*)statusDone {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"status": self.roundInfo[@"status"],
                           };
    return [self sendMessage:@"blackjack.round.status_done" withBody:body];
}

- (NSString*)createHandAtSpot:(BetableBlackjackSpot*)spot withWager:(NSString*)wager withCurrency:(NSString*)currency {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"spot": spot,
                           @"wager": wager,
                           @"currency": currency,
                           @"economy": self.economy
                           };
    return [self sendMessage:@"blackjack.hand.create" withBody:body];
}

- (NSString*)updateHandAtSpot:(BetableBlackjackSpot*)spot withWager:(NSString*)wager withCurrency:(NSString*)currency {
    
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"spot": spot,
                           @"wager": wager,
                           @"currency": currency,
                           @"economy": self.economy
                           };
    return [self sendMessage:@"blackjack.hand.update" withBody:body];
}

- (NSString*)destroyHand:(NSDictionary*)hand {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"hand_id": hand[@"id"]
                           };
    return [self sendMessage:@"blackjack.hand.destroy" withBody:body];
}

- (NSString*)insureHand:(NSDictionary*)hand withWager:(NSString*)wager andCurrency:(NSString*)currency {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"hand_id": hand[@"id"],
                           @"wager": wager,
                           @"currency": currency,
                           @"economy": self.economy

                           };
    return [self sendMessage:@"blackjack.hand.insurance" withBody:body];
}

#pragma mark - Player Hand Actions

- (NSString*)hitHand:(NSDictionary*)hand {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"hand_id": hand[@"id"],
                           };
    return [self sendMessage:@"blackjack.hand.hit" withBody:body];
}

- (NSString*)standHand:(NSDictionary*)hand {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"hand_id": hand[@"id"],
                           };
    return [self sendMessage:@"blackjack.hand.hit" withBody:body];
}

- (NSString*)doubleDownHand:(NSDictionary*)hand {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"hand_id": hand[@"id"],
                           };
    return [self sendMessage:@"blackjack.hand.hit" withBody:body];
}

- (NSString*)splitHand:(NSDictionary*)hand {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"hand_id": hand[@"id"],
                           @"wager": hand[@"wager"],
                           };
    return [self sendMessage:@"blackjack.hand.split" withBody:body];
}

#pragma mark - Utils

- (BetableBlackjackSpot*)spotForHandData:(NSDictionary*)hand {
    if (hand) {
        BetableBlackjackSpot *spot = self.spots[hand[@"spot"][@"spot"]];
        return spot;
    }
    return nil;
}

- (void)addHand:(NSDictionary*)hand {
    BetableBlackjackSpot *spot = [self spotForHandData:hand];
    [[spot hands] addObject:hand];
}

- (void)updateHand:(NSDictionary*)hand {
    BetableBlackjackSpot *spot = [self spotForHandData:hand];
    NSInteger handIndex = [spot handIndexForHand:hand];
    [[spot hands] replaceObjectAtIndex:handIndex withObject:hand];
}

- (void)deleteHand:(NSDictionary*)hand {
    BetableBlackjackSpot *spot = [self spotForHandData:hand];
    NSInteger handIndex = [spot handIndexForHand:hand];
    [[spot hands] removeObjectAtIndex:handIndex];
}

- (void)setActiveHand:(NSDictionary*)hand {
    BetableBlackjackSpot *spot = [self spotForHandData:hand];
    [self.activeSpot setActiveHand:nil];
    self.activeSpot = spot;
    [self updateHand:hand];
    [spot setActiveHand:hand];
}
#pragma mark - Overridden Methods

- (void)handleJoiningTable {
    self.spots = [self.tableInfo[@"spots"] mutableCopy];
}

- (void)setDelegate:(id<BetableBlackjackTableDelegate>)delegate {
    [super setDelegate:delegate];
    //TODO handle setting up delegate checkers
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSDictionary *data = (NSDictionary*)[(NSString*)message objectFromJSONString];
    NSString *type = data[@"type"];
    NSDictionary *body = data[@"body"];
    NSString *nonce = data[@"nonce"];
    NSInteger sequence = [data[@"seq"] integerValue];
    BOOL shouldAcknowledge = NO;
    //TODO handle all event types
    
    
    // User actions
    if ([type isEqualToString:@"blackjack.hand.create"]){
        [self addHand:data[@"hand"]];
        shouldAcknowledge = _delCreatedHand && [self.delegate betableTable:self handCreated:body withNonce:nonce];
    } else if ([type isEqualToString:@"blackjack.hand.updated"]){
        [self updateHand:data[@"hand"]];
        shouldAcknowledge = _delUpdatedHand && [self.delegate betableTable:self handUpdated:body withNonce:nonce];
    } else if ([type isEqualToString:@"blackjack.hand.destroy"]){
        [self deleteHand:data[@"hand"]];
        shouldAcknowledge = _delDestroyedHand && [self.delegate betableTable:self handDestroyed:body withNonce:nonce];
    } else if ([type isEqualToString:@"blackjack.round.status_done"]){
        shouldAcknowledge = _delStatusDone && [self.delegate betableTable:self statusDone:body withNonce:nonce];
    } else if ([type isEqualToString:@"blackjack.hand.insurance"]){
        shouldAcknowledge = _delInsuredHand && [self.delegate betableTable:self insuredHand:body withNonce:nonce];
        
    } else if ([type isEqualToString:@"blackjack.hand.stand"]){
        shouldAcknowledge = _delStandHand && [self.delegate betableTable:self standHand:body withNonce:nonce];
    } else if ([type isEqualToString:@"blackjack.hand.hit"]){
        shouldAcknowledge = _delHitHand && [self.delegate betableTable:self hitHand:body withNonce:nonce];
    } else if ([type isEqualToString:@"blackjack.hand.double_down"]){
        shouldAcknowledge = _delDoubledDownHand && [self.delegate betableTable:self doubledDownHand:body withNonce:nonce];
    } else if ([type isEqualToString:@"blackjack.hand.surrender"]){
        shouldAcknowledge = _delSurrenderedHand && [self.delegate betableTable:self surrenderedHand:body withNonce:nonce];
    } else if ([type isEqualToString:@"blackjack.hand.split"]){
        shouldAcknowledge = _delSplitHand && [self.delegate betableTable:self splitHand:body withNonce:nonce];
        
    // Other actions
    } else if ([type isEqualToString:@"blackjack.hand.other_created"]){
        [self addHand:data[@"hand"]];
        shouldAcknowledge = _delOtherCreatedHand && [self.delegate betableTable:self otherHandCreated:body];
    } else if ([type isEqualToString:@"blackjack.hand.other_updated"]){
        [self updateHand:data[@"hand"]];
        shouldAcknowledge = _delOtherUpdatedHand && [self.delegate betableTable:self otherHandUpdated:body];
    } else if ([type isEqualToString:@"blackjack.hand.other_destroyed"]){
        [self deleteHand:data[@"hand"]];
        shouldAcknowledge = _delOtherDestroyedHand && [self.delegate betableTable:self otherHandDestroyed:body];
    } else if ([type isEqualToString:@"blackjack.round.other_status_done"]){
        shouldAcknowledge = _delOtherStatusDone && [self.delegate betableTable:self otherStatusDone:body];
    } else if ([type isEqualToString:@"blackjack.hand.other_insurance"]){
        shouldAcknowledge = _delOtherInsuredHand && [self.delegate betableTable:self otherInsuredHand:body];
    } else if ([type isEqualToString:@"blackjack.hand.other_stand"]){
        shouldAcknowledge = _delOtherStandHand && [self.delegate betableTable:self otherStandHand:body];
    } else if ([type isEqualToString:@"blackjack.hand.other_hit"]){
        shouldAcknowledge = _delOtherHitHand && [self.delegate betableTable:self otherHitHand:body];
    } else if ([type isEqualToString:@"blackjack.hand.other_double_down"]){
        shouldAcknowledge = _delOtherDoubledDownHand && [self.delegate betableTable:self otherDoubledDownHand:body];
    } else if ([type isEqualToString:@"blackjack.hand.other_surrender"]){
        shouldAcknowledge = _delOtherSurrenderedHand && [self.delegate betableTable:self otherSurrenderedHand:body];
    } else if ([type isEqualToString:@"blackjack.hand.other_split"]){
        shouldAcknowledge = _delOtherSplitHand && [self.delegate betableTable:self otherSplitHand:body];
    
    // Table Actions
    } else if ([type isEqualToString:@"blackjack.round.dealing_opened"]){
        shouldAcknowledge = _delDealingOpened && [self.delegate betableTable:self dealingOpen:body];
    } else if ([type isEqualToString:@"blackjack.hand.card_dealt"]){
        shouldAcknowledge = _delCardDealt && [self.delegate betableTable:self cardDealt:body];
    } else if ([type isEqualToString:@"blackjack.round.dealing_closed"]){
        shouldAcknowledge = _delDealingClosed && [self.delegate betableTable:self dealingClosed:body];
    } else if ([type isEqualToString:@"blackjack.round.insurance_opened"]){
        shouldAcknowledge = _delInsuranceOpened && [self.delegate betableTable:self insuranceOpened:body];
    } else if ([type isEqualToString:@"blackjack.round.insurance_closed"]){
        shouldAcknowledge = _delInsuranceClosed && [self.delegate betableTable:self insuranceClosed:body];
    } else if ([type isEqualToString:@"blackjack.round.blackjack_opened"]){
        shouldAcknowledge = _delBlackjackOpened && [self.delegate betableTable:self blackjackCheckOpened:body];
    } else if ([type isEqualToString:@"blackjack.round.blackjack_closed"]){
        shouldAcknowledge = _delBlackjackClosed && [self.delegate betableTable:self blackjackCheckClosed:body];
    } else if ([type isEqualToString:@"blackjack.round.action_opened"]){
        shouldAcknowledge = _delRoundActionOpened && [self.delegate betableTable:self roundActionOpened:body];
    } else if ([type isEqualToString:@"blackjack.hand.action_opened"]){
        [self setActiveHand:data[@"hand"]];
        shouldAcknowledge = _delHandActionOpened && [self.delegate betableTable:self roundActionOpened:body];
    } else if ([type isEqualToString:@"blackjack.hand.action_closed"]){
        [self setActiveHand:nil];
        shouldAcknowledge = _delHandActionClosed && [self.delegate betableTable:self handActionClosed:body];
    } else if ([type isEqualToString:@"blackjack.round.action_closed"]){
        shouldAcknowledge = _delRoundActionClosed && [self.delegate betableTable:self roundActionClosed:body];
    } else if ([type isEqualToString:@"blackjack.round.dealer_action_opened"]){
        shouldAcknowledge = _delDealerRoundActionOpened && [self.delegate betableTable:self dealerRoundActionOpened:body];
    } else if ([type isEqualToString:@"blackjack.hand.dealer_action_opened"]){
        shouldAcknowledge = _delDealerHandActionOpened && [self.delegate betableTable:self dealerHandActionOpened:body];
    } else if ([type isEqualToString:@"blackjack.hand.dealer_hit"]){
        shouldAcknowledge = _delDealerHitHand && [self.delegate betableTable:self dealerHitHand:body];
    } else if ([type isEqualToString:@"blackjack.hand.dealer_stand"]){
        shouldAcknowledge = _delDealerStandHand && [self.delegate betableTable:self dealerStandHand:body];
    } else if ([type isEqualToString:@"blackjack.hand.dealer_action_closed"]){
        shouldAcknowledge = _delDealerHandActionClosed && [self.delegate betableTable:self dealerHandActionClosed:body];
    } else if ([type isEqualToString:@"blackjack.round.dealer_action_closed"]){
        shouldAcknowledge = _delDealerRoundActionClosed && [self.delegate betableTable:self dealerRoundActionClosed:body];
    } else if ([type isEqualToString:@"blackjack.shoe.shuffled"]){
        shouldAcknowledge = _delShoeShuffled && [self.delegate betableTable:self shoeShuffled:body];
    }
    // Capture messages before we pass them up so that we can do some book keeping
    else if ([type isEqualToString:@"blackjack.table.other_joined"]) {
        BetableBlackjackSpot *spot = [[BetableBlackjackSpot alloc] initWithSpotData:data[@"spot"]];
        [self.spots setObject:spot forKey:@(spot.spotIndex)];
    } else if ([type isEqualToString:@"blackjack.table.other_parted"]) {
        [self.spots removeObjectForKey:body[@"spot"][@"spot"]];
    }
    if (shouldAcknowledge) {
        [self acknowledge:sequence];
    }
    
    //always pass the message on.
    [super webSocket:webSocket didReceiveMessage:message];
}

- (NSString*)gameType {
    return @"blackjack";
}
@end
