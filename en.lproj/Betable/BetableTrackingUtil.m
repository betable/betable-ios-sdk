//
//  AIUtil.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-05.
//  Copyright (c) 2013 adeven. All rights reserved.
//

#import "BetableTrackingUtil.h"
#import "UIDevice+BetableTracking.h"

#include <sys/xattr.h>

static NSString * const kBaseUrl   = @"https://app.adjust.io";
static NSString * const kClientSdk = @"ios3.3.2";

static NSString * const kDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'Z";
static NSDateFormatter * dateFormat;

#pragma mark -
@implementation BetableTrackingUtil

+ (NSString *)baseUrl {
    return kBaseUrl;
}

+ (NSString *)clientSdk {
    return kClientSdk;
}

+ (NSString *)userAgent {
    UIDevice *device = UIDevice.currentDevice;
    NSLocale *locale = NSLocale.currentLocale;
    NSBundle *bundle = NSBundle.mainBundle;
    NSDictionary *infoDictionary = bundle.infoDictionary;
    
    NSString *bundeIdentifier = [infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey];
    NSString *bundleVersion   = [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey];
    NSString *languageCode    = [locale objectForKey:NSLocaleLanguageCode];
    NSString *countryCode     = [locale objectForKey:NSLocaleCountryCode];
    NSString *osName          = @"ios";
    
    NSString *userAgent = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@",
                           [self.class sanitizeU:bundeIdentifier],
                           [self.class sanitizeU:bundleVersion],
                           [self.class sanitizeU:device.aiDeviceType],
                           [self.class sanitizeU:device.aiDeviceName],
                           [self.class sanitizeU:osName],
                           [self.class sanitizeU:device.systemVersion],
                           [self.class sanitizeZ:languageCode],
                           [self.class sanitizeZ:countryCode]];
    
    return userAgent;
}

#pragma mark - sanitization
+ (NSString *)sanitizeU:(NSString *)string {
    return [self.class sanitize:string defaultString:@"unknown"];
}

+ (NSString *)sanitizeZ:(NSString *)string {
    return [self.class sanitize:string defaultString:@"zz"];
}

+ (NSString *)sanitize:(NSString *)string defaultString:(NSString *)defaultString {
    if (string == nil) {
        return defaultString;
    }
    
    NSString *result = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (result.length == 0) {
        return defaultString;
    }
    
    return result;
}

// inspired by https://gist.github.com/kevinbarrett/2002382
//Probably don't need this for our simple implmentation
+ (void)excludeFromBackup:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    const char* filePath = [[url path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
    
    if (&NSURLIsExcludedFromBackupKey == nil) { // iOS 5.0.1 and lower
        u_int8_t attrValue = 1;
        setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    } else { // iOS 5.0 and higher
        // First try and remove the extended attribute if it is present
        ssize_t result = getxattr(filePath, attrName, NULL, sizeof(u_int8_t), 0, 0);
        if (result != -1) {
            // The attribute exists, we need to remove it
            removexattr(filePath, attrName, 0);
        }
        
        // Set the new key
        NSError *error = nil;
        [url setResourceValue:[NSNumber numberWithBool:YES]
                                      forKey:NSURLIsExcludedFromBackupKey
                                       error:&error];
    }
}

+ (NSString *)dateFormat:(double) value {
    if (dateFormat == nil) {
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:kDateFormat];
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:value];
    
    return [dateFormat stringFromDate:date];
}


@end

