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
    @State private var totalSize: Int64 = 0
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
            }
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

#Preview {
    Setting()
}
