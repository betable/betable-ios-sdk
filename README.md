If the SDK you downloaded does not have a versioning number, assume it is pre 0.8.0.


**NOTES for upgrading to 1.0 and above:**

* To update you must be sure to call [betable launchWithOptions:launchOptions] in your app delegate's +applicationDidFinishLaunchingWithOptions: method
* You must add `AdSupport.framework` and `iAd.framework` to your projects
* For 5.1 support you need to set the AdSupport iAd and Foundation frameworks to optional under "Link Binary With Libraries" in the "Build Phases" section of your target's settings.
* You must add `-ObjC` to your other linker flags inside your target's build settings

# Changelog

## 1.1.6a [Download](https://github.com/betable/betable-ios-sdk/releases/download/v1.1.6a/BetableFramework-1.1.6a.zip)

Ensure localhost is off in both source and binary


## 1.1.6 [Download](https://github.com/betable/betable-ios-sdk/releases/download/v1.1.6/BetableFramework-1.1.6.zip)

Ensure reality checks are displayed from the correct thread (main)


## 1.1.5 [Download](https://github.com/betable/betable-ios-sdk/releases/download/v1.1.5/BetableFramework-1.1.5.zip)

Release 1.1.4 included some debugging that would cause problems on production systems.


## 1.1.4 [Download](https://github.com/betable/betable-ios-sdk/releases/download/v1.1.4/BetableFramework-1.1.4.zip)

Update naming of authentication cookies, ensure calls all provide a session_id


## 1.1.2 [Download](https://github.com/betable/betable-ios-sdk/releases/download/v1.1.2/BetableFramework-1.1.2.zip)

* Fixed selector for onCredentialsFailure


## 1.1.1  [Download](https://github.com/betable/betable-ios-sdk/releases/download/v1.1.1/BetableFramework-1.1.1.zip)

* Housekeeping.  Removed some clutter
* Pulled CFBundleExecutable key from bundled plist


## 1.1.0  [Download](https://github.com/betable/betable-ios-sdk/releases/download/v1.1.0/BetableFramework-1.1.0.zip)

* Added player reality checks to coincide with session compatablity changes in Betable's SDK
* Note: The notion of accessToken in the game is now handled by a Credentials class and methods requiring
backed access tokens are all depricated in favour of a checkCredentials method and a number of callbacks.
The callback will be called asynchronously over the livetime of the session because player reality checks 
may be triggered repeatedly over the lifetime of the given session.  


## 1.0.7

**Changes** 

* Now targeting changes to iOS 9 sdk with xcode 7.2

## 1.0.6

 * Added operator support. Open any betable powered game inside of your app

## 1.0.5

**Changes** 

* Now supporting iOS 8 keyboard orientation

**1.0 Changes**

* Now supporting install attribution through adjust.
* Added calls for displaying deposit, withdraw, wallet, and redeem track endpoints
* Now supporting the storing of an access token in the keychain
* Now requires `AdSupport.framework`
* Support for iOS7
* More stable pre-caching of authorize page
* Now using a track enpoint for better tracking of users, and tracks users through ad installs.

## 1.0.4 

* Added 5.1 support
* No longer persisting stored access tokens after app deletion.
* Removed the requirement to add an environment
* Added -supportInViewController:onClose: although the website does not currently support it
* Added landscape views for all web views except authorize
* Exposing the proper methods from betable.h

## 0.9.0

* Added hooks for Betable Testing Profiles. Which allows you to test your games against new features and flows, without changing the code at all (Coming Soon)

## 0.8.0

* Now supports batched requests
* Uses in app web view for authorization instead of bouncing to Safari
* Now supports unbacked bets and credit bets.
* added logout method, which properly clears cookies and access tokens when a user logs out.

# Betable iOS SDK

## Adding the Framework

In the `framework` directory under the version you wish to install are two folder called `Betable.framework` and `Betable.bundle`.  Download these directories and then drag and drop them into your project (Usually into the frameworks group).  Then just `#import <Betable/Betable.h>` in whichever files you reference the Betable object form.  (This is the method that the [`betable-ios-sample`](https://github.com/betable/betable-ios-sample) app uses.)

To use this framework you are required to include the following iOS frameworks: `Foundation.framework`, `UIKit.framework`, `iAd.framework`, and `AdSupport.framework`.

You must also add `-ObjC` to other linker flags under your target's build settings.

If you want to modify the code and build a new framework, simply build the Framework target in this project and the folders will be built to the proper build locations (usually `~/Library/Developer/Xcode/DerivedData/Betable.framework-<hash>/Build/Products/Debug-iphoneos/`).  Simply drag those files into your project from there or you can link to them so you can continue development on both the framework and your project at the same time.

## `Betable` Object

This is the object that serves as a wrapper for all calls to the Betable API.

### Initializing

    - (Betable*)initWithClientID:(NSString*)clientID
                    clientSecret:(NSString*)clientSecret
                     redirectURI:(NSString*)redirectURI;
                     environment:(NSString*)environment;

To create a `Betable` object simply initilize it with your client ID, client secret and redirect URI.  All of these can be set at <https://developers.betable.com> when you create your game.  Your redirect URI needs to have a custom unique scheme and the domain needs to be authorize. An example is betable+<company_name>+<game_name>://authorize .  It is important that it is unique so the oauth flow can be completed.  See **Authorization** below for more details. For environment you can set it to `BetableEnvironmentProduction` or `BetableEnvironmentSandbox`. **It is important that this be set to `BetableEnvironmentSandbox` unless you are releasing your app**

### Launching

You must now launch your app before the game can authorize or use any API's. This must be done in the `UIApplicationDelegate`'s `+applicationDidFinishLaunchingWithOptions:` method. to launch, simply call the `launchWithOptions:` method on the betable object and pass in the launchOptions from the `+applicationDidFinishLaunchingWithOptions:` method.

    - (void)launchWithOptions:(NSDictionary*)launcOptions;


### Credentials

As of Betable v1.1; session lifetimes are no longer scoped within the SDK and relying on `accessToken` alone may result in undesired behaviours 

* Note that unbacked betting does not require a session and will continue to work as before

Calls to

    - (void)storeAccessToken
    - (BOOL)loadStoredAccessToken
    - (void)authorizeInViewController

and their respective callbacks will continue to work for the interim, but may result in poor experience for players as they cannot properly manage the player's session.

    - (void)checkCredentials:(id<BetableCredentialCallbacks> _Nonnull) callbacks

The game should then call this method as soon as credentials are required and the game is comfortable asking the player to log in.

The SDK will begin monitoring the lifetime of the player's session via regular heartbeats, and will extend the session as player behaviour demands--which may involve removing control from the game to facilitate player decision-making regarding timed reality checks.  If the player doesn't have a live session when called, it will prompt the player to log in.

Prompting the player to log in will be done via OAuth protocol.  It will open a UIWebView in portrait and direct it to the Betable signup/login page.  After the player authorizes your app at <https://betable.com>, Betable will redirect them to your redirect URI which can be registered at <https://developers.betable.com> when configuring your game.

The redirect URI should have a protocol that opens your app.  See [Apple's documentation](http://developer.apple.com/library/ios/#documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/AdvancedAppTricks/AdvancedAppTricks.html#//apple_ref/doc/uid/TP40007072-CH7-SW50) for details.  It is suggested that your URL scheme be `betable+<em>game_id</em>` and that your redirect URI be `betable+<em>game_id</em>://authorize<`.

After the player has authorized the player, the authorize view will invoke your app's `handleOpenURL:` in the game's `UIApplicationDelegate`.  In that method, the game should pass the redirect URI to the `Betable` object's `handleAuthorizeURL:` method.

This is the final step in the OAuth protocol.

Implementing `BetableCredentialCallbacks` is mostly a matter of the `Betable` object notifying the game what is going on where player's credentials are concerned...

    - (UIViewController*) currentGameView;
    
Is the only required method in the protocol--it needs to return the `UIViewController` currently active when a reality check asynchronously goes off--for simplicity, it may be enough to return `[UIApplication sharedApplication].delegate.window.rootViewController` but more complicated UIs may warrant more complicated controller reporting.

    -(void) onCredentialsSuccess:(BetableCredentials*) credentials;

Will notify the game that the player has valid credentials--possibly after a login, or possibly extended from a previous credential check.  Consider this a cue that SDK calls requiring an `accessToken` or a `sessionID` are now feasible--both are readonly properties of the passed `BetableCredentials` object.

    -(void) onCredentialsRevoked;

Will notify the game that while at some point earlier `onCredentialsSuccess` indicated the player had credentials--this is no longer the case.  A call to `checkCredentials` again may be required--though its possible the the game called `logout` or the player decided to stop playing after a reality check.

    -(void) onCredentialsFailure;

Will notify the game that `onCredentialsSuccess` is not going to be called and a call to `checkCredentials` again may be required.

    - (void) onPreRealityCheck;

Will notify the game that a reality check is in order.  This is an opportunity for the game to block the `Betable` object before it engages with the player in a reality check--and offers the game an opportunity to do housekeeping before relinquishing control back to `Betable`.

    - (void) onPostRealityCheck;

Will notify the game that a reality check has finished--this is an opportunity for the game to recover following a reality check.  Note that the reality check may also revoke credentials during this time as per the player's indication to do so.

### Logging out

    - (void)logout

If the game needs to disassociate the current player with the betable object and end their session; simply call the logout method.  This handles destroying the cookies, resetting the authorize web browser, and removing the `BetableCredentials` object from the `Betable` object.

### Launching Web Views

You can launch a couple of other web views for the other track endpoints. They all require you give the viewController that they will be displayed over modally. They all take an onClose method. To protect the user the onClose method does not return any information about what actions the user has taken while the webview is displayed. It will simply notifiy you that they browser has closed.

#### Deposit

    - (void)depositInViewController:(UIViewController*) onClose:(BetableCancelHandler);

#### Withdraw

    - (void)withdrawInViewController:(UIViewController*) onClose:(BetableCancelHandler);

#### Wallet

    - (void)walletInViewController:(UIViewController*) onClose:(BetableCancelHandler);

#### Redeem

    - (void)redeemPromotion:(NSString*) inViewController:(UIViewController*) onClose:(BetableCancelHandler);

    For this you can pass in the promotion as the first argument. It should be a string version of the complete unencoded URL for the promotion.

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

####Unbacked Betting
If you want to make a bet that is not backed by the accounting software but just uses our betting math, you can make an unbacked bet. 
    - (void)unbackedBetForGame:(NSString*)gameID
                      withData:(NSDictionary*)data
                    onComplete:(BetableCompletionHandler)onComplete
                     onFailure:(BetableFailureHandler)onFailure;

If you would like to do this with an unauthorized user you can an access token that only has unbacked betting permission from the following method:

    - (void)unbackedToken:(NSString*)clientUserID
               onComplete:(BetableAccessTokenHandler)onComplete
                onFailure:(BetableFailureHandler)onFailure;

#### Credit Betting

If you want to make a credit bet, backed and unbacked, use these two methods respectively:

    - (void)creditBetForGame:(NSString*)gameID
                  creditGame:(NSString*)creditGameID
                    withData:(NSDictionary*)data
                  onComplete:(BetableCompletionHandler)onComplete
                   onFailure:(BetableFailureHandler)onFailure;

    - (void)unbackedCreditBetForGame:(NSString*)gameID
                          creditGame:(NSString*)creditGameID
                            withData:(NSDictionary*)data
                          onComplete:(BetableCompletionHandler)onComplete
                           onFailure:(BetableFailureHandler)onFailure;

In both of these methods `creditGameID` is the ID of the game for which you would like to make a bet.  `gameID` is the game your user authed with and the game in which they won the credits.

### Batching Bet Requests

You can batch requests to the api server by using the [`Betable request batching endpoint`](https://developers.betable.com/docs/#batch-requests).

The SDK supports this with an object called `BetableBatchRequest`. You simply initialize it with a Betable object and you can add requests to it. Once all the requests you wish to batch have been added you can fire the requests and wait for the batch response. There are two ways of creating these requests, you can create them manually and add them, or you can use the prebuilt convenience methods.

####Manually Creating Requests

You can create your own requests using the following.

    - (NSMutableDictionary* )createRequestWithPath:(NSString*)path
                                            method:(NSString*)method
                                              name:(NSString*)name
                                      dependencies:(NSArray*)dependnecies
                                              data:(NSDictionary*)data;

And then add it to the requests for that batch with the following.

	- (void)addRequest:(NSDictionary*)request;

####Using the convenience request methods

You can use the betting and unbacked betting methods which automatically create and add the proper requests.

    - (NSMutableDictionary* )betForGame:(NSString*)gameID
                               withData:(NSDictionary*)data
                              withName: (NSString*)name;

    - (NSMutableDictionary* )unbackedBetForGame:(NSString*)gameID
                                       withData:(NSDictionary*)data
                                       withName: (NSString*)name;

    - (NSMutableDictionary* )creditBetForGame:(NSString*)gameID
                                   creditGame:(NSString*)creditGameID
                                     withData:(NSDictionary*)data
                                     withName:(NSString*)name;

    - (NSMutableDictionary* )unbackedCreditBetForGame:(NSString*)gameID
                                           creditGame:(NSString*)creditGameID
                                             withData:(NSDictionary*)data
                                             withName: (NSString*)name;

####Issuing the batched requests

Once you have added all the requests you want to the batch, simply fire the batch request.

    - (void)runBatchOnComplete:(BetableCompletionHandler)onComplete 
                     onFailure:(BetableFailureHandler)onFailure;

The `BetableCompletionHandler` will receive a `NSDictionary` that will represent the documented JSON response found in the [Betable batch request api](https://developers.betable.com/docs/#response-protocol).

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
