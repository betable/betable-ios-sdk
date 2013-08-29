//
//  BetableProfile.h
//  Betable.framework
//
//  Created by Tony hauber on 8/7/13.
//  Copyright (c) 2013 Tony hauber. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BetableProfile : NSObject <UIAlertViewDelegate>

@property (readonly) BOOL loadedVerification;

- (NSURL*)apiURL;
- (NSURL*)authURL;
- (void)verify:(void(^)(void))onComplete;

@end
