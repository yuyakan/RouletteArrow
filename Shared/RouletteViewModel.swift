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
    
    init() {
        self.roulette = Roulette(rotationDegree: 0, text: "Roulette")
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
    
    func start() {
        isVisibleStartButton.toggle()
        rouletteRotate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            self.isVisibleStartButton.toggle()
        }
    }
    
    private func rouletteRotate() {
        roulette.rotate()
    }
}
