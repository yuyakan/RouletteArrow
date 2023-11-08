//
//  RouletteArrowApp.swift
//  Shared
//
//  Created by 上別縄祐也 on 2022/03/02.
//

import SwiftUI
import AppTrackingTransparency
import UIKit
import GoogleMobileAds

// AppDelegateクラスを定義する
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Mobile Ads SDKを初期化する
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }
}

@main
struct RouletteArrowApp: App {
    init() {
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                //User has not indicated their choice for app tracking
                //You may want to show a pop-up explaining why you are collecting their data
                //Toggle any variables to do this here
            } else {
                ATTrackingManager.requestTrackingAuthorization { status in
                    //Whether or not user has opted in initialize GADMobileAds here it will handle the rest
                                                                
                    GADMobileAds.sharedInstance().start(completionHandler: nil)
                }
            }
        }
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var appOpen = AppOpen()
    var body: some Scene {
        WindowGroup {
            RouletteView()
        }
        .onChange(of: appOpen.appOpenAdLoaded) { newValue in
            appOpen.presentAppOpenAd()
        }
    }
}
