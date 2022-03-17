//
//  MainView.swift
//  Tempo
//
//  Created by Sam Korman on 3/14/22.
//

import Foundation
import ARCL
import CoreLocation
import UIKit

class ARView: UIViewController {
    var sceneLocationView = SceneLocationView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneLocationView.run()
        getNearbyEvents(nil)
        
        //****** ARCL Code Ends Here
        
        
        
        //******** CreateEvent Code Below:

        // add "+" button to create an event
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let button = UIButton(frame: CGRect(
            x: frame.width-100, y: frame.height-100, width: 50, height: 50))
        // transparent background
        button.backgroundColor = .blue.withAlphaComponent(0)
        // make button contain large green + sign
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 50)
        button.setTitleColor(.green, for: .normal)
        button.addTarget(self, action: #selector(createEventButtonTapped), for: .touchUpInside)
        
        // add + button to view
        self.view.addSubview(button)

    }
    
    
    // function that runs when the create event "+" button is tapped
    @objc func createEventButtonTapped(sender: UIButton!) {
        // get CreateEvent.storyboard
        let storyboard = UIStoryboard(name: "CreateEvent", bundle: nil)
        // click on the storyboard file, click the correct view, and give it the same
        // Storyboard ID as below
        let vc = storyboard.instantiateViewController(
            withIdentifier: "CreateEventStoryboardID") as! CreateEventView
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
        
        // this was the previous way I opened the CreateEventView
        // this can be left blank for a swipe-closable modal
        //vc.modalPresentationStyle = .fullScreen
        //self.present(vc, animated: true, completion: nil)
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sceneLocationView.frame = view.bounds
    }
    
    private func getNearbyEvents(_ sender: UIAction?) {
            
        // Make a call to eventStore.shared.getEvents
        // That call will populate the events array with all the relevent data
        // Once the data is supplied, grab the longitude and latitude off the data and use it here to display the AR pins
        let locationArray = [
            (lat: 42.2768206, longi: 83.745065),
            (lat: 47.2768209, longi: 83.745065),
            (lat: 42.295904, longi: -83.719227),
            (lat: 42.293904, longi: -83.720686),
        ]
        
        for (lat, longit) in locationArray {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: longit)
            let location = CLLocation(coordinate: coordinate, altitude: 300)
            let image = UIImage(systemName: "eye")!
            let annotationNode = LocationAnnotationNode(location: location, image: image)
            // this works, but makes the icons so tiny you cant see them, need to increase scale
            //annotationNode.scaleRelativeToDistance = true
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        }
        view.addSubview(sceneLocationView)
    }
    
}


