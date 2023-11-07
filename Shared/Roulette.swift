//
//  RouletteModel.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/11/06.
//

import Foundation

class Roulette {
    var text: String
    @Published var rotationDegree: Int
    
    init(rotationDegree: Int, text: String) {
        self.rotationDegree = rotationDegree
        self.text = text
    }
    
    func rotate() {
        let decisionAngle = Int.random(in: 1...3600)
        let preRotation = 3600
        rotationDegree += preRotation + decisionAngle
    }
}
