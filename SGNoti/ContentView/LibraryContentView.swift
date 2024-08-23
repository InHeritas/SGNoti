//
//  LibraryContentView.swift
//  SGNoti
//
//  Created by InHeritas on 8/13/24.
//

import Alamofire
import SwiftData
import SwiftSoup
import SwiftUI
import WebKit

struct LibraryContentView: View {
    let pkId: Int
    let libraryCode: Int
    @AppStorage("foldFileLise") private var foldFileList: Bool = true
    @State private var noticeDetail: LibraryDetail?
    @State private var isLoading: Bool = true
    @State private var isPageLoading: Bool = true
    @State private var webViewContentHeight: CGFloat = .zero
    @State private var content: String = ""
    @State private var isBookmarked: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var settingsDetent = PresentationDetent.medium
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [BookmarkedNoticeDetail]
    @State private var showSafariView = false
    @State private var selectedFileURL: Int?
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if let noticeDetail = noticeDetail {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
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
                                        }, label: {
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
                                                Text("\(noticeDetail.fileNames[index])")
                                                    .multilineTextAlignment(.leading)
                                                    .font(.subheadline)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .foregroundStyle(Color("grey100"))
                                            )
                                        })
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
                            LibraryWebView(url: URL(string: "https://library.sogang.ac.kr/bbs/content/\(libraryCode)_\(pkId)")!, contentHeight: $webViewContentHeight, isPageLoading: $isPageLoading)
                                .frame(height: webViewContentHeight)
                            if isPageLoading {
                                Color.white
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
                    }, label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    })
                    Button(action: {
                        showShareSheet.toggle()
                    }, label: {
                        Image(systemName: "square.and.arrow.up")
                    })
                    .sheet(isPresented: $showShareSheet) {
                        if noticeDetail != nil {
                            ShareSheet(items: [URL(string: "https://library.sogang.ac.kr/bbs/content/\(libraryCode)_\(pkId)")!])
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
        let url = "https://library.sogang.ac.kr/bbs/content/\(libraryCode)_\(pkId)"
        AF.request(url).responseString { response in
            DispatchQueue.main.async {
                switch response.result {
                case let .success(html):
                    do {
                        let document = try SwiftSoup.parse(html)

                        let title = try document.select("div.boardInfo p.boardInfoTitle").text()
                        var regDate = try document.select("div.boardInfo div.writeInfo").text()
                        if let range = regDate.range(of: "\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) {
                            regDate = regDate[range].replacingOccurrences(of: "-", with: ".")
                        }
                        let userName = try document.select("div.boardInfo dl.writerInfo dd.writer span").text()

                        let files = try document.select("#divContent > div > div:nth-child(1) > div.additionalItems > div > ul > li > a")
                        var fileUrl: [String] = []
                        var fileName: [String] = []
                        var fileDownloading: [Bool] = []
                        for element in files {
                            if let href = try? element.attr("href"), let title = try? element.text() {
                                fileUrl.append(href)
                                fileName.append(title)
                                fileDownloading.append(false)
                            }
                        }

                        let detail = LibraryDetail(title: title, userName: userName, regDate: regDate, fileUrls: fileUrl, fileNames: fileName, fileDownloading: fileDownloading)
                        self.noticeDetail = detail
                        self.isLoading = false
                    } catch {
                        print("Error parsing HTML: \(error)")
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                    }
                case let .failure(error):
                    print("Error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
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
                let fileName = noticeDetail.fileNames[selectedFileURLIndex]

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
              let rootViewController = windowScene.windows.first?.rootViewController
        else {
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
              let rootViewController = windowScene.windows.first?.rootViewController
        else {
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
            let newBookmark = BookmarkedNoticeDetail(
                pkId: pkId,
                title: noticeDetail.title,
                regDate: noticeDetail.regDate,
                userName: noticeDetail.userName,
                content: "",
                tags: ["library_notice", String(libraryCode)]
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
}

#Preview {
    LibraryContentView(pkId: 57145, libraryCode: 1)
}
