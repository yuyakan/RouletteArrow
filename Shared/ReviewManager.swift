//
//  ReviewManager.swift
//  RouletteArrow
//
//  レビュー依頼（App Store の星評価ポップアップ）の表示タイミングを管理する共有オブジェクト。
//  実際に実行されたスタートの累計を永続化し、4回目・以降20刻み(20,40,60,…)で依頼する。
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

    /// 実際に実行されたスタートの累計（全タブ合算・永続化）
    private var executedSpinCount: Int {
        get { UserDefaults.standard.integer(forKey: Self.executedSpinCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.executedSpinCountKey) }
    }

    private init() {}

    /// 実際にスタート(回転/線引き)が実行されたことを通知して累計する。
    /// （表示はここでは行わない。設定を閉じたときに shouldRequestReview で判定する）
    func notifyExecutedSpin() {
        executedSpinCount += 1
    }

    /// 現在の累計がレビュー依頼のしきい値(4, 20, 40, 60, …)に達しているか。
    /// 設定を閉じたときにこれを見て、達していればレビューダイアログを出す。
    var shouldRequestReview: Bool {
        isThreshold(executedSpinCount)
    }

    /// しきい値かどうか。4回目、または20の倍数(20,40,60,…)。
    private func isThreshold(_ count: Int) -> Bool {
        count == 4 || (count % 20 == 0)
    }

    /// 設定を閉じたときに呼ぶ。しきい値に達していればレビュー依頼を出し、累計を進めて次のしきい値へ。
    /// - Returns: レビュー依頼を出したら true（＝この設定閉じでは広告を出さない）。
    @discardableResult
    func requestReviewIfNeededOnSettingsClosed() -> Bool {
        guard shouldRequestReview else { return false }
        // 同じしきい値で連続して出さないよう、+1 して次のしきい値まで進める
        executedSpinCount += 1
        requestReview()
        return true
    }

    /// レビュー依頼ポップアップを表示する。
    func requestReview() {
        #if canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        SKStoreReviewController.requestReview(in: scene)
        #endif
    }
}
