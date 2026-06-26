import SwiftUI

struct TOSView: View {
    let onAccept: () -> Void

    @State private var scrolledToBottom = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KometSpacing.lg) {
                    Text(String(localized: "Terms of Service"))
                        .font(.kometLarge)

                    // Embedded WebView of the TOS
                    TOSWebView(url: URL(string: AppConstants.legalUrl)!)
                        .frame(height: UIScreen.main.bounds.height * 0.6)
                        .clipShape(RoundedRectangle(cornerRadius: KometSpacing.cornerRadius, style: .continuous))

                    GeometryReader { geo in
                        Color.clear.onAppear {
                            scrolledToBottom = geo.frame(in: .global).maxY <= UIScreen.main.bounds.height
                        }
                    }
                    .frame(height: 1)
                }
                .padding(KometSpacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Decline")) { dismiss() }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Accept"), action: onAccept)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

import WebKit

struct TOSWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
