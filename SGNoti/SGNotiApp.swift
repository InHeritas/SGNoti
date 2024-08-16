//
//  Noti_SogangApp.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/7/24.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseMessaging

@main
struct SGNotiApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(Color("sogang_red"))
                .modelContainer(for: Bookmark_NoticeDetail.self)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self

        return true
    }
    
    // 원격 알림 등록 성공 시 호출
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // FCM 토큰 갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM token: \(fcmToken ?? "")")
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
    
    // 포그라운드 상태에서 푸시 알림 수신 시 호출
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}
