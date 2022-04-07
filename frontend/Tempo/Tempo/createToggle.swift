//
//  MapView.swift
//  Tempo
//
//  Created by Hannah Salameh on 3/16/22.
//

import Foundation
import UIKit
import SwiftUI

final class createToggle {
    
    func createButtonContainer(screenHeight: CGFloat) -> UIStackView {
        
        let buttonContainer = UIStackView(frame:CGRect(
            x:30, y:screenHeight-130, width: 200, height:70))
        buttonContainer.axis = .horizontal
        buttonContainer.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        buttonContainer.layer.cornerRadius = 10
        buttonContainer.distribution = .fillEqually
        
        return buttonContainer
    }
    
    func createMapButton(screenHeight: CGFloat) -> UIButton {
        let mapToggle = UIButton(frame:CGRect(
            x:30, y:screenHeight-130, width: 50, height:50))
        let mapImg = UIImage(named: "mapIcon")?.withTintColor(.black)
        mapToggle.setImage(mapImg, for: .normal)
        let mapImg2 = UIImage(named: "mapIcon")?.withTintColor(.gray)
        mapToggle.setImage(mapImg2, for: .disabled)
        
        return mapToggle
    }
    
    func createARButton(screenHeight: CGFloat) -> UIButton {
        let VRToggle = UIButton(frame: CGRect(
            x: 80, y: screenHeight-130, width: 50, height: 50))
        VRToggle.backgroundColor = .blue.withAlphaComponent(0)
        let VRImg = UIImage(named: "goggles")?.withTintColor(.black)
        VRToggle.setImage(VRImg, for: .normal)
        let VRImg2 = UIImage(named:"goggles")?.withTintColor(.gray)
        VRToggle.setImage(VRImg2, for: .disabled)
        
        return VRToggle
    }
    
    
    
}
