//
//  View+Notifications.swift
//  SGNoti
//
//  Created by InHeritas on 8/20/24.
//

import Foundation
import SwiftUI

extension View {
    func onNotification(perform action: @escaping (UNNotificationResponse) -> Void) -> some View {
        modifier(NotificationViewModifier(onNotification: action, handler: NotificationHandler()))
    }
}
