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
#import "BetableProfile.h"

// Acceptable values for onLoadState
#define BETABLE_WALLET_STATE @"chrome.nux.wallet"
#define BETABLE_REGISTER_STATE @"chrome.nux.deposit"
#define BETABLE_LOGIN_STATE @"chrome.auth.play"

@interface BetableWebViewController : UIViewController <UIWebViewDelegate, UIAlertViewDelegate, WKNavigationDelegate>

@property (nonatomic, copy) BetableCancelHandler onCancel;
@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSString* onLoadState;
@property BOOL showInternalCloseButton;
@property BOOL finishedLoading;
@property BOOL portraitOnly;
@property BOOL loadCachedStateOnFinish;
@property BOOL forcedOrientationWithNavController;

- (id)initWithURL:(NSString*)url onCancel:(BetableCancelHandler)onCancel showInternalCloseButton:(BOOL)showInternalCloseButton renderUsingWebkit:(BOOL)useWK;

- (void)closeWindowAndRunCallback:(BOOL)runCallback;
- (void)resetView;
- (void)loadCachedState;

- (void)show;

@end
