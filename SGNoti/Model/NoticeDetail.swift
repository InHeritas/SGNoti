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
        pkId = try container.decode(Int.self, forKey: .pkId)
        title = try container.decode(String.self, forKey: .title)
        userName = try container.decode(String.self, forKey: .userName)
        content = try container.decode(String.self, forKey: .content)
        viewCount = try container.decode(Int.self, forKey: .viewCount)

        // Extract tags from title
        let rawTitle = try container.decode(String.self, forKey: .title)
        tags = extractTags(from: rawTitle)
        title = rawTitle.replacingOccurrences(of: tags.joined(separator: " "), with: "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract and format date
        let rawRegDate = try container.decode(String.self, forKey: .regDate)
        if rawRegDate.count >= 12 {
            let startIndex = rawRegDate.index(rawRegDate.startIndex, offsetBy: 0)
            let dateEndIndex = rawRegDate.index(rawRegDate.startIndex, offsetBy: 8)
            let dateSubstring = rawRegDate[startIndex ..< dateEndIndex]
            let year = dateSubstring.prefix(4)
            let month = dateSubstring.dropFirst(4).prefix(2)
            let day = dateSubstring.dropFirst(6).prefix(2)
            let timeStartIndex = rawRegDate.index(rawRegDate.startIndex, offsetBy: 8)
            let timeEndIndex = rawRegDate.index(rawRegDate.startIndex, offsetBy: 12)
            let timeSubstring = rawRegDate[timeStartIndex ..< timeEndIndex]
            let hour = timeSubstring.prefix(2)
            let minute = timeSubstring.dropFirst(2).prefix(2)
            regDate = "\(year).\(month).\(day) \(hour):\(minute)"
        } else {
            regDate = rawRegDate
        }

        // Extract file URLs and decode
        fileUrls = []
        fileDownloading = []
        if let fileValue1 = try container.decodeIfPresent(String.self, forKey: .fileValue1) {
            fileUrls.append(fileValue1)
            fileDownloading.append(false)
        }
        if let fileValue2 = try container.decodeIfPresent(String.self, forKey: .fileValue2) {
            fileUrls.append(fileValue2)
            fileDownloading.append(false)
        }
        if let fileValue3 = try container.decodeIfPresent(String.self, forKey: .fileValue3) {
            fileUrls.append(fileValue3)
            fileDownloading.append(false)
        }
        if let fileValue4 = try container.decodeIfPresent(String.self, forKey: .fileValue4) {
            fileUrls.append(fileValue4)
            fileDownloading.append(false)
        }
        if let fileValue5 = try container.decodeIfPresent(String.self, forKey: .fileValue5) {
            fileUrls.append(fileValue5)
            fileDownloading.append(false)
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

    do {
        let regex = try NSRegularExpression(pattern: "\\[(.*?)\\]", options: [])
        let matches = regex.matches(in: title, options: [], range: NSRange(location: 0, length: title.count))
        for match in matches {
            if let range = Range(match.range, in: title) {
                let tag = String(title[range])
                tags.append(tag)
            }
        }
    } catch {
        print("Regex creation failed with error: \(error.localizedDescription)")
    }

    return tags
}
