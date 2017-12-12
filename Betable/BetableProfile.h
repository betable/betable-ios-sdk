//
//  BetableProfile.h
//  Betable.framework
//
//  Created by Tony hauber on 8/7/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

@interface BetableProfile : NSObject

- (NSURL*)apiURL;

@property (readonly) BOOL hasProfile;
- (NSString*)simpleURL:(NSString*)path withParams:(NSDictionary*)params;
- (NSString*)decorateURL:(NSString*)path forClient:(NSString*)clientID withParams:(NSDictionary*)aParams;
- (NSString*)decorateTrackURLForClient:(NSString*)clientID withAction:(NSString*)action;
- (NSString*)decorateTrackURLForClient:(NSString*)clientID withAction:(NSString*)action andParams:(NSDictionary*)aParams;
@end
