//
//  TipKit.swift
//  SGNoti
//
//  Created by InHeritas on 8/22/24.
//

import Foundation
import TipKit

struct NotificationTip: Tip {
    var title: Text {
        Text("알림 설정")
    }

    var message: Text? {
        Text("설정 - 알림에서 공지사항별 알림과 키워드 알림을 사용자화할 수 있습니다.")
    }

    var image: Image? {
        Image(systemName: "app.badge")
            .symbolRenderingMode(.multicolor)
    }

    var actions: [Action] {
        Action(id: "goToSetting", title: "사용자화 하러 가기")
    }
}
