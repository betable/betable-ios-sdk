//
//  BetableTrackingUtil.h
//  Betable.framework
//
//  Created by Tony hauber on 6/9/14.
//  Copyright (c) 2014 Tony hauber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BetableTrackingUtil : NSObject

+ (NSString *)baseUrl;
+ (NSString *)clientSdk;
+ (NSString *)userAgent;

+ (void)excludeFromBackup:(NSString *)filename;
+ (NSString *)dateFormat:(double)value;

@end
