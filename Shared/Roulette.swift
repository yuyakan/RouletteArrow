//
//  RouletteModel.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/11/06.
//

import Foundation

class Roulette {
    @Published var rotationDegree: Int
    
    init(rotationDegree: Int) {
        self.rotationDegree = rotationDegree
    }
    
    func rotate() {
        let decisionAngle = Int.random(in: 1...3600)
        let preRotation = 3600
        rotationDegree += preRotation + decisionAngle
    }
}
