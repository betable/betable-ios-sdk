//
//  NSString+stringUtil.h
//  WhereYouAt
//
//  Created by Tony Hauber on 11/2/12.
//
//

#import <Foundation/Foundation.h>

@interface NSString (TCF)

- (NSString*)pluralize:(NSInteger)count;
- (NSString *)stringByDecodingURLFormat;
- (NSString *)stringByEncodingURLFormat;
- (NSMutableDictionary *)dictionaryFromQueryComponents;

@end
