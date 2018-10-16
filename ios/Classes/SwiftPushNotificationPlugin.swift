import Flutter
import UIKit
import UserNotifications

public class SwiftPushNotificationPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    
    var _channel: FlutterMethodChannel

    var _resumeFromBackground:Bool;
    var _launchNotification: NSDictionary?;
 
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.bluechilli.plugins/push_notification", binaryMessenger: registrar.messenger())
        let instance = SwiftPushNotificationPlugin(channel: channel)
        registrar.addApplicationDelegate(instance);
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch(call.method) {
        case "getPlatformVersion":
            result(UIDevice.current.systemVersion);
            break;
        case "requestNotificationPermissions":
            requestPermission(call: call, result: result);
            break;
        case "configure":
            configureMethods(call: call, result: result);
            break;
        case "setupCategories":
            setupCategories(call: call, result: result);
            break;
        default:
            result(FlutterMethodNotImplemented)
            break;
            
        }
        
    }

    init(channel:FlutterMethodChannel){
        _channel = channel
        _resumeFromBackground = false;
        super.init()
    }
    
    // Mark: - UserNotificationCenter Delegate

    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        var action:String = "";
        
        switch(response.actionIdentifier) {
            case UNNotificationDefaultActionIdentifier:
                action = "default";
                break;
            case UNNotificationDismissActionIdentifier:
                action = "dismiss";
                break;
            default:
                action = response.actionIdentifier;
                break;
        };
        
        let res:NSDictionary = [
                "action": action,
                "data":  getParamters(userInfo: response.notification.request.content.userInfo)
            ];
        _channel.invokeMethod("onOpened", arguments: res);
        completionHandler();
    }
    
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        _channel.invokeMethod("onResume", arguments: getParamters(userInfo: notification.request.content.userInfo));
        completionHandler(.alert);
    }
    
    
    // Mark: - Application Delegate
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {

        if(_launchNotification != nil) {
            _launchNotification = launchOptions[UIApplicationLaunchOptionsKey.remoteNotification] as! NSDictionary?;
        }
        
        return true;
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        _resumeFromBackground = true;
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        _resumeFromBackground = false;
        application.applicationIconBadgeNumber = 1;
        application.applicationIconBadgeNumber = 0;
    }
    
    public func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
       let settings:NSDictionary = [
            "sound": notificationSettings.types.contains(.sound),
            "badge": notificationSettings.types.contains(.badge),
            "alert": notificationSettings.types.contains(.alert)
        ];
        
        _channel.invokeMethod("onIosSettingsRegistered", arguments: settings);
    }

    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        _channel.invokeMethod("onMessage", arguments: getParamters(userInfo: userInfo));
        completionHandler(.noData);
        return true;
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token:NSData = NSData.init(data: deviceToken);
        var trimmedDeviceToken = token.description;
        
        if (!trimmedDeviceToken.isNullOrWhitespace())
        {
            trimmedDeviceToken = trimmedDeviceToken.trimmingCharacters(in: CharacterSet.init(charactersIn:"<"));
            trimmedDeviceToken = trimmedDeviceToken.trimmingCharacters(in: CharacterSet.init(charactersIn:">"));
            trimmedDeviceToken = trimmedDeviceToken.trimmingCharacters(in: .whitespaces);
            trimmedDeviceToken = trimmedDeviceToken.replacingOccurrences(of: " ", with: "");
            _channel.invokeMethod("onToken", arguments: trimmedDeviceToken);
        }
    }
    
    private func getParamters(userInfo:[AnyHashable : Any]) -> [AnyHashable : Any] {
        return userInfo;
    }
    
  
    private func setupCategories(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        if #available(iOS 10.0, *) {
            let args:NSArray = call.arguments as! NSArray;

            var categories:Set<UNNotificationCategory> = [];

            args.forEach { (item: Any) in
                let categoryItem:NSDictionary = item as! NSDictionary;
                
                let identifier:String = categoryItem["identifier"] as! String;
                let intentIdentifiers:[String] = categoryItem["intentIdentifiers"] as! [String];
                var hiddenPreviewBodyPlaceHolder:String?;
                
                if let placeholder = categoryItem["hiddenPreviewBodyPlaceHolder"] as? String  {
                    hiddenPreviewBodyPlaceHolder = placeholder;
                }
                
                var actions:[UNNotificationAction] = [];
                var options:UNNotificationCategoryOptions = [];
                
                if let categoryActions = categoryItem["actions"] as? [[AnyHashable : Any]]  {
                    categoryActions.forEach({ item in
                        let identifier:String = item["identifier"] as! String;
                        let title:String = item["title"] as! String;
                        var actionOptions:UNNotificationActionOptions = [];
                        
                        if let actionActionOptions = item["options"] as? NSDictionary {
                            
                            if(actionActionOptions["authenticationRequired"] as! Bool) {
                                actionOptions = actionOptions.union(.authenticationRequired);
                            }
                            
                            if(actionActionOptions["destructive"] as! Bool) {
                                actionOptions = actionOptions.union(.destructive);
                            }
                            
                            if(actionActionOptions["foreground"] as! Bool) {
                                actionOptions = actionOptions.union(.foreground);
                            }
                        }
                        
                        let action:UNNotificationAction = UNNotificationAction.init(identifier: identifier, title: title, options:actionOptions);
                        actions.append(action);
                    });
                }
                
                if let categoryOption = categoryItem["options"] as! NSDictionary? {
                    
                    if(categoryOption["customDismissAction"] as! Bool) {
                        options = options.union(.customDismissAction);
                    }
                    
                    if(categoryOption["allowInCarPlay"] as! Bool) {
                        options = options.union(.allowInCarPlay);
                    }

                    if  #available(iOS 11.0, *) {
                        if(categoryOption["hiddenPreviewShowTitle"] as! Bool) {
                            options = options.union(.hiddenPreviewsShowTitle);
                        }
                        
                        if(categoryOption["hiddenPreviewShowTitle"] as! Bool) {
                            options = options.union(.hiddenPreviewsShowSubtitle);
                        }
                    }
                }

                var category:UNNotificationCategory;
                
                if #available(iOS 11.0, *) {
                    if(hiddenPreviewBodyPlaceHolder != nil) {
                        category = UNNotificationCategory.init(identifier: identifier, actions: actions, intentIdentifiers: intentIdentifiers, hiddenPreviewsBodyPlaceholder: hiddenPreviewBodyPlaceHolder!,  options: options);
                    }
                    else {
                        category = UNNotificationCategory.init(identifier: identifier, actions: actions, intentIdentifiers: intentIdentifiers,  options: options);
                    }
                }
                else {
                    category = UNNotificationCategory.init(identifier: identifier, actions: actions, intentIdentifiers: intentIdentifiers,  options: options);
                }
              
                categories.insert(category);
            }
            
            if(categories.count > 0) {
                UNUserNotificationCenter.current().setNotificationCategories(categories);
            }
        }
        
        result(nil);
    }
    
    private func configureMethods(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.registerForRemoteNotifications();
            
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                if(settings.authorizationStatus == .authorized) {
                    let settings:NSDictionary = [
                        "sound": settings.alertSetting == UNNotificationSetting.enabled,
                        "badge": settings.badgeSetting == UNNotificationSetting.enabled,
                        "alert": settings.alertSetting == UNNotificationSetting.enabled
                    ];
                    self._channel.invokeMethod("onIosSettingsRegistered", arguments: settings);
                }
            }
        }
        else {
            UIApplication.shared.registerForRemoteNotifications();
        }
        
        if (_launchNotification != nil) {
            _channel.invokeMethod("onLaunch", arguments:_launchNotification);
        }
        
        result(nil);
    }
    
    private func requestPermission(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        let args:NSDictionary = call.arguments as! NSDictionary;
        let sound:Bool = args["sound"] as! Bool;
        let alert:Bool = args["alert"] as! Bool;
        let badge:Bool = args["badge"] as! Bool;
        
        // todo : be able to pass the category
        if #available(iOS 10.0, *) {
            
            var authOptions: UNAuthorizationOptions = .alert;
            
            if (sound) {
                authOptions = authOptions.union(UNAuthorizationOptions.sound);
            }
            
            if (alert) {
                authOptions = authOptions.union(UNAuthorizationOptions.alert);
            }
            
            if (badge) {
                authOptions = authOptions.union(UNAuthorizationOptions.badge);
            }
            
            UNUserNotificationCenter.current().delegate = self;
            
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (granted, error) in
                
                if(error != nil) {
                    
                    result(FlutterError(code: "PERMISSION_ERROR",message: "Something went wrong getting the permission", details: error!.localizedDescription));
                    
                }
                else {
                    result(granted);
                }
            };
            
        }
        else {
            var notificationTypes:UIUserNotificationType = .alert;
            
            
            if (sound) {
                notificationTypes = notificationTypes.union(UIUserNotificationType.sound);
            }
            
            if (alert) {
                notificationTypes = notificationTypes.union(UIUserNotificationType.alert);
            }
            
            if (badge) {
                notificationTypes = notificationTypes.union(UIUserNotificationType.badge);
            }
            
            let settings:UIUserNotificationSettings = UIUserNotificationSettings.init(types: notificationTypes, categories: nil);

            UIApplication.shared.registerUserNotificationSettings(settings);
            
            result(true);
        }
    }
}

extension String {
    func isNullOrWhitespace() -> Bool {
        if(self.isEmpty) {
            return true
        }
        
        return (self.trimmingCharacters(in: NSCharacterSet.whitespaces) == "")
    }
}
