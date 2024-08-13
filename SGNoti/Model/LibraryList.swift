//
//  LibraryList.swift
//  SGNoti
//
//  Created by InHeritas on 8/13/24.
//

import Foundation

struct LibraryNoticeData: Identifiable, Decodable, Equatable {
    var id = UUID()
    var isAlways: Bool
    var title: String
    var writer: String
    var reportDate: String
    var pkId: Int
}
