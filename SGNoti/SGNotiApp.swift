//
//  Noti_SogangApp.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/7/24.
//

import SwiftUI
import SwiftData

@main
struct SGNotiApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(Color("sogang_red"))
                .modelContainer(for: Bookmark_NoticeDetail.self)
        }
    }
}
