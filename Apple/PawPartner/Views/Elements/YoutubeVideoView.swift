//
//  YoutubeVideoView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 12/5/23.
//

import SwiftUI
import WebKit

struct YoutubeVideoView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let youtubeURL = URL(string: "https://www.youtube.com/embed/\(videoID)") else { return }
        uiView.scrollView.isScrollEnabled = false
        uiView.load(URLRequest(url: youtubeURL))
    }
}

//#Preview {
//    YoutubeVideoView()
//}
