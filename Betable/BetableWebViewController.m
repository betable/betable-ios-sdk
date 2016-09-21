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
+ (NSBundle *)frameworkBundle;
@end

@implementation UIImage (BetableBundle)
+ (UIImage*)frameworkImageNamed:(NSString*)file {
    NSArray *nameParts = [file componentsSeparatedByString:@"."];
    
    NSString *fileName = nameParts[0];
    NSString *fileExtension = nameParts[1];

    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        ([UIScreen mainScreen].scale == 2.0)) {
        fileName = [fileName stringByAppendingString:@"@2x"];
        return [UIImage imageWithContentsOfFile:[[UIImage frameworkBundle] pathForResource:fileName ofType:fileExtension]];
    } else {
        return [UIImage imageWithContentsOfFile:[[UIImage frameworkBundle] pathForResource:fileName ofType:fileExtension]];
    }
}

// Load the framework bundle.
+ (NSBundle *)frameworkBundle {
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


@interface BetableWebViewController () {
    NSError *_errorLoading;
    BOOL _viewLoaded;
    BOOL _errorShown;
    BOOL _noClose;
    UIButton *_closeButton;
}


@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIView *betableLoader;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

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
    }
    return self;
}

- (id)initWithURL:(NSString*)url onCancel:(BetableCancelHandler)onCancel {
    self = [self init];
    if (self) {
        self.url = url;
        self.onCancel = onCancel;
    }
    return self;
}

- (id)initWithURL:(NSString*)url onCancel:(BetableCancelHandler)onCancel showInternalCloseButton:(BOOL)showInternalCloseButton {
    self = [self init];
    if (self) {
        self.showInternalCloseButton = showInternalCloseButton;
        self.url = url;
        self.onCancel = onCancel;
    }
    return self;
}

- (void)setUrl:(NSString *)url {
    _url = url;
    [self preloadWebview];
}

- (void)preloadWebview {
    NSURL *url = [NSURL URLWithString:self.url];
    NSString *queryDelimeter = @"?";
    if ([[url query] length]) {
        queryDelimeter = @"&";
    }
    if (self.showInternalCloseButton) {
        NSString *adjustedURLString = [NSString stringWithFormat:@"%@%@link_back_to_game=true", self.url, queryDelimeter];
        url = [NSURL URLWithString:adjustedURLString];
    }
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, -20, self.view.frame.size.width, self.view.frame.size.height+20)];
    self.webView.clipsToBounds = YES;
    [self.webView loadRequest:request];
    self.webView.hidden = YES;
    self.webView.delegate = self;
    
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
    @try {
        [_closeButton setTranslatesAutoresizingMaskIntoConstraints: NO];
    }
    @catch (NSException *exception) {
        // iOS 5.0 doesn't support auto layout.
        _closeButton.frame = CGRectMake(self.view.frame.size.width-35, 5, 30, 30);
        _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  |   UIViewAutoresizingFlexibleBottomMargin;
        return;
    }
    id topGuide;
    NSString *verticalFormat;
    @try {
        topGuide = self.topLayoutGuide;
        verticalFormat = @"V:[topGuide]-5-[_closeButton(30)]";
    } @catch (NSException *exception) {
        // iOS 6.0 doesn't support topLayoutGuide.
        topGuide = [[UIView alloc] init];
        verticalFormat = @"V:|-5-[_closeButton(30)]";
    }
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings (_closeButton, topGuide);
    NSArray *consts = [NSLayoutConstraint constraintsWithVisualFormat: verticalFormat
                                                              options: 0
                                                              metrics: nil
                                                                views: viewsDictionary];
    [self.view addConstraints:consts];
    
    consts = [NSLayoutConstraint constraintsWithVisualFormat: @"H:[_closeButton(30)]-5-|"
                                                     options: 0
                                                     metrics: nil
                                                       views: viewsDictionary];
    [self.view addConstraints:consts];
}
- (void)addWebViewConstraints {
    //Align webview to the top of the statusBar
    @try {
        [self.webView setTranslatesAutoresizingMaskIntoConstraints: NO];
    }
    @catch (NSException *exception) {
        // iOS 5.0 doesn't support auto layout.
        self.webView.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        return;
    }
    id topGuide;
    NSString *verticalFormat;
    @try {
        topGuide = self.topLayoutGuide;
        verticalFormat = @"V:[topGuide][webView]|";
    } @catch (NSException *exception) {
        // iOS 6.0 doesn't support topLayoutGuide.
        topGuide = [[UIView alloc] init];
        verticalFormat = @"V:|[webView]|";
    }
    if (self.forcedOrientationWithNavController) {
        verticalFormat = @"V:|[webView]|";
    }
    UIView *webView = self.webView;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings (webView, topGuide);
    NSArray *consts = [NSLayoutConstraint constraintsWithVisualFormat: verticalFormat
                                                              options: 0
                                                              metrics: nil
                                                                views: viewsDictionary];
    [self.view addConstraints:consts];
    
    consts = [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[webView]|"
                                                     options: 0
                                                     metrics: nil
                                                       views: viewsDictionary];
    [self.view addConstraints:consts];
}

+ (void)attemptRotationToDeviceOrientation {

}

- (void)viewDidLoad {

    self.view.frame = [[UIScreen mainScreen] bounds];

    [super viewDidLoad];
    
    if (self.forcedOrientationWithNavController) {
        UIView *clockBacker = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
        clockBacker.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:clockBacker];
    }
    
    self.betableLoader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.betableLoader.backgroundColor = [UIColor colorWithRed:238.0/255.0 green:243.0/255.0 blue:347.9/255.0 alpha:1.0];
    self.betableLoader.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.betableLoader];
    
    UIImageView *betableLogo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 63)];
    betableLogo.image = [UIImage frameworkImageNamed:@"betable_player.png"];
    betableLogo.center = CGPointMake(self.betableLoader.frame.size.width/2, self.betableLoader.frame.size.height/2+20);
    
    betableLogo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin;
    
    [self.betableLoader addSubview:betableLogo];
    
    CGFloat logoBottom = betableLogo.frame.origin.y + betableLogo.frame.size.height;
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.frame = CGRectMake(0, logoBottom+20, 40, 40);
    self.spinner.center = CGPointMake(self.betableLoader.frame.size.width/2, self.spinner.center.y);
    [self.spinner startAnimating];
    [self.betableLoader addSubview:self.spinner];
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin;
    
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

- (void)viewWillAppear:(BOOL)animated {

    if (!self.webView) {
        //If the webview was destroyed for memory usage or because of error
        [self preloadWebview];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    if (_errorLoading) {
        [self showErrorAlert:_errorLoading];
    }
}
- (void)closeWindow {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.onCancel) {
            self.onCancel();
        }
        self.onCancel = nil;
    }];
}
- (void)loadCachedState {
    NSString *javacript = @"window.loadCachedState()";
    if (self.onLoadState) {
        [NSString stringWithFormat:@"window.loadCachedState(%@)", self.onLoadState];
    }
    
    if ([self.webView isKindOfClass:[WKWebView class]]) {
        [((WKWebView*)self.webView) evaluateJavaScript:javacript completionHandler:^(id result, NSError *error) {
            if (error != nil) {
                [self showErrorAlert:error];
                return;
            }
        }];
        
    } else if ( [self.webView isKindOfClass:[UIWebView class]] ) {
        [((UIWebView*)self.webView) stringByEvaluatingJavaScriptFromString:javacript];

    } else {
        NSLog( @"CRITICAL! BetableWebViewController cannot run javascript" );
    }
    
    
}

- (void)showErrorAlert:(NSError*)error {
    _errorShown = YES;
    UIAlertController* alert;
    if ([error.domain isEqualToString:@"NSURLErrorDomain"] && error.userInfo[NSURLErrorFailingURLPeerTrustErrorKey]) {
        alert = [UIAlertController alertControllerWithTitle:@"Error connecting to Betable"
                                                    message:@"There was an issue connecting to Betable.  Please ensure that the time and date on this device are correct by going to Settings > General > Date & Time."
                                             preferredStyle:UIAlertControllerStyleAlert];
    } else {
        alert = [UIAlertController alertControllerWithTitle:@"Error connecting to Betable"
                                                    message:@"There was a problem connecting to betable.com at this time. Make sure you are connected to the internet and then try again shortly."
                                             preferredStyle:UIAlertControllerStyleAlert];
    }
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              _errorShown = NO;
                                                              [self closeWindow];
                                                          }];
    [alert addAction:defaultAction];
    [alert show];
    
    [self.webView removeFromSuperview];
    self.webView = nil;
    self.finishedLoading = NO;
    _errorLoading = nil;
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    _errorShown = NO;
    [self closeWindow];
}

#pragma mark - Utilities

- (NSDictionary*)paramsFromURL:(NSURL*)url {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [[url query] componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
    }
    return params;
}

#pragma mark - Orientation Stuff


//
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    return UIInterfaceOrientationPortrait;
//    
//}
//
-(BOOL)shouldAutorotate
{
    if (isPad() || !self.portraitOnly) {
        return YES;
    } else {
        return [[UIDevice currentDevice] orientation] != UIDeviceOrientationPortrait;
    }
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (isPad() || !self.portraitOnly) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - commonalities for web delegate methods

- (void)dealloc {
    self.webView.delegate = nil;
}
@end
