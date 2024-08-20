//
//  ContentsView.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/7/24.
//

import SwiftUI
import UIKit
import Alamofire
import SwiftData

struct NoticeContentView: View {
    let pkId: Int
    @AppStorage("foldFileLise") private var foldFileList: Bool = true
    @State private var noticeDetail: NoticeDetail?
    @State private var isLoading: Bool = true
    @State private var isPageLoading: Bool = true
    @State private var webViewContentHeight: CGFloat = .zero
    @State private var content: String = ""
    @State private var isBookmarked: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var settingsDetent = PresentationDetent.medium
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [Bookmark_NoticeDetail]
    @State private var showSafariView = false
    @State private var selectedFileURL: Int? = nil
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if let noticeDetail = noticeDetail {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        if !noticeDetail.tags.isEmpty {
                            HStack {
                                ForEach(noticeDetail.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.footnote)
                                        .foregroundStyle(Color("sogang_red"))
                                }
                            }
                        }
                        Text(noticeDetail.title)
                            .font(.headline)
                            .bold()
                        HStack {
                            Text(noticeDetail.regDate)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("｜")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(noticeDetail.userName)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Divider()
                        if !noticeDetail.fileUrls.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                DisclosureGroup(isExpanded: $isExpanded) {
                                    ForEach(noticeDetail.fileUrls.indices, id: \.self) { index in
                                        Button(action: {
                                            selectedFileURL = index
                                            downloadAndOpenFile(at: noticeDetail.fileUrls[index])
                                        }) {
                                            HStack {
                                                if noticeDetail.fileDownloading[index] {
                                                    ProgressView()
                                                        .frame(width: 14, height: 14)
                                                        .hpadding(5)
                                                } else {
                                                    Image(systemName: "paperclip")
                                                        .frame(width: 14, height: 14)
                                                        .hpadding(5)
                                                }
                                                Text(extractFileName(from: noticeDetail.fileUrls[index]) ?? "첨부파일")
                                                    .multilineTextAlignment(.leading)
                                                    .font(.subheadline)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .foregroundStyle(Color("grey100"))
                                            )
                                        }
                                        .padding(.top, index == 0 ? 10 : 0)
                                        .padding(.bottom, index == noticeDetail.fileUrls.count - 1 ? 10 : 0)
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                } label: {
                                    Text("\(noticeDetail.fileUrls.count)개의 첨부파일")
                                        .font(.subheadline)
                                        .bold()
                                }
                            }
                            Divider()
                        }
                        ZStack {
                            WebView(url: URL(string: "https://www.sogang.ac.kr/ko/detail/\(pkId)")!, content: content, contentHeight: $webViewContentHeight, isPageLoading: $isPageLoading)
                                .frame(height: webViewContentHeight)
                            if isPageLoading {
                                VStack {
                                    Spacer().frame(height: 200)
                                    ProgressView()
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("Failed to load notice details")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 24) {
                    Button(action: {
                        toggleBookmark()
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    Button(action: {
                        showShareSheet.toggle()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .sheet(isPresented: $showShareSheet) {
                        if noticeDetail != nil {
                            ShareSheet(items: [URL(string: "https://www.sogang.ac.kr/ko/detail/\(pkId)")!])
                                .presentationDetents(
                                    [.medium, .large],
                                    selection: $settingsDetent
                                )
                                .ignoresSafeArea()
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await fetchNoticeDetail()
                if !foldFileList {
                    isExpanded = true
                }
                checkIfBookmarked()
            }
        }
    }
    
    func fetchNoticeDetail() async {
        let url = "https://www.sogang.ac.kr/api/api/v1/mainKo/BbsData?pkId=\(pkId)"
        AF.request(url, method: .get).responseDecodable(of: NoticeDetailResponse.self) { response in
            switch response.result {
            case .success(let detailResponse):
                if detailResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.noticeDetail = detailResponse.data
                        self.content = detailResponse.data.content
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func downloadAndOpenFile(at urlString: String) {
        if let selectedFileURLIndex = selectedFileURL {
            noticeDetail?.fileDownloading[selectedFileURLIndex] = true
            
            // Download file
            downloadFile(from: urlString) { url in
                if let url = url {
                    if url.absoluteString.contains(".hwp") {
                        openDownloadedHWPFile(fileURL: url)
                    } else {
                        openDownloadedFile(fileURL: url)
                    }
                } else {
                    print("파일 다운로드 실패")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    noticeDetail?.fileDownloading[selectedFileURLIndex] = false
                }
            }
        } else {
            print("파일 다운로드 실패")
        }
    }
    
    func downloadFile(from url: String, completion: @escaping (URL?) -> Void) {
        AF.request(url).responseData { response in
            guard response.response != nil else {
                completion(nil)
                return
            }
            
            if let noticeDetail = noticeDetail, let selectedFileURLIndex = selectedFileURL {
                let fileName = extractFileName(from: noticeDetail.fileUrls[selectedFileURLIndex]) ?? "첨부파일"
                
                let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
                
                do {
                    try response.data?.write(to: fileURL)
                    completion(fileURL)
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func openDownloadedFile(fileURL: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let documentInteractionController = UIDocumentInteractionController(url: fileURL)
        documentInteractionController.delegate = rootViewController
        
        // 전체 화면 미리보기
        documentInteractionController.presentPreview(animated: true)
    }
    
    // HWP 파일은 미리보기로 열리지 않음
    func openDownloadedHWPFile(fileURL: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        rootViewController.present(activityViewController, animated: true, completion: nil)
    }
    
    func checkIfBookmarked() {
        isBookmarked = bookmarks.contains { $0.pkId == pkId }
    }
    
    func toggleBookmark() {
        if isBookmarked {
            if let bookmark = bookmarks.first(where: { $0.pkId == pkId }) {
                modelContext.delete(bookmark)
                isBookmarked = false
            }
        } else {
            guard let noticeDetail = noticeDetail else { return }
            let newBookmark = Bookmark_NoticeDetail(
                pkId: pkId,
                title: noticeDetail.title,
                regDate: noticeDetail.regDate,
                userName: noticeDetail.userName,
                content: noticeDetail.content,
                tags: noticeDetail.tags
            )
            modelContext.insert(newBookmark)
            isBookmarked = true
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save bookmark: \(error.localizedDescription)")
        }
    }
    
    func extractFileName(from url: String) -> String? {
        if let range = url.range(of: "?sg=") {
            let fileName = url[range.upperBound...]
            return String(fileName)
        }
        return nil
    }
    
    func removeSGParameter(from url: String) -> String {
        if let range = url.range(of: "?sg=") {
            return String(url[..<range.lowerBound])
        }
        return url
    }
}

#Preview {
    NoticeContentView(pkId: 544696)
}
