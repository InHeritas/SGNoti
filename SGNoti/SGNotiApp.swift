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
import FirebaseFirestore

@main
struct SGNotiApp: App {
    @Environment(\.scenePhase) var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(Color("sogang_red"))
                .modelContainer(for: Bookmark_NoticeDetail.self)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        UNUserNotificationCenter.current().setBadgeCount(0)
                    }
                }
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
        
        if let userId = UIDevice.current.identifierForVendor?.uuidString, let fcmToken = fcmToken {
            checkUserDataInFirestore(userId: userId, fcmToken: fcmToken)
        } else {
            print("Error: Could not retrieve identifierForVendor.")
        }
    }
    
    // 포그라운드 상태에서 푸시 알림 수신 시 호출
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
    
    // Firestore에서 유저 데이터를 확인하고 로컬에 저장하는 함수
    private func checkUserDataInFirestore(userId: String, fcmToken: String) {
        @AppStorage("subscribedBoards") var subscribedBoards: [Int] = [1, 2, 3, 141]
        @AppStorage("subscribedKeywords") var subscribedKeywords: [String] = []
        let db = Firestore.firestore()
        
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                
                // Firestore에서 가져온 데이터로 로컬 데이터 설정
                let subscribedBoards = data?["subscribedBoards"] as? [Int] ?? []
                let keywords = data?["keywords"] as? [String] ?? []
                
                UserDefaults.standard.set(subscribedBoards, forKey: "subscribedBoards")
                UserDefaults.standard.set(keywords, forKey: "subscribedKeywords")
            } else {
                db.collection("users").document(userId).setData([
                    "fcmToken": fcmToken,
                    "subscribedBoards": subscribedBoards,
                    "keywords": subscribedKeywords
                ], merge: true) { error in
                    if let error = error {
                        print("Error saving user settings: \(error)")
                    } else {
                        print("User settings saved successfully")
                    }
                }
            }
        }
    }
}
