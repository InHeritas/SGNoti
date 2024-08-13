//
//  OSSView.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/10/24.
//

import SwiftUI

struct OSSView: View {
    @State private var isExpanded_Alamofire = false
    @State private var isExpanded_SwiftSoup = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Alamofire")
                    Spacer()
                    Text("5.9.1")
                }
                DisclosureGroup(isExpanded: $isExpanded_Alamofire) {
                    Text("""
                    Copyright (c) 2014-2022 Alamofire Software Foundation (http://alamofire.org/)
                    
                    Permission is hereby granted, free of charge, to any person obtaining a copy
                    of this software and associated documentation files (the "Software"), to deal
                    in the Software without restriction, including without limitation the rights
                    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                    copies of the Software, and to permit persons to whom the Software is
                    furnished to do so, subject to the following conditions:
                    
                    The above copyright notice and this permission notice shall be included in
                    all copies or substantial portions of the Software.
                    
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
                    THE SOFTWARE.
                    """)
                    .monospaced()
                    .font(.footnote)
                } label: {
                    Text("MIT License")
                }
            }
            Section {
                HStack {
                    Text("SwiftSoup")
                    Spacer()
                    Text("2.7.3")
                }
                DisclosureGroup(isExpanded: $isExpanded_SwiftSoup) {
                    Text("""
                    Copyright (c) 2016 Nabil Chatbi
                    
                    Permission is hereby granted, free of charge, to any person obtaining a copy
                    of this software and associated documentation files (the "Software"), to deal
                    in the Software without restriction, including without limitation the rights
                    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                    copies of the Software, and to permit persons to whom the Software is
                    furnished to do so, subject to the following conditions:
                    
                    The above copyright notice and this permission notice shall be included in all
                    copies or substantial portions of the Software.
                    
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                    SOFTWARE.
                    """)
                    .monospaced()
                    .font(.footnote)
                } label: {
                    Text("MIT License")
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("오픈소스 라이선스")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    OSSView()
}
