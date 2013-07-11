//
//  BetableAuthViewController.h
//  Betable
//
//  Created by Robert Forte on 7/3/13.
//
//

#import <UIKit/UIKit.h>

@interface BetableAuthViewController : UIViewController<UIWebViewDelegate> {
    UIWebView *webView;
    NSString *authURL;
    UIToolbar *toolbar;
}

-(id) initWithURLString:(NSString*)authURL;

@property (retain, nonatomic) UIWebView *webView;
@property (retain, nonatomic) NSString *authURL;
@property (retain, nonatomic) UIToolbar *toolbar;

@end
