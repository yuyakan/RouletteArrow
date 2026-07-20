//
//  InterstitialAd.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/10/16.
//

import GoogleMobileAds

class Interstitial: NSObject, FullScreenContentDelegate {
    /// 使用する広告ユニットID。
    /// DEBUG ビルド（Xcode 実行）では Google 公式のテスト用 ID を使い、
    /// Release ビルド（App Store 配布）では本番 ID を使う。
    /// 手動でテスト広告に固定したいときは、下の #if DEBUG を無視して
    /// テスト用 ID をそのまま返すよう一時的に書き換えればよい。
    private static let productionAdUnitID = "ca-app-pub-3155724310732667/6815701656"
    /// Google 公式のインタースティシャル用テスト ID（誤クリックでもアカウント影響なし）
    private static let testAdUnitID = "ca-app-pub-3940256099942544/4411468910"

    private static var adUnitID: String {
        #if DEBUG
        return testAdUnitID
        #else
        return productionAdUnitID
        #endif
    }

    var interstitialAd: InterstitialAd?
    private var retryCount = 0
    private let maxRetryCount = 5
    /// 読み込み処理が進行中かどうか（多重ロード防止）
    private var isLoading = false

    override init() {
        super.init()
    }

    // 広告の読み込み
    func loadInterstitial() {
        // すでに広告を保持している、または読み込み中なら何もしない（多重リクエスト防止）
        guard interstitialAd == nil, !isLoading else { return }
        isLoading = true
        InterstitialAd.load(with: Self.adUnitID, request: Request()) { (ad, error) in
            self.isLoading = false
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
        if let ad = interstitialAd, let root = root {
            ad.present(from: root)
        } else {
            // 準備ができていないときは今回は表示せず、次回に備えて読み込むだけ。
            // （多重ロードは loadInterstitial 側のガードで防ぐ）
            print("広告の準備ができていませんでした")
            self.loadInterstitial()
        }
    }
    // 失敗通知：使い捨てのため破棄して次回分を読み込む
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.interstitialAd = nil
        self.loadInterstitial()
    }

    // 表示通知
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("インタースティシャル広告を表示しました")
    }

    // クローズ通知：使い捨てのため破棄して次回分を読み込む
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("インタースティシャル広告を閉じました")
        self.interstitialAd = nil
        self.loadInterstitial()
    }
}
