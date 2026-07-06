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
    private static let weightsKey = "lottery_weights"

    /// 割合の重みの範囲（各項目に設定できる整数）
    static let weightRange = 1...20

    /// 抽選項目（ラベル）。「はずれ」を混ぜることで外れ枠を表現する。
    @Published var items: [String] {
        didSet {
            // items の増減に weights を追従させる（末尾は重み1で追加）
            syncWeightsCount()
            persist()
        }
    }

    /// 各項目の割合の重み。items と同じ index で対応する。
    /// 実際の割合は「各重み ÷ 有効項目の重み合計」で決まる。
    @Published var weights: [Int] {
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
    /// 回転秒数（全タブ共通・12秒固定）
    let spinDuration = SpinSettings.duration

    init() {
        let savedItems: [String]
        if let saved = UserDefaults.standard.stringArray(forKey: Self.itemsKey), !saved.isEmpty {
            savedItems = saved
        } else {
            // 初期サンプル
            savedItems = ["A", "B", "C", "D"]
        }
        self.items = savedItems

        // 保存済みの重みを読み込む。旧データや欠損分は重み1で補う（=従来の均等割）。
        let savedWeights = UserDefaults.standard.array(forKey: Self.weightsKey) as? [Int] ?? []
        self.weights = savedItems.indices.map { i in
            let w = i < savedWeights.count ? savedWeights[i] : 1
            return Self.clampWeight(w)
        }
    }

    private func persist() {
        UserDefaults.standard.set(items, forKey: Self.itemsKey)
        UserDefaults.standard.set(weights, forKey: Self.weightsKey)
    }

    /// items の要素数に weights を合わせる（不足分は重み1、余剰分は切り捨て）。
    private func syncWeightsCount() {
        if weights.count < items.count {
            weights.append(contentsOf: Array(repeating: 1, count: items.count - weights.count))
        } else if weights.count > items.count {
            weights.removeLast(weights.count - items.count)
        }
    }

    private static func clampWeight(_ w: Int) -> Int {
        min(max(w, weightRange.lowerBound), weightRange.upperBound)
    }

    // MARK: - 項目編集

    func addItem() {
        items.append("")
        // items の didSet で weights も追従する
    }

    func removeItem(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where items.indices.contains(index) {
            items.remove(at: index)
            if weights.indices.contains(index) {
                weights.remove(at: index)
            }
        }
    }

    /// 指定 index の重みを設定する（範囲内にクランプ）。
    func setWeight(_ w: Int, at index: Int) {
        guard weights.indices.contains(index) else { return }
        weights[index] = Self.clampWeight(w)
    }

    /// 空でない項目のみ（抽選対象）
    var validItems: [String] {
        items.enumerated()
            .filter { !$1.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { $0.element }
    }

    /// validItems と同じ並びの重み。円グラフの扇形サイズや割合表示に使う。
    var validWeights: [Int] {
        items.indices
            .filter { !items[$0].trimmingCharacters(in: .whitespaces).isEmpty }
            .map { weights.indices.contains($0) ? weights[$0] : 1 }
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
        AdManager.shared.notifySpin()

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
