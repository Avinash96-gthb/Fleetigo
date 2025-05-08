//
//  WebViewRepresentable.swift
//  Fleetigo
//
//  Created by Avinash on 22/04/25.
//

import SwiftUI
import WebKit      // ← fixes 'Cannot find WebViewRepresentable' :contentReference[oaicite:8]{index=8}

struct WebViewRepresentable: UIViewRepresentable {
    let htmlContent: String
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        loadContent(webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadContent(uiView)
    }

    private func loadContent(_ webView: WKWebView) {
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        init(isLoading: Binding<Bool>) { _isLoading = isLoading }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }
    }
}
