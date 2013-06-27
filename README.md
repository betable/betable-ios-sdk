# Betable iOS SDK

## Setting It Up With Your Project

There are two ways you can get Betable iOS SDK up and working with your project: adding the framework to your project or adding the raw classes.

### Adding the Framework

In the `framework` directory of this repository is a folder called `Betable.framework`.  Download the directory and then drag and drop it onto your project.  Then just `#import <Betable/Betable.h>` in whichever files you reference the Betable object form.  (This is the method that the [`betable-ios-sample`](https://github.com/betable/betable-ios-sample) app uses.)

### Adding the Raw Classes

In the `Betable` directory of this repository are four files: `Betable.h`, `Betable.m`, `JSONKit.h`, `JSONKit.m`: you simply drag these files into your project and the `#import "betable.h"` wherever you wish to use the `Betable` object and you are done.

## `Betable` Object

This is the object that serves as a wrapper for all calls to the Betable API.

### Initializing

    - (Betable*)initWithClientID:(NSString*)clientID clientSecret:(NSString*)clientSecret redirectURI:(NSString*)redirectURI;

To create a `Betable` object simply initilize it with your client ID, client secret and redirect URI.  All of these can be set at <https://developers.betable.com> when you create your game.  We suggest that your redirect URI be <code>betable+<em>game_id</em>://authorize</code>.  See **Authorization** below for more details.

### Adding the Token

<pre><code>self.accessToken = <em>accessToken</em></code></pre>

If you have previously acquired an access token for the user you can simply set it after the initialization, skipping the authorization and access token acquisition steps, and start making requests to the Betable API.

### Authorization

    - (void)authorize;

This method should be called when no access token exists for the current user.  It will initiate the OAuth protocol.  It will bounce the user to the Safari app that is native on the device.  After the person authorizes your app at <https://betable.com>, Betable will redirect them to your redirect URI which can be registered at <https://developers.betable.com> after configuring your game.

The redirect URI should have a protocol that opens your app.  See [Apple's documentation](http://developer.apple.com/library/ios/#documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/AdvancedAppTricks/AdvancedAppTricks.html#//apple_ref/doc/uid/TP40007072-CH7-SW50) for details.  It is suggested that your URL scheme be <code>betable+<em>game_id</em></code> and that your redirect URI be <code>betable+<em>game_id</em>://authorize</code>.  After login in your `UIApplicationDelegate`'s method `application:handleOpenURL:` you can handle the request, which will be formed as <code>betable+<em>game_id</em>://authorize?code=<em>code</em>&state=<em>state</em></code>.

### Getting the Access Token

    - (void)token:(NSString*)code
       onComplete:(BetableAccessTokenHandler)onComplete
        onFailure:(BetableFailureHandler)onFailure;

Once you have the code from the `application:handleOpenURL:` of your `UIApplicationDelegate` after Betable redirects to your app's redirect URI you can pass the code to the `token:onComplete:onFailure` method of your `Betable` object.

This is the final step in the OAuth protocol.  In the `onComplete` handler you will recieve your access token for the user associated with this `Betable` object.  You will want to store this with the user so you can make future requests on their behalf.

### Betting

    - (void)betForGame:(NSString*)gameID
              withData:(NSDictionary*)data
            onComplete:(BetableCompletionHandler)onComplete
             onFailure:(BetableFailureHandler)onFailure;

This method is used to place a bet for the user associated with this Betable object.

* `gameID`: this is your gameID which is registered and can be checked at <https://developers.betable.com>
* `data`: this is a dictionary that will converted to JSON and sent as the request body.  It contains all the important information about the bet being made.  For documentation on the format of this dictionary see <https://developers.betable.com/docs#api-documentation>.
* `onComplete`: this is a block that will be called in case of success.  Its only argument is a dictionary that contains Betable's JSON response.
* `onFailure`: This is a block that will be called in case of error.  Its arguments are the `NSURLResponse` object, the string reresentation of the body, and the `NSError` that was raised.

### Getting User's Account

    - (void)userAccountOnComplete:(BetableCompletionHandler)onComplete
                        onFailure:(BetableFailureHandler)onFailure;

This method is used to retrieve information about the account of the user associated with this `Betable` object.

* `onComplete`: this is a block that will be called in case of success.  Its only argument is a dictionary that contains Betable's JSON response.
* `onFailure`: this is a block that will be called in case of error.  Its arguments are the `NSURLResponse` object, the string reresentation of the body, and the `NSError` that was raised.

### Getting User's Wallet

    - (void)userWalletOnComplete:(BetableCompletionHandler)onComplete
                       onFailure:(BetableFailureHandler)onFailure;

This method is used to retrieve information about the wallet of the user associated with this betable object.


* `onComplete`: this is a block that will be called in case of success.  Its only argument is a dictionary that contains Betable's JSON response.
* `onFailure`: this is a block that will be called in case of error.  Its arguments are the `NSURLResponse` object, the string reresentation of the body, and the `NSError` that was raised.

### Completion and Failure Handlers

#### BetableAccessTokenHandler:

    typedef void (^BetableAccessTokenHandler)(NSString *accessToken);

This is called when `token:onCompletion:onFailure` successfully retrieves the access token.

#### BetableCompletionHandler:

    typedef void (^BetableCompletionHandler)(NSDictionary *data);

This is called when any of the APIs successfully return from the server.  `data` is a nested NSDictionary object that represents the JSON response.

#### BetableFailureHandler:

    typedef void (^BetableFailureHandler)(NSURLResponse *response, NSString *responseBody, NSError *error);

This is called when something goes wrong during the request.  `error` will have details about the nature of the error and `responseBody` will be a string representation of the body of the response.

### Accessing the API URLs

* `(NSString*)getTokenURL;`
* `(NSString*)getBetURL:(NSString*)gameID;`
* `(NSString*)getWalletURL;`
* `(NSString*)getAccountURL;`
