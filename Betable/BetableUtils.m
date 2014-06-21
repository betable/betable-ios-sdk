//
//  BetableUtils.m
//  Betable
//
//  Created by Tony hauber on 6/18/14.
//  Copyright (c) 2014 betable. All rights reserved.
//

#import "BetableUtils.h"

id NULLIFY(NSObject *object) {
    if (object == nil) {
        return [NSNull null];
    }
    return object;
}

id NILIFY(NSObject *object) {
    if (object == (id)[NSNull null]) {
        return nil;
    }
    return object;
}

@implementation BetableUtils

@end
