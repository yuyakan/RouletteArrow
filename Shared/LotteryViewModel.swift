//
//  LotteryViewModel.swift
//  RouletteArrow
//
//  ルーレット抽選モードのビューモデル。
//  名前ラベル付きの項目を円グラフに並べて回し、当選/順位を決める。
//

import Foundation

/// 抽選モード
enum LotteryMode: Int, CaseIterable, Identifiable {
    case single    // 通常（1件当選）
    case multiple  // 複数当選（n件）
    case ranking   // 順番決め（全項目の順位）

    var id: Int { rawValue }

    var titleKey: String {
        switch self {
        case .single:   return "LotteryModeSingle"
        case .multiple: return "LotteryModeMultiple"
        case .ranking:  return "LotteryModeRanking"
        }
    }
}

class LotteryViewModel: ObservableObject {
    private static let itemsKey = "lottery_items"

    /// 抽選項目（ラベル）。「はずれ」を混ぜることで外れ枠を表現する。
    @Published var items: [String] {
        didSet { persist() }
    }
    /// 円グラフの回転角度
    @Published var rotationDegree: Int = 0
    /// 抽選モード
    @Published var mode: LotteryMode = .single
    /// 複数当選のときの当選数
    @Published var winnerCount: Int = 2
    /// 回転中はStartを無効化する
    @Published var isSpinning: Bool = false
    /// 回転秒数（全タブ共通。変更時は SpinSettings に永続化する）
    @Published var spinDuration: Int = SpinSettings.duration {
        didSet { SpinSettings.duration = spinDuration }
    }

    /// 他タブで秒数が変更されている場合に備えて、共通設定から読み直す。
    func reloadSpinDuration() {
        let current = SpinSettings.duration
        if current != spinDuration {
            spinDuration = current
        }
    }

    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: Self.itemsKey), !saved.isEmpty {
            self.items = saved
        } else {
            // 初期サンプル
            self.items = ["A", "B", "C", "D"]
        }
    }

    private func persist() {
        UserDefaults.standard.set(items, forKey: Self.itemsKey)
    }

    // MARK: - 項目編集

    func addItem() {
        items.append("")
    }

    func removeItem(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where items.indices.contains(index) {
            items.remove(at: index)
        }
    }

    /// 空でない項目のみ（抽選対象）
    var validItems: [String] {
        items.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// 複数当選で選べる最大数
    var maxWinnerCount: Int {
        max(2, validItems.count - 1)
    }

    /// 抽選可能か（2項目以上必要）
    var canSpin: Bool {
        validItems.count >= 2 && !isSpinning
    }

    // MARK: - 抽選

    func spin() {
        let targets = validItems
        guard targets.count >= 2, !isSpinning else { return }

        isSpinning = true

        // 回転量を決める（矢印モードと同様に十分な回転＋乱数）
        let decisionAngle = Int.random(in: 1...3600)
        rotationDegree += 3600 + decisionAngle

        // アニメーション完了後に回転状態を解除する。
        // 当選はポインタが指すセグメントで示すため、結果の保持は不要。
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(spinDuration)) { [weak self] in
            self?.isSpinning = false
        }
    }
}
