#import <Cordova/CDV.h>
#import "DBLCard.h"

@interface DBLCard () {
    NSString* callbackId;
}

@end

@implementation DBLCard {
    BOOL _connected;
    BOOL _ready;
}

NSString * const READY_EVENT_VALUE = @"ff 00 00 00 00 00 00 00 01 00 00 00 00 00 00 00 00";

- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView {
    if( self = [super initWithWebView:theWebView] )
    {
        self->_ready = false;
    }
    
    return self;
    
}

- (void)readCreditCard:(CDVInvokedUrlCommand *)command {
    self->callbackId = command.callbackId;
    
    SwipeHandler *handler = [[SwipeHandler alloc] init];
    handler.mSwipeListener = self;
    
    Settings *settings = [[Settings alloc] init];
    [settings setSwipeHandler:handler];
    
    if ([handler isConnected] == YES) {
        [handler powerOn];
    }
    
    NSLog(@"readCreditCard");
}

- (BOOL)isReady {
    return self->_ready;
}

- (BOOL)isConnected {
    return self->_connected;
}

- (void)onConnected:(SwipeEvent*)event {
    self->_connected = true;
    NSLog(@"Connected.");
}

- (void)onStarted:(SwipeEvent*)event {
    NSLog(@"Started.");
}

- (void)onStopped:(SwipeEvent*)event {
    NSLog(@"Stopped.");
}

- (void)onDisconnected:(SwipeEvent*)event {
    self->_connected = false;
    NSLog(@"Disconnected.");
}

- (void)onReadData:(SwipeEvent*)event
{}

- (void)callCordova:(CDVPluginResult *)result {
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:self->callbackId];
}

- (void)onParseData:(SwipeEvent*)event {
    
    // check if event value is device ready information
    CDVPluginResult *readyResult;
    
    if([[event getValue] isEqualToString:READY_EVENT_VALUE]){
        self->_ready = true;
        NSLog(@"device ready: %@", self->_ready ? @"yes": @"no");
        NSDictionary *ready = [NSDictionary dictionaryWithObjectsAndKeys:
               @"ready", @"_name",
               nil];
        
        readyResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:ready];

    } else if (![self isReady]) {
        NSLog(@"device not ready");

        NSDictionary *notReady = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"ready", @"_name",
                               @"device not ready!", @"message",
                               nil];
        
        readyResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:notReady];
    }
    
    if(readyResult) {
        [self callCordova:readyResult];
        return;
    }
    
    // parse hex string with spaces to array
    NSLog(@"hex data: %@", [event getValue]);
    NSMutableArray *data = [NSMutableArray arrayWithArray:
                            [[event getValue] componentsSeparatedByString:@" "]];
    
    // hex to string convertion
    NSUInteger i = 0;
    for (id stringHex in [data copy]) {
        unsigned asciiCode = 0;
        
        NSScanner *scanner = [NSScanner scannerWithString:stringHex];
        [scanner scanHexInt:&asciiCode];
        
        [data replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"%c", asciiCode]];
        
        i++;
    }
    
    // array of characters to string convertion
    NSString *deviceResult = [data componentsJoinedByString:@""];
    
    // explode tracks
    NSArray *tracks = [deviceResult componentsSeparatedByString:@";"];
    NSLog(@"tracs: %lu %@", [tracks count], tracks);
    
    // check if all needed tracks are present (first and second, third is optional)
    if([tracks count] < 2) {
        NSLog(@"not enough tracks were readed");
        [self callCordova:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"read", @"_name", @"card has not enough tracks!", @"message",nil]]];
        return;
    }
    
    NSString *track1 = [tracks objectAtIndex:0];
    NSString *track2 = [tracks objectAtIndex:1];
    
    // parse card holder form track 1
    NSArray *cardHolderArray = [[[[track1 componentsSeparatedByString:@"^"] objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@"/"];
    
    NSDictionary *cardHolder = [NSDictionary dictionaryWithObjectsAndKeys:
                                [cardHolderArray objectAtIndex:0], @"last_name",
                                [cardHolderArray objectAtIndex:1], @"first_name",
                               nil];
    
    // parse card number from track 2
    NSString *cardNumber = [track2 substringWithRange:NSMakeRange(0, [track2 rangeOfString:@"="].location)];
    
    // parse card expirationDate from track 2
    NSString *expDateString = [track2 substringWithRange:NSMakeRange([track2 rangeOfString:@"="].location+1,4)];
    NSString *expDateYear = [expDateString substringWithRange:NSMakeRange(0,2)];
    NSString *expDateMonth = [expDateString substringWithRange:NSMakeRange(2,2)];
    
    NSDictionary *expDate = [NSDictionary dictionaryWithObjectsAndKeys:
                             expDateMonth, @"month",
                             expDateYear, @"year",
                             nil];
    
    NSDictionary *returnData = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"read", @"_name",
                                cardHolder, @"card_holder",
                                cardNumber, @"card_number",
                                expDate, @"exp_date",
                                nil];
    NSLog(@"returnData: %@", returnData);
    
    
    // return data as object to javascript
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnData];
    
    [self callCordova:pluginResult];
}


@end
