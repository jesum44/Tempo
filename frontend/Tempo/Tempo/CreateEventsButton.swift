//
//  CreateEventsButton.swift
//  Tempo
//
//  Created by Hannah Salameh on 3/16/22.
//

import Foundation
import UIKit

final class CreateEventsButton: UIViewController {
    
    func createButton(frame: UILayoutGuide) -> UIButton {
        //let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let button = UIButton(frame: CGRect(
            x: frame.layoutFrame.width-70, y: frame.layoutFrame.height-120, width: 50, height: 50))
        // transparent background
        button.backgroundColor = .blue.withAlphaComponent(0)
        // make button contain large green + sign
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 50)
        button.setTitleColor(.green, for: .normal)
        
        return button
    }
}
