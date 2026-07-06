//
//  AmidaViewModel.swift
//  RouletteArrow
//
//  あみだくじタブのビューモデル。
//  上段の参加者と下段の結果を縦線で結び、ランダムな横棒(rung)をたどって対応を決める。
//

import Foundation

class AmidaViewModel: ObservableObject {
    private static let participantsKey = "amida_participants"
    private static let resultsKey = "amida_results"

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

    /// 直近でたどった経路（各 row 通過後の lane 位置。ハイライト表示に使う）。
    /// nil のときは経路を表示しない。
    @Published var tracedLanes: [Int]? = nil
    /// たどり始めた上段の lane（結果表示のため保持）
    @Published var tracedStartLane: Int? = nil
    /// アニメーション中フラグ
    @Published var isTracing: Bool = false

    /// 横棒を並べる段数。多いほど入り組んだあみだくじになる。
    static let rowCount = 8

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
        var newRungs: [[Int]] = []
        for _ in 0..<Self.rowCount {
            var rowRungs: [Int] = []
            var lane = 0
            // lane を左から見て、確率で横棒を置く。置いたら次の lane を1つ飛ばして交差を防ぐ。
            while lane < lanes - 1 {
                if Bool.random() {
                    rowRungs.append(lane)
                    lane += 2
                } else {
                    lane += 1
                }
            }
            newRungs.append(rowRungs)
        }
        rungs = newRungs
    }

    /// 経路表示をクリアする。
    func clearTrace() {
        tracedLanes = nil
        tracedStartLane = nil
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

    /// 指定した上段 lane からの経路をたどってハイライト表示する。
    func trace(from startLane: Int) {
        guard !isTracing, participants.indices.contains(startLane) else { return }
        tracedStartLane = startLane
        tracedLanes = tracePath(from: startLane)
        isTracing = true
        // 表示アニメーションのために一定時間後にフラグを解除する
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.isTracing = false
        }
    }
}
