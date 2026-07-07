//
//  SegmentResolver.swift
//  RouletteArrow
//
//  回転角度・項目数・オフセットから、止まったセグメント(index)を算出する純関数群。
//  矢印モード / ルーレット抽選モードの両方から共通利用する。
//

import Foundation

enum SegmentResolver {
    /// 円を `count` 等分したとき、`pointerDegree` が指すセグメントの index を返す。
    ///
    /// - Parameters:
    ///   - pointerDegree: ポインタ(または矢印)が指している絶対角度。時計回り(SwiftUIの `rotationEffect` と同じ向き)。
    ///   - count: セグメント数（1以上）。
    ///   - offsetDegree: 分割の回転オフセット（分割線を手で回した角度など）。0でセグメント0の開始が0度。
    /// - Returns: 0..<count のセグメント index。`count <= 0` の場合は 0。
    static func segmentIndex(pointerDegree: Double, count: Int, offsetDegree: Double = 0) -> Int {
        guard count > 0 else { return 0 }
        let step = 360.0 / Double(count)
        // オフセットぶんを引いてからセグメント幅で割る
        let normalized = normalizedDegree(pointerDegree - offsetDegree)
        let index = Int(normalized / step)
        // 浮動小数の丸めで count に達した場合の保険
        return min(index, count - 1)
    }

    /// 基準矢印から `winnerCount` 本を等間隔に配置したとき、
    /// 各矢印が指すセグメント index の配列を返す（重複を除かず、矢印の並び順で返す）。
    ///
    /// - Parameters:
    ///   - baseDegree: 基準矢印(1本目)の絶対角度。
    ///   - winnerCount: 矢印の本数（1以上）。
    ///   - count: セグメント数。
    ///   - offsetDegree: 分割の回転オフセット。
    static func arrowSegmentIndices(baseDegree: Double, winnerCount: Int, count: Int, offsetDegree: Double = 0) -> [Int] {
        guard winnerCount > 0, count > 0 else { return [] }
        let spread = 360.0 / Double(winnerCount)
        return (0..<winnerCount).map { i in
            segmentIndex(pointerDegree: baseDegree + spread * Double(i), count: count, offsetDegree: offsetDegree)
        }
    }

    /// 角度を 0..<360 に正規化する。
    static func normalizedDegree(_ degree: Double) -> Double {
        let m = degree.truncatingRemainder(dividingBy: 360)
        return m < 0 ? m + 360 : m
    }
}
