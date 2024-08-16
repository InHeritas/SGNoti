//
//  LibraryContentView.swift
//  SGNoti
//
//  Created by InHeritas on 8/13/24.
//

import SwiftUI
import Alamofire
import SwiftSoup
import SwiftData
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
                                            showSafariView = true
                                        }) {
                                            HStack {
                                                Image(systemName: "paperclip")
                                                Text("\(noticeDetail.fileNames[index])")
                                                    .multilineTextAlignment(.leading)
                                                    .font(.subheadline)
                                                Spacer()
                                            }
                                            .padding(10)
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
                            .fullScreenCover(item: self.$selectedFileURL) { selectedFileURL in
                                if let url = URL(string: noticeDetail.fileUrls[selectedFileURL]) {
                                    SFSafariFileView(url: url)
                                        .ignoresSafeArea()
                                }
                            }
                            Divider()
                        }
                        ZStack {
                            WebView_Library(url: URL(string: "https://library.sogang.ac.kr/bbs/content/\(libraryCode)_\(pkId)")!, contentHeight: $webViewContentHeight, isPageLoading: $isPageLoading)
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
                case .success(let html):
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
                        for element in files {
                            if let href = try? element.attr("href"), let title = try? element.text() {
                                fileUrl.append(href)
                                fileName.append(title)
                            }
                        }
                        
                        let detail = LibraryDetail(title: title, userName: userName, regDate: regDate, fileUrls: fileUrl, fileNames: fileName)
                        self.noticeDetail = detail
                        self.isLoading = false
                    } catch {
                        print("Error parsing HTML: \(error)")
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
