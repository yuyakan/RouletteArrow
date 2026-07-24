//
//  RouletteArrowApp.swift
//  Shared
//
//  Created by 上別縄祐也 on 2022/03/02.
//

import SwiftUI
import UIKit

// AppDelegateクラスを定義する
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Mobile Ads SDK の初期化は同意フロー(UMP → ATT)の完了後に
        // ConsentManager で行うため、ここでは初期化しない。
        return true
    }
}

@main
struct RouletteArrowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .onAppear {
                    // UMP 同意 → ATT 許諾 → Mobile Ads SDK 初期化 の順に実行する。
                    ConsentManager.shared.gatherConsentAndStart()
                }
        }
    }
}
