//
//  Notification.swift
//  SGNoti
//
//  Created by InHeritas on 8/18/24.
//

import SwiftUI
import FirebaseFirestore

struct Notification: View {
    @AppStorage("subscribedBoards") private var subscribedBoards: [Int] = [1, 2, 3, 141]
    @AppStorage("subscribedKeywords") private var subscribedKeywords: [String] = []
    @State private var isNotificationEnabled: Bool = true
    @State private var keyword: String = ""
    
    let boards = [1, 2, 3, 141, 142]
    
    var body: some View {
        List {
            Section(footer: Text("본 알림은 실시간이 아니며 약 30분 간격으로 새로운 공지사항을 확인하여 알림을 전송합니다.")) {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "bell.badge")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundStyle(Color.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .foregroundStyle(Color("grey600"))
                            )
                        Spacer()
                    }
                    Spacer.height(15)
                    Text("알림")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer.height(10)
                    Text("설정한 게시판에 새로운 공지사항이 있거나,\n설정한 키워드가 포함된 공지사항이 올라오면\n푸시 알림을 받을 수 있습니다.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                }
                .vpadding(10)
            }
            if !isNotificationEnabled {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("알림이 비활성화 상태입니다.")
                    }
                    Button(action: {
                        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                            if UIApplication.shared.canOpenURL(appSettings) {
                                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                            }
                        }
                    }) {
                        Text("앱 설정 열기")
                    }
                    Button(action: {
                        checkNotificationSettings() { isEnabled in
                            isNotificationEnabled = isEnabled
                        }
                    }) {
                        Text("설정 새로고침")
                    }
                }
            }
            Section(header: Text("새 글 알림 설정")) {
                ForEach(boards) { board in
                    HStack {
                        Text(noticeTitle(board))
                        Spacer()
                        Toggle(isOn: Binding(
                            get: {
                                subscribedBoards.contains(board)
                            },
                            set: { isOn in
                                if isOn {
                                    subscribedBoards.append(board)
                                } else {
                                    if let index = subscribedBoards.firstIndex(of: board) {
                                        subscribedBoards.remove(at: index)
                                    }
                                }
                            }
                        )) {
                            Text("")
                        }
                        .disabled(!isNotificationEnabled)
                    }
                }
                .onChange(of: subscribedBoards) { newValue, _ in
                    saveUserSettings(subscribedBoards: subscribedBoards, keywords: subscribedKeywords)
                }
            }
            Section(header: Text("키워드 알림 설정"), footer: Text("공백만 있거나 한글, 영어가 포함되지 않은 키워드는 추가할 수 없습니다.")) {
                HStack {
                    TextField("추가할 키워드를 입력하세요", text: $keyword)
                        .onSubmit {
                            addKeyword()
                        }
                    Spacer()
                    Button(action: {
                        addKeyword()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.green)
                    }
                    .disabled(!isNotificationEnabled)
                }
                .onChange(of: subscribedKeywords) { newValue, _ in
                    saveUserSettings(subscribedBoards: subscribedBoards, keywords: subscribedKeywords)
                }
                if !subscribedKeywords.isEmpty {
                    ForEach(subscribedKeywords.indices, id: \.self) { index in
                        HStack {
                            Text(subscribedKeywords[index])
                            Spacer()
                            Button(action: {
                                subscribedKeywords.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color.red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear() {
            checkNotificationSettings() { isEnabled in
                isNotificationEnabled = isEnabled
            }
        }
    }
    
    func checkNotificationSettings(completion: @escaping (Bool) -> Void) {
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                // 알림이 허용된 상태입니다.
                completion(true)
            case .denied, .notDetermined:
                // 알림이 거부되었거나 아직 요청되지 않은 상태입니다.
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
    
    private func addKeyword() {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let specialCharacterPattern = "^[^a-zA-Z0-9가-힣]+$"
        let numericPattern = "^[0-9]+$"
        
        if !trimmedKeyword.isEmpty &&
            !subscribedKeywords.contains(trimmedKeyword) &&
            trimmedKeyword.range(of: specialCharacterPattern, options: .regularExpression) == nil &&
            trimmedKeyword.range(of: numericPattern, options: .regularExpression) == nil {
            subscribedKeywords.append(trimmedKeyword)
        }
        
        keyword = ""
    }
    
    func saveUserSettings(subscribedBoards: [Int], keywords: [String]) {
        guard let userId = getUserId() else {
            print("Error: Could not retrieve identifierForVendor.")
            return
        }
        
        let db = Firestore.firestore()
        
        // Firestore에 데이터 저장
        db.collection("users").document(userId).updateData([
            "subscribedBoards": subscribedBoards,
            "keywords": keywords
        ]) { error in
            if let error = error {
                print("Error saving user settings: \(error)")
            } else {
                print("User settings saved successfully")
            }
        }
    }
    
    func getUserId() -> String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    func noticeTitle(_ bbsConfigFk: Int) -> String {
        if bbsConfigFk == 1 {
            return "일반공지"
        } else if bbsConfigFk == 2 {
            return "학사공지"
        } else if bbsConfigFk == 141 {
            return "장학공지"
        } else if bbsConfigFk == 3 {
            return "종합봉사실"
        } else if bbsConfigFk == 142 {
            return "행사특강"
        } else {
            return "공지사항"
        }
    }
}

#Preview {
    Notification()
}
