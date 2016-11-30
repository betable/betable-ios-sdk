//
//  BetableWebViewController.m
//  Betable
//
//  Created by Tony hauber on 7/10/13.
//
//

#import "BetableWebViewController.h"
#import "UIAlertController+Window.h"

BOOL isPad() {
    UIDevice* device = [UIDevice currentDevice];
    return
        // App was built for iPad
        [device userInterfaceIdiom] == UIUserInterfaceIdiomPad ||
        // It's been reported the idiom result misses some iPads--so fall back to harware model
        [device.model rangeOfString:@"iPad"].location != NSNotFound;
}

@interface UIImage (BetableBundle)
+ (UIImage*)frameworkImageNamed:(NSString*)file;
+ (NSBundle*)frameworkBundle;
@end

@implementation UIImage (BetableBundle)
+ (UIImage*)frameworkImageNamed:(NSString*)file {
    NSArray* nameParts = [file componentsSeparatedByString:@"."];

    NSString* fileName = nameParts[0];
    NSString* fileExtension = nameParts[1];

    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        ([UIScreen mainScreen].scale == 2.0)) {
        fileName = [fileName stringByAppendingString:@"@2x"];
        return [UIImage imageWithContentsOfFile:[[UIImage frameworkBundle] pathForResource:fileName ofType:fileExtension]];
    } else {
        return [UIImage imageWithContentsOfFile:[[UIImage frameworkBundle] pathForResource:fileName ofType:fileExtension]];
    }
}

// Load the framework bundle.
+ (NSBundle*)frameworkBundle {
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"Betable.bundle"];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });
    return frameworkBundle;
}

@end


@interface BetableWebViewController (){
    NSError* _errorLoading;
    BOOL _viewLoaded;
    BOOL _errorShown;
    BOOL _noClose;
    UIButton* _closeButton;
    BOOL _useWK;
}

@property (nonatomic, strong) UIView* webView;
@property (nonatomic, strong) UIView* betableLoader;
@property (nonatomic, strong) UIActivityIndicatorView* spinner;

@end

@implementation BetableWebViewController

- (id)init {
    self = [super init];
    if (self) {
        self.finishedLoading = NO;
        _errorLoading = nil;
        _viewLoaded = NO;
        _errorShown = NO;
        self.portraitOnly = NO;
        self.showInternalCloseButton = YES;
        _useWK = YES;
    }
    return self;
}

- (id)initWithURL:(NSString*)url onClose:(BetableCloseHandler)onClose showInternalCloseButton:(BOOL)showInternalCloseButton renderUsingWebkit:(BOOL)useWK {
    self = [self init];
    if (self) {
        self.showInternalCloseButton = showInternalCloseButton;
        [self setUrl:url renderUsingWebkit:useWK];
        self.onClose = onClose;
    }
    return self;
}

- (void)setUrl:(NSString*)url renderUsingWebkit:(BOOL)useWK {
    _url = url;
    [self preloadWebviewUsingWebkit:useWK];
}

- (void)preloadWebviewUsingWebkit:(BOOL)useWK {
    _useWK = NSClassFromString(@"WKWebView") && useWK;

    NSURL* url = [NSURL URLWithString:self.url];
    NSString* queryDelimeter = @"?";
    if ([[url query] length]) {
        queryDelimeter = @"&";
    }
    if (self.showInternalCloseButton) {
        NSString* adjustedURLString = [NSString stringWithFormat:@"%@%@link_back_to_game=true", self.url, queryDelimeter];
        url = [NSURL URLWithString:adjustedURLString];
    }
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];

    CGRect rect = CGRectMake(0, -20, self.view.frame.size.width, self.view.frame.size.height+20);
    if (_useWK) {
        WKWebView* webView = [[WKWebView alloc] initWithFrame:rect];
        [webView setNavigationDelegate:self];
        [webView loadRequest:request];
        self.webView = webView;

    } else {
        UIWebView* webView = [[UIWebView alloc] initWithFrame:rect];
        webView.delegate = self;
        [webView loadRequest:request];
        self.webView = webView;
    }

    self.webView.clipsToBounds = YES;
    self.webView.hidden = YES;

    [self.view insertSubview:self.webView atIndex:0];
    [self addWebViewConstraints];

    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButton setTitle:@"×" forState:UIControlStateNormal];
    [_closeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    _closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:32];
    [_closeButton addTarget:self action:@selector(closeWindow) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:_closeButton];
    [self addCloseButtonConstraints];
}

- (void)addCloseButtonConstraints {
    [_closeButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    id topGuide = self.topLayoutGuide;
    NSString* verticalFormat = @"V:[topGuide]-5-[_closeButton(30)]";
    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(_closeButton, topGuide);
    NSArray* constraints = [NSLayoutConstraint constraintsWithVisualFormat:verticalFormat
                                                                   options:0
                                                                   metrics:nil
                                                                     views:viewsDictionary];
    [self.view addConstraints:constraints];

    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_closeButton(30)]-5-|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDictionary];
    [self.view addConstraints:constraints];
}

- (void)addWebViewConstraints {
    //Align webview to the top of the statusBar
    [self.webView setTranslatesAutoresizingMaskIntoConstraints:NO];

    NSString* verticalFormat = @"V:[topGuide][webView]|";
    if (self.forcedOrientationWithNavController) {
        verticalFormat = @"V:|[webView]|";
    }

    // Dictionary keys by name...
    id topGuide = self.topLayoutGuide;
    id webView = self.webView;

    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(webView, topGuide);
    NSArray* consts = [NSLayoutConstraint constraintsWithVisualFormat:verticalFormat
                                                              options:0
                                                              metrics:nil
                                                                views:viewsDictionary];
    [self.view addConstraints:consts];

    consts = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|"
                                                     options:0
                                                     metrics:nil
                                                       views:viewsDictionary];
    [self.view addConstraints:consts];
}

+ (void)attemptRotationToDeviceOrientation {

}

- (void)viewDidLoad {

    self.view.frame = [[UIScreen mainScreen] bounds];

    [super viewDidLoad];

    if (self.forcedOrientationWithNavController) {
        UIView* clockBacker = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
        clockBacker.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:clockBacker];
    }

    self.betableLoader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.betableLoader.backgroundColor = [UIColor colorWithRed:238.0/255.0 green:243.0/255.0 blue:347.9/255.0 alpha:1.0];
    self.betableLoader.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.betableLoader];

    UIImageView* betableLogo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 63)];
    betableLogo.image = [UIImage frameworkImageNamed:@"betable_player.png"];
    betableLogo.center = CGPointMake(self.betableLoader.frame.size.width/2, self.betableLoader.frame.size.height/2+20);

    betableLogo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    [self.betableLoader addSubview:betableLogo];

    CGFloat logoBottom = betableLogo.frame.origin.y + betableLogo.frame.size.height;
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.frame = CGRectMake(0, logoBottom+20, 40, 40);
    self.spinner.center = CGPointMake(self.betableLoader.frame.size.width/2, self.spinner.center.y);
    [self.spinner startAnimating];
    [self.betableLoader addSubview:self.spinner];
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    //If we have already loaded then don't show the betableLoader and show the webview
    if (self.finishedLoading) {
        self.betableLoader.hidden = YES;
    } else {
        self.betableLoader.hidden = NO;
    }
}

- (void)resetView {
    CGRect frame = self.betableLoader.frame;
    frame.origin.y = 0;
    self.betableLoader.frame = frame;
}

- (void)viewDidAppear:(BOOL)animated {
    if (_errorLoading) {
        [self showErrorAlert:_errorLoading];
    } else if (!self.webView) {
        // This is pretty late, but by this point _useWK should be properly set...
        NSLog(@"Preloading missing webview...");
        [self preloadWebviewUsingWebkit:_useWK];
    }
    [super viewDidAppear:animated];
}

- (void)closeWindow {
    [self closeWindowAndRunCallback:YES];
}

- (void)closeWindowAndRunCallback:(BOOL)runCallback  {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (runCallback && self.onClose) {
            self.onClose();
        }

        if (_useWK) {
            [((WKWebView*)self.webView) setNavigationDelegate:nil];
        } else {
            ((UIWebView*)self.webView).delegate = nil;
        }


    }];
}

- (void)loadCachedState {
    NSString* javacript = @"window.loadCachedState();";
    if (self.onLoadState) {
        javacript = [NSString stringWithFormat:@"window.loadCachedState('%@');", self.onLoadState];
    }

    if (_useWK) {
        [((WKWebView*)self.webView) evaluateJavaScript:javacript completionHandler:^(id result, NSError* error) {
            if (error != nil) {
                [self showErrorAlert:error];
                return;
            }
        }];

    } else {
        [((UIWebView*)self.webView) stringByEvaluatingJavaScriptFromString:javacript];
    }

}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView*)webView {
    [self delegateFinishedLoading];
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    return [self shouldDelegateLoadRequest:request];
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    [self delegateLoadingError:error];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView*)webView didFinishNavigation:(WKNavigation*)navigation {
    [self delegateFinishedLoading];
}

- (void)webView:(WKWebView*)webView decidePolicyForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([self shouldDelegateLoadRequest:navigationAction.request ]) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void)webView:(WKWebView*)webView didFailProvisionalNavigation:(WKNavigation*)navigation withError:(NSError*)error {
    [self delegateLoadingError:error];
}

- (void)showErrorAlert:(NSError*)error {
    _errorShown = YES;

    NSString* title = @"Error connecting to Betable";
    NSString* message = @"There was a problem connecting to betable.com at this time. Make sure you are connected to the internet and then try again shortly";
    if ([error.domain isEqualToString:@"NSURLErrorDomain"] && error.userInfo[NSURLErrorFailingURLPeerTrustErrorKey]) {
        message = @"There was an issue connecting to Betable.  Please ensure that the time and date on this device are correct by going to Settings > General > Date & Time";
    }

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction* action) {
        _errorShown = NO;
        [self closeWindow];
    }];
    [alert addAction:defaultAction];
    [alert show];

    self.finishedLoading = NO;
    _errorLoading = nil;
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    _errorShown = NO;
    [self closeWindow];
}

#pragma mark - Utilities

- (NSDictionary*)paramsFromURL:(NSURL*)url {
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    for (NSString* param in [[url query] componentsSeparatedByString:@"&"]) {
        NSArray* elts = [param componentsSeparatedByString:@"="];
        if ([elts count] < 2) continue;
        [params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
    }
    return params;
}

#pragma mark - Orientation Stuff

- (BOOL)shouldAutorotate {
    if (isPad() || !self.portraitOnly) {
        return YES;
    } else {
        return [[UIDevice currentDevice] orientation] != UIDeviceOrientationPortrait;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (isPad() || !self.portraitOnly) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - commonalities for web delegate methods

- (void)delegateFinishedLoading {
    self.webView.hidden = NO;
    [self.spinner stopAnimating];
    self.finishedLoading = YES;
    _closeButton.hidden = YES;

    if (self.loadCachedStateOnFinish) {
        [self loadCachedState];
    }

    if (!self.betableLoader.hidden) {
        [UIView animateWithDuration:.2 animations:^{
            CGRect frame = self.betableLoader.frame;
            frame.origin.y = -10;
            self.betableLoader.frame = frame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.2 animations:^{
                CGRect frame = self.betableLoader.frame;
                frame.origin.y = -frame.size.height;
                self.betableLoader.frame = frame;
            } completion:^(BOOL finished) {
                self.betableLoader.hidden = YES;
            }];
        }];
    }
}

- (BOOL)shouldDelegateLoadRequest:(NSURLRequest*)request {
    NSURL* url = request.URL;
    NSDictionary* params = [self paramsFromURL:url];
    if (![[url scheme] isEqualToString:@"http"] && ![[url scheme] isEqualToString:@"https"]) {
        BOOL userCloseError = params[@"error"] && [params[@"error_description"] isEqualToString:@"user_close"];
        BOOL userCloseAction = [params[@"action"] isEqualToString:@"close"];
        if (userCloseAction || userCloseError) {
            [self closeWindow];
        } else {

            [[UIApplication sharedApplication] openURL:url];
        }
        return NO;
    } else if ([[url host] rangeOfString:@"prospecthallcasino.com"].location != NSNotFound && params[@"reason"] && params[@"gameId"] && params[@"sessId"]) {

        //This is enough to determine that the home button was hit with netent
        [self closeWindow];
    }
    return YES;
}

- (void)delegateLoadingError:(NSError*)error {
    if (_viewLoaded) {
        NSLog(@"Showing Error on failure");
        [self showErrorAlert:error];
    } else if (!_errorShown) {
        _errorLoading = error;
    } else {
        _errorLoading = nil;
    }
}

# pragma mark - Standalone View Controller Stuff


- (void)show {

    UIWindow* webViewWindow = [UIApplication sharedApplication].keyWindow;
    [webViewWindow.rootViewController presentViewController:self animated:YES completion:nil];
}

@end
