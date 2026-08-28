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

    private enum LoadSource: String {
        case initial
        case retry
        case presentFallback
        case didFailToPresent
        case didDismiss
    }

    var interstitialAd: InterstitialAd?
    private var retryCount = 0
    private let maxRetryCount = 5
    /// 読み込み処理が進行中かどうか（多重ロード防止）
    private var isLoading = false
    /// ログで追跡しやすいよう、ロード試行回数を通しで数える。
    private var loadSequence = 0
    private var noFillCount = 0
    private var retryableFailureCount = 0
    private var nonRetryableFailureCount = 0

    override init() {
        super.init()
        log("initialized with adUnitID=\(Self.adUnitID) build=\(Self.buildFlavor)")
    }

    // 広告の読み込み
    func loadInterstitial() {
        loadInterstitial(source: .initial)
    }

    private func loadInterstitial(source: LoadSource) {
        // すでに広告を保持している、または読み込み中なら何もしない（多重リクエスト防止）
        guard interstitialAd == nil, !isLoading else {
            log("skip load source=\(source.rawValue) hasAd=\(interstitialAd != nil) isLoading=\(isLoading)")
            return
        }
        loadSequence += 1
        isLoading = true
        log("start load #\(loadSequence) source=\(source.rawValue) adUnitID=\(Self.adUnitID)")
        InterstitialAd.load(with: Self.adUnitID, request: Request()) { (ad, error) in
            self.isLoading = false
            if let error = error {
                let nsError = error as NSError
                let classification = self.classifyFailure(nsError)
                switch classification {
                case .noFill:
                    self.noFillCount += 1
                case .retryable:
                    self.retryableFailureCount += 1
                case .nonRetryable:
                    self.nonRetryableFailureCount += 1
                }
                self.log("load failed #\(self.loadSequence) source=\(source.rawValue) class=\(classification.rawValue) noFill=\(self.noFillCount) retryable=\(self.retryableFailureCount) nonRetryable=\(self.nonRetryableFailureCount) message=\(error.localizedDescription) domain=\(nsError.domain) code=\(nsError.code)")
                if self.shouldRetryLoad(after: nsError) {
                    self.retryLoadInterstitial()
                } else {
                    // no fill など、再試行しても改善しにくい失敗は待機状態に戻す。
                    self.retryCount = 0
                }
                return
            }
            self.log("load succeeded #\(self.loadSequence) source=\(source.rawValue)")
            self.retryCount = 0
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    private func shouldRetryLoad(after error: NSError) -> Bool {
        guard error.domain == GADErrorDomain else { return true }
        return true
    }

    private enum FailureClass: String {
        case noFill
        case retryable
        case nonRetryable
    }

    private func classifyFailure(_ error: NSError) -> FailureClass {
        guard error.domain == GADErrorDomain else {
            return .retryable
        }

        switch error.code {
        case 1:
            return .noFill
        case 0, 4, 19, 20, 21:
            return .nonRetryable
        case 2, 3, 5, 7, 10, 11, 12:
            return .retryable
        default:
            return .retryable
        }
    }

    // 読み込み失敗時の指数バックオフによるリトライ（最大 maxRetryCount 回）
    private func retryLoadInterstitial() {
        guard retryCount < maxRetryCount else {
            log("retry exhausted after \(maxRetryCount) attempts")
            return
        }
        retryCount += 1
        let delay = pow(2.0, Double(retryCount - 1))
        log("schedule retry in \(delay)s (\(retryCount)/\(maxRetryCount))")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.loadInterstitial(source: .retry)
        }
    }

    // インタースティシャル広告の表示
    func presentInterstitial() {
        let root = Self.activeRootViewController()
        if let ad = interstitialAd, let root = root {
            log("present ad")
            ad.present(from: root)
        } else {
            // 準備ができていないときは今回は表示せず、次回に備えて読み込むだけ。
            // （多重ロードは loadInterstitial 側のガードで防ぐ）
            log("present fallback: ad not ready or root missing (hasAd=\(interstitialAd != nil), hasRoot=\(root != nil))")
            self.loadInterstitial(source: .presentFallback)
        }
    }
    // 失敗通知：使い捨てのため破棄して次回分を読み込む
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        log("didFailToPresent message=\(error.localizedDescription)")
        self.interstitialAd = nil
        self.loadInterstitial(source: .didFailToPresent)
    }

    // 表示通知
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        log("will present")
    }

    // クローズ通知：使い捨てのため破棄して次回分を読み込む
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        log("did dismiss")
        self.interstitialAd = nil
        self.loadInterstitial(source: .didDismiss)
    }

    private static func activeRootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        let window = scenes
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        return window?.rootViewController
    }

    private static var buildFlavor: String {
        #if DEBUG
        return "DEBUG"
        #else
        return "RELEASE"
        #endif
    }

    private func log(_ message: String) {
        print("[AdMob][Interstitial] \(message)")
    }
}
