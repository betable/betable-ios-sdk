//
//  NSString+Betable.m
//  Betable
//
//  Created by Tony hauber on 6/13/14.
//  Copyright (c) 2014 betable. All rights reserved.
//

#import "NSString+Betable.h"
#import "LoadableCategory.h"

MAKE_CATEGORIES_LOADABLE(NSString_Betable);

@implementation NSString (Betable)

- (NSObject*)objectFromJSONString {
    NSData* JSONdata = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError* jsonError = nil;
    if (JSONdata != nil) {
        NSObject* object = [NSJSONSerialization JSONObjectWithData:JSONdata options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError == nil) {
            return object;
        }
        NSLog(@"JSONERROR: %@", jsonError);

        [NSException raise:@"JSON is not formated correctly"
                    format:@"The JSON returned from the server was improperly formated: %@", jsonError];
    }
    return nil;
}

- (NSString*)stringByDecodingURLFormat {
    NSString* result = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

- (NSString*)stringByEncodingURLFormat {
    NSString* result = [self stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    result = [result stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

- (NSMutableDictionary*)dictionaryFromQueryComponents {
    NSMutableDictionary* queryComponents = [NSMutableDictionary dictionary];
    for (NSString* keyValuePairString in [self componentsSeparatedByString:@"&"]) {
        NSArray* keyValuePairArray = [keyValuePairString componentsSeparatedByString:@"="];
        if ([keyValuePairArray count] < 2) continue; // Verify that there is at least one key, and at least one value.  Ignore extra = signs
        NSString* key = [[keyValuePairArray objectAtIndex:0] stringByDecodingURLFormat];
        NSArray* valueArray = [keyValuePairArray subarrayWithRange:NSMakeRange(1, keyValuePairArray.count-1)];
        NSString* value = [[valueArray componentsJoinedByString:@"="] stringByDecodingURLFormat];
        NSMutableArray* results = [queryComponents objectForKey:key]; // URL spec says that multiple values are allowed per key
        if (!results) { // First object
            results = [NSMutableArray arrayWithCapacity:1];
            [queryComponents setObject:results forKey:key];
        }
        [results addObject:value];
    }
    return queryComponents;
}

@end
