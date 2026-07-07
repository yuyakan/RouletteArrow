//
//  AdManager.swift
//  RouletteArrow
//
//  インタースティシャル広告の表示を全タブ合算で管理する共有オブジェクト。
//  ・スタートが frequency 回目に達したら、そのスタートは実行せず広告を表示する
//  ・広告表示直後の次の1回のスタートはカウントに含めない
//  ・スタートを minSpinsForAd 回以上した状態で設定パネルを閉じたときにも広告を表示する
//

import Foundation

final class AdManager {
    static let shared = AdManager()

    private let interstitial = Interstitial()
    /// 前回の広告表示以降に実行されたスタート回数（全タブ合算）
    private var spinCount = 0
    /// 何回目のスタートで広告を表示するか
    private let frequency = 3
    /// 設定を閉じたときに広告表示するための最低スタート回数
    private let minSpinsForAd = 2
    /// 広告表示直後の次の1回のスタートをカウント対象外にするフラグ
    private var skipNextCount = false

    private init() {
        interstitial.loadInterstitial()
    }

    /// スタート(回転)が押されたことを通知する。
    /// - Returns: このスタート処理（回転/線引き）を実行してよければ true。
    ///            広告を表示した回は false（＝スタート処理は行わない）。
    @discardableResult
    func notifySpin() -> Bool {
        // 広告表示直後の次の1回はカウントせず、そのまま実行させる
        if skipNextCount {
            skipNextCount = false
            return true
        }

        spinCount += 1
        if spinCount >= frequency {
            // frequency 回目：スタート処理は行わず広告を表示し、カウントをリセット
            spinCount = 0
            skipNextCount = true
            interstitial.presentInterstitial()
            return false
        }
        return true
    }

    /// 設定パネルを閉じたことを通知する。
    /// レビュー依頼のしきい値に達していればレビューを優先し、広告は出さない。
    /// そうでなく、前回表示以降にスタートを minSpinsForAd 回以上していれば広告を表示する。
    func notifySettingsClosed() {
        // レビュー依頼を優先（同じタイミングなら広告は出さない）
        if ReviewManager.shared.requestReviewIfNeededOnSettingsClosed() {
            spinCount = 0
            return
        }
        guard spinCount >= minSpinsForAd else { return }
        spinCount = 0
        interstitial.presentInterstitial()
    }
}
