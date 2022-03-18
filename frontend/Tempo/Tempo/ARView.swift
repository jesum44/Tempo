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
import SwiftyJSON
import SwiftUI


// TODO: REMOVE & REPLACE
var locationArray: [[String]] = [
    ["42.2768206", "83.745065", "Pizza Party"],
    ["42.3031", "-83.729657", "Board Games"],
    ["42.295904", "-83.719227", "Jam Sesh"],
    ["42.293904", "-83.720686", "Free Food"],
]


class ARView: UIViewController /*, CLLocationManagerDelegate*/ {
    var sceneLocationView = SceneLocationView()
    private let locmanager = CLLocationManager()
    private var lat = 0.0
    private var lon = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        locmanager.delegate = self
//        locmanager.desiredAccuracy = kCLLocationAccuracyBest
//        locmanager.requestWhenInUseAuthorization()
//        locmanager.startUpdatingLocation()
        getNearbyEvents(nil)

        sceneLocationView.run()
        
        //****** ARCL Code Ends Here
        self.addButtons()
    }
    
    func addButtons() {
        //******** CreateEvent Code Below:
        // add "+" button to create an event
        let buttonFactory = CreateEventsButton()
        let frame = self.view.safeAreaLayoutGuide

        let button = buttonFactory.createButton(frame:frame)
        
        button.addTarget(self, action: #selector(createEventButtonTapped), for: .touchUpInside)
        
        let toggleFactory = createToggle()
        let toggleContainer = toggleFactory.createButtonContainer(screenHeight: screenHeight)
        let mapButton = toggleFactory.createMapButton(screenHeight: screenHeight)
        let ARButton = toggleFactory.createARButton(screenHeight: screenHeight)
        mapButton.isEnabled = true
        ARButton.isEnabled = false
        mapButton.addTarget(self, action:#selector(toggleMap), for: .touchUpInside)
        
        // add + button to view
        self.view.addSubview(button)
        self.view.addSubview(toggleContainer)
        
        toggleContainer.addArrangedSubview(mapButton)
        toggleContainer.addArrangedSubview(ARButton)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
           if let location = locations.last {
               
               // If the user has moved a significant distance, call getNearbyEvent again
               if (abs(lat - location.coordinate.latitude) > 0.001 || abs(lon - location.coordinate.longitude) > 0.001) {
                   lat = location.coordinate.latitude
                   lon = location.coordinate.longitude
                   getNearbyEvents(nil)
               }
               
               // Get user's location
               lat = location.coordinate.latitude
               lon = location.coordinate.longitude
            
           }
       
       }
    
    @objc func toggleMap(sender: UIButton!){
        sender.isEnabled = false
        
        let mapView = MapView()
        let vc = UINavigationController(rootViewController: mapView)
        vc.modalPresentationStyle = .fullScreen
        show(vc, sender:self)
    }
    
    @objc func createEventButtonTapped(sender: UIButton!){
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
        
        
        // TODO: REMOVE & REPLACE
        locationArray.append(["42.298275", "-83.720859", "Smash Bros Tournament"])
        getNearbyEvents(nil)
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sceneLocationView.frame = view.bounds
    }
    
    private func getNearbyEvents(_ sender: UIAction?) {
        var locManager = CLLocationManager()
        locManager.requestWhenInUseAuthorization()
        
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse
            || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways
            )
        {
            guard let currentLocation = locManager.location else {
                print("Error: ARView:getNearbyEvents - Unable to acquire user's location!")
                return
            }
            
            let baseAPIUrl = "https://54.175.206.175/events"
            let queryParams = [
                URLQueryItem(name: "lat",
                             value: String(currentLocation.coordinate.latitude)),
                URLQueryItem(name: "lon",
                             value: String(currentLocation.coordinate.longitude)),
                URLQueryItem(name: "results", value: "20")
            ]
            var urlComps = URLComponents(string: baseAPIUrl)!
            urlComps.queryItems = queryParams
            let apiURL = urlComps.url!
            //print(apiURL)
            
            let task = URLSession.shared.dataTask(with: apiURL) { data, res, err in
                guard let data = data, err == nil else {
                    print("GET nearbyEvents had error!")
                    return
                }
                //print(res ?? ":(")
            }
        }
            
        // Make a call to eventStore.shared.getEvents
        // That call will populate the events array with all the relevent data
        // Once the data is supplied, grab the longitude and latitude off the data and use it here to display the AR pins
        EventStore.shared.getEvents() {
            print(EventStore.shared.events)
        }
       
        for var event in EventStore.shared.events{
            print(event)
        }
        
        
        for event in locationArray {
            let lat = Double(event[0])!
            let lon = Double(event[1])!
            let title = event[2]
            
            
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let location = CLLocation(coordinate: coordinate, altitude: 300)
            //let image = UIImage(systemName: "eye")!
            let eventLabel = UIView.prettyLabeledView(
                text: title, backgroundColor: .white, textColor: .black)
            let annotationNode = LocationAnnotationNode(location: location, view: eventLabel)
            // this works, but makes the icons so tiny you cant see them, need to increase scale
            //annotationNode.scaleRelativeToDistance = true
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        }
        
        self.view.addSubview(sceneLocationView)
        self.addButtons()
    }
}



// Extension to UIView provided by ARKit-CoreLocation library
extension UIView {
    // Create a colored view with label, border, and rounded corners.
    class func prettyLabeledView(text: String,
                                 backgroundColor: UIColor = .systemBackground,
                                 borderColor: UIColor = .black,
                                // adding this in myself
                                 textColor: UIColor = .white
                                    ) -> UIView {
        let font = UIFont.preferredFont(forTextStyle: .title2)
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: fontAttributes)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let attributedString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font])
        label.attributedText = attributedString
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true

        let cframe = CGRect(x: 0, y: 0, width: label.frame.width + 20, height: label.frame.height + 10)
        let cview = UIView(frame: cframe)
        cview.translatesAutoresizingMaskIntoConstraints = false
        cview.layer.cornerRadius = 10
        cview.layer.backgroundColor = backgroundColor.cgColor
        cview.layer.borderColor = borderColor.cgColor
        // adding this in myself
        label.textColor = textColor
        cview.layer.borderWidth = 1
        cview.addSubview(label)
        label.center = cview.center

        return cview
    }

}
