//
//  RouletteModel.swift
//  RouletteArrow
//
//  Created by 上別縄祐也 on 2023/11/06.
//

import Foundation

class Roulette {
    private let oneRotationAngle = 360
    var text: String
    var rotationDegree: Int
    var peoples: Int
    var previousPeoples: Int
    
    init(rotationDegree: Int, peoples: Int, text: String) {
        self.rotationDegree = rotationDegree
        self.text = text
        self.peoples = peoples
        self.previousPeoples = peoples
    }
    
    func rotate() {
        let winningNumber = Int.random(in: 1...peoples)
        let preRotation = oneRotationAngle * 6
        let compensateAngle = rotation(peoples: previousPeoples, times: peoples-winningNumber)
        let decisionAngle = rotation(peoples: peoples, times: winningNumber)
        rotationDegree += preRotation + compensateAngle + decisionAngle
        savePepoles()
    }
    
    private func rotation(peoples: Int, times: Int) -> Int {
        return Int((oneRotationAngle / peoples) * times)
    }
    
    private func savePepoles() {
        previousPeoples = peoples
    }
}
