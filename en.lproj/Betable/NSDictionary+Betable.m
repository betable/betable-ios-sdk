//
//  NSDictionary+Betable.m
//  Betable
//
//  Created by Tony hauber on 6/13/14.
//  Copyright (c) 2014 betable. All rights reserved.
//

#import "NSDictionary+Betable.h"
#import "LoadableCategory.h"

MAKE_CATEGORIES_LOADABLE(NSDictionary_Betable);

@implementation NSDictionary (Betable)

- (NSData*)JSONData {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:0
                                                         error:&error];
    if (!jsonData) {
        return nil;
    } else if (!error) {
        return jsonData;
    }
    [NSException raise:@"JSON is not formated correctly"
                format:@"The JSON returned from the server was improperly formated"];
    return nil;
}

@end
