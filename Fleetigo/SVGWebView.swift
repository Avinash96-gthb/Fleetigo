//
//  SVGWebView.swift
//  Fleetigo
//
//  Created by Avinash on 23/04/25.
//


import SwiftUI
import WebKit

struct SVGWebView: UIViewRepresentable {
  let svgString: String

  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    let html = """
    <html>
      <head><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
      <body style="margin:0; padding:0; display:flex; justify-content:center; align-items:center; height:100vh;">
        \(svgString)
      </body>
    </html>
    """
    uiView.loadHTMLString(html, baseURL: nil)
  }
}
