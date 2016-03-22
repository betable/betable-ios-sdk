//
//  BetableCredentials.m
//  Betable
//
//  Created by Matthew Hilliard on 2016-03-22.
//  Copyright © 2016 betable. All rights reserved.
//

#import "BetableCredentials.h"

@implementation BetableCredentials

-(id) initWithAccessToken:(NSString*)accessToken andSessionID:(NSString*) sessionID {
    
    // This container won't exist without both fields being present
    if( accessToken == nil) {
        return nil;
    }
    
    self = [self init];
    _accessToken = accessToken;
    _sessionID = sessionID;
    return self;
}

-(id) initWithSerialised:(NSString*)serialisedMarkers {
    self = [self init];
    NSArray* tokens = [serialisedMarkers componentsSeparatedByString:@" "];
    return [self initWithAccessToken:tokens[0] andSessionID:tokens[1]];
}


- (NSString *)description {
    return [NSString stringWithFormat: @"%@ %@", _accessToken, _sessionID];
}

-(BOOL) isUnbacked {
    return nil == _sessionID ;
}

@end
