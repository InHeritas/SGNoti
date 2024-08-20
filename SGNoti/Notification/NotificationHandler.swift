//
//  NotificationHandler.swift
//  SGNoti
//
//  Created by InHeritas on 8/20/24.
//

import Foundation
import UserNotifications

public class NotificationHandler: ObservableObject {
    public static let shared = NotificationHandler()
    
    @Published private(set) var latestNotification: UNNotificationResponse? = .none
    
    public func handle(response: UNNotificationResponse) {
        self.latestNotification = response
    }
}
