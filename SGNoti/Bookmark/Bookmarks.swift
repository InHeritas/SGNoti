//
//  Bookmarks.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/7/24.
//

import SwiftUI
import SwiftData

struct Bookmark: View {
    @Query private var bookmarks: [Bookmark_NoticeDetail]
    @State private var isEditing: Bool = false
    @State private var showDeleteAllAlert: Bool = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            List {
                ForEach(bookmarks) { notice in
                    NavigationLink(destination: ContentView(tags: notice.tags, pkId: notice.pkId)) {
                        VStack(alignment: .leading, spacing: 6) {
                            if !(notice.tags[0] == "library_notice") {
                                HStack {
                                    ForEach(notice.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.footnote)
                                            .foregroundStyle(Color("sogang_red"))
                                    }
                                }
                            }
                            Text(notice.title)
                                .lineLimit(1)
                                .font(.headline)
                            HStack {
                                Text(notice.regDate)
                                    .font(.subheadline)
                                Text("｜")
                                    .font(.subheadline)
                                Text(notice.userName)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("북마크")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    isEditing ? Button("전체 삭제", action: { showDeleteAllAlert = true }) : nil
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "완료" : "편집") {
                        isEditing.toggle()
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
            .alert(isPresented: $showDeleteAllAlert) {
                Alert(
                    title: Text("전체 삭제"),
                    message: Text("정말로 모든 북마크를 삭제하시겠습니까?"),
                    primaryButton: .destructive(Text("삭제"), action: deleteAll),
                    secondaryButton: .cancel(Text("취소"))
                )
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let bookmark = bookmarks[index]
            modelContext.delete(bookmark)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete bookmark: \(error.localizedDescription)")
        }
    }
    
    private func deleteAll() {
        for bookmark in bookmarks {
            modelContext.delete(bookmark)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete all bookmarks: \(error.localizedDescription)")
        }
    }
}

#Preview {
    Bookmark()
}
