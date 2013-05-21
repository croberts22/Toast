//
//  Toast.h
//  iMapMy3
//
//  Created by Corey Roberts on 1/14/13.
//  Copyright (c) 2013 MapMyFitness, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#define TOAST_HEIGHT 40
#define SMALL_TOAST_HEIGHT 32

typedef enum {
    ToastMessageTypeDefault = 1,            // Black message with no icon.
    ToastMessageTypeDefaultSmall,
    ToastMessageTypeWarning,                // Orange message with warning icon.
    ToastMessageTypeWarningSmall,
    ToastMessageTypeWarningNoIcon,          // Orange message with no icon.
    ToastMessageTypeWarningNoIconSmall,
    ToastMessageTypeSuccess,                // Green message with success icon.
    ToastMessageTypeSuccessSmall,
    ToastMessageTypeSuccessNoIcon,          // Green message with no icon.
    ToastMessageTypeSuccessNoIconSmall,
    ToastMessageTypeError,                  // Red message with error icon.
    ToastMessageTypeErrorSmall,
    ToastMessageTypeErrorNoIcon,            // Red message with no icon.
    ToastMessageTypeErrorNoIconSmall,
    ToastMessageTypeLoading,                // Black message with a loading indicator.
    ToastMessageTypeLoadingSmall,
    ToastMessageTypeLoadingOrange,          // Orange message with a loading indicator.
    ToastMessageTypeLoadingOrangeSmall
} ToastMessageType;

@protocol ToastDelegate <NSObject>

@optional
- (void)toastWillDisplayWithMessageType:(ToastMessageType)messageType;
- (void)toastDidDisplayWithMessageType:(ToastMessageType)messageType;
- (void)toastWillDismissWithMessageType:(ToastMessageType)messageType;
- (void)toastdidDismissWithMessageType:(ToastMessageType)messageType;
- (void)toastDidToastAndWasSpreadWithGrapeJellyAndButter;

@end

@interface Toast : UIView

@property (nonatomic, assign) id<ToastDelegate> delegate;
@property (nonatomic, assign) BOOL isVisible;

/** @name Access Method */

+ (Toast *)sharedInstance;

/** @name Display Methods */

/**
 * Displays a regular toast message.
 * @param message The message to be displayed.
 * @param view The view to display the toast.
 */
+ (void)display:(NSString *)message inView:(UIView *)view;

/**
 * Displays a regular toast message with a duration specified by the user.
 * @param message The message to be displayed.
 * @param seconds The duration of time for the toast to stay on screen.
 * @param view The view to display the toast.
 */
+ (void)display:(NSString *)message forDuration:(NSTimeInterval)seconds inView:(UIView *)view;

/**
 * Displays a regular toast message with a duration and a Toast-based selector specified by the user.
 * @param message The message to be displayed.
 * @param seconds The duration of time for the toast to stay on screen.
 * @param selector A Toast-provided selector that responds to a touch event.
 * @param view The view to display the toast.
 */
+ (void)display:(NSString *)message forDuration:(NSTimeInterval)seconds withSelector:(SEL)selector inView:(UIView *)view;

/**
 * Displays a type-specific toast message and places it dynamically depending on the contents of the UIView.
 * @param message The message to be displayed.
 * @param view The view to display the toast.
 * @param messageType A ToastMessageType enum that determines the kind of toast display to show.
 */
+ (void)display:(NSString *)message inView:(UIView *)view messageType:(ToastMessageType)messageType;

/**
 * Displays a type-specific toast message with a duration specified by the user and places it dynamically depending on the contents of the UIView.
 * @param message The message to be displayed.
 * @param seconds The duration of time for the toast to stay on screen.
 * @param view The view to display the toast.
 * @param messageType A ToastMessageType enum that determines the kind of toast display to show.
 */
+ (void)display:(NSString *)message forDuration:(NSTimeInterval)seconds inView:(UIView *)view messageType:(ToastMessageType)messageType;

/**
 * Displays a type-specific toast message with a duration and selector specified by the user and places it dynamically depending on the contents of the UIView.
 * @param message The message to be displayed.
 * @param seconds The duration of time for the toast to stay on screen.
 * @param selector A Toast-provided selector that responds to a touch event.
 * @param view The view to display the toast.
 * @param messageType A ToastMessageType enum that determines the kind of toast display to show.
 */
+ (void)display:(NSString *)message forDuration:(NSTimeInterval)seconds withSelector:(SEL)selector inView:(UIView *)view messageType:(ToastMessageType)messageType;

/** @name Persistent Display Methods */

/**
 * Displays a regular toast message and does not fade out unless forced by calling dismiss.
 * @param message The message to be displayed.
 * @param view The view to display the toast.
 */
+ (void)displayPersistently:(NSString *)message inView:(UIView *)view;

/**
 * Displays a type-specific toast message and does not fade out unless either 'dismiss' is invoked, or another persistent message is invoked.
 * @param message The message to be displayed.
 * @param view The view to display the toast.
 * @param messageType A ToastMessageType enum that determines the kind of toast display to show.
 */
+ (void)displayPersistently:(NSString *)message inView:(UIView *)view messageType:(ToastMessageType)messageType;

/**
 * Displays a type-specific toast message with a target and selctor, and does not fade out unless either 'dismiss' is invoked, or another persistent message is invoked.
 * @param message The message to be displayed.
 * @param view The view to display the toast.
 * @param target A class to receive a message.
 * @param selector A selector that responds to the target provided.
 * @param messageType A ToastMessageType enum that determines the kind of toast display to show.
 */
+ (void)displayPersistently:(NSString *)message inView:(UIView *)view withTarget:(id)target andSelector:(SEL)selector messageType:(ToastMessageType)messageType;

/** @name Global Display Methods */

/**
 * Shows a global toast message with the default duration.
 * @param message The message to be displayed.
 */
+ (void)displayGlobally:(NSString *)message DEPRECATED_ATTRIBUTE;

/**
 * Displays a global toast message with a duration specified by the user.
 * @param message The message to be displayed.
 * @param seconds The duration of time for the toast to stay on screen.
 */
+ (void)displayGlobally:(NSString *)message forDuration:(NSTimeInterval)seconds DEPRECATED_ATTRIBUTE;

/**
 * Displays a global toast message with a duration and selector specified by the user.
 * @param message The message to be displayed.
 * @param seconds The duration of time for the toast to stay on screen.
 * @param selector A Toast-provided selector that responds to a touch event.
 */
+ (void)displayGlobally:(NSString *)message forDuration:(NSTimeInterval)seconds withSelector:(SEL)selector DEPRECATED_ATTRIBUTE;

/**
 * Displays a type-specific global toast message with a duration and selector specified by the user.
 * @param message The message to be displayed.
 * @param seconds The duration of time for the toast to stay on screen.
 * @param selector A Toast-provided selector that responds to a touch event.
 * @param messageType A ToastMessageType enum that determines the kind of toast display to show.
 */
+ (void)displayGlobally:(NSString *)message forDuration:(NSTimeInterval)seconds withSelector:(SEL)selector messageType:(ToastMessageType)messageType DEPRECATED_ATTRIBUTE;

/** @name Dismiss Methods */

/**
 * Manually dismisses the currently visible toast message.
 */
+ (void)dismiss;

@end
