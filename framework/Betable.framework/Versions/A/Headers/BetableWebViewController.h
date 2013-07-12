//
//  BetableWebViewController.h
//  Betable
//
//  Created by Tony hauber on 7/10/13.
//
//

#import <UIKit/UIKit.h>
#import "BetableHandlers.h"

@interface BetableWebViewController : UIViewController <UIWebViewDelegate>

- (BetableWebViewController*)initWithURL:(NSString*)url onClose:(BetableCancelHandler)onClose;

@end
