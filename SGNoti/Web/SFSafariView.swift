//
//  SFSafariView.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/8/24.
//

import SafariServices
import SwiftUI

struct SFSafariView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let url: URL

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var parent: SFSafariView

        init(parent: SFSafariView) {
            self.parent = parent
        }

        func safariViewControllerDidFinish(_: SFSafariViewController) {
            parent.isPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<SFSafariView>) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator
        return safariVC
    }

    func updateUIViewController(_: SFSafariViewController, context _: UIViewControllerRepresentableContext<SFSafariView>) {
        // 업데이트 로직이 필요한 경우 추가
    }
}

struct SFSafariFileView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context _: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_: SFSafariViewController, context _: Context) {}
}
