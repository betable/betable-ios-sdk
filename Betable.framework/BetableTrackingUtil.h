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

@interface NSData(BetableTracking)

- (NSString *)aiEncodeBase64;

@end

@interface NSString(BetableTracking)

- (NSString *)aiTrim;
- (NSString *)aiQuote;
- (NSString *)aiMd5;
- (NSString *)aiSha1;
- (NSString *)aiUrlEncode;
- (NSString *)aiRemoveColons;

+ (NSString *)aiJoin:(NSString *)strings, ...;

@end

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

@interface NSMutableDictionary (BetableTracking)

- (void)parameterizeString:(NSString *)value forKey:(NSString *)key;
- (void)parameterizeInt:(int)value forKey:(NSString *)key;
- (void)parameterizeDate:(double)value forKey:(NSString *)key;
- (void)parameterizeDuration:(double)value forKey:(NSString *)key;
- (void)parameterizeBool:(BOOL)value forKey:(NSString *)key;
@end
