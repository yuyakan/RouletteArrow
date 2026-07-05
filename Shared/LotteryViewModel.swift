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

/// 抽選結果
struct LotteryResult: Identifiable {
    let id = UUID()
    /// 順位（1始まり）。single/multiple では表示順の便宜値。
    let rank: Int
    /// 当選した項目名
    let name: String
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
    /// 直近の抽選結果
    @Published var results: [LotteryResult] = []
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
        results = []

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
        let winningIndex = SegmentResolver.segmentIndex(pointerDegree: pointerDegree(), count: count)

        switch mode {
        case .single:
            results = [LotteryResult(rank: 1, name: targets[winningIndex])]

        case .multiple:
            // 当選indexを起点に、時計回りへ等間隔で winnerCount 件を選ぶ
            let n = min(max(2, winnerCount), count)
            let step = max(1, count / n)
            var chosen: [String] = []
            var idx = winningIndex
            for _ in 0..<n {
                chosen.append(targets[idx % count])
                idx += step
            }
            results = chosen.enumerated().map { LotteryResult(rank: $0.offset + 1, name: $0.element) }

        case .ranking:
            // 当選indexを1位とし、時計回りに順位を割り当てる
            results = (0..<count).map { i in
                LotteryResult(rank: i + 1, name: targets[(winningIndex + i) % count])
            }
        }

        isSpinning = false
    }
}
