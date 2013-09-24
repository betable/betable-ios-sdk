//
//  BetableRouletteTable.m
//  Betable.framework
//
//  Created by Tony hauber on 9/19/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import "BetableRouletteTable.h"

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

@end
