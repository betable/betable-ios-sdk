//
//  BetableTracking.h
//  Betable.framework
//
//  Created by Tony hauber on 6/9/14.
//  Copyright (c) 2014 Tony hauber. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BetableTracking : NSObject

@property (nonatomic, copy) NSString* environment;

- (id)initWithClientID:(NSString*)clientID andEnvironment:(NSString*)environment;
- (void)trackSession;

@end
