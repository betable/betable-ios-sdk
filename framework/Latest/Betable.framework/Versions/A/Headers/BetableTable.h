//
//  BetableTable.h
//  Betable.framework
//
//  Created by Tony hauber on 9/3/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"

@class BetableTable;

@protocol BetableTableDelegate <NSObject>

// User actions
//    Table Joined
//    Session Resume
//    Table Part
- (BOOL)betableTable:(BetableTable*)betableTable joined:(NSDictionary*)tableInfo withNonce:(NSString*)nonce;
- (BOOL)betableTable:(BetableTable*)betableTable sessionResumed:(NSDictionary*)tableInfo;
- (BOOL)betableTable:(BetableTable *)betableTable parted:(NSDictionary *)info withNonce:(NSString*)nonce;

// Game actions
//    Round Created
//    Betting Opened
//    Betting Closed
//    Round Closed
//    Round Cancelled
- (BOOL)betableTable:(BetableTable *)betableTable roundCreated:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable bettingOpened:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable bettingClosed:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable roundClosed:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable roundCanceled:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable inactiveParted:(NSDictionary *)info;

// Other actions:
//    Other Joined
//    Other Parted
- (BOOL)betableTable:(BetableTable *)betableTable otherJoined:(NSDictionary *)info;
- (BOOL)betableTable:(BetableTable *)betableTable otherParted:(NSDictionary *)info;

//Misc
- (void)betableTable:(BetableTable *)betableTable didFailWithError:(id)error;
- (void)betableTable:(BetableTable *)betableTable connectionClosedWithCode:(NSInteger)code reason:(NSString*)reason wasClean:(BOOL)wasClean;


@end

@interface BetableTable : NSObject <SRWebSocketDelegate>

@property (strong, nonatomic) NSString *gameID;
@property (strong, nonatomic) NSString *roundID;
@property (strong, nonatomic) NSString *tableID;
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) NSString *userID;

@property (strong, nonatomic) NSDictionary *tableInfo;
@property (strong, nonatomic) NSDictionary *roundInfo;
@property (strong, nonatomic) NSMutableArray *players;

@property (strong, nonatomic) NSString *economy;
@property (strong, nonatomic) SRWebSocket *socket;
@property (readonly) NSString *gameType;
@property BOOL betableManaged;
@property NSInteger lastAck;
@property (weak, nonatomic) id<BetableTableDelegate> delegate;


- (id)initBetableManagedTableWithGameID:(NSString*)gameID andEconomy:(NSString*)economy;
- (id)initTableWithTableID:(NSString*)tableID andGameID:(NSString*)gameID andEconomy:(NSString*)economy;
- (void)connectWithAccessToken:(NSString*)accessToken;
- (void)reconnectWithAccessToken:(NSString*)accessToken;
- (NSString*)partTable;
- (NSString*)joinTable;
- (NSString*)sendMessage:(NSString*)type withBody:(NSDictionary*)body;
- (void)acknowledge:(NSInteger)ack;

//subclass
- (void)handleJoiningTable;
- (NSString*)gameType;


@end
