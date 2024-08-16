//
//  NoticeDetail.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/8/24.
//

import Foundation

struct NoticeDetail: Decodable {
    let pkId: Int
    var title: String
    let tags: [String]
    let userName: String
    let content: String
    let regDate: String
    let viewCount: Int
    var fileUrls: [String]
    var fileDownloading: [Bool]
    
    enum CodingKeys: String, CodingKey {
        case pkId, title, userName, content, regDate, viewCount, fileValue1, fileValue2, fileValue3, fileValue4, fileValue5
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.pkId = try container.decode(Int.self, forKey: .pkId)
        self.title = try container.decode(String.self, forKey: .title)
        self.userName = try container.decode(String.self, forKey: .userName)
        self.content = try container.decode(String.self, forKey: .content)
        self.viewCount = try container.decode(Int.self, forKey: .viewCount)
        
        // Extract tags from title
        let rawTitle = try container.decode(String.self, forKey: .title)
        self.tags = extractTags(from: rawTitle)
        self.title = rawTitle.replacingOccurrences(of: tags.joined(separator: " "), with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract and format date
        let rawRegDate = try container.decode(String.self, forKey: .regDate)
        if rawRegDate.count >= 8 {
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
        
        // Extract file URLs and decode
        self.fileUrls = []
        self.fileDownloading = []
        if let fileValue1 = try container.decodeIfPresent(String.self, forKey: .fileValue1) {
            self.fileUrls.append(fileValue1)
            self.fileDownloading.append(false)
        }
        if let fileValue2 = try container.decodeIfPresent(String.self, forKey: .fileValue2) {
            self.fileUrls.append(fileValue2)
            self.fileDownloading.append(false)
        }
        if let fileValue3 = try container.decodeIfPresent(String.self, forKey: .fileValue3) {
            self.fileUrls.append(fileValue3)
            self.fileDownloading.append(false)
        }
        if let fileValue4 = try container.decodeIfPresent(String.self, forKey: .fileValue4) {
            self.fileUrls.append(fileValue4)
            self.fileDownloading.append(false)
        }
        if let fileValue5 = try container.decodeIfPresent(String.self, forKey: .fileValue5) {
            self.fileUrls.append(fileValue5)
            self.fileDownloading.append(false)
        }
    }
}

struct NoticeDetailResponse: Decodable {
    let statusCode: Int
    let responseMessage: String
    let data: NoticeDetail
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
