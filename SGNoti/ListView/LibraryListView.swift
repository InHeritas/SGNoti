//
//  LibraryListView.swift
//  SGNoti
//
//  Created by InHeritas on 8/13/24.
//

import Alamofire
import SwiftSoup
import SwiftUI

struct LibraryListView: View {
    let libraryCode: Int
    @State private var notices: [LibraryNoticeData] = []
    @State private var totalCount: Int = 0
    @State private var isLoading = true
    @State private var pageNum = 1
    @State private var showSearchBar: Bool = false
    @State private var searchText: String = ""
    @State private var dismissBar: Bool = true
    @State private var searchPopup: Bool = false
    @State private var searching: Bool = false
    @State private var isLoadMore: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                if pageNum == 1 && isLoading {
                    ProgressView()
                } else {
                    LibraryList(libraryCode: libraryCode, notices: $notices, pageNum: $pageNum, searching: $searching, isLoading: $isLoading, isLoadMore: $isLoadMore, totalCount: $totalCount)
                }
            }
            .navigationTitle(libraryCode == 1 ? "로욜라 도서관" : "법학전문도서관")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "검색어를 입력하세요"
            )
            .onSubmit(of: .search) {
                notices = []
                pageNum = 1
                fetchLibraryNotices()
            }
            .onChange(of: isLoadMore) { newValue, _ in
                if !newValue {
                    isLoadMore = false
                    loadMore()
                }
            }
            .onAppear {
                if notices.isEmpty {
                    fetchLibraryNotices()
                }
            }
        }
    }

    func loadMore() {
        guard notices.count < totalCount else {
            isLoadMore = false
            return
        }
        isLoading = true
        fetchLibraryNotices()
    }

    func fetchLibraryNotices() {
        var searchParam = ""
        if !searchText.isEmpty {
            searchParam = "&searchKind=title&searchKey=\(searchText)"
        } else {
            searchParam = ""
        }

        let url = "https://library.sogang.ac.kr/bbs/list/\(libraryCode)?pn=\(pageNum)\(searchParam)&countPerPage=20"

        AF.request(url).responseString { response in
            DispatchQueue.main.async {
                switch response.result {
                case let .success(html):
                    do {
                        let document = try SwiftSoup.parse(html)

                        if let totalString = try document.select("#divContent > div.listInfo > div.listInfo1 > p.totalCnt > span").first()?.text(),
                           let total = Int(totalString) {
                            self.totalCount = total
                        }

                        let rows = try document.select("#divContent > form > div > table > tbody > tr")

                        var fetchedNotices: [LibraryNoticeData] = []

                        for row in rows {
                            let isAlways = row.hasClass("always")
                            let title = try row.select("td.title a").text()
                            let writer = try row.select("td.writer").text()
                            let reportDate = try row.select("td.reportDate").text()
                            let href = try row.select("td.title a").attr("href")
                            let pkId: Int
                            if let match = href.range(of: "(?<=content/\(libraryCode)_)[0-9]+", options: .regularExpression) {
                                pkId = Int(href[match]) ?? 57145
                            } else {
                                pkId = 57145
                            }

                            let notice = LibraryNoticeData(isAlways: isAlways, title: title, writer: writer, reportDate: reportDate, pkId: pkId)
                            fetchedNotices.append(notice)
                        }

                        self.notices.append(contentsOf: fetchedNotices)

                        if self.notices.count < self.totalCount {
                            self.pageNum += 1
                        }

                        self.isLoading = false
                    } catch {
                        print("Error parsing HTML: \(error)")
                        self.isLoading = false
                    }
                case let .failure(error):
                    print("Error fetching HTML: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
}

struct LibraryList: View {
    let libraryCode: Int
    @Environment(\.isSearching) private var isSearching
    @Binding var notices: [LibraryNoticeData]
    @Binding var pageNum: Int
    @Binding var searching: Bool
    @Binding var isLoading: Bool
    @Binding var isLoadMore: Bool
    @Binding var totalCount: Int

    var body: some View {
        List {
            ForEach(notices) { notice in
                NavigationLink(destination: LibraryContentView(pkId: notice.pkId, libraryCode: libraryCode)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            if notice.isAlways {
                                Image(systemName: "pin.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 14)
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 6).padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .foregroundStyle(Color("sogang_red"))
                                    )
                            }
                            Text(notice.title)
                                .lineLimit(1)
                                .font(.headline)
                        }
                        HStack {
                            Text(notice.reportDate)
                                .font(.subheadline)
                            Text("｜")
                                .font(.subheadline)
                            Text(notice.writer)
                                .font(.subheadline)
                        }
                    }.onAppear {
                        if notice == notices.last && notices.count < totalCount {
                            isLoadMore = true
                        }
                    }
                }
            }
            if isLoading {
                HStack {
                    Spacer()
                    Text("불러오는 중 ...")
                    Spacer()
                }
                .listSectionSeparator(.hidden, edges: .bottom)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            notices = []
            pageNum = 1
            isLoadMore = true
        }
        .onChange(of: isSearching) { newValue, _ in
            if newValue {
                notices = []
                pageNum = 1
                isLoadMore = true
            }
        }
    }
}

#Preview {
    LibraryListView(libraryCode: 1)
}
