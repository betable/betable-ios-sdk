//
//  BetableWebViewController.m
//  Betable
//
//  Created by Tony hauber on 7/10/13.
//
//

#import "BetableWebViewController.h"

BOOL isPad() {
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
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
    BOOL _finishedLoading;
    NSError *_errorLoading;
    BOOL _viewLoaded;
    BOOL _errorShown;
}

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIView *betableLoader;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation BetableWebViewController

- (id)init {
    self = [super init];
    if (self) {
        _finishedLoading = NO;
        _errorLoading = nil;
        _viewLoaded = NO;
        _errorShown = NO;
    }
    return self;
}

- (id)initWithURL:(NSString*)url onCancel:(BetableCancelHandler)onCancel {
    self = [self init];
    if (self) {
        self.url = url;
        self.onCancel = onCancel;
        [self preloadWebview];
    }
    return self;
}

- (void)preloadWebview {
    CGRect frame = [[UIScreen mainScreen] bounds];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.url]];
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.webView loadRequest:request];
    self.webView.hidden = YES;
    self.webView.delegate = self;
}

- (void)viewDidLoad {
    self.view.frame = [[UIScreen mainScreen] bounds];

    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
    
    self.betableLoader = [[UIView alloc] initWithFrame:CGRectMake(0, -20, self.view.frame.size.width, self.view.frame.size.height+20)];
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
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(self.view.frame.size.width-40, 7, 30, 30);
    [closeButton setTitle:@"×" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:32];
    [closeButton addTarget:self action:@selector(closeWindow) forControlEvents:UIControlEventTouchUpInside];
    
    closeButton.autoresizingMask =UIViewAutoresizingFlexibleLeftMargin  |   UIViewAutoresizingFlexibleBottomMargin;
    
    [self.view addSubview:closeButton];
    
    //If we have already loaded then don't show the betableLoader and show the webview
    if (_finishedLoading) {
        self.webView.hidden = NO;
        self.betableLoader.hidden = YES;
    } else {
        self.webView.hidden = YES;
        self.betableLoader.hidden = NO;
    }
    
    _viewLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated {

    if (!self.webView) {
        //If the webview was destroyed for memory usage or because of error
        [self preloadWebview];
    }
    if ([self.webView superview] == nil) {
        [self.view addSubview:self.webView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    if (_errorLoading) {
        [self showErrorAlert:_errorLoading];
    }
}
- (void)closeWindow {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    if (self.onCancel) {
        self.onCancel();
    }
    self.onCancel = nil;
}

#pragma mark - Web View Delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.webView.hidden = NO;
    [self.spinner stopAnimating];
    _finishedLoading = YES;
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

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    if (_viewLoaded) {
        NSLog(@"Showing Error on fail");
        [self showErrorAlert:error];
    } else if (!_errorShown) {
        _errorLoading = error;
    } else {
        _errorLoading = nil;
    }
}

- (void)showErrorAlert:(NSError*)error {
    _errorShown = YES;
    if ([error.domain isEqualToString:@"NSURLErrorDomain"] && error.userInfo[NSURLErrorFailingURLPeerTrustErrorKey]) {
        [[[UIAlertView alloc] initWithTitle:@"Error connecting to Betable" message:@"There was an issue connecting to Betable.  Please ensure that the time and date on this device are correct by going to Settings > General > Date & Time." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error connecting to Betable" message:@"There was a problem connecting to betable.com at this time. Make sure you are connected to the internet and then try again shortly." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
    [self.webView removeFromSuperview];
    self.webView = nil;
    _finishedLoading = NO;
    _errorLoading = nil;
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    _errorShown = NO;
    [self closeWindow];
}

#pragma mark - Orientation Stuff

-(BOOL)shouldAutorotate
{
    if (isPad()) {
        return YES;
    } else {
        return NO;
    }
}

-(NSUInteger)supportedInterfaceOrientations
{
    if (isPad()) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

// pre-iOS 6 support
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (isPad()) {
        return YES;
    } else {
        return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
    }
}
@end
