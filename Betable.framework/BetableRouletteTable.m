//
//  BetableRouletteTable.m
//  Betable.framework
//
//  Created by Tony hauber on 9/19/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import "BetableRouletteTable.h"
@interface BetableRouletteTable () {
    //Delegate checkers
    BOOL _delCreatedBet;
    BOOL _delDestroyedBet;
    BOOL _delFinishedBetting;
    BOOL _delOtherCreatedBet;
    BOOL _delOtherDestroyedBet;
    BOOL _delOtherFinishedBetting;
}

@end

@implementation BetableRouletteTable

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

- (NSString*)finishBetting {
    NSDictionary *body = @{
                           @"round_id": self.roundID,
                           @"table_id": self.tableID
                           };
    return [self sendMessage:@"roulette.round.betting_opened_player_done" withBody:body];
}

- (void)handleJoiningTable {
    NSString *roundStatus = self.roundInfo[@"status"];
    if ([roundStatus isEqualToString:@"betting_opened"] && [self.delegate respondsToSelector:@selector(betableTable:bettingOpened:)]) {
        [self.delegate betableTable:self bettingOpened:self.roundInfo];
    } else if ([roundStatus isEqualToString:@"betting_closed"] && [self.delegate respondsToSelector:@selector(betableTable:bettingClosed:)]) {
        [self.delegate betableTable:self bettingClosed:self.roundInfo];
    } else if ([roundStatus isEqualToString:@"betting_created"] && [self.delegate respondsToSelector:@selector(betableTable:roundCreated:)]) {
        [self.delegate betableTable:self roundCreated:self.roundInfo];
    } else if ([roundStatus isEqualToString:@"closed"] && [self.delegate respondsToSelector:@selector(betableTable:roundClosed:)]) {
        [self.delegate betableTable:self roundClosed:self.roundInfo];
    }
}

- (void)setDelegate:(id<BetableTableDelegate>)delegate {
    [super setDelegate:delegate];
    _delCreatedBet = [delegate respondsToSelector:@selector(betableTable:createdBet:withNonce:)];
    _delDestroyedBet = [delegate respondsToSelector:@selector(betableTable:destroyedBet:withNonce:)];
    _delFinishedBetting = [delegate respondsToSelector:@selector(betableTable:finishedBetting:withNonce:)];
    _delOtherCreatedBet = [delegate respondsToSelector:@selector(betableTable:otherCreatedBet:)];
    _delOtherDestroyedBet = [delegate respondsToSelector:@selector(betableTable:otherDestroyedBet:)];
    _delOtherFinishedBetting = [delegate respondsToSelector:@selector(betableTable:otherFinishedBetting:)];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSDictionary *data = (NSDictionary*)[(NSString*)message objectFromJSONString];
    NSString *type = data[@"type"];
    NSDictionary *body = data[@"body"];
    NSString *nonce = data[@"nonce"];
    NSInteger sequence = [data[@"seq"] integerValue];
    BOOL shouldAcknowledge = NO;
    if ([type isEqualToString:@"roulette.bet.create"] && _delCreatedBet){
        shouldAcknowledge = [self.delegate betableTable:self createdBet:body withNonce:nonce];
    } else if ([type isEqualToString:@"roulette.bet.destroy"] && _delDestroyedBet){
        shouldAcknowledge = [self.delegate betableTable:self destroyedBet:body withNonce:nonce];
    } else if ([type isEqualToString:@"roulette.round.betting_opened_player_done"] && _delFinishedBetting){
        shouldAcknowledge = [self.delegate betableTable:self finishedBetting:body withNonce:nonce];
    } else if ([type isEqualToString:@"roulette.bet.other_created"] && _delOtherCreatedBet){
        shouldAcknowledge = [self.delegate betableTable:self otherCreatedBet:body];
    } else if ([type isEqualToString:@"roulette.bet.other_destroyed"] && _delOtherDestroyedBet){
        shouldAcknowledge = [self.delegate betableTable:self otherDestroyedBet:body];
    } else if ([type isEqualToString:@"roulette.round.other_betting_opened_player_done"] && _delOtherFinishedBetting){
        shouldAcknowledge = [self.delegate betableTable:self otherFinishedBetting:body];
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
