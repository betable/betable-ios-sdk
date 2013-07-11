//
//  BetableAuthViewController.m
//  Betable
//
//  Created by Robert Forte on 7/3/13.
//
//

#import "BetableAuthViewController.h"

@interface BetableAuthViewController ()

@end

@implementation BetableAuthViewController

@synthesize authURL, webView, toolbar;

-(id) initWithURLString:(NSString*)url {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.authURL = url;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    // Add toolbar + cancel button
    self.view.autoresizesSubviews = YES;
//    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, 44);
    self.toolbar = [[UIToolbar alloc] initWithFrame:rect];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbar.barStyle = UIBarStyleBlack;
    [toolbar sizeToFit];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancelAuth:)]];
    [toolbar setItems:items animated:NO];
    [items release];
    [self.view addSubview:toolbar];
    
    // Add webview
    rect = self.view.bounds;
    rect.origin.y += toolbar.bounds.size.height;
    rect.size.height -= toolbar.bounds.size.height;
    self.webView = [[UIWebView alloc] initWithFrame:rect];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.delegate = self;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.authURL]]];
    [self.view addSubview:webView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.webView = nil;
    self.toolbar = nil;
    self.authURL = nil;
}

- (void) cancelAuth:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *url = [request.URL absoluteString];
    NSLog(@"loading: %@", url);
    
    if ([url rangeOfString:@"//authorize?code="].location != NSNotFound) {
        [self dismissModalViewControllerAnimated:YES];
    }
    
    return YES;
}

- (void) dealloc {
    [super dealloc];
    self.authURL = nil;
    self.webView = nil;
    self.toolbar = nil;
}
@end
