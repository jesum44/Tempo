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
       
        getNearbyEvents(nil)
    

       
        
//        annotationNode.scaleRelativeToDistance = true

       

        
        

    }
    
    private func getNearbyEvents(_ sender: UIAction?) {
        
        // Make a call to eventStore.shared.getEvents
        // That call will populate the events array with all the relevent data
        // Once the data is supplied, grab the longitude and latitude off the data and use it here to display the AR pins
        let locationArray = [(lat: 42.2768206, longi: 83.745065), (lat: 47.2768209, longi: 83.745065)]
        
        for (lat, longit) in locationArray {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: longit)
            let location = CLLocation(coordinate: coordinate, altitude: 300)
            let image = UIImage(systemName: "eye")!
            let annotationNode = LocationAnnotationNode(location: location, image: image)
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
            view.addSubview(sceneLocationView)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sceneLocationView.frame = view.bounds
    }
    
}
