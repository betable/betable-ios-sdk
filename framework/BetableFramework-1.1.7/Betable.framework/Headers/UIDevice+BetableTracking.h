//
//  UIDevice+AIAdditions.h
//  Adjust
//
//  Created by Christian Wellenbrock on 23.07.12.
//  Copyright (c) 2012-2013 adeven. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIDevice(BetableTracking)

- (BOOL)aiTrackingEnabled;
- (NSString *)aiIdForAdvertisers;
- (NSString *)aiFbAttributionId;
- (NSString *)aiMacAddress;
- (NSString *)aiDeviceType;
- (NSString *)aiDeviceName;
- (NSString *)aiCreateUuid;
- (NSString *)aiVendorId;

@end
