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

/// セグメント(項目)ごとの抽選結果。盤面上のハイライトに使う。
/// 順位は番号付きポインタで表すため、ここでは当選有無のみ持つ。
struct SegmentOutcome {
    /// 当選かどうか（当選以外は減光する）
    let isWinner: Bool
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
    /// 直近の抽選結果。セグメントindex -> 結果。盤面上のハイライト/順位バッジに使う。
    @Published var segmentResults: [Int: SegmentOutcome] = [:]
    /// 回転中はStartを無効化する
    @Published var isSpinning: Bool = false

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

    /// 上部固定ポインタは真上(12時=270度方向で扇の開始が右基準)を指す想定。
    /// 円グラフはセグメント0を0度(右)から時計回りに描画し、ポインタが指す角度は
    /// 「270 - 回転量」に相当する。ここではその角度から当選indexを算出する。
    private func pointerDegree() -> Double {
        // ポインタ位置(真上=270度)から、円グラフの回転ぶんを差し引く
        SegmentResolver.normalizedDegree(270 - Double(rotationDegree))
    }

    func spin() {
        let targets = validItems
        guard targets.count >= 2, !isSpinning else { return }

        isSpinning = true
        segmentResults = [:]

        // 回転量を決める（矢印モードと同様に十分な回転＋乱数）
        let decisionAngle = Int.random(in: 1...3600)
        rotationDegree += 3600 + decisionAngle

        // アニメーション(12秒)完了後に結果を確定する
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            self?.finishSpin(targets: targets)
        }
    }

    private func finishSpin(targets: [String]) {
        let count = targets.count
        var outcomes: [Int: SegmentOutcome] = [:]

        switch mode {
        case .single:
            let idx = SegmentResolver.segmentIndex(pointerDegree: pointerDegree(), count: count)
            outcomes[idx] = SegmentOutcome(isWinner: true)

        case .multiple, .ranking:
            // 円周上に等間隔で配置した winnerCount 本のポインタが、それぞれ指すセグメントを当選にする。
            // 順番決めはポインタに順位番号が振ってあるため、判定ロジックは複数当選と共通。
            // 矢印モードと同じ SegmentResolver.arrowSegmentIndices を流用する。
            let n = min(max(2, winnerCount), count)
            let indices = SegmentResolver.arrowSegmentIndices(
                baseDegree: pointerDegree(), winnerCount: n, count: count
            )
            for idx in indices {
                outcomes[idx] = SegmentOutcome(isWinner: true)
            }
        }

        segmentResults = outcomes
        isSpinning = false
    }
}
