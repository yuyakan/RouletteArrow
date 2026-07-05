//
//  AppOpenAd.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/11/07.
//

import GoogleMobileAds

class AppOpen: NSObject, FullScreenContentDelegate, ObservableObject {

    @Published var appOpenAdLoaded: Bool = false
    var appOpenAd: AppOpenAd?
    private var retryCount = 0
    private let maxRetryCount = 5

    override init() {
        super.init()
        loadAppOpenAd()
    }

    func loadAppOpenAd() {
        let request = Request()
        AppOpenAd.load(
            with: "ca-app-pub-3940256099942544/5662855259",//テスト
            request: request
        ) { appOpenAdIn, error in
            if let error = error {
                print("アプリ起動広告の読み込みに失敗しました: \(error.localizedDescription)")
                self.retryLoadAppOpenAd()
                return
            }
            self.retryCount = 0
            self.appOpenAd = appOpenAdIn
            self.appOpenAd?.fullScreenContentDelegate = self
            self.appOpenAdLoaded = true
        }
    }

    // 読み込み失敗時の指数バックオフによるリトライ（最大 maxRetryCount 回）
    private func retryLoadAppOpenAd() {
        guard retryCount < maxRetryCount else {
            print("アプリ起動広告の読み込みを \(maxRetryCount) 回試みましたが失敗しました")
            return
        }
        retryCount += 1
        let delay = pow(2.0, Double(retryCount - 1))
        print("アプリ起動広告を \(delay) 秒後に再読み込みします（\(retryCount)/\(maxRetryCount)）")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.loadAppOpenAd()
        }
    }

    func presentAppOpenAd() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        guard let root = self.appOpenAd else { return }
        root.present(from: (windowScenes?.keyWindow?.rootViewController)!)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.loadAppOpenAd()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        self.loadAppOpenAd()
    }
}
