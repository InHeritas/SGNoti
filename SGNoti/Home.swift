//
//  Home.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/7/24.
//

import SwiftUI
import Alamofire
import UserNotifications

struct Home: View {
    @AppStorage("sectionOrderData") private var sectionOrderData: String = ""
    @AppStorage("noticeCountsData") private var noticeCountsData: String = "[4, 4, 4, 4, 4]"
    @AppStorage("hiddenNoticesData") private var hiddenNoticesData: String = "[]"
    
    @State private var academicNotices: [NoticeData] = []
    @State private var generalNotices: [NoticeData] = []
    @State private var scholarshipNotices: [NoticeData] = []
    @State private var onestopNotices: [NoticeData] = []
    @State private var eventNotices: [NoticeData] = []
    @State private var isLoading: Bool = true
    @State private var showSafariView: Bool = false
    @State private var showEditSectionsView: Bool = false
    @State private var openNoticePage: Bool = false
    @State private var notificationPkId: Int = 0
    
    @State private var noticeName: [String] = ["학사공지", "일반공지", "장학공지", "종합봉사실", "행사특강"]
    @State private var bbsConfigFk: [Int] = [2, 1, 141, 3, 142]
    
    @State private var sectionOrder: [Int] = []
    @State private var noticeCounts: [Int] = []
    @State private var hiddenNotices: Set<Int> = []
    
    init() {
        if let data = sectionOrderData.data(using: .utf8), let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            _sectionOrder = State(initialValue: decoded)
        } else {
            _sectionOrder = State(initialValue: bbsConfigFk)
        }
        
        if let data = noticeCountsData.data(using: .utf8), let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            _noticeCounts = State(initialValue: decoded)
        } else {
            _noticeCounts = State(initialValue: [4, 4, 4, 4, 4])
        }
        
        if let data = hiddenNoticesData.data(using: .utf8), let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            _hiddenNotices = State(initialValue: decoded)
        } else {
            _hiddenNotices = State(initialValue: [])
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(sectionOrder, id: \.self) { section in
                            if !hiddenNotices.contains(section) {
                                Section(header: Text(noticeName[bbsConfigFk.firstIndex(of: section)!])) {
                                    ForEach(getNotices(for: section)) { notice in
                                        NoticeRow(notice: notice)
                                    }
                                    NavigationLink(destination: NoticeListView(bbsConfigFk: section)) {
                                        HStack {
                                            Image(systemName: "plus")
                                            Text("전체글 보기")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        isLoading = true
                        await fetchAllNotices()
                    }
                }
            }
            .navigationTitle("둘러보기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        self.showSafariView = true
                    }) {
                        Text("웹페이지")
                    }
                    .fullScreenCover(isPresented: $showSafariView) {
                        SFSafariView(isPresented: self.$showSafariView, url: URL(string: "https://www.sogang.ac.kr")!)
                            .ignoresSafeArea()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        self.showEditSectionsView = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .sheet(isPresented: $showEditSectionsView, onDismiss: {
                        saveSettings()
                    }) {
                        EditSectionsView(
                            sectionOrder: $sectionOrder,
                            noticeCounts: $noticeCounts,
                            hiddenNotices: $hiddenNotices,
                            noticeNames: noticeName,
                            bbsConfigFk: bbsConfigFk
                        )
                    }
                }
            }
            .onAppear {
                Task {
                    await fetchAllNotices()
                }
            }
            .navigationDestination(isPresented: $openNoticePage) {
                NoticeContentView(pkId: notificationPkId)
            }
        }
        .onChange(of: sectionOrder) { newValue, _ in
            saveSettings()
        }
        .onChange(of: noticeCounts) { newValue, _ in
            saveSettings()
        }
        .onChange(of: hiddenNotices) { newValue, _ in
            saveSettings()
        }
        .onChange(of: showEditSectionsView) { newValue, _ in
            if newValue {
                Task {
                    await fetchAllNotices()
                }
            }
        }
        .onNotification { response in
            let userInfo = response.notification.request.content.userInfo
            if let urlString = userInfo["url"] as? String,
               let url = URL(string: urlString) {
                handleURL(url)
            }
        }
    }
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "sgnoti" else { return }
        guard url.host == "notices" else { return }
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let pkIdQueryItem = components.queryItems?.first(where: { $0.name == "pkId" }),
           let pkIdString = pkIdQueryItem.value,
           let pkIdInt = Int(pkIdString) {
            notificationPkId = pkIdInt
            openNoticePage = true
        }
    }
    
    func getNotices(for section: Int) -> [NoticeData] {
        switch section {
        case 2:
            return academicNotices
        case 1:
            return generalNotices
        case 3:
            return scholarshipNotices
        case 141:
            return onestopNotices
        case 142:
            return eventNotices
        default:
            return []
        }
    }
    
    func fetchAllNotices() async {
        await withTaskGroup(of: Void.self) { group in
            for (index, bbsConfig) in bbsConfigFk.enumerated() {
                if !hiddenNotices.contains(bbsConfig) {
                    let url = "https://www.sogang.ac.kr/api/api/v1/mainKo/BbsData/boardList?pageNum=1&pageSize=\(noticeCounts[index])&bbsConfigFk=\(bbsConfig)"
                    group.addTask {
                        await fetchNotices(url: url) { notices in
                            DispatchQueue.main.async {
                                switch bbsConfig {
                                case 2:
                                    self.academicNotices = notices
                                case 1:
                                    self.generalNotices = notices
                                case 3:
                                    self.scholarshipNotices = notices
                                case 141:
                                    self.onestopNotices = notices
                                case 142:
                                    self.eventNotices = notices
                                default:
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    func fetchNotices(url: String, completion: @escaping ([NoticeData]) -> Void) async {
        guard let apiResponse = await fetchAPIResponse(url: url) else {
            completion([])
            return
        }
        if apiResponse.statusCode == 200 {
            completion(apiResponse.data.list)
        } else {
            completion([])
        }
    }
    
    func fetchAPIResponse(url: String) async -> APIResponse? {
        return await withCheckedContinuation { continuation in
            AF.request(url, method: .get).responseDecodable(of: APIResponse.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    continuation.resume(returning: apiResponse)
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func saveSettings() {
        if let encodedOrder = try? JSONEncoder().encode(sectionOrder) {
            sectionOrderData = String(data: encodedOrder, encoding: .utf8) ?? ""
        }
        if let encodedCounts = try? JSONEncoder().encode(noticeCounts) {
            noticeCountsData = String(data: encodedCounts, encoding: .utf8) ?? "[4, 4, 4, 4, 4]"
        }
        if let encodedHidden = try? JSONEncoder().encode(hiddenNotices) {
            hiddenNoticesData = String(data: encodedHidden, encoding: .utf8) ?? "[]"
        }
    }
}

struct NoticeRow: View {
    let notice: NoticeData
    
    var body: some View {
        NavigationLink(destination: NoticeContentView(pkId: notice.pkId)) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ForEach(notice.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.footnote)
                            .foregroundStyle(Color("sogang_red"))
                    }
                }
                Text(notice.title ?? "No Title")
                    .lineLimit(1)
                    .font(.headline)
                HStack {
                    Text(notice.regDate ?? "No Date")
                        .font(.subheadline)
                    Text("｜")
                        .font(.subheadline)
                    Text(notice.userName ?? "No Username")
                        .font(.subheadline)
                }
            }
        }
    }
}

struct EditSectionsView: View {
    @Binding var sectionOrder: [Int]
    @Binding var noticeCounts: [Int]
    @Binding var hiddenNotices: Set<Int>
    let noticeNames: [String]
    let bbsConfigFk: [Int]
    @Environment(\.dismiss) var dismiss
    @State private var editMode: EditMode = .active
    
    var body: some View {
        NavigationStack {
            List {
                // 순서 변경 섹션
                Section(header: Text("순서 변경")) {
                    ForEach(sectionOrder, id: \.self) { section in
                        if !hiddenNotices.contains(section) {
                            HStack {
                                Text(noticeNames[bbsConfigFk.firstIndex(of: section)!])
                                Spacer()
                                Button(action: {
                                    hiddenNotices.insert(section)
                                }) {
                                    Text("숨김")
                                }.padding(.trailing, 20)
                            }
                        }
                    }
                    .onMove(perform: moveSection)
                }
                
                // 글 개수 설정 섹션
                Section(header: Text("글 개수 설정")) {
                    ForEach(sectionOrder, id: \.self) { section in
                        if !hiddenNotices.contains(section) {
                            LabeledStepper(
                                noticeNames[bbsConfigFk.firstIndex(of: section)!],
                                value: $noticeCounts[bbsConfigFk.firstIndex(of: section)!],
                                in: 1...5
                            )
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // 숨긴 공지 표시 섹션
                Section(header: Text("숨긴 공지")) {
                    ForEach(bbsConfigFk, id: \.self) { section in
                        if hiddenNotices.contains(section) {
                            HStack {
                                Text(noticeNames[bbsConfigFk.firstIndex(of: section)!])
                                Spacer()
                                Button(action: {
                                    hiddenNotices.remove(section)
                                }) {
                                    Text("표시")
                                }
                            }
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("둘러보기 설정")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("닫기") {
                dismiss()
            })
        }
    }
    
    func moveSection(from source: IndexSet, to destination: Int) {
        sectionOrder.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    Home()
}
