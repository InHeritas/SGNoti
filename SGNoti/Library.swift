//
//  BoardList.swift
//  SGNoti
//
//  Created by InHeritas on 8/13/24.
//

import SwiftUI

struct Library: View {
    var body: some View {
        NavigationStack {
            List {
                Section() {
                    NavigationLink(destination: LibraryListView(libraryCode: 1)) {
                        Text("로욜라 도서관")
                    }
                    NavigationLink(destination: LibraryListView(libraryCode: 44)) {
                        Text("법학전문도서관")
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("도서관")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    Library()
}
