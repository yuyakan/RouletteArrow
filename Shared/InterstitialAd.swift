//
//  InterstitialAd.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/10/16.
//

import GoogleMobileAds

class Interstitial: NSObject, GADFullScreenContentDelegate {
    var interstitialAd: GADInterstitialAd?

    override init() {
        super.init()
    }

    // 広告の読み込み
    func loadInterstitial() {
        GADInterstitialAd.load(withAdUnitID: "ca-app-pub-3940256099942544/4411468910", request: GADRequest()) { (ad, error) in
            if let _ = error {
                print("読み込みに失敗しました")
                return
            }
            print("読み込みに成功しました")
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    // インタースティシャル広告の表示
    func presentInterstitial() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let root = windowScenes?.keyWindow?.rootViewController
        if let ad = interstitialAd {
            ad.present(fromRootViewController: root!)
        } else {
            print("広告の準備ができていませんでした")
            self.loadInterstitial()
        }
    }
    // 失敗通知
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.loadInterstitial()
    }

    // 表示通知
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("インタースティシャル広告を表示しました")
    }

    // クローズ通知
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("インタースティシャル広告を閉じました")
    }
}
