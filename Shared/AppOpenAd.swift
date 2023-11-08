//
//  AppOpenAd.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/11/07.
//

import GoogleMobileAds

class AppOpen: NSObject, GADFullScreenContentDelegate, ObservableObject {

    @Published var appOpenAdLoaded: Bool = false
    var appOpenAd: GADAppOpenAd?

    override init() {
        super.init()
        loadAppOpenAd()
    }

    func loadAppOpenAd() {
        let request = GADRequest()
        GADAppOpenAd.load(
            withAdUnitID: "ca-app-pub-3940256099942544/5662855259",//テスト
            request: request,
            orientation: UIInterfaceOrientation.portrait
        ) { appOpenAdIn, _ in
            self.appOpenAd = appOpenAdIn
            self.appOpenAd?.fullScreenContentDelegate = self
            self.appOpenAdLoaded = true
        }
    }

    func presentAppOpenAd() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        guard let root = self.appOpenAd else { return }
        root.present(fromRootViewController: (windowScenes?.keyWindow?.rootViewController)!)
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.loadAppOpenAd()
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        self.loadAppOpenAd()
    }
}
