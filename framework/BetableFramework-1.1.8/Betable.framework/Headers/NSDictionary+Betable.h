//
//  NSDictionary+Betable.h
//  Betable
//
//  Created by Tony hauber on 6/13/14.
//  Copyright (c) 2014 betable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Betable)

- (NSData*)JSONData;
-(NSString*) urlEncodedString;

@end
