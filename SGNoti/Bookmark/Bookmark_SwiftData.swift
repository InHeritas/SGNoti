//
//  Bookmark_SwiftData.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/8/24.
//

import SwiftData

@Model
class Bookmark_NoticeDetail {
    var pkId: Int
    var title: String
    var regDate: String
    var userName: String
    var content: String
    var tags: [String]
    
    init(pkId: Int, title: String, regDate: String, userName: String, content: String, tags: [String]) {
        self.pkId = pkId
        self.title = title
        self.regDate = regDate
        self.userName = userName
        self.content = content
        self.tags = tags
    }
}
