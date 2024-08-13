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
