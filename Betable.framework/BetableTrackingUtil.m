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


#pragma mark - NSDictionary+BetableTracking.m


@implementation NSData(BetableTracking)

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// http://stackoverflow.com/a/4727124
- (NSString *)aiEncodeBase64 {
    const unsigned char * objRawData = self.bytes;
    char * objPointer;
    char * strResult;
    
    // Get the Raw Data length and ensure we actually have data
    NSUInteger intLength = self.length;
    if (intLength == 0) return nil;
    
    // Setup the String-based Result placeholder and pointer within that placeholder
    strResult = (char *)calloc((((intLength + 2) / 3) * 4) + 1, sizeof(char));
    objPointer = strResult;
    
    // Iterate through everything
    while (intLength > 2) { // keep going until we have less than 24 bits
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
        *objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
        *objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];
        
        // we just handled 3 octets (24 bits) of data
        objRawData += 3;
        intLength -= 3;
    }
    
    // now deal with the tail end of things
    if (intLength != 0) {
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        if (intLength > 1) {
            *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
            *objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
            *objPointer++ = '=';
        } else {
            *objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
            *objPointer++ = '=';
            *objPointer++ = '=';
        }
    }
    
    // Terminate the string-based result
    *objPointer = '\0';
    
    // Return the results as an NSString object
    NSString *encodedString = [NSString stringWithCString:strResult encoding:NSASCIIStringEncoding];
    free(strResult);
    return encodedString;
}

@end


#pragma mark - NSString+BetableTracking.m

@implementation NSMutableDictionary (BetableTracking)


- (void)parameterizeString:(NSString *)value forKey:(NSString *)key {
    if (value == nil || [value isEqualToString:@""]) return;
    [self setObject:value forKey:key];
}

- (void)parameterizeInt:(int)value forKey:(NSString *)key {
    if (value < 0) return;
    
    NSString *valueString = [NSString stringWithFormat:@"%d", value];
    [self parameterizeString:valueString forKey:key];
}

- (void)parameterizeDate:(double)value forKey:(NSString *)key {
    if (value < 0) return;
    
    NSString *dateString = [BetableTrackingUtil dateFormat:value];
    [self parameterizeString:dateString forKey:key];
}

- (void)parameterizeDuration:(double)value forKey:(NSString *)key {
    if (value < 0) return;
    
    int intValue = round(value);
    [self parameterizeInt:intValue forKey:key];
}

- (void)parameterizeBool:(BOOL)value forKey:(NSString *)key {
    if (value < 0) return;
    
    int valueInt = [[NSNumber numberWithBool:value] intValue];
    
    [self parameterizeInt:valueInt forKey:key];
}
@end





#pragma mark - NSString+BetableTracking.m

#import "CommonCrypto/CommonDigest.h"

@implementation NSString(BetableTracking)

- (NSString *)aiTrim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)aiQuote {
    if (self == nil) {
        return nil;
    }
    
    if ([self rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location == NSNotFound) {
        return self;
    }
    return [NSString stringWithFormat:@"'%@'", self];
}

- (NSString *)aiMd5 {
    const char *cStr = [self UTF8String];
    unsigned char digest[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return  output;
}

- (NSString *)aiSha1 {
    const char *cstr = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:self.length];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

-(NSString *)aiUrlEncode {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
}

- (NSString *)aiRemoveColons {
    return [self stringByReplacingOccurrencesOfString:@":" withString:@""];
}

+ (NSString *)aiJoin:(NSString *)first, ... {
    NSString *iter, *result = first;
    va_list strings;
    va_start(strings, first);
    
    while ((iter = va_arg(strings, NSString*))) {
        NSString *capitalized = iter.capitalizedString;
        result = [result stringByAppendingString:capitalized];
    }
    
    va_end(strings);
    return result;
}

@end

#pragma mark - UIDevice+BetableTracking.m

#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>

#if !ADJUST_NO_IDFA
#import <AdSupport/ASIdentifierManager.h>
#endif

@implementation UIDevice(BetableTracking)

- (BOOL)aiTrackingEnabled {
#if !ADJUST_NO_IDFA
    NSString *className  = [NSString aiJoin:@"A", @"S", @"identifier", @"manager", nil];
    NSString *keyManager = [NSString aiJoin:@"shared", @"manager", nil];
    NSString *keyEnabled = [NSString aiJoin:@"is", @"advertising", @"tracking", @"enabled", nil];
    
    Class class = NSClassFromString(className);
    if (class) {
        @try {
            SEL selManager = NSSelectorFromString(keyManager);
            SEL selEnabled = NSSelectorFromString(keyEnabled);
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id manager   = [class performSelector:selManager];
            BOOL enabled = (BOOL)[manager performSelector:selEnabled];
#pragma clang diagnostic pop
            
            return enabled;
        } @catch (NSException *e) {
            return NO;
        }
    } else
#endif
    {
        return NO;
    }
}

- (NSString *)aiIdForAdvertisers {
#if !ADJUST_NO_IDFA
    NSString *className     = [NSString aiJoin:@"A", @"S", @"identifier", @"manager", nil];
    NSString *keyManager    = [NSString aiJoin:@"shared", @"manager", nil];
    NSString *keyIdentifier = [NSString aiJoin:@"advertising", @"identifier", nil];
    NSString *keyString     = [NSString aiJoin:@"UUID", @"string", nil];
    
    Class class = NSClassFromString(className);
    if (class) {
        @try {
            SEL selManager    = NSSelectorFromString(keyManager);
            SEL selIdentifier = NSSelectorFromString(keyIdentifier);
            SEL selString     = NSSelectorFromString(keyString);
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id manager       = [class performSelector:selManager];
            id identifier    = [manager performSelector:selIdentifier];
            NSString *string = [identifier performSelector:selString];
#pragma clang diagnostic pop
            
            return string;
        } @catch (NSException *e) {
            return @"";
        }
    } else
#endif
    {
        return @"";
    }
}

- (NSString *)aiFbAttributionId {
    NSString *result = [UIPasteboard pasteboardWithName:@"fb_app_attribution" create:NO].string;
    if (result == nil) return @"";
    return result;
}

- (NSString *)aiMacAddress {
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    
    NSString *macAddress = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                            *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    
    free(buf);
    
    return macAddress;
}

- (NSString *)aiDeviceType {
    NSString *type = [self.model stringByReplacingOccurrencesOfString:@" " withString:@""];
    return type;
}

- (NSString *)aiDeviceName {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *name = malloc(size);
    sysctlbyname("hw.machine", name, &size, NULL, 0);
    NSString *machine = [NSString stringWithUTF8String:name];
    free(name);
    return machine;
}

- (NSString *)aiCreateUuid {
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef stringRef = CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    NSString *uuidString = (__bridge_transfer NSString*)stringRef;
    NSString *lowerUuid = [uuidString lowercaseString];
    CFRelease(newUniqueId);
    return lowerUuid;
}

- (NSString *)aiVendorId {
    NSString * vendorId = [UIDevice.currentDevice.identifierForVendor UUIDString];
    return vendorId;
}

@end

