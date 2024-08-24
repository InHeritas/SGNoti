//
//  NoticeList.swift
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
    let configPkid: String?
    let pkId: Int
    let isTop: Bool

    enum CodingKeys: String, CodingKey {
        case title
        case userName
        case regDate
        case config_pkid
        case pkId
        case isTop
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // title과 tags 처리
        let rawTitle = try container.decodeIfPresent(String.self, forKey: .title)
        if let rawTitle = rawTitle {
            let tags = extractTags(from: rawTitle)
            self.tags = tags
            title = rawTitle.replacingOccurrences(of: tags.joined(separator: " "), with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            tags = []
            title = rawTitle
        }

        userName = try container.decodeIfPresent(String.self, forKey: .userName)

        // regDate 처리
        let rawRegDate = try container.decodeIfPresent(String.self, forKey: .regDate)
        if let rawRegDate = rawRegDate, rawRegDate.count >= 8 {
            let startIndex = rawRegDate.index(rawRegDate.startIndex, offsetBy: 0)
            let endIndex = rawRegDate.index(rawRegDate.startIndex, offsetBy: 8)
            let dateSubstring = rawRegDate[startIndex ..< endIndex]
            let year = dateSubstring.prefix(4)
            let month = dateSubstring.dropFirst(4).prefix(2)
            let day = dateSubstring.dropFirst(6).prefix(2)
            regDate = "\(year).\(month).\(day)"
        } else {
            regDate = rawRegDate
        }

        // config_pkid 처리
        configPkid = try container.decodeIfPresent(String.self, forKey: .config_pkid)
        pkId = try container.decode(Int.self, forKey: .pkId)

        // isTop 처리
        if let rawIsTop = try container.decodeIfPresent(String.self, forKey: .isTop) {
            isTop = (rawIsTop == "Y")
        } else {
            isTop = false // isTop 필드가 없으면 기본값은 false
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
