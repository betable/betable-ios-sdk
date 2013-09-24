//
//  BetableTable.m
//  Betable.framework
//
//  Created by Tony hauber on 9/3/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import "BetableTable.h"
#import "Betable.h"

NSString *BetableTableSocketURL = @"wss://api.betable.com/1.0/websocket";

@interface BetableTable () {
    NSTimer *_keepAliveTimer;
    
    //Delegate checkers
    
}

@end

@implementation BetableTable

- (id)init {
    self = [super init];
    if (self) {
        self.players = [NSMutableArray array];
    }
    return self;
}

- (id)initBetableManagedTableWithGameID:(NSString*)gameID andEconomy:(NSString*)economy {
    self = [self init];
    if (self) {
        self.gameID = gameID;
        self.economy = economy;
        self.betableManaged = YES;
    }
    return self;
}

- (id)initTableWithTableID:(NSString*)tableID andGameID:(NSString*)gameID andEconomy:(NSString*)economy {
    self = [self init];
    if (self) {
        self.gameID = gameID;
        self.economy = economy;
        self.tableID = tableID;
        self.betableManaged = NO;
    }
    return self;
}

- (void)connectWithAccessToken:(NSString*)accessToken {
    NSString *urlString = [NSString stringWithFormat:@"%@?access_token=%@", BetableTableSocketURL, accessToken];
    self.socket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:urlString]];
    self.socket.delegate = self;
    [self.socket open];
}

- (void)reconnectWithAccessToken:(NSString*)accessToken {
    NSString *urlString = [NSString stringWithFormat:@"%@?access_token=%@&session_id=%@&ack=%d", BetableTableSocketURL, accessToken, self.sessionID, self.lastAck];
    self.socket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:urlString]];
    self.socket.delegate = self;
    [self.socket open];
}

#pragma mark - User Actions

- (NSString*)joinTable {
    NSDictionary *body = @{
                           @"game_id": self.gameID,
                           @"economy": self.economy,
                           @"managed": [NSNumber numberWithBool:YES]
                           };
    if (!self.betableManaged) {
        body = @{
                 @"game_id": self.gameID,
                 @"economy": self.economy,
                 @"table_id": self.tableID
                 };
    }
    return [self sendMessage:[NSString stringWithFormat:@"%@.table.join", self.gameType] withBody:body];
}

- (NSString*)partTable {
    NSDictionary *body = @{@"table_id": self.tableID};
    return [self sendMessage:@"roulette.table.part" withBody:body];
}

- (NSString*)sendMessage:(NSString *)type withBody:(NSDictionary *)body {
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString* nonce = [[NSString stringWithFormat:@"%@", UUIDSRef] substringToIndex:25];
    return [self sendMessage:type withBody:body withNonce:nonce];
}


- (void)sendKeepAlive {
    [self sendMessage:@"session.keepalive" withBody:@{}];
}

- (void)acknowledge:(NSInteger)ack {
    if (ack > self.lastAck) {
        self.lastAck = ack;
    }
}

- (void)startSession:(NSDictionary*)data {
    self.sessionID = data[@"session_id"];
    self.userID = data[@"user_id"];
    [_keepAliveTimer invalidate];
    _keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(sendKeepAlive) userInfo:nil repeats:YES];
}

- (NSString*)sendMessage:(NSString*)type withBody:(NSDictionary*)body withNonce:(NSString*)nonce {
    NSDictionary *data = @{
                           @"type":type,
                           @"body":body,
                           @"ack": @(self.lastAck)
                           };
    if (nonce) {
        data = @{
                 @"nonce": nonce,
                 @"type":type,
                 @"body":body,
                 @"ack": @(self.lastAck)
                 };
    }
    NSLog(@"Sending \"%@\" with data: %@", type, data);
    [_keepAliveTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    [self.socket send:[[NSString alloc] initWithData:[data JSONData]
                                            encoding:NSUTF8StringEncoding]];
    return nonce;
}



#pragma mark - Utils

- (NSString*)eventWithGameType:(NSString*)eventTemplate {
    return [NSString stringWithFormat:eventTemplate, self.gameType];
}

#pragma mark - Getters and Setters

- (NSString*)gameType {
    return @"roulette";
}

#pragma mark - SRWebSocket delegate methods

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    //do nothing while we wait for session to start
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self.delegate betableTable:self didFailWithError:error];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSDictionary *data = (NSDictionary*)[(NSString*)message objectFromJSONString];
    NSString *type = data[@"type"];
    NSDictionary *body = data[@"body"];
    NSString *nonce = data[@"nonce"];
    NSInteger sequence = [data[@"seq"] integerValue];
    BOOL shouldAcknowledge = NO;
    
    NSLog(@"Receieved Message:%@", type);
    
    if (data[@"error"]) {
        [self.delegate betableTable:self didFailWithError:data[@"error"]];
        return;
    }
    
    //Session stuff
    if ([type isEqualToString:@"session.create"]) {
        [self startSession:body];
        [self joinTable];
        shouldAcknowledge = YES;
    } else if ([type isEqualToString:@"session.resume"]) {
        [self.delegate betableTable:self sessionResumed:body];
        [self startSession:body];
        [self joinTable];
    } else if ([type isEqualToString:@"bad_message"]) {
        NSLog(@"Bad Message:%@", body);
    }
    //User Actions
    else if ([type isEqualToString:@"roulette.table.join"]){
        self.tableID = body[@"table"][@"id"];
        self.roundID = body[@"table"][@"current_round"][@"id"];
        self.tableInfo = body[@"table"];
        self.roundInfo = body[@"table"][@"current_round"];
        self.players = [self.tableInfo[@"players"] mutableCopy];
        shouldAcknowledge = [self.delegate betableTable:self joined:body withNonce:nonce];
        //TODO move this to Handle Joining Table Status method
        NSString *roundStatus = self.roundInfo[@"status"];
        if ([roundStatus isEqualToString:@"betting_opened"]) {
            [self.delegate betableTable:self bettingOpened:self.roundInfo];
        } else if ([roundStatus isEqualToString:@"betting_closed"]) {
            [self.delegate betableTable:self bettingClosed:self.roundInfo];
        } else if ([roundStatus isEqualToString:@"betting_created"]) {
            [self.delegate betableTable:self roundCreated:self.roundInfo];
        } else if ([roundStatus isEqualToString:@"closed"]) {
            [self.delegate betableTable:self roundClosed:self.roundInfo];
        }
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.bet.create"]]){
        shouldAcknowledge = [self.delegate betableTable:self createdBet:body withNonce:nonce];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.bet.destroy"]]){
        shouldAcknowledge = [self.delegate betableTable:self destroyedBet:body withNonce:nonce];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.round.betting_opened_player_done"]]){
        shouldAcknowledge = [self.delegate betableTable:self finishedBetting:body withNonce:nonce];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.table.part"]]) {
        [_keepAliveTimer invalidate];
        _keepAliveTimer = nil;
        shouldAcknowledge = [self.delegate betableTable:self parted:body withNonce:nonce];
    }
    
    //Round Actions
    else if ([type isEqualToString:@"roulette.round.created"]){
        self.roundID = body[@"round"][@"id"];
        shouldAcknowledge = [self.delegate betableTable:self roundCreated:body];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.round.betting_opened"]]){
        shouldAcknowledge = [self.delegate betableTable:self bettingOpened:body];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.round.betting_closed"]]){
        shouldAcknowledge = [self.delegate betableTable:self bettingClosed:body];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.round.closed"]]){
        shouldAcknowledge = [self.delegate betableTable:self roundClosed:body];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.round.canceled"]]){
        shouldAcknowledge = [self.delegate betableTable:self roundCancelled:body];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.table.inactive_parted"]]) {
        [_keepAliveTimer invalidate];
        _keepAliveTimer = nil;
        shouldAcknowledge = [self.delegate betableTable:self inactiveParted:body];
    }
    
    //Other player action
    else if ([type isEqualToString:[self eventWithGameType:@"@%.table.other_joined"]]){
        NSDictionary *newPlayer = body[@"user"];
        BOOL isPlayerNew = YES;
        for (NSDictionary* player in self.players) {
            if ([player[@"id"] isEqualToString:newPlayer[@"id"]]) {
                [self.players removeObject:player];
                break;
            }
        }
        if (isPlayerNew) {
            [self.players addObject:newPlayer];
        }
        shouldAcknowledge = [self.delegate betableTable:self otherJoined:body];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.bet.other_created"]]){
        shouldAcknowledge = [self.delegate betableTable:self otherCreatedBet:body];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.bet.other_destroyed"]]){
        shouldAcknowledge = [self.delegate betableTable:self otherDestroyedBet:body];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.round.other_betting_opened_player_done"]]){
        shouldAcknowledge = [self.delegate betableTable:self otherFinishedBetting:body];
    } else if ([type isEqualToString:[self eventWithGameType:@"@%.table.other_parted"]]){
        NSString *partingUserId = body[@"user_id"];
        for (NSDictionary* player in self.players) {
            if ([player[@"id"] isEqualToString:partingUserId]) {
                [self.players removeObject:player];
                break;
            }
        }
        shouldAcknowledge = [self.delegate betableTable:self otherParted:body];
    }
    
    if (shouldAcknowledge) {
        [self acknowledge:sequence];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [_keepAliveTimer invalidate];
    _keepAliveTimer = nil;
    [self.delegate betableTable:self connectionClosedWithCode:code reason:reason wasClean:wasClean];
}
@end
