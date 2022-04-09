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
    private var frame:UILayoutGuide;
    
    init(frame: UILayoutGuide){
        self.frame = frame;
    }
    
    func createButtonContainer() -> UIStackView {
        let buttonContainer = UIStackView(frame:CGRect(
            x:self.frame.layoutFrame.width-80, y:self.frame.layoutFrame.height-100, width: 60, height:130))
        buttonContainer.axis = .vertical
        buttonContainer.distribution = .fillEqually
        buttonContainer.spacing = 10
        
        return buttonContainer
    }
    
    func createMapButton() -> UIButton {
        let mapToggle = UIButton()
        let mapImg = UIImage(named: "mapIcon")?.withTintColor(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0))
        mapToggle.setImage(mapImg, for: .normal)
        mapToggle.imageView?.contentMode = .scaleAspectFit
        mapToggle.backgroundColor = .white
        mapToggle.layer.cornerRadius = 30
        
        return mapToggle
    }
    
    func createEventButton() -> UIButton {
        var button = UIButton.Configuration.plain()
        
//        button.contentHorizontalAlignment = .fill
//        button.contentVerticalAlignment = .fill
        button.image = UIImage(systemName: "plus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
        button.imagePadding = 5
        button.background.backgroundColor = .white
        button.cornerStyle = .capsule
        
        let realButton = UIButton(configuration: button)
        return realButton
    } 
}
