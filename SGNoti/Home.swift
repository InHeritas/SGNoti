//
//  Home.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/7/24.
//

import Alamofire
import SwiftUI
import TipKit
import UserNotifications

struct Home: View {
    @AppStorage("sectionOrderData") private var sectionOrder: [Int] = [2, 1, 141, 3, 142]
    @AppStorage("noticeCountsData") private var noticeCounts: [Int] = [4, 4, 4, 4, 4]
    @AppStorage("hiddenNoticesData") private var hiddenNotices: [Int] = []

    @State private var academicNotices: [NoticeData] = []
    @State private var generalNotices: [NoticeData] = []
    @State private var scholarshipNotices: [NoticeData] = []
    @State private var onestopNotices: [NoticeData] = []
    @State private var eventNotices: [NoticeData] = []
    @State private var isLoading: Bool = true
    @State private var showSafariView: Bool = false
    @State private var showEditSectionsView: Bool = false
    @State private var openNoticePage: Bool = false
    @State private var openSettingPage: Bool = false
    @State private var notificationPkId: Int = 0

    @State private var noticeName: [String] = ["학사공지", "일반공지", "장학공지", "종합봉사실", "행사특강"]
    @State private var bbsConfigFk: [Int] = [2, 1, 141, 3, 142]

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    TipView(NotificationTip()) { action in
                        if action.id == "goToSetting" {
                            UIApplication.shared.open(URL(string: "sgnoti://view?setting=notification")!)
                            NotificationTip().invalidate(reason: .actionPerformed)
                        }
                    }
                    .tipImageSize(CGSize(width: 30, height: 30))
                    .padding()
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
                                            Text("더보기")
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
                    }, label: {
                        Text("웹페이지")
                    })
                    .fullScreenCover(isPresented: $showSafariView, content: {
                        SFSafariView(isPresented: self.$showSafariView, url: URL(string: "https://www.sogang.ac.kr")!)
                            .ignoresSafeArea()
                    })
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        self.showEditSectionsView = true
                    }, label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    })
                    .sheet(isPresented: $showEditSectionsView, content: {
                        EditSectionsView(
                            sectionOrder: $sectionOrder,
                            noticeCounts: $noticeCounts,
                            hiddenNotices: $hiddenNotices,
                            noticeNames: noticeName,
                            bbsConfigFk: bbsConfigFk
                        )
                    })
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
            .navigationDestination(isPresented: $openSettingPage) {
                Notification()
            }
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
        .onOpenURL { inputURL in
            guard inputURL.scheme == "sgnoti" else { return }
            guard inputURL.host == "view" else { return }

            if let components = URLComponents(url: inputURL, resolvingAgainstBaseURL: false),
               let settingQueryItem = components.queryItems?.first(where: { $0.name == "setting" }),
               let settingString = settingQueryItem.value {
                if settingString == "notification" {
                    openSettingPage = true
                }
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
            for (index, bbsConfig) in bbsConfigFk.enumerated() where !hiddenNotices.contains(bbsConfig) {
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
                case let .success(apiResponse):
                    continuation.resume(returning: apiResponse)
                case let .failure(error):
                    print("Error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

struct NoticeRow: View {
    let notice: NoticeData

    var body: some View {
        NavigationLink(destination: NoticeContentView(pkId: notice.pkId)) {
            VStack(alignment: .leading, spacing: 6) {
                if !notice.tags.isEmpty {
                    HStack {
                        ForEach(notice.tags, id: \.self) { tag in
                            Text(tag.trimmingCharacters(in: CharacterSet(charactersIn: "[]")))
                                .font(.footnote)
                                .foregroundStyle(Color("grey900"))
                                .hpadding(5).vpadding(2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .foregroundStyle(Color(.systemGray6))
                                )
                        }
                    }
                    .padding(.bottom, 2)
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
    @Binding var hiddenNotices: [Int]
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
                                    hiddenNotices.append(section)
                                }, label: {
                                    Text("숨김")
                                })
                                .padding(.trailing, 20)
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
                                in: 1 ... 5
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
                                    if let index = hiddenNotices.firstIndex(of: section) {
                                        hiddenNotices.remove(at: index)
                                    }
                                }, label: {
                                    Text("표시")
                                })
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
