//
//  MainTabView.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/7/24.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Home().tabItem {
                Image(systemName: "square.stack.fill")
                Text("둘러보기")
            }
            Library().tabItem {
                Image(systemName: "book.closed.fill")
                Text("도서관")
            }
            Bookmark().tabItem {
                Image(systemName: "bookmark.fill")
                Text("북마크")
            }
            Setting().tabItem {
                Image(systemName: "gearshape.fill")
                Text("설정")
            }
        }
    }
}

#Preview {
    MainTabView()
}
