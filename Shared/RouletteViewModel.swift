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
    @Published var isVisibleSeparation = false
    @Published var roulette: Roulette
    
    init() {
        self.roulette = Roulette(rotationDegree: 0, peoples: 4, text: "Roulette Arrow")
    }
    
    var roulettePeoples: Int {
        get {
            roulette.peoples
        }
        set(peoples) {
            roulette.peoples = peoples
        }
    }
    
    var rouletteTheme: String {
        get {
            roulette.text
        }
        set(text) {
            roulette.text = text
        }
    }
    
    var rouletteDegree: Int {
        get {
            roulette.rotationDegree
        }
    }
    
    func rouletteRotate() {
        roulette.rotate()
    }
}
