//
//  AdManager.swift
//  RouletteArrow
//
//  インタースティシャル広告の表示頻度を全タブ合算で管理する共有オブジェクト。
//  矢印・ルーレット両タブのスタート回数を合算し、一定回数ごとに広告を表示する。
//

import Foundation

final class AdManager {
    static let shared = AdManager()

    private let interstitial = Interstitial()
    private var spinCount = 0
    /// 何回のスタートごとに広告を表示するか
    private let frequency = 3

    private init() {
        interstitial.loadInterstitial()
    }

    /// スタート(回転)が実行されたことを通知する。合算カウントが頻度に達したら広告を表示。
    func notifySpin() {
        spinCount += 1
        if spinCount % frequency == 0 {
            interstitial.presentInterstitial()
        }
    }
}
