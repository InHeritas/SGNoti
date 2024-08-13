//
//  Data.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/7/24.
//

import Foundation

struct NoticeData: Identifiable, Decodable, Equatable {
    let id = UUID()
    let title: String?
    let tags: [String]
    let userName: String?
    let regDate: String?
    let pkId: Int
    let isTop: Bool
    
    enum CodingKeys: String, CodingKey {
        case title
        case userName
        case regDate
        case pkId
        case isTop
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawTitle = try container.decodeIfPresent(String.self, forKey: .title)
        self.userName = try container.decodeIfPresent(String.self, forKey: .userName)
        let rawRegDate = try container.decodeIfPresent(String.self, forKey: .regDate)
        self.pkId = try container.decode(Int.self, forKey: .pkId)
        let rawIsTop = try container.decodeIfPresent(String.self, forKey: .isTop)
        self.isTop = (rawIsTop == "Y")
        
        if let rawTitle = rawTitle {
            let tags = extractTags(from: rawTitle)
            self.tags = tags
            self.title = rawTitle.replacingOccurrences(of: tags.joined(separator: " "), with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            self.tags = []
            self.title = rawTitle
        }
        
        if let rawRegDate = rawRegDate, rawRegDate.count >= 8 {
            let startIndex = rawRegDate.index(rawRegDate.startIndex, offsetBy: 0)
            let endIndex = rawRegDate.index(rawRegDate.startIndex, offsetBy: 8)
            let dateSubstring = rawRegDate[startIndex..<endIndex]
            let year = dateSubstring.prefix(4)
            let month = dateSubstring.dropFirst(4).prefix(2)
            let day = dateSubstring.dropFirst(6).prefix(2)
            self.regDate = "\(year).\(month).\(day)"
        } else {
            self.regDate = rawRegDate
        }
    }
}

struct APIResponse: Decodable {
    let statusCode: Int
    let responseMessage: String
    let data: ResponseData
}

struct ResponseData: Decodable {
    let total: Int
    let list: [NoticeData]
}

private func extractTags(from title: String) -> [String] {
    var tags: [String] = []
    let regex = try! NSRegularExpression(pattern: "\\[(.*?)\\]", options: [])
    let matches = regex.matches(in: title, options: [], range: NSRange(location: 0, length: title.count))
    for match in matches {
        if let range = Range(match.range, in: title) {
            let tag = String(title[range])
            tags.append(tag)
        }
    }
    return tags
}
