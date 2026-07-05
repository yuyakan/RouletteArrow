//
//  RootTabView.swift
//  RouletteArrow
//
//  2タブ構成のルートビュー。
//  タブ1: 矢印モード（既存の RouletteView）
//  タブ2: ルーレット抽選モード（新規 LotteryView）
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RootTabView: View {
    init() {
        // タブバーのアクセント色をブランドカラーに
        #if canImport(UIKit)
        UITabBar.appearance().tintColor = UIColor(BrandTheme.mint)
        #endif
    }

    var body: some View {
        TabView {
            RouletteView()
                .tabItem {
                    Image(systemName: "location.north.fill")
                    Text(LocalizedStringKey("Arrow"))
                }

            LotteryView()
                .tabItem {
                    Image(systemName: "circle.hexagongrid.fill")
                    Text(LocalizedStringKey("Lottery"))
                }
        }
        .tint(BrandTheme.mint)
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
    }
}
