//
//  ViewExtension.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2022/03/04.
//

import SwiftUI

extension View {
    public func presentInterstitialAd(isPresented: Binding<Bool>, adUnitId: String) -> some View {
        FullScreenModifier(isPresented: isPresented, adType: .interstitial, adUnitId: adUnitId, parent: self)
    }
}
