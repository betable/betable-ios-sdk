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

@property (nonatomic, copy) BetableCancelHandler onCancel;

- (BetableWebViewController*)initWithURL:(NSString*)url onCancel:(BetableCancelHandler)onClose;

@end
