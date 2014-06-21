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
    NSData *JSONdata = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError = nil;
    if (JSONdata != nil) {
        NSObject *object = [NSJSONSerialization JSONObjectWithData:JSONdata options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError == nil) {
            return object;
        }
        NSLog(@"JSONERROR: %@", jsonError);
        
        [NSException raise:@"JSON is not formated correctly"
                    format:@"The JSON returned from the server was improperly formated: %@", jsonError];
    }
    return nil;
}
@end
