//
//  BetableCredentials.h
//  Betable
//
//  Created by Matthew Hilliard on 2016-03-22.
//  Copyright © 2016 betable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BetableCredentials : NSObject

@property (nonatomic, strong, readonly) NSString* accessToken;
@property (nonatomic, strong, readonly) NSString* sessionID;


- (id)initWithAccessToken:(NSString*)accessToken andSessionID:(NSString*)sessionID;

- (id)initWithSerialised:(NSString*)serialisedMarkers;

- (BOOL)isUnbacked;

@end
