#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

#import "iMagPay/SwipeHandler.h"
#import "iMagPay/SwipeListener.h"
#import "iMagPay/Settings.h"

@interface DBLCard : CDVPlugin<SwipeListener>
{}

- (void)initializeCardReader:(CDVInvokedUrlCommand*)command;
- (void)readIsReady:(CDVInvokedUrlCommand*)command;
- (void)readIsConnected:(CDVInvokedUrlCommand*)command;
- (void)callCordova:(CDVPluginResult*)result;
- (BOOL)isReady;
- (BOOL)isConnected;

@end