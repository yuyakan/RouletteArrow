//
//  SpinSettings.swift
//  RouletteArrow
//
//  回転時間（秒）の共通設定。矢印タブ・ルーレットタブで共有し、UserDefaults に永続化する。
//

import Foundation

enum SpinSettings {
    /// UserDefaults 上のキー
    static let durationKey = "spin_duration_seconds"

    /// 選べる秒数のプリセット（上限12秒）
    static let options: [Int] = [3, 6, 9, 12]

    /// 既定値（従来と同じ12秒）
    static let defaultDuration = 12

    /// 現在の回転秒数を取得する。未設定・範囲外なら既定値。
    static var duration: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: durationKey)
            return options.contains(saved) ? saved : defaultDuration
        }
        set {
            UserDefaults.standard.set(newValue, forKey: durationKey)
        }
    }
}
