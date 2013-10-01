//
//  BetableBlackjackTable.m
//  Betable.framework
//
//  Created by Tony hauber on 9/24/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import "BetableBlackjackTable.h"
@interface BetableBlackjackTable () {
    //Delegate checkers
    BOOL _delCreatedBet;
    BOOL _delDestroyedBet;
    BOOL _delFinishedBetting;
    BOOL _delOtherCreatedBet;
    BOOL _delOtherDestroyedBet;
    BOOL _delOtherFinishedBetting;
}
@end

@implementation BetableBlackjackTable

- (NSString*)createBet:(NSString*)wager onSpaces:(NSArray*)spaces withCurrency:(NSString*)currency inEconomy:(NSString*)economy {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"spaces": spaces,
                           @"wager": wager,
                           @"currency": currency,
                           @"economy": economy
                           };
    return [self sendMessage:@"roulette.bet.create" withBody:body];
}

- (NSString*)destroyBet:(NSString*)betID {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"bet_id": betID
                           };
    return [self sendMessage:@"roulette.bet.destroy" withBody:body];
}

- (NSString*)statusDone {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"round_id": self.roundID,
                           @"table_id": self.tableID,
                           @"status": self.roundInfo[@"status"],
                           };
    return [self sendMessage:@"blackjack.round.status_done" withBody:body];
}

- (NSString*)createHandAtSpot:(NSNumber*)spot withWager:(NSString*)wager withCurrency:(NSString*)currency {
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

- (NSString*)updateHandAtSpot:(NSNumber*)spot withWager:(NSString*)wager withCurrency:(NSString*)currency {
    
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

- (void)handleJoiningTable {
    NSString *roundStatus = self.roundInfo[@"status"];
    //TODO handle joining table
}

- (void)setDelegate:(id<BetableTableDelegate>)delegate {
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
    if ([type isEqualToString:@"roulette.bet.create"]){
        
    } else {
        [super webSocket:webSocket didReceiveMessage:message];
    }
    if (shouldAcknowledge) {
        [self acknowledge:sequence];
    }
}

- (NSString*)gameType {
    return @"roulette";
}
@end
