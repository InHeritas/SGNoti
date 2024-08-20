//
//  NotificationViewModifier.swift
//  SGNoti
//
//  Created by InHeritas on 8/20/24.
//

import Foundation
import SwiftUI

struct NotificationViewModifier: ViewModifier {
    private let onNotification: (UNNotificationResponse) -> Void
    
    init(onNotification: @escaping (UNNotificationResponse) -> Void, handler: NotificationHandler) {
        self.onNotification = onNotification
    }
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationHandler.shared.$latestNotification) { response in
                guard let response else { return }
                onNotification(response)
            }
    }
}
