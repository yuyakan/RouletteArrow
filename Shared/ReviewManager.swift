//
//  ReviewManager.swift
//  RouletteArrow
//
//  レビュー依頼（App Store の星評価ポップアップ）の表示タイミングを管理する共有オブジェクト。
//  実際に実行されたスタートの累計を永続化し、4回目・以降20刻み(20,40,60,…)で依頼する。
//  しきい値をまたいでスタートしても（例: 設定を開かずに 3→7 回）、次に設定を
//  閉じたときに未達成のしきい値へ到達していれば依頼する（取りこぼしを防ぐ）。
//  結果表示を妨げないよう、依頼はアニメーション完了後に呼び出すこと。
//

import Foundation
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

final class ReviewManager {
    static let shared = ReviewManager()

    private static let executedSpinCountKey = "review_executed_spin_count"
    /// これまでに依頼を出した（＝達成済みの）最後のしきい値。まだ一度も出していなければ 0。
    private static let lastRequestedThresholdKey = "review_last_requested_threshold"

    /// 実際に実行されたスタートの累計（全タブ合算・永続化）
    private var executedSpinCount: Int {
        get { UserDefaults.standard.integer(forKey: Self.executedSpinCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.executedSpinCountKey) }
    }

    /// 依頼済みの最後のしきい値（永続化）。
    private var lastRequestedThreshold: Int {
        get { UserDefaults.standard.integer(forKey: Self.lastRequestedThresholdKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.lastRequestedThresholdKey) }
    }

    private init() {}

    /// 実際にスタート(回転/線引き)が実行されたことを通知して累計する。
    /// （表示はここでは行わない。設定を閉じたときに shouldRequestReview で判定する）
    func notifyExecutedSpin() {
        executedSpinCount += 1
    }

    /// 未達成のしきい値に到達しているか（しきい値をまたいでいても true）。
    /// 設定を閉じたときにこれを見て、達していればレビューダイアログを出す。
    var shouldRequestReview: Bool {
        nextThreshold(after: lastRequestedThreshold) <= executedSpinCount
    }

    /// 指定したしきい値の次のしきい値を返す。系列は 4, 20, 40, 60, …。
    /// - `after == 0`（未依頼）のとき: 最初のしきい値 4
    /// - `after == 4` のとき: 20
    /// - それ以外（20以上）: 次の20の倍数
    private func nextThreshold(after threshold: Int) -> Int {
        if threshold < 4 { return 4 }
        if threshold < 20 { return 20 }
        return threshold + 20
    }

    /// 設定を閉じたときに呼ぶ。未達成のしきい値に到達していればレビュー依頼を出し、
    /// 到達済みのしきい値を記録して次へ進める（またいでいても取りこぼさない）。
    /// - Returns: レビュー依頼を出したら true（＝この設定閉じでは広告を出さない）。
    @discardableResult
    func requestReviewIfNeededOnSettingsClosed() -> Bool {
        guard shouldRequestReview else { return false }
        // 現在の累計以下で最大の「達成したしきい値」まで記録を進める。
        // 例: しきい値20を出す時点で累計が45でも、記録は20に進め、次は40を待つ。
        var reached = nextThreshold(after: lastRequestedThreshold)
        while nextThreshold(after: reached) <= executedSpinCount {
            reached = nextThreshold(after: reached)
        }
        lastRequestedThreshold = reached
        requestReview()
        return true
    }

    /// レビュー依頼ポップアップを表示する。
    /// 実際に表示されるかは OS が判断する（年3回上限・TestFlight/デバッグでは出ないことがある）。
    func requestReview() {
        #if canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else {
            print("[ReviewManager] レビュー依頼をスキップ: foregroundActive な windowScene が見つかりません")
            return
        }
        print("[ReviewManager] レビュー依頼をリクエストします (累計=\(executedSpinCount), 達成しきい値=\(lastRequestedThreshold))")
        SKStoreReviewController.requestReview(in: scene)
        #endif
    }
}
