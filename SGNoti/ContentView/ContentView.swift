//
//  ContentView.swift
//  SGNoti
//
//  Created by InHeritas on 8/13/24.
//

import SwiftUI

struct ContentView: View {
    let tags: [String]
    let pkId: Int
    
    var body: some View {
        if tags[0] == "library_notice" {
            LibraryContentView(pkId: pkId, libraryCode: Int(tags[1]) ?? 1)
        } else {
            NoticeContentView(pkId: pkId)
        }
    }
}
