//
//  SpinSettings.swift
//  RouletteArrow
//
//  回転時間（秒）の共通設定。矢印タブ・ルーレットタブで共有する。
//  カスタム設定は廃止し、12秒固定とする。
//

import Foundation

enum SpinSettings {
    /// 回転秒数（固定・12秒）
    static let duration = 12
}
