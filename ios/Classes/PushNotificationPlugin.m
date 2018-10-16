#import "PushNotificationPlugin.h"
#import <push_notification/push_notification-Swift.h>

@implementation PushNotificationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPushNotificationPlugin registerWithRegistrar:registrar];
}
@end
