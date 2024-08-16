//
//  Settings.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/7/24.
//

import SwiftUI
import Firebase
import FirebaseMessaging

struct Setting: View {
    @AppStorage("foldFileLise") private var foldFileList: Bool = true
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
}

#Preview {
    Setting()
}
