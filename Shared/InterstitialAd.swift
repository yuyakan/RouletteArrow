//
//  InterstitialAd.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/10/16.
//

import GoogleMobileAds

class Interstitial: NSObject, FullScreenContentDelegate {
    var interstitialAd: InterstitialAd?
    private var retryCount = 0
    private let maxRetryCount = 5

    override init() {
        super.init()
    }

    // 広告の読み込み
    func loadInterstitial() {
        InterstitialAd.load(with: "ca-app-pub-3940256099942544/4411468910", request: Request()) { (ad, error) in
            if let error = error {
                print("読み込みに失敗しました: \(error.localizedDescription)")
                self.retryLoadInterstitial()
                return
            }
            print("読み込みに成功しました")
            self.retryCount = 0
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    // 読み込み失敗時の指数バックオフによるリトライ（最大 maxRetryCount 回）
    private func retryLoadInterstitial() {
        guard retryCount < maxRetryCount else {
            print("インタースティシャル広告の読み込みを \(maxRetryCount) 回試みましたが失敗しました")
            return
        }
        retryCount += 1
        let delay = pow(2.0, Double(retryCount - 1))
        print("インタースティシャル広告を \(delay) 秒後に再読み込みします（\(retryCount)/\(maxRetryCount)）")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.loadInterstitial()
        }
    }

    // インタースティシャル広告の表示
    func presentInterstitial() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let root = windowScenes?.keyWindow?.rootViewController
        if let ad = interstitialAd {
            ad.present(from: root!)
        } else {
            print("広告の準備ができていませんでした")
            self.loadInterstitial()
        }
    }
    // 失敗通知
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.loadInterstitial()
    }

    // 表示通知
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("インタースティシャル広告を表示しました")
    }

    // クローズ通知
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("インタースティシャル広告を閉じました")
    }
}
