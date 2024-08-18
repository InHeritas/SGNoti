//
//  Settings.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/7/24.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging

struct Setting: View {
    @AppStorage("foldFileLise") private var foldFileList: Bool = true
    @AppStorage("subscribedBoards") private var subscribedBoards: [Int] = [1, 2, 3, 141]
    @AppStorage("subscribedKeywords") private var subscribedKeywords: [String] = []
    
    @State private var totalSize: Int64 = 0
    @State private var keyword: String = ""
    @State private var isNotificationEnabled: Bool = true
    
    let boards = [1, 2, 3, 141, 142]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(""), footer: Text("이 옵션을 끄면 첨부파일 리스트가 펼쳐진 상태로 나타납니다.")) {
                    HStack {
                        Toggle(isOn: $foldFileList, label: {
                            Text("첨부파일 목록 접어두기")
                        })
                    }
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
                Section(header: Text("임시 파일 관리"), footer: Text("첨부파일 다운로드 시 미리보기 창을 닫으면 기본적으로 해당 파일은 삭제됩니다. 첨부파일이 삭제되지 않은 경우 직접 삭제할 수 있습니다.")) {
                    HStack {
                        Text("임시 파일 용량")
                        Spacer()
                        Text("\(formatSize(size: totalSize))")
                    }
                    Button(action: deleteAllFiles) {
                        Text("임시 파일 삭제")
                    }
                }
                Section(header: Text("지원")) {
                    Button(action: { openURLInSafari(urlString: "https://www.inheritas.dev") }) {
                        HStack {
                            Text("개발자 웹사이트")
                            Spacer()
                            Image(systemName: "safari")
                        }
                    }.buttonStyle(PlainButtonStyle())
                }
                Section(header: Text("정보")) {
                    NavigationLink(destination: OSSView()) {
                        Text("오픈소스 라이선스")
                    }
                    HStack {
                        Text("현재 버전")
                        Spacer()
                        Text(versionNumber())
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear() {
                calculateTotalSize()
                checkNotificationSettings() { isEnabled in
                    isNotificationEnabled = isEnabled
                }
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
    
    func readFromFirestore() {
        let firestoreManager = FirestoreManager()
        firestoreManager.fetchDocument(collectionName: "users", documentID: "E4F44FF2-0499-42CC-911F-46E9095287A3") { (document, error) in
            if let error = error {
                print("Failed to fetch document: \(error)")
            } else if let document = document {
                print("\(document.documentID) => \(document.data() ?? [:])")
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
    
    func openURLInSafari(urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    func versionNumber() -> String {
        let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if let versionNumber = versionNumber {
            return "\(versionNumber)"
        } else {
            return ""
        }
    }
    
    func calculateTotalSize() {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        do {
            let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles)
            totalSize = files.reduce(0) { total, file in
                let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return total + Int64(size)
            }
        } catch {
            print("Failed to calculate total size: \(error.localizedDescription)")
        }
    }
    
    func deleteAllFiles() {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        do {
            let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            totalSize = 0
        } catch {
            print("Failed to delete files: \(error.localizedDescription)")
        }
    }
    
    func formatSize(size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

class FirestoreManager {
    let db = Firestore.firestore()
    
    // 특정 컬렉션에서 모든 문서를 읽어오는 함수
    func fetchAllDocuments(collectionName: String, completion: @escaping ([QueryDocumentSnapshot]?, Error?) -> Void) {
        db.collection(collectionName).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(nil, error)
            } else {
                if let documents = querySnapshot?.documents {
                    completion(documents, nil)
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    // 특정 문서를 읽어오는 함수
    func fetchDocument(collectionName: String, documentID: String, completion: @escaping (DocumentSnapshot?, Error?) -> Void) {
        let docRef = db.collection(collectionName).document(documentID)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error getting document: \(error)")
                completion(nil, error)
            } else {
                if let document = document, document.exists {
                    completion(document, nil)
                } else {
                    print("Document does not exist")
                    completion(nil, nil)
                }
            }
        }
    }
}

#Preview {
    Setting()
}
