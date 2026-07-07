//
//  BrandTheme.swift
//  RouletteArrow
//
//  アプリ全体で使うブランドカラー・スタイル定義。
//  ブランドカラーは矢印画像(arrow2)のミントグリーン #1DD5A8 を基準にしている。
//

import SwiftUI

enum BrandTheme {
    /// ブランドの主役となるミントグリーン（矢印画像と同色）
    static let mint = Color(red: 0x1D / 255, green: 0xD5 / 255, blue: 0xA8 / 255)

    /// 画面全体の背景（フラットな白）
    static let background = Color.white

    /// 落ち着いた濃色のテキスト色
    static let textPrimary = Color(red: 0x1C / 255, green: 0x24 / 255, blue: 0x2E / 255)
    static let textSecondary = Color(red: 0x1C / 255, green: 0x24 / 255, blue: 0x2E / 255).opacity(0.6)
}
