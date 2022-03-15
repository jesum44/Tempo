//
//  MainView.swift
//  Tempo
//
//  Created by Sam Korman on 3/14/22.
//

import Foundation
import ARCL
import CoreLocation

class ARView: UIViewController {
    var sceneLocationView = SceneLocationView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneLocationView.run()
        let coordinate = CLLocationCoordinate2D(latitude: 42.27165, longitude: 83.74038)
        let location = CLLocation(coordinate: coordinate, altitude: 300)
        let image = UIImage(systemName: "eye")!

        let annotationNode = LocationAnnotationNode(location: location, image: image)
        
//        annotationNode.scaleRelativeToDistance = true

        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        
        
        
        view.addSubview(sceneLocationView)
        
        

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sceneLocationView.frame = view.bounds
    }
    
}
