//
//  RouletteViewModel.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/10/16.
//

import Foundation

class RouletteViewModel: ObservableObject {
    @Published var isVisibleStartButton: Bool = false
    @Published var isVisibleSettingValue = false
    @Published var isVisibleSeparation = true
    @Published var peoples = 4
    private var roulette: Roulette
    private let interstitial = Interstitial()
    private var startCount = 0
    private let interstitialFrequency = 5

    init() {
        self.roulette = Roulette(rotationDegree: 0)
        interstitial.loadInterstitial()
    }
    
    var rouletteDegree: Int {
        get {
            roulette.rotationDegree
        }
    }
    
    func start() {
        isVisibleStartButton.toggle()
        rouletteRotate()
        startCount += 1
        if startCount % interstitialFrequency == 0 {
            interstitial.presentInterstitial()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            self.isVisibleStartButton.toggle()
        }
    }
    
    private func rouletteRotate() {
        roulette.rotate()
    }
    
    func setting() {
        isVisibleSettingValue.toggle()
    }
}
