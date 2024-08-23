//
//  NoticeListView.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/8/24.
//

import Alamofire
import SwiftUI

struct NoticeListView: View {
    let bbsConfigFk: Int

    @State private var notices: [NoticeData] = []
    @State private var totalCount = 0
    let academicCategory: [String] = ["전체", "수업,수강신청", "출결", "전공", "휴,복학", "성적,학점인정", "졸업", "국내교류", "기타"]
    let academicPKID: [String] = ["", "9", "10", "11", "12", "13", "14", "15", "16"]
    let scholarshipCategory: [String] = ["전체", "교내/국가", "교외", "국가근로", "학자금대출", "대청교", "발전기금", "동문회", "공통"]
    let scholarshipPKID: [String] = ["", "1", "2", "3", "4", "5", "6", "7", "8"]

    @State private var isLoading = true
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
                    NoticeList(notices: $notices, pageNum: $pageNum, searching: $searching, isLoading: $isLoading, isLoadMore: $isLoadMore)
                }
            }
            .navigationTitle(noticeTitle(bbsConfigFk))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if bbsConfigFk == 2 {
                            ForEach(academicCategory, id: \.self) { cat in
                                Button(action: { selectedCategory = cat }, label: {
                                    HStack {
                                        Text(cat)
                                        if cat == selectedCategory {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                })
                            }
                        } else if bbsConfigFk == 141 {
                            ForEach(scholarshipCategory, id: \.self) { cat in
                                Button(action: { selectedCategory = cat }, label: {
                                    HStack {
                                        Text(cat)
                                        if cat == selectedCategory {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                })
                            }
                        } else {
                            Button(action: {}, label: {
                                HStack {
                                    Text("전체")
                                }
                            })
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
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
            .onChange(of: selectedCategory) { _, _ in
                notices = []
                pageNum = 1
                fetchNotices()
            }
            .onAppear {
                if notices.isEmpty {
                    fetchNotices()
                }
            }
        }
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

    func loadMore() {
        isLoading = true
        fetchNotices()
    }

    func generateCatParam(bbsConfigFk _: Int, categories: [String], pkIDs: [String], selectedCategory: String) -> String {
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
        if notices.count >= totalCount && totalCount != 0 {
            isLoading = false
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
        }

        let searchParam = generateSearchParam(selectedParam: selectedParam, searchText: searchText)

        var catParam = ""
        switch bbsConfigFk {
        case 2:
            catParam = generateCatParam(bbsConfigFk: bbsConfigFk, categories: academicCategory, pkIDs: academicPKID, selectedCategory: selectedCategory)
        case 141:
            catParam = generateCatParam(bbsConfigFk: bbsConfigFk, categories: scholarshipCategory, pkIDs: scholarshipPKID, selectedCategory: selectedCategory)
        default:
            catParam = ""
        }

        let url = "https://www.sogang.ac.kr/api/api/v1/mainKo/BbsData/boardList?pageNum=\(pageNum)&pageSize=20&bbsConfigFk=\(bbsConfigFk)\(searchParam)\(catParam)"

        AF.request(url, method: .get).responseDecodable(of: APIResponse.self) { response in
            switch response.result {
            case let .success(apiResponse):
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
            case let .failure(error):
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

struct NoticeList: View {
    @Environment(\.isSearching) private var isSearching
    @Binding var notices: [NoticeData]
    @Binding var pageNum: Int
    @Binding var searching: Bool
    @Binding var isLoading: Bool
    @Binding var isLoadMore: Bool
    var body: some View {
        List {
            ForEach(notices) { notice in
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
                            if notice.isTop {
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
                            Text(notice.title ?? "No Title")
                                .lineLimit(1)
                                .font(.headline)
                        }
                        HStack {
                            Text(notice.regDate ?? "No Date")
                                .font(.subheadline)
                            Text("｜")
                                .font(.subheadline)
                            Text(notice.userName ?? "No Username")
                                .font(.subheadline)
                        }
                    }.onAppear {
                        if notice == notices.last {
                            isLoadMore = true
                        }
                    }
                }
            }
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
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
    NoticeListView(bbsConfigFk: 2)
}
