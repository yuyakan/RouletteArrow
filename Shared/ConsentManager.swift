//
//  ConsentManager.swift
//  RouletteArrow
//
//  広告の同意フローを一元管理する共有オブジェクト。
//  Google 推奨の順序でセットアップする:
//    1. UMP(User Messaging Platform) で同意情報を更新し、必要なら同意フォームを提示する
//       （GDPR/EEA・英国などで必要。不要な地域では何も表示されない）
//    2. ATT(App Tracking Transparency) の許諾ダイアログを要求する
//    3. 上記が済んでから Mobile Ads SDK を初期化する
//  こうすることで、ATT で許可された端末ではパーソナライズ広告が、
//  拒否・未同意の端末では非パーソナライズ広告が正しく配信される。
//

import AppTrackingTransparency
import UserMessagingPlatform
import GoogleMobileAds
import UIKit

final class ConsentManager {
    static let shared = ConsentManager()

    /// Mobile Ads SDK の初期化を一度だけ行うためのフラグ。
    private var didStartMobileAds = false

    private init() {}

    /// 同意フロー全体を開始する。アプリ起動後、UI が表示されてから呼ぶ。
    /// - Parameter completion: Mobile Ads SDK の初期化まで完了したときに呼ばれる。
    func gatherConsentAndStart(completion: (() -> Void)? = nil) {
        let parameters = RequestParameters()
        // 本番では地域は UMP が自動判定する。テスト時に地域を強制したい場合は
        // parameters.debugSettings に geography / testDeviceIdentifiers を設定する。

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self else { return }
            if let error {
                // 同意情報の取得に失敗しても広告表示自体は継続する
                // （UMP は前回セッションの同意状態を保持しているため）。
                print("UMP: 同意情報の更新に失敗しました: \(error.localizedDescription)")
                self.requestTrackingAndStart(completion: completion)
                return
            }

            // 同意が必要な地域では同意フォームを提示する。
            // 不要な地域では即座に completionHandler が呼ばれフォームは出ない。
            ConsentForm.loadAndPresentIfRequired(from: self.topViewController()) { [weak self] formError in
                guard let self else { return }
                if let formError {
                    print("UMP: 同意フォームの表示に失敗しました: \(formError.localizedDescription)")
                }
                // 同意フロー完了後に ATT を要求し、SDK を初期化する。
                self.requestTrackingAndStart(completion: completion)
            }
        }
    }

    /// ATT の許諾を要求し、その結果にかかわらず Mobile Ads SDK を初期化する。
    /// `.notDetermined`（未回答）のときのみダイアログが表示される。
    private func requestTrackingAndStart(completion: (() -> Void)?) {
        DispatchQueue.main.async { [weak self] in
            ATTrackingManager.requestTrackingAuthorization { _ in
                // 許可・拒否いずれの結果でも SDK は動作する
                // （拒否時や未同意時は AdMob が自動的に非パーソナライズ広告へフォールバックする）。
                self?.startMobileAdsIfNeeded(completion: completion)
            }
        }
    }

    /// Mobile Ads SDK を一度だけ初期化する。
    private func startMobileAdsIfNeeded(completion: (() -> Void)?) {
        guard !didStartMobileAds else {
            completion?()
            return
        }
        didStartMobileAds = true
        MobileAds.shared.start { _ in
            completion?()
        }
    }

    /// 同意フォームを提示するための最前面の ViewController を取得する。
    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
