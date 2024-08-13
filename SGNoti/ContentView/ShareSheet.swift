//
//  ShareSheet.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/8/24.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: [SafariActivity()])
        controller.excludedActivityTypes = excludedActivityTypes
        
        if let presentationController = controller.presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class SafariActivity: UIActivity {
    var url: URL?
    
    override var activityTitle: String? {
        return "Safari로 열기"
    }
    
    override var activityImage: UIImage? {
        return UIImage(systemName: "safari")
    }
    
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType("SafariActivity")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let url = item as? URL, UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if let url = item as? URL {
                self.url = url
            }
        }
    }
    
    override func perform() {
        if let url = url {
            UIApplication.shared.open(url, options: [:]) { _ in
                self.activityDidFinish(true)
            }
        }
    }
}
