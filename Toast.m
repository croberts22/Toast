//
//  Toast.m
//  iMapMy3
//
//  Created by Corey Roberts on 1/14/13.
//  Copyright (c) 2013 MapMyFitness, Inc. All rights reserved.
//

/* Things to fix:
 * Animation for small toast height does not fade out with height SMALL_TOAST_HEIGHT. Still fades out with TOAST_HEIGHT.
 * Global messages (soon to be deprecated, methinks) don't respond to user selectors. Following messages also don't respond to selectors.
 * I'd love to unit test, but all public methods are pretty much UI based. I can access private methods, but this is generally not good practice.
 * Add one pixel border.
 */

#import "Toast.h"

#define DEFAULT_DURATION  5
#define ANIMATION_FADE_DURATION 0.4f
#define DEBUG_MESSAGES NO

#pragma mark - ToastItem Class Declaration/Implementation

@interface ToastItem : NSObject

@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) id target;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) ToastMessageType messageType;
@property (nonatomic, assign) BOOL isPersistent;

@end

@implementation ToastItem

@end

#pragma mark - Toast Class Declaration/Implementation

@interface Toast()

+ (Toast *)sharedView;

- (void)displayMessage:(NSString *)message forDuration:(NSTimeInterval)seconds withTarget:(id)target andSelector:(SEL)selector inView:(UIView *)view messageType:(ToastMessageType)messageType;
- (void)dissolve;
- (void)dissolveImmediately;

- (void)setMessage:(NSString *)message withTarget:(id)target andSelector:(SEL)action fromView:(UIView *)view messageType:(ToastMessageType)messageType;
- (void)resetFramesWithHeight:(int)height withImage:(UIImage *)image;
- (BOOL)messageTypeIsSmall:(ToastMessageType)messageType;

- (void)dissolveAction;

@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *toastAction;
@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, strong) NSTimer *dissolveTimer;
@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) UIView *currentView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, assign) BOOL isPersistent;
@property (nonatomic, assign) BOOL displaying;
@property (nonatomic, assign) BOOL dissolving;
@property (nonatomic, assign) ToastMessageType currentMessageType;

@end

@implementation Toast

@synthesize toastAction, dissolveTimer, queue, currentView, imageView, isVisible;

/**
 * Shared instance of Toast.
 * @return The singleton instance.
 */
+ (Toast *)sharedInstance {
    return [Toast sharedView];
}

/**
 * Singleton view of Toast.
 * @return The singleton view.
 */
+ (Toast *)sharedView {
    static dispatch_once_t once;
    static Toast *sharedView;
    dispatch_once(&once, ^ {
        sharedView = [[Toast alloc] initWithFrame:CGRectMake(0, -TOAST_HEIGHT, 320, TOAST_HEIGHT)];
    });
    return sharedView;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.alpha = 0.0f;
        self.queue = [[NSMutableArray alloc] init];
        self.isVisible = NO;
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 1, 300, TOAST_HEIGHT-2)];
        self.messageLabel.textColor = [UIColor whiteColor];
		self.messageLabel.backgroundColor = [UIColor clearColor];
		self.messageLabel.adjustsFontSizeToFitWidth = YES;
        self.messageLabel.minimumFontSize = 10;
		self.messageLabel.textAlignment = UITextAlignmentCenter;
		self.messageLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		self.messageLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:12];
        self.messageLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
        self.messageLabel.shadowOffset = CGSizeMake(0, -1);
        self.messageLabel.numberOfLines = 1;
        self.messageLabel.lineBreakMode = UILineBreakModeTailTruncation;
        
        self.layer.shadowOffset = CGSizeMake(0, 1);
        self.layer.shadowOpacity = 0.35f;
        self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        self.layer.shadowRadius = 0.5;
        
        [self addSubview:self.messageLabel];
    }
    return self;
}

#pragma mark - Public Methods

#pragma mark - Display Methods

+ (void)display:(NSString *)message inView:(UIView *)view {
    [[Toast sharedView] displayMessage:message forDuration:DEFAULT_DURATION withTarget:nil andSelector:@selector(dissolveAction) inView:view messageType:ToastMessageTypeDefault];
}

+ (void)display:(NSString *)message forDuration:(NSTimeInterval)seconds inView:(UIView *)view {
    [[Toast sharedView] displayMessage:message forDuration:seconds withTarget:nil andSelector:@selector(dissolveAction) inView:view messageType:ToastMessageTypeDefault];
}

+ (void)display:(NSString *)message forDuration:(NSTimeInterval)seconds withSelector:(SEL)selector inView:(UIView *)view {
    [[Toast sharedView] displayMessage:message forDuration:seconds withTarget:nil andSelector:selector inView:view messageType:ToastMessageTypeDefault];
}

+ (void)display:(NSString *)message inView:(UIView *)view messageType:(ToastMessageType)messageType {
    [[Toast sharedView] displayMessage:message forDuration:DEFAULT_DURATION withTarget:nil andSelector:@selector(dissolveAction) inView:view messageType:messageType];
}

+ (void)display:(NSString *)message forDuration:(NSTimeInterval)seconds inView:(UIView *)view messageType:(ToastMessageType)messageType {
    [[Toast sharedView] displayMessage:message forDuration:seconds withTarget:nil andSelector:@selector(dissolveAction) inView:view messageType:messageType];
}

+ (void)display:(NSString *)message forDuration:(NSTimeInterval)seconds withSelector:(SEL)selector inView:(UIView *)view messageType:(ToastMessageType)messageType {
    [[Toast sharedView] displayMessage:message forDuration:seconds withTarget:nil andSelector:selector inView:view messageType:messageType];
}

#pragma mark - Persistent Display Methods

+ (void)displayPersistently:(NSString *)message inView:(UIView *)view {
    [[Toast sharedView] displayMessage:message forDuration:INT_MAX withTarget:nil andSelector:nil inView:view messageType:ToastMessageTypeDefault];
}

+ (void)displayPersistently:(NSString *)message inView:(UIView *)view messageType:(ToastMessageType)messageType {
    [[Toast sharedView] displayMessage:message forDuration:INT_MAX withTarget:nil andSelector:nil inView:view messageType:messageType];
}

+ (void)displayPersistently:(NSString *)message inView:(UIView *)view withTarget:(id)target andSelector:(SEL)selector messageType:(ToastMessageType)messageType {
    [[Toast sharedView] displayMessage:message forDuration:INT_MAX withTarget:target andSelector:selector inView:view messageType:messageType];
}

#pragma mark - Global Display Methods

+ (void)displayGlobally:(NSString *)message {
    [[Toast sharedView] displayMessage:message forDuration:DEFAULT_DURATION withTarget:nil andSelector:@selector(dissolveAction) inView:nil messageType:ToastMessageTypeDefault];
}

+ (void)displayGlobally:(NSString *)message forDuration:(NSTimeInterval)seconds {
    [[Toast sharedView] displayMessage:message forDuration:seconds withTarget:nil andSelector:@selector(dissolveAction) inView:nil messageType:ToastMessageTypeDefault];
}

+ (void)displayGlobally:(NSString *)message forDuration:(NSTimeInterval)seconds withSelector:(SEL)selector {
    [[Toast sharedView] displayMessage:message forDuration:seconds withTarget:nil andSelector:selector inView:nil messageType:ToastMessageTypeDefault];
}

+ (void)displayGlobally:(NSString *)message forDuration:(NSTimeInterval)seconds withSelector:(SEL)selector messageType:(ToastMessageType)messageType {
    [[Toast sharedView] displayMessage:message forDuration:seconds withTarget:nil andSelector:selector inView:nil messageType:messageType];
}

#pragma mark - Dismiss Methods

+ (void)dismiss {
    [[Toast sharedView] dissolve];
}

#pragma mark - Private Methods
/** @name Private Methods */

/**
 * Causes Toast to fade into the view. If the view passed in does not match the current view, Toast is reset and will display this message.
 * @param message The message to be displayed.
 * @param seconds The duration of time for the toast to stay on screen.
 * @param target A class to receive a message.
 * @param selector A selector that responds to the target provided.
 * @param view The view to display the toast.
 * @param messageType A ToastMessageType enum that determines the kind of toast display to show.
 */
- (void)displayMessage:(NSString *)message forDuration:(NSTimeInterval)seconds withTarget:(id)target andSelector:(SEL)selector inView:(UIView *)view messageType:(ToastMessageType)messageType {
    dispatch_async(dispatch_get_main_queue(), ^{
        // If currentView is not set, make it so.
        if(!currentView) {
            self.currentView = view;
        }
        // If the views aren't matching, then Toast must be in the previous view.
        // Reset all state and begin with this message in this view.
        else if(self.currentView != view && self.currentView && view) {
            if(DEBUG_MESSAGES) [Logger log:@"[Toast] Views conflict. Dissolve immediately."];
            self.currentView = view;
            [self dissolveImmediately];
        }
        
        if(self.isPersistent && self.isVisible) {
            if(DEBUG_MESSAGES) [Logger log:@"[Toast] Current view is persistent; dissolve first."];
            [self dissolve]; 
        }
        
        // Don't perform any UI changes unless Toast is not visible (not active).
        if(!isVisible) {
            if(DEBUG_MESSAGES) [Logger log:@"[Toast] About to display message: \"%@\"", message];
            self.currentMessageType = messageType;
            [self toastWillDisplayWithMessageType:messageType];
            
            self.alpha = 0.0f;
            
            if(seconds == INT_MAX) {
                self.isPersistent = YES;
                [self.dissolveTimer invalidate];
                self.dissolveTimer = nil;
            }
            else {
                self.isPersistent = NO;
                self.dissolveTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(dissolve) userInfo:nil repeats:NO];
            }
            
            [self setMessage:message withTarget:target andSelector:selector fromView:view messageType:messageType];
            
            int toastHeight = TOAST_HEIGHT;
            
            if([self messageTypeIsSmall:messageType]) {
                toastHeight = SMALL_TOAST_HEIGHT;
            }
            
            if(!view) {
                [self.overlayWindow addSubview:self];
            }
            else {
                [view addSubview:self];
            }
            
            // Display Toast.
            if(DEBUG_MESSAGES) [Logger log:@"[Toast] Displaying toast."];
            [UIView animateWithDuration:ANIMATION_FADE_DURATION
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y + toastHeight, self.frame.size.width, self.frame.size.height);
                                 self.alpha = 1.0f;
                             }
                             completion:^(BOOL finished) {
                                 self.isVisible = YES;
                                 [self toastDidDisplayWithMessageType:messageType];
                             }];
            
            [self setNeedsDisplay];
        }
        else {
            if(DEBUG_MESSAGES) [Logger log:@"[Toast] Can't display message \"%@\". Adding to queue.", message];
            // If we're currently displaying Toast, add the next message into the queue so we can show it later.
            // This assumes that the following messages reside on the same view.
            ToastItem *toastItem = [[ToastItem alloc] init];
            toastItem.message = message;
            toastItem.timeInterval = (NSTimeInterval)seconds;
            toastItem.target = target;
            toastItem.selector = selector;
            toastItem.view = view;
            toastItem.messageType = messageType;
            toastItem.isPersistent = NO;
            
            if(seconds == INT_MAX) {
                toastItem.isPersistent = YES;
            }
            
            [self.queue addObject:toastItem];
        }
    });
}

/**
 * Causes Toast to fade out.
 */
- (void)dissolve {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(isVisible && !_dissolving) {
            _dissolving = YES;
            
            // Dissolve Toast.
            if(DEBUG_MESSAGES) [Logger log:@"[Toast] Dissolving toast..."];
            [self toastWillDismissWithMessageType:_currentMessageType];
            
            [UIView animateWithDuration:ANIMATION_FADE_DURATION
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y - TOAST_HEIGHT, self.frame.size.width, self.frame.size.height);
                                 self.alpha = 0.0f;
                             }
                             completion:^(BOOL finished) {
                                 [self.dissolveTimer invalidate];
                                 self.dissolveTimer = nil;
                                 
                                 self.isVisible = NO;
                                 self.dissolving = NO;
                                 
                                 [self toastDidDismissWithMessageType:_currentMessageType];
                                 
                                 // If we have any items in the queue, fetch the first one and display it.
                                 if([self.queue count] > 0) {
                                     if(DEBUG_MESSAGES) [Logger log:@"[Toast] Fetching new item from queue."];
                                     ToastItem *toastItem = [self.queue objectAtIndex:0];
                                     [self displayMessage:toastItem.message forDuration:toastItem.timeInterval withTarget:toastItem.target andSelector:toastItem.selector inView:toastItem.view messageType:toastItem.messageType];
                                     [self.queue removeObjectAtIndex:0];
                                 }
                                 else {
                                     if(DEBUG_MESSAGES) [Logger log:@"[Toast] Removing overlay."];
                                     [_overlayWindow removeFromSuperview];
                                     self.currentView = nil;
                                 }
                             }];
            
            [self setNeedsDisplay];
        }
    });
}

/**
 * Resets the state of Toast in the event that the current view does not match the view Toast is in. 
 * This ultimately removes everything in the queue.
 */
- (void)dissolveImmediately {
    [self.dissolveTimer invalidate];
    self.dissolveTimer = nil;
    self.frame = CGRectMake(self.frame.origin.x, -TOAST_HEIGHT, self.frame.size.width, self.frame.size.height);
    self.alpha = 0.0f;
    self.isVisible = NO;
    
    // Remove all items in the queue.
    [self.queue removeAllObjects];
    
    [_overlayWindow removeFromSuperview];
}

/**
 * Sets up the Toast that will be displayed on screen.
 * @param message The message to be displayed.
 * @param target A class to receive a message.
 * @param action A selector that responds to the target provided.
 * @param view The view to display the toast.
 * @param messageType A ToastMessageType enum that determines the kind of toast display to show.
 */
- (void)setMessage:(NSString *)message withTarget:(id)target andSelector:(SEL)action fromView:(UIView *)view messageType:(ToastMessageType)messageType {
    
    for(UIView *gradientView in self.subviews) {
        if(gradientView.tag == 1000) {
            [gradientView removeFromSuperview];
        }
    }
    
    UIColor *bottomGradientColor;
    UIColor *upperGradientColor;
    UIImage *image;
    BOOL includeIndicator = NO;
    
    int toastHeight = 0;
    
    switch (messageType) {
        case ToastMessageTypeDefault :
            bottomGradientColor = HEXCOLOR(0x131313FF);
            upperGradientColor = HEXCOLOR(0x313131FF);
            toastHeight = TOAST_HEIGHT;
            image = nil;
            break;
        case ToastMessageTypeDefaultSmall :
            bottomGradientColor = HEXCOLOR(0x131313FF);
            upperGradientColor = HEXCOLOR(0x313131FF);
            toastHeight = SMALL_TOAST_HEIGHT;
            image = nil;
            break;
        case ToastMessageTypeWarning :
            bottomGradientColor = HEXCOLOR(0xDA771BFF);
            upperGradientColor = HEXCOLOR(0xFE8A1FFF);
            toastHeight = TOAST_HEIGHT;
            image = [UIImage imageNamed:@"Toast.bundle/alert.png"];
            break;
        case ToastMessageTypeWarningSmall :
            bottomGradientColor = HEXCOLOR(0xDA771BFF);
            upperGradientColor = HEXCOLOR(0xFE8A1FFF);
            toastHeight = SMALL_TOAST_HEIGHT;
            image = [UIImage imageNamed:@"Toast.bundle/alert.png"];
            break;
        case ToastMessageTypeWarningNoIcon :
            bottomGradientColor = HEXCOLOR(0xDA771BFF);
            upperGradientColor = HEXCOLOR(0xFE8A1FFF);
            toastHeight = TOAST_HEIGHT;
            image = nil;
            break;
        case ToastMessageTypeWarningNoIconSmall :
            bottomGradientColor = HEXCOLOR(0xDA771BFF);
            upperGradientColor = HEXCOLOR(0xFE8A1FFF);
            toastHeight = SMALL_TOAST_HEIGHT;
            image = nil;
            break;
        case ToastMessageTypeSuccess :
            bottomGradientColor = HEXCOLOR(0x004805FF);
            upperGradientColor = HEXCOLOR(0x007708FF);
            toastHeight = TOAST_HEIGHT;
            image = [UIImage imageNamed:@"Toast.bundle/success.png"];
            break;
        case ToastMessageTypeSuccessSmall :
            bottomGradientColor = HEXCOLOR(0x004805FF);
            upperGradientColor = HEXCOLOR(0x007708FF);
            toastHeight = SMALL_TOAST_HEIGHT;
            image = [UIImage imageNamed:@"Toast.bundle/success.png"];
            break;
        case ToastMessageTypeSuccessNoIcon :
            bottomGradientColor = HEXCOLOR(0x004805FF);
            upperGradientColor = HEXCOLOR(0x007708FF);
            toastHeight = TOAST_HEIGHT;
            image = nil;
            break;
        case ToastMessageTypeSuccessNoIconSmall :
            bottomGradientColor = HEXCOLOR(0x004805FF);
            upperGradientColor = HEXCOLOR(0x007708FF);
            toastHeight = SMALL_TOAST_HEIGHT;
            image = nil;
            break;
        case ToastMessageTypeError :
            bottomGradientColor = HEXCOLOR(0x470101FF);
            upperGradientColor = HEXCOLOR(0x790000FF);
            toastHeight = TOAST_HEIGHT;
            image = [UIImage imageNamed:@"Toast.bundle/error.png"];
            break;
        case ToastMessageTypeErrorSmall :
            bottomGradientColor = HEXCOLOR(0x470101FF);
            upperGradientColor = HEXCOLOR(0x790000FF);
            toastHeight = SMALL_TOAST_HEIGHT;
            image = [UIImage imageNamed:@"Toast.bundle/error.png"];
            break;
        case ToastMessageTypeErrorNoIcon :
            bottomGradientColor = HEXCOLOR(0x470101FF);
            upperGradientColor = HEXCOLOR(0x790000FF);
            toastHeight = TOAST_HEIGHT;
            image = nil;
            break;
        case ToastMessageTypeErrorNoIconSmall :
            bottomGradientColor = HEXCOLOR(0x470101FF);
            upperGradientColor = HEXCOLOR(0x790000FF);
            toastHeight = SMALL_TOAST_HEIGHT;
            image = nil;
            break;
        case ToastMessageTypeLoading :
            bottomGradientColor = HEXCOLOR(0x131313FF);
            upperGradientColor = HEXCOLOR(0x313131FF);
            toastHeight = TOAST_HEIGHT;
            includeIndicator = YES;
            image = nil;
            break;
        case ToastMessageTypeLoadingSmall :
            bottomGradientColor = HEXCOLOR(0x131313FF);
            upperGradientColor = HEXCOLOR(0x313131FF);
            toastHeight = SMALL_TOAST_HEIGHT;
            includeIndicator = YES;
            image = nil;
            break;
        case ToastMessageTypeLoadingOrange :
            bottomGradientColor = HEXCOLOR(0xDA771BFF);
            upperGradientColor = HEXCOLOR(0xFE8A1FFF);
            toastHeight = TOAST_HEIGHT;
            includeIndicator = YES;
            image = nil;
            break;
        case ToastMessageTypeLoadingOrangeSmall :
            bottomGradientColor = HEXCOLOR(0xDA771BFF);
            upperGradientColor = HEXCOLOR(0xFE8A1FFF);
            toastHeight = SMALL_TOAST_HEIGHT;
            includeIndicator = YES;
            image = nil;
            break;
    }
    
    UIView *gradientView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, toastHeight)];
    gradientView.tag = 1000;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = gradientView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[upperGradientColor CGColor], (id)[bottomGradientColor CGColor], nil];
    [gradientView.layer insertSublayer:gradient atIndex:0];
    [self addSubview:gradientView];

    // Push the gradient view to the lowest layer.
    [self sendSubviewToBack:gradientView];
    
    if(!imageView) {
        self.imageView = [[UIImageView alloc] init];
        //self.imageView.backgroundColor = [UIColor purpleColor];
    }
    
    if(!_indicator) {
        self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.indicator startAnimating];
    }
    
    if(includeIndicator) {
        [self addSubview:self.indicator];
        // To center:
        //self.indicator.frame = CGRectMake(320/2-10, toastHeight/2-(self.indicator.frame.size.height/2), self.indicator.frame.size.width, self.indicator.frame.size.height);
        self.indicator.frame = CGRectMake(5, toastHeight/2-(self.indicator.frame.size.height/2), self.indicator.frame.size.width, self.indicator.frame.size.height);
    }
    else {
        [self.indicator removeFromSuperview];
    }
    
    // Assign the image and adjust the frame.
    self.imageView.image = image;
    self.imageView.frame = CGRectMake(5, (toastHeight/4), toastHeight/2, toastHeight/2);
    
    [self addSubview:imageView];
    
    self.messageLabel.text = message;
    
    // Reset frames depending on the toast height.
    [self resetFramesWithHeight:toastHeight withImage:image];
    
    if(!toastAction) {
        toastAction = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 320, toastHeight)];
        toastAction.backgroundColor = [UIColor clearColor];
    }

    [self bringSubviewToFront:toastAction];
    
    
    // Remove any existing actions before adding an action.
    [toastAction removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
    // If view is not nil, then we need to register this selector with this view as the target.
    // We add a sanity check to make sure the view implements this action.
    // In the event that it doesn't, add the default action.
    if(target) {
        if([target respondsToSelector:action]) {
            [toastAction addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        }
        else {
            if(action) {
                [toastAction addTarget:self action:@selector(dissolveAction) forControlEvents:UIControlEventTouchUpInside];
            }
        }
    }
    else {
        if(action) {
            [toastAction addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    if(!toastAction.superview) {
        [self addSubview:toastAction];
    }
}

/**
 * Resets the frame sizes depending on the height of Toast. Also takes into account if an image is present on the left side.
 * @param height The size of Toast (i.e. TOAST_HEIGHT or SMALL_TOAST_HEIGHT).
 * @param image An image to be displayed on the left side of Toast.
 */
- (void)resetFramesWithHeight:(int)height withImage:(UIImage *)image {
    self.frame = CGRectMake(self.frame.origin.x, -height, self.frame.size.width, height);
    self.messageLabel.frame = CGRectMake(10, 1, 300, height-2);
    self.toastAction.frame = CGRectMake(0, 0, 320, height);
    
    // If the image is available, adjust the message label frame.
    if(image) {
        self.messageLabel.frame = CGRectMake(25, 1, 270, height-2);
    }
}

/**
 * Determines if the ToastMessageType is of the small format.
 * @param messageType A ToastMessageType enum that determines the kind of Toast display.
 * @return YES if the message type is small; NO otherwise.
 */
- (BOOL)messageTypeIsSmall:(ToastMessageType)messageType {
    if(messageType == ToastMessageTypeDefaultSmall          || messageType == ToastMessageTypeErrorSmall        || messageType == ToastMessageTypeSuccessSmall          ||
       messageType == ToastMessageTypeWarningSmall          || messageType == ToastMessageTypeErrorNoIconSmall  || messageType == ToastMessageTypeSuccessNoIconSmall    ||
       messageType == ToastMessageTypeWarningNoIconSmall    || messageType == ToastMessageTypeLoadingSmall      || messageType == ToastMessageTypeLoadingOrangeSmall) {
        return YES;
    }

    return NO;
}

#pragma mark - Toast Action Methods

/**
 * Default action upon user tap. Toast merely dissolves.
 */
- (void)dissolveAction {
    if(DEBUG_MESSAGES) [Logger log:@"[Toast] Dissolve action invoked."];
    [self.dissolveTimer invalidate];
    self.dissolveTimer = nil;
    [[Toast sharedView] dissolve];
}

#pragma mark - ToastDelegate Methods 

/**
 * Delegate method that gets invoked when Toast will be displayed on the view.
 * @param messageType A ToastMessageType enum that determines the kind of toast that will be shown.
 */
- (void)toastWillDisplayWithMessageType:(ToastMessageType)messageType {
    if([self.delegate respondsToSelector:@selector(toastWillDisplayWithMessageType:)]) {
        [self.delegate toastWillDisplayWithMessageType:messageType];
    }
}

/**
 * Delegate method that gets invoked when Toast did get displayed on the view.
 * @param messageType A ToastMessageType enum that determines the kind of toast that was shown.
 */
- (void)toastDidDisplayWithMessageType:(ToastMessageType)messageType {
    if([self.delegate respondsToSelector:@selector(toastDidDisplayWithMessageType:)]) {
        [self.delegate toastDidDisplayWithMessageType:messageType];
    }
}

/**
 * Delegate method that gets invoked when Toast will be dismissed from the view.
 * @param messageType A ToastMessageType enum that determines the kind of toast that will be dismissed.
 */
- (void)toastWillDismissWithMessageType:(ToastMessageType)messageType {
    if([self.delegate respondsToSelector:@selector(toastWillDismissWithMessageType:)]) {
        [self.delegate toastWillDismissWithMessageType:messageType];
    }
    
}

/**
 * Delegate method that gets invoked when Toast did get dismissed from the view.
 * @param messageType A ToastMessageType enum that determines the kind of toast that was dismissed.
 */
- (void)toastDidDismissWithMessageType:(ToastMessageType)messageType {
    if([self.delegate respondsToSelector:@selector(toastDidDismissWithMessageType:)]) {
        [self.delegate toastdidDismissWithMessageType:messageType];
    }
}

@end
