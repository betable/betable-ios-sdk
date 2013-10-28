//
//  BetableWebViewController.h
//  Betable
//
//  Created by Tony hauber on 7/10/13.
//
//

#import <UIKit/UIKit.h>
#import "BetableHandlers.h"

@interface BetableWebViewController : UIViewController <UIWebViewDelegate, UIAlertViewDelegate>

@property (nonatomic, copy) BetableCancelHandler onCancel;
@property (nonatomic, strong) NSString *url;

- (BetableWebViewController*)initWithURL:(NSString*)url onCancel:(BetableCancelHandler)onClose;

- (void)closeWindow;
- (void)resetView;
@end
