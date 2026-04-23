//
//  WebRepresentableView.swift
//  Profile
//
//  Created by Wonji Suh  on 1/4/26.
//

import SwiftUI
import WebKit

import DesignSystem


public struct WebRepresentableView: UIViewRepresentable {

  // MARK: - URL to load
  private var urlToLoad: String

  public init(urlToLoad: String) {
    self.urlToLoad = urlToLoad
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  public func makeUIView(context: Context) -> UIView {
    // 컨테이너
    let containerView = UIView()
    containerView.backgroundColor = UIColor(red: 26/255.0, green: 26/255.0, blue: 26/255.0, alpha: 1.0)

    // WKWebView
    let configuration = WKWebViewConfiguration()
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.scrollView.showsVerticalScrollIndicator = false
    webView.scrollView.minimumZoomScale = 1.0
    webView.scrollView.maximumZoomScale = 1.0
    webView.navigationDelegate = context.coordinator
    webView.uiDelegate = context.coordinator
    webView.allowsLinkPreview = true
    webView.backgroundColor = UIColor(red: 26/255.0, green: 26/255.0, blue: 26/255.0, alpha: 1.0)
    webView.translatesAutoresizingMaskIntoConstraints = false

    // AnimatedImage로 로딩 GIF 표시
    let loadingContainer = createAnimatedImageLoader()
    loadingContainer.translatesAutoresizingMaskIntoConstraints = false

    containerView.addSubview(webView)
    containerView.addSubview(loadingContainer)

    NSLayoutConstraint.activate([
      // WebView는 전체
      webView.topAnchor.constraint(equalTo: containerView.topAnchor),
      webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

      // 로딩 컨테이너는 중앙
      loadingContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      loadingContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
      loadingContainer.widthAnchor.constraint(equalToConstant: 200),
      loadingContainer.heightAnchor.constraint(equalToConstant: 200),
    ])

    // 코디네이터가 참조 보관
    context.coordinator.webView = webView
    context.coordinator.loadingIndicator = loadingContainer

    // 로드 직전에 로딩 컨테이너 표시
    loadingContainer.alpha = 1

    // 로드
    _Concurrency.Task {
      await loadURLInWebView(urlToLoad: urlToLoad, webView: webView)
    }

    return containerView
  }

  func loadURLInWebView(urlToLoad: String, webView: WKWebView) async {
    guard let url = URL(string: urlToLoad) else {
      return
    }
    let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)

    await MainActor.run {
      webView.configuration.upgradeKnownHostsToHTTPS = true
      webView.configuration.preferences.minimumFontSize = 16
      webView.load(request)
    }
  }

  public func updateUIView(_ uiView: UIView, context: Context) {
    // 필요 시 업데이트
  }

  // MARK: - Loading Indicator Helper
  //
  // 이전에는 UIHostingController(rootView: ProgressView())를 로컬 변수로 만들어
  // subview만 추가했는데, 컨트롤러가 즉시 dealloc되면서 `.view`(내부 _UIHostingView)가
  // zombie가 되어 trait 전파 중 `objc_msgSend` 크래시(EXC_BAD_ACCESS)가 발생했다.
  // UIKit 네이티브 UIActivityIndicatorView를 사용해 호스팅 컨트롤러 수명 관리 이슈를 제거한다.
  private func createAnimatedImageLoader() -> UIView {
    let containerView = UIView()
    containerView.backgroundColor = .clear

    let indicator = UIActivityIndicatorView(style: .large)
    indicator.color = .white
    indicator.hidesWhenStopped = false
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.startAnimating()

    containerView.addSubview(indicator)

    NSLayoutConstraint.activate([
      indicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      indicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])

    return containerView
  }

  // MARK: - Coordinator
  public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: WebRepresentableView
    weak var webView: WKWebView?
    weak var loadingIndicator: UIView?

    init(_ parent: WebRepresentableView) {
      self.parent = parent
    }

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
      // 로딩 시작 → AnimatedImage 표시
      DispatchQueue.main.async { [weak self] in
        guard let self = self, let loadingIndicator = self.loadingIndicator else { return }
        loadingIndicator.alpha = 1
      }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      // 로딩 완료 → AnimatedImage 숨김(페이드아웃)
      hideLoadingIndicator()
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      hideLoadingIndicator()
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
      hideLoadingIndicator()
    }

    private func hideLoadingIndicator() {
      DispatchQueue.main.async { [weak self] in
        guard let self = self, let loadingIndicator = self.loadingIndicator else { return }

        // 로딩을 2초 더 표시한 후 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
          UIView.animate(withDuration: 0.5, animations: {
            loadingIndicator.alpha = 0
          })
        }
      }
    }
  }
}
