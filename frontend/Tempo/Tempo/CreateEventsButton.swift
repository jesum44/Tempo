//
//  CreateEventsButton.swift
//  Tempo
//
//  Created by Hannah Salameh on 3/16/22.
//

import Foundation
import UIKit

var initialValue = -1.1
var screenHeight = initialValue
var screenWidth = initialValue

final class CreateEventsButton: UIViewController {
    
    func createButton(frame: UILayoutGuide) -> UIButton {
        // make sure buttons are always added to bottom right of screen and not any subviews
        if screenHeight == initialValue {
            screenHeight = frame.layoutFrame.height
        }
        if screenWidth == initialValue {
            screenWidth = frame.layoutFrame.width
        }
        
        
        //let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let button = UIButton(frame: CGRect(
            x: screenWidth-70, y: screenHeight-120, width: 50, height: 50))
        // transparent background
        button.backgroundColor = .blue.withAlphaComponent(0)
        // make button contain large green + sign
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 50)
        button.setTitleColor(.green, for: .normal)
        
        return button
    }
}
