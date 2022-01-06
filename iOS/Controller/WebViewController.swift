//
//  WebViewController.swift
//  Kiwix
//
//  Created by Chris Li on 12/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import Defaults

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController = {
            let controller = WKUserContentController()
            guard FeatureFlags.wikipediaDarkUserCSS,
                  let path = Bundle.main.path(forResource: "wikipedia_dark", ofType: "css"),
                  let css = try? String(contentsOfFile: path) else { return controller }
            let source = """
                var style = document.createElement('style');
                style.innerHTML = `\(css)`;
                document.head.appendChild(style);
                """
            let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            controller.addUserScript(script)
            return controller
        }()
        return WKWebView(frame: .zero, configuration: config)
    }()
    private var textSizeAdjustFactorObserver: DefaultsObservation?
    private var rootViewController: RootViewController? {
        splitViewController?.parent as? RootViewController
    }
    
    var activityIndicator = UIActivityIndicatorView(style: .large)
    
    init() {
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }
    
    convenience init(url: URL) {
        self.init()
        webView.load(URLRequest(url: url))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14.0, *) {
            navigationController?.isNavigationBarHidden = true
        }
        setActivityIndicator()
        
        // observe webView font size adjust factor
        textSizeAdjustFactorObserver = Defaults.observe(keys: .webViewTextSizeAdjustFactor) { self.adjustTextSize() }
        
        NotificationCenter.default.addObserver(self, selector: #selector(hideIndicator), name: NSNotification.Name("Hide_Loader_OnWeb"), object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }
    
    func setActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        if isInitialWeb {
            activityIndicator.startAnimating()
        }
    }
    
    func showInternetConnectionAlert() {
        let alert = UIAlertController(title: "", message: "Offline mode only available in Pro version. Please connect to the internet.", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default) { okAct in
            print("Ok")
        }
        alert.addAction(alertAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func adjustTextSize() {
        let scale = Defaults[.webViewTextSizeAdjustFactor]
        let javascript = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", scale * 100)
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    @objc func hideIndicator() {
        activityIndicator.stopAnimating()
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel, preferences); return }
        if !Reachability.isConnectedToNetwork() {
            showInternetConnectionAlert()
            decisionHandler(.cancel, preferences)
            return
        }
        if url.isKiwixURL {
            if let redirectedURL = ZimFileService.shared.getRedirectedURL(url: url) {
                decisionHandler(.cancel, preferences)
                webView.load(URLRequest(url: redirectedURL))
            } else {
                preferences.preferredContentMode = .mobile
                decisionHandler(.allow, preferences)
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            let policy = Defaults[.externalLinkLoadingPolicy]
            if policy == .alwaysLoad {
                rootViewController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
            } else {
                rootViewController?.present(UIAlertController.externalLink(policy: policy, action: {
                    self.present(SFSafariViewController(url: url), animated: true, completion: nil)
                }), animated: true)
            }
            decisionHandler(.cancel, preferences)
        } else if url.scheme == "geo" {
            decisionHandler(.cancel, preferences)
        } else {
            decisionHandler(.cancel, preferences)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        adjustTextSize()
        webView.evaluateJavaScript(
            "document.querySelectorAll(\"details\").forEach((detail) => {detail.setAttribute(\"open\", true)});",
            completionHandler: nil
        )
    }
    
    // MARK: - WKUIDelegate
    
    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        guard let url = elementInfo.linkURL else { completionHandler(nil); return }
        if url.isKiwixURL {
            let config = UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: { WebViewController(url: url) },
                actionProvider: { elements -> UIMenu? in
                    UIMenu(children: elements)
                }
            )
            completionHandler(config)
        } else {
            completionHandler(nil)
        }
    }
}
