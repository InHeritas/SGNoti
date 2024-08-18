//
//  Extensions.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/9/24.
//

import Foundation
import SwiftUI

extension Int: Identifiable {
    public var id: Int { self }
}

extension View {
    func vpadding(_ value: CGFloat? = nil) -> some View {
        if let value = value {
            // 값이 제공된 경우
            return self.padding(.vertical, value)
        } else {
            // 값이 제공되지 않은 경우
            return self.padding(.vertical)
        }
    }
    func hpadding(_ value: CGFloat? = nil) -> some View {
        if let value = value {
            // 값이 제공된 경우
            return self.padding(.horizontal, value)
        } else {
            // 값이 제공되지 않은 경우
            return self.padding(.horizontal)
        }
    }
}

extension Spacer {
    @ViewBuilder static func width(_ value: CGFloat?) -> some View {
        switch value {
        case .some(let value): Spacer().frame(width: max(value, 0))
        case nil: Spacer()
        }
    }
    @ViewBuilder static func height(_ value: CGFloat?) -> some View {
        switch value {
        case .some(let value): Spacer().frame(height: max(value, 0))
        case nil: Spacer()
        }
    }
}

// MARK:  파일 미리보기
extension UIViewController: UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    public func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        // 미리보기가 끝난 후 파일 삭제
        if let fileURL = controller.url {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("파일 삭제에 실패했습니다: \(error)")
            }
        }
    }
    
    public func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        if let fileURL = controller.url {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("파일 삭제에 실패했습니다: \(error)")
            }
        }
    }
}

// MARK:  @AppStorage에 Array 저장
extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard
            let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
