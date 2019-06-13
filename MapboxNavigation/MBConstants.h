#import <Foundation/Foundation.h>

/**
 Key used for constructing errors when spoken instructions fail.
 */
extern const NSErrorUserInfoKey MBSpokenInstructionErrorCodeKey;

/**
 Posted when `MBStyleManager` applies a new style triggered by change of day of time, or when entering or exiting a tunnel.
 
 :nodoc:
 */
extern const _Nonnull NSNotificationName MBStyleManagerDidApplyStyleNotification;

/**
 Keys in the user info dictionaries of various notifications posted by instances of `MBStyleManager`.
 
 :nodoc:
 */
typedef NSString *MBStyleManagerNotificationUserInfoKey NS_EXTENSIBLE_STRING_ENUM;

/**
 A key in the user info dictionary of `MBStyleManagerDidApplyStyleNotification` notification. The corresponding value is an `MBStyle` instance that was applied.
 */
extern const _Nonnull MBStyleManagerNotificationUserInfoKey MBStyleManagerStyleKey;

/**
 A key in the user info dictionary of `MBStyleManagerDidApplyStyleNotification` notification. The corresponding value is an `MBStyleManager` instance that applied the style.
 */
extern const _Nonnull MBStyleManagerNotificationUserInfoKey MBStyleManagerStyleManagerKey;
