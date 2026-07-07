//
//  AmidaViewModel.swift
//  RouletteArrow
//
//  あみだくじタブのビューモデル。
//  上段の参加者と下段の結果を縦線で結び、ランダムな横棒(rung)をたどって対応を決める。
//

import Foundation

/// あみだくじの複雑さ（横棒の量）。段数で表現する。
enum AmidaComplexity: Int, CaseIterable, Identifiable {
    case easy    // かんたん
    case normal  // ふつう
    case hard    // ふくざつ

    var id: Int { rawValue }

    var titleKey: String {
        switch self {
        case .easy:   return "AmidaComplexityEasy"
        case .normal: return "AmidaComplexityNormal"
        case .hard:   return "AmidaComplexityHard"
        }
    }

    /// この複雑さでの横棒の段数。多いほど入り組む。
    var rowCount: Int {
        switch self {
        case .easy:   return 5
        case .normal: return 9
        case .hard:   return 15
        }
    }
}

class AmidaViewModel: ObservableObject {
    private static let participantsKey = "amida_participants"
    private static let resultsKey = "amida_results"
    private static let complexityKey = "amida_complexity"

    /// 縦線の本数（＝参加者数＝結果数）の範囲
    static let laneRange = 2...8

    /// 上段の参加者ラベル
    @Published var participants: [String] {
        didSet { persist() }
    }
    /// 下段の結果ラベル（「当たり」「はずれ」など）
    @Published var results: [String] {
        didSet { persist() }
    }

    /// 各段(row)ごとの横棒。rungs[row] には「lane と lane+1 を繋ぐ」lane 番号の集合が入る。
    /// あみだくじの見た目・判定はこの配列から決まる。
    @Published private(set) var rungs: [[Int]] = []

    /// 表示中の経路。上段 lane をキーに、その経路（各 row 通過後の lane 位置）を持つ。
    /// 複数の選択肢を同時に色分け表示できる。
    @Published var tracedPaths: [Int: [Int]] = [:]
    /// 経路を描くアニメーションの進捗（0→1）。線が引かれていく表現に使う。
    @Published var drawProgress: CGFloat = 0
    /// アニメーション中フラグ（描画中は操作を抑制する）
    @Published var isTracing: Bool = false

    /// あみだくじの複雑さ。変更時は永続化し、横棒を引き直す。
    @Published var complexity: AmidaComplexity {
        didSet {
            UserDefaults.standard.set(complexity.rawValue, forKey: Self.complexityKey)
            regenerate()
        }
    }

    /// 横棒を並べる段数（複雑さに応じて変わる）。
    var rowCount: Int { complexity.rowCount }

    init() {
        let savedParticipants = UserDefaults.standard.stringArray(forKey: Self.participantsKey)
        let savedResults = UserDefaults.standard.stringArray(forKey: Self.resultsKey)
        if let p = savedParticipants, let r = savedResults, p.count == r.count, p.count >= 2 {
            self.participants = p
            self.results = r
        } else {
            // 初期サンプル（3人 → 当たり1・はずれ2）
            self.participants = ["A", "B", "C"]
            self.results = ["🎁", "❌", "❌"]
        }
        // 保存済みの複雑さを復元（未設定は ふつう）
        let savedComplexity = UserDefaults.standard.object(forKey: Self.complexityKey) as? Int
        self.complexity = savedComplexity.flatMap(AmidaComplexity.init) ?? .normal
        regenerate()
    }

    private func persist() {
        UserDefaults.standard.set(participants, forKey: Self.participantsKey)
        UserDefaults.standard.set(results, forKey: Self.resultsKey)
    }

    /// 縦線の本数（参加者数に一致させる）
    var laneCount: Int { participants.count }

    // MARK: - 項目編集

    /// 参加者を1人追加する（本数上限まで）。結果も1つ追加してペアを保つ。
    func addLane() {
        guard participants.count < Self.laneRange.upperBound else { return }
        participants.append("")
        results.append("")
        regenerate()
    }

    /// 指定 lane を削除する（下限本数までは削除可能）。
    func removeLane(at index: Int) {
        guard participants.count > Self.laneRange.lowerBound,
              participants.indices.contains(index) else { return }
        participants.remove(at: index)
        if results.indices.contains(index) {
            results.remove(at: index)
        }
        regenerate()
    }

    // MARK: - あみだくじ生成

    /// 横棒をランダムに引き直す。隣り合う横棒が同じ段で重ならないようにする。
    func regenerate() {
        clearTrace()
        let lanes = laneCount
        guard lanes >= 2 else {
            rungs = []
            return
        }
        // gap i は lane i と lane i+1 を繋ぐ横棒の位置（0..<lanes-1）。
        let gaps = Array(0..<(lanes - 1))
        // 1本あたりの横棒を置く確率。左詰めの偏りをなくすため、
        // 各行で gap の順序をシャッフルしてから隣接衝突を避けて置く。
        let placeProbability = 0.5

        var newRungs: [[Int]] = []
        for _ in 0..<rowCount {
            var used = Array(repeating: false, count: lanes - 1)
            // gap をランダム順に見て、両隣が未使用なら確率で横棒を置く（左右どちらにも偏らない）
            for gap in gaps.shuffled() {
                let leftBusy = gap > 0 && used[gap - 1]
                let rightBusy = gap < lanes - 2 && used[gap + 1]
                if !leftBusy && !rightBusy && Double.random(in: 0..<1) < placeProbability {
                    used[gap] = true
                }
            }
            let rowRungs = gaps.filter { used[$0] }
            newRungs.append(rowRungs)
        }
        rungs = newRungs
    }

    /// 線を引くアニメーションの秒数。
    static let drawDuration: Double = 6.0

    /// 経路表示をクリアする。
    func clearTrace() {
        tracedPaths = [:]
        drawProgress = 0
        isTracing = false
    }

    // MARK: - 判定

    /// 上段 startLane から下段までたどり、通過した lane 位置の配列を返す。
    /// 返り値 path は長さ rowCount+1（開始位置＋各段通過後の位置）。
    func tracePath(from startLane: Int) -> [Int] {
        var lane = startLane
        var path = [lane]
        for row in rungs {
            if row.contains(lane) {
                // 右へ渡る横棒
                lane += 1
            } else if row.contains(lane - 1) {
                // 左へ渡る横棒
                lane -= 1
            }
            path.append(lane)
        }
        return path
    }

    /// startLane がたどり着く下段の lane（結果の index）。
    func resultLane(from startLane: Int) -> Int {
        tracePath(from: startLane).last ?? startLane
    }

    /// startLane に対応する結果ラベル。
    func resultLabel(from startLane: Int) -> String {
        let lane = resultLane(from: startLane)
        return results.indices.contains(lane) ? results[lane] : ""
    }

    /// 指定した上段 lane の経路を表示対象に加える。実際の線引きアニメーションは View 側で drawProgress を進めて行う。
    /// - Returns: 新たに追加された（＝アニメーションが必要な）場合 true。
    @discardableResult
    func trace(from startLane: Int) -> Bool {
        guard !isTracing, participants.indices.contains(startLane) else { return false }
        // すでに表示済みなら何もしない
        if tracedPaths[startLane] != nil { return false }
        tracedPaths[startLane] = tracePath(from: startLane)
        return true
    }

    /// 全参加者の経路を一度に表示対象にする。
    /// - Returns: 新たに追加された経路があれば true。
    @discardableResult
    func traceAll() -> Bool {
        guard !isTracing else { return false }
        var added = false
        for lane in participants.indices where tracedPaths[lane] == nil {
            tracedPaths[lane] = tracePath(from: lane)
            added = true
        }
        return added
    }

    /// 描画アニメーションの開始/終了を管理する。View から呼ぶ。
    func beginDrawing() {
        isTracing = true
        drawProgress = 0
    }

    func endDrawing() {
        isTracing = false
    }
}
