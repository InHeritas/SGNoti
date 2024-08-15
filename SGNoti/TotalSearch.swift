//
//  Search.swift
//  SGNoti
//
//  Created by InHeritas on 8/15/24.
//

import SwiftUI
import Alamofire

struct TotalSearch: View {
    @State private var notices: [NoticeData] = []
    @State private var totalCount = 0
    
    @State private var isLoading = false
    @State private var pageNum = 1
    @State private var showSearchBar: Bool = false
    @State private var searchText: String = ""
    @State private var dismissBar: Bool = true
    @State private var searchPopup: Bool = false
    @State private var searching: Bool = false
    @State private var isLoadMore: Bool = false
    @State private var selectedCategory: String = "전체"
    
    @State private var selectedParam = "제목"
    let params = ["제목", "내용", "작성자"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                if pageNum == 1 && isLoading {
                    ProgressView()
                } else {
                    TotalSearchListView(notices: $notices, pageNum: $pageNum, searching: $searching, isLoading: $isLoading, isLoadMore: $isLoadMore)
                }
            }
            .navigationTitle("통합검색")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "검색어를 입력하세요"
            )
            .onSubmit(of: .search) {
                notices = []
                pageNum = 1
                fetchNotices()
            }
            .onChange(of: isLoadMore) { newValue, _ in
                if !newValue {
                    isLoadMore = false
                    loadMore()
                }
            }
            .onChange(of: selectedCategory) { newValue, _ in
                notices = []
                pageNum = 1
                fetchNotices()
            }
        }
    }
    
    func loadMore() {
        isLoading = true
        fetchNotices()
    }
    
    func generateCatParam(bbsConfigFk: Int, categories: [String], pkIDs: [String], selectedCategory: String) -> String {
        if let pkIdIndex = categories.firstIndex(of: selectedCategory), !pkIDs[pkIdIndex].isEmpty {
            return "&introPkId=\(pkIDs[pkIdIndex])"
        }
        return ""
    }
    
    func generateSearchParam(selectedParam: String, searchText: String) -> String {
        switch selectedParam {
        case "제목":
            return "&title=\(searchText)"
        case "내용":
            return "&content=\(searchText)"
        case "작성자":
            return "&username=\(searchText)"
        default:
            return ""
        }
    }
    
    func fetchNotices() {
        // 모든 게시글을 불러온 경우 추가 요청을 막음
        if self.notices.count >= self.totalCount && self.totalCount != 0 {
            self.isLoading = false
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }

        let defaultParam = "&searchOption=title&dateOption=all&sortBy=date"
        let url = "https://www.sogang.ac.kr/api/api/v1/mainKo/BbsData/findAllSearch?pageNum=\(pageNum)&pageSize=15&keyword=\(searchText)\(defaultParam)"
        
        AF.request(url, method: .get).responseDecodable(of: APIResponse.self) { response in
            switch response.result {
            case .success(let apiResponse):
                if apiResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.totalCount = apiResponse.data.total // 전체 게시글 수 저장
                        self.notices.append(contentsOf: apiResponse.data.list)
                        self.isLoading = false
                        if self.notices.count < self.totalCount {
                            self.pageNum += 1
                        }
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
}

struct TotalSearchListView: View {
    @Environment(\.isSearching) private var isSearching
    @Binding var notices: [NoticeData]
    @Binding var pageNum: Int
    @Binding var searching: Bool
    @Binding var isLoading: Bool
    @Binding var isLoadMore: Bool
    let configPkidSet: Set<String> = ["1", "2", "3", "141", "142"]
    
    var body: some View {
        List {
            ForEach(filteredNotices(notices)) { notice in
                NavigationLink(destination: NoticeContentView(pkId: notice.pkId)) {
                    VStack(alignment: .leading, spacing: 6) {
                        if !notice.tags.isEmpty {
                            HStack {
                                ForEach(notice.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.footnote)
                                        .foregroundStyle(Color("sogang_red"))
                                }
                            }
                        }
                        HStack {
                            Text(notice.title ?? "No Title")
                                .lineLimit(1)
                                .font(.headline)
                        }
                        Text(notice.regDate ?? "No Date")
                            .font(.subheadline)
                    }.onAppear {
                        if notice == filteredNotices(notices).last {
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
            if !notices.isEmpty {
                notices = []
                pageNum = 1
                isLoadMore = true
            }
        }
        .onChange(of: isSearching) { newValue, _ in
            if newValue {
                notices = []
                pageNum = 1
            }
        }
    }
    
    func filteredNotices(_ notices: [NoticeData]) -> [NoticeData] {
        return notices.filter { configPkidSet.contains($0.config_pkid ?? "") }
    }
}

#Preview {
    TotalSearch()
}
