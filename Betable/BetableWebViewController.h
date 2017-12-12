//
//  BetableWebViewController.h
//  Betable
//
//  Created by Tony hauber on 7/10/13.
//
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "BetableHandlers.h"

// Acceptable values for onLoadState
#define BETABLE_WALLET_STATE @"chrome.nux.wallet"
#define BETABLE_REGISTER_STATE @"chrome.nux.deposit"
#define BETABLE_LOGIN_STATE @"chrome.auth.play"

@interface BetableWebViewController : UIViewController <UIWebViewDelegate, UIAlertViewDelegate, WKNavigationDelegate>

@property (nonatomic, copy) BetableCloseHandler onClose;
@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSString* onLoadState;
@property BOOL showInternalCloseButton;
@property BOOL finishedLoading;
@property BOOL loadCachedStateOnFinish;

- (id)initWithURL:(NSString*)url onClose:(BetableCloseHandler)onClose showInternalCloseButton:(BOOL)showInternalCloseButton renderUsingWebkit:(BOOL)useWK;

- (void)closeWindowAndRunCallback:(BOOL)runCallback;
- (void)resetView;
- (void)loadCachedState;

- (void)show;

@end
