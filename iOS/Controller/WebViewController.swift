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
import GoogleMobileAds
import SwiftUI

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
    
    var bannerView: GAMBannerView!
    var interstitial: GAMInterstitialAd?
    let lblName = UILabel()
    
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
        
        setBannerAd()
        
        // observe webView font size adjust factor
        textSizeAdjustFactorObserver = Defaults.observe(keys: .webViewTextSizeAdjustFactor) { self.adjustTextSize() }
        
        NotificationCenter.default.addObserver(self, selector: #selector(hideIndicator), name: NSNotification.Name("Hide_Loader_OnWeb"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideAdOnPurchase), name: NSNotification.Name("Hide_Banner_Purchase"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setInterstitialAd()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }
    
    @objc func hideAdOnPurchase() {
        bannerView.isHidden = true
        lblName.isHidden = true
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
    
    func setBannerAd() {
        lblName.isHidden = true
        let height = CGFloat(50)

        lblName.text = ""
        lblName.backgroundColor = .white
        lblName.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(lblName)

        NSLayoutConstraint.activate([
            lblName.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            lblName.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            lblName.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,constant: -height),
            lblName.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        let request = GAMRequest()
        let extras = GADExtras()
        extras.additionalParameters = ["suppress_test_label": "1"]
        request.register(extras)
        
        // In this case, we instantiate the banner with desired ad size.
        let adSize = GADAdSizeFromCGSize(CGSize(width: 320, height: 50))
        bannerView = GAMBannerView(adSize: adSize)
        
        if UserDefaults.standard.bool(forKey: "Is_Purchased") {
            bannerView.isHidden = true
        } else {
            bannerView.isHidden = false
        }
        bannerView.adUnitID = "/154013155,7264022/1016210/72846/1016210-72846-mobile_leaderboard"
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(request)
        
        addBannerViewToView(bannerView)
    }
    
    func setInterstitialAd() {
        let request = GAMRequest()
        let extras = GADExtras()
        extras.additionalParameters = ["suppress_test_label": "1"]
        request.register(extras)
        
        GAMInterstitialAd.load(withAdManagerAdUnitID: "/154013155,7264022/1016210/72846/1016210-72846-in_game_item", request: request) { [self] ad, error in
            if let error = error {
              print("Failed to load interstitial ad with error: \(error.localizedDescription)")
              return
            }
            interstitial = ad
            interstitial?.fullScreenContentDelegate = self
        }
    }
    
    func addBannerViewToView(_ bannerView: GAMBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
          [NSLayoutConstraint(item: bannerView,
                              attribute: .bottom,
                              relatedBy: .equal,
                              toItem: view.safeAreaLayoutGuide,
                              attribute: .bottom,
                              multiplier: 1,
                              constant: 0),
           NSLayoutConstraint(item: bannerView,
                              attribute: .centerX,
                              relatedBy: .equal,
                              toItem: view,
                              attribute: .centerX,
                              multiplier: 1,
                              constant: 0)
        ])
    }
    
    func presentInterstitialAdOnArticle() {
        if interstitial != nil {
            interstitial?.present(fromRootViewController: self)
        } else {
            print("Ad wasn't ready")
            setInterstitialAd()
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
        let isPurchased = UserDefaults.standard.bool(forKey: "Is_Purchased")
        if !Reachability.isConnectedToNetwork() && !isPurchased {
            showInternetConnectionAlert()
            decisionHandler(.cancel, preferences)
            return
        }
        if url.isKiwixURL {
            var viewedArticleCount = UserDefaults.standard.integer(forKey: "NumberOf_Article_viewed")
                        
            if let redirectedURL = ZimFileService.shared.getRedirectedURL(url: url) {
                decisionHandler(.cancel, preferences)
                webView.load(URLRequest(url: redirectedURL))
            } else {
                preferences.preferredContentMode = .mobile
                decisionHandler(.allow, preferences)
            }
            if viewedArticleCount == 7 {
                viewedArticleCount = 0
                if !UserDefaults.standard.bool(forKey: "Is_Purchased") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.presentInterstitialAdOnArticle()
                    }
                }
            } else {
                viewedArticleCount += 1
            }
            UserDefaults.standard.set(viewedArticleCount, forKey: "NumberOf_Article_viewed")
            UserDefaults.standard.synchronize()
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

//MARK:- Interstitial ad delegates.
extension WebViewController: GADFullScreenContentDelegate {
      func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
          print("Ad did fail to present full screen content.")
      }

      func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
          print("Ad did present full screen content.")
      }

      func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
          if UserDefaults.standard.bool(forKey: "Is_Active_Session") == false {
              UserDefaults.standard.set(true, forKey: "Is_Active_Session")
              UserDefaults.standard.synchronize()
              let removeAdsPopup = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RemoveAdsVC") as! RemoveAdsVC
              removeAdsPopup.modalPresentationStyle = .fullScreen
              self.present(removeAdsPopup, animated: true, completion: nil)
          }
      }
}

//MARK:- Banner ad delegates.
extension WebViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.lblName.isHidden = false
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("bannerViewDidRecordImpression")
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillPresentScreen")
    }

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillDIsmissScreen")
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        self.lblName.isHidden = true
    }
}
