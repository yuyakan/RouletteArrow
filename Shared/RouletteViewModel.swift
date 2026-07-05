//
//  RouletteViewModel.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/10/16.
//

import Foundation

/// 矢印モードの動作モード
enum ArrowMode: Int, CaseIterable, Identifiable {
    case single   // 通常（1本の矢印で1人）
    case multiple // 複数当選（複数本の矢印を等間隔配置）
    case ranking  // 順番決め（複数本の矢印に順位番号を付与）

    var id: Int { rawValue }

    /// ローカライズキー
    var titleKey: String {
        switch self {
        case .single:   return "ArrowModeSingle"
        case .multiple: return "ArrowModeMultiple"
        case .ranking:  return "ArrowModeRanking"
        }
    }
}

class RouletteViewModel: ObservableObject {
    @Published var isVisibleStartButton: Bool = false
    @Published var isVisibleSettingValue = false
    @Published var isVisibleSeparation = true
    @Published var peoples = 4 {
        didSet {
            // 人数を減らしたときに矢印本数がはみ出さないよう丸める
            if arrowCount > maxArrowCount {
                arrowCount = maxArrowCount
            }
        }
    }

    /// 矢印モード
    @Published var mode: ArrowMode = .single {
        didSet { shuffleRanksIfNeeded() }
    }
    /// 複数当選/順番決めで配置する矢印の本数
    @Published var arrowCount = 2 {
        didSet { shuffleRanksIfNeeded() }
    }
    /// 順番決めで、矢印index -> 表示順位(1始まり) の割り当て。
    /// start() のほか、本数・モードを変えたときにも振り直す。
    @Published var rankAssignments: [Int] = []

    /// 回転秒数（全タブ共通。変更時は SpinSettings に永続化する）
    @Published var spinDuration: Int = SpinSettings.duration {
        didSet { SpinSettings.duration = spinDuration }
    }

    private var roulette: Roulette
    private let interstitial = Interstitial()
    private var startCount = 0
    private let interstitialFrequency = 5

    init() {
        self.roulette = Roulette(rotationDegree: 0)
        interstitial.loadInterstitial()
    }

    var rouletteDegree: Int {
        get {
            roulette.rotationDegree
        }
    }

    /// 現在のモードで実際に描画する矢印の本数
    var effectiveArrowCount: Int {
        switch mode {
        case .single:
            return 1
        case .multiple, .ranking:
            // 人数を超えないように、かつ最低2本
            return max(2, min(arrowCount, peoples))
        }
    }

    /// arrowCount のピッカー選択肢の上限（peoples に追従）
    var maxArrowCount: Int {
        max(2, peoples)
    }

    /// 指定した矢印index に割り当てられた順位（1始まり）。未割り当てなら index+1 を返す。
    func rank(for arrowIndex: Int) -> Int {
        guard rankAssignments.indices.contains(arrowIndex) else { return arrowIndex + 1 }
        return rankAssignments[arrowIndex]
    }

    /// 順番決めのとき、順位の並びをシャッフルして各矢印へ割り当て直す。
    func shuffleRanksIfNeeded() {
        guard mode == .ranking else { return }
        rankAssignments = Array(1...effectiveArrowCount).shuffled()
    }

    func start() {
        isVisibleStartButton.toggle()
        // 回すたびに順位の並びをシャッフルして各矢印へ割り当てる
        shuffleRanksIfNeeded()
        rouletteRotate()
        startCount += 1
        if startCount % interstitialFrequency == 0 {
            interstitial.presentInterstitial()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(spinDuration)) {
            self.isVisibleStartButton.toggle()
        }
    }

    /// 他タブで秒数が変更されている場合に備えて、共通設定から読み直す。
    func reloadSpinDuration() {
        let current = SpinSettings.duration
        if current != spinDuration {
            spinDuration = current
        }
    }

    private func rouletteRotate() {
        roulette.rotate()
    }

    func setting() {
        isVisibleSettingValue.toggle()
    }
}
