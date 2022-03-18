//
//  MapView2.swift
//  Tempo
//
//  Created by Hannah Salameh on 3/17/22.
//

import Foundation
import UIKit

class MapView2: UIView {
    override init(frame: CGRect){
        super.init(frame: CGRect(x: 0, y: 0, width:390, height: 844))
        self.backgroundColor = .systemBackground
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) view deserialization not supported")
    }
}
