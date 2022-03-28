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
import Alamofire



// TODO: REMOVE & REPLACE
//var locationArray: [[String]] = [
//    ["42.2768206", "83.745065", "Pizza Party"],
//    ["42.3031", "-83.729657", "Board Games"],
//    ["42.295904", "-83.719227", "Jam Sesh"],
//    ["42.293904", "-83.720686", "Free Food"],
//]


// change this value whenever an event is clicked so it can be used for the modal
var GLOBAL_CURRENT_EVENT = Event(event_id: "123456abc", title: "Shrek's Grad Party", address: "987 Swamp Street Ann Arbor, MI", latitude: "42.2768206", longititude: "-83.729657", start_time: "1648408690", end_time: "1648408690", description: "Food & Drinks provided. Live music by Smash Mouth.")

// use this to call getNearbyEvents in other files
var GLOBAL_AR_VIEW: ARView? = nil


class ARView: UIViewController, CLLocationManagerDelegate {
    var sceneLocationView = SceneLocationView()
    private let locmanager = CLLocationManager()
    private var lat = 0.0
    private var lon = 0.0
    
    // use this dict to get the eventID of a tapped location node
    var locationNodesAndTheirEventIDsDict: [LocationAnnotationNode:String] = [:]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GLOBAL_AR_VIEW = self;
        
        locmanager.delegate = self
        locmanager.desiredAccuracy = kCLLocationAccuracyBest
        locmanager.requestWhenInUseAuthorization()
        locmanager.startUpdatingLocation()
        
//        getNearbyEvents(nil)
        sceneLocationView.run()
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
        
        //this was the previous way I opened the CreateEventView
        //this can be left blank for a swipe-closable modal
        //vc.modalPresentationStyle = .fullScreen
        //self.present(vc, animated: true, completion: nil)
        
        
        // TODO: REMOVE & REPLACE
        // locationArray.append(["42.298275", "-83.720859", "Smash Bros Tournament"])
        
        
        getNearbyEvents(nil)
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sceneLocationView.frame = view.bounds
    }
    

    
    func getNearbyEvents(_ sender: UIAction?) {
        print("getNearbyEventsCalled")
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
            
            // remove all pre-existing popups for use by delete/edit events functions
            self.sceneLocationView.removeAllNodes()
            
            // Make a call to eventStore.shared.getEvents
            // That call will populate the events array with all the relevent data
            // Once the data is supplied, grab the longitude and latitude off the data and use it here to display the AR pins
            EventStore.shared.getEvents(
                lat: currentLocation.coordinate.latitude,
                lon: currentLocation.coordinate.longitude
            ) {
                
                for event in EventStore.shared.events {
                    let lat = Double( event.latitude! )!
                    let lon = Double( event.longititude! )!
                    let title = event.title!
                                
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

                    let location = CLLocation(coordinate: coordinate, altitude: 300)
                    //let image = UIImage(systemName: "eye")!
                    let eventLabel = UIView.prettyLabeledView(
                        text: title, backgroundColor: .white, textColor: .black, eventID: event.title!)
                    let annotationNode = LocationAnnotationNode(location: location, view: eventLabel)
                    
                    // add event's node and its event_id to the dict
                    self.locationNodesAndTheirEventIDsDict[annotationNode] = event.event_id!
                    
                    // this works, but makes the icons so tiny you cant see them, need to increase scale
                    //annotationNode.scaleRelativeToDistance = true
                    self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
                }
                
            }
            
        }
                
        self.view.addSubview(sceneLocationView)
        self.addButtons()
        
        // add tap gesture recognizer to AR scene's view, so that stuff can happen when an event popup is clicked
        // https://aclima93.com/medium/2018/08/23/01.html
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(handleARObjectTap(gestureRecognizer:))
        )
        sceneLocationView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // https://aclima93.com/medium/2018/08/23/01.html
    // runs when a event popup is tapped
    @objc func handleARObjectTap(gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }

        if gestureRecognizer.state == .ended {

            // Look for an object directly under the touch location
            let location: CGPoint = gestureRecognizer.location(in: sceneLocationView)
            let hits = sceneLocationView.hitTest(location, options: nil)
            if !hits.isEmpty {

                // select the first match
                if let tappedNode = hits.first?.node.parent as? LocationAnnotationNode {
                    let tappedNodeEventID = self.locationNodesAndTheirEventIDsDict[tappedNode]!;
                    // handle the tapped event stuff
                    self.handleEventPopupTapped(eventID: tappedNodeEventID)
                }
            }
        }
    }
    
    // runs when a event popup is tapped
    func handleEventPopupTapped(eventID: String) {
        // get event's full info
        let getURL = "https://54.175.206.175/events/" + eventID
        AF.request(getURL, method: .get).response { res in
            //let resData = String(data: res.data!, encoding: String.Encoding.utf8)!
            if let json = try? JSON(data: res.data!) {
                for eventEntry in json["events"].arrayValue {
                    
                    // set global event to the one just tapped
                    GLOBAL_CURRENT_EVENT = Event(
                        event_id: eventEntry[0].stringValue,
                        title: eventEntry[1].stringValue,
                        address: eventEntry[2].stringValue,
                        latitude: "\(eventEntry[3].stringValue)",
                        longititude: "\(eventEntry[4].stringValue)",
                        start_time: eventEntry[5].stringValue,
                        end_time:  eventEntry[6].stringValue,
                        description: eventEntry[7].stringValue
                    )
                    
                    // now, launch the event info modal, filled with info about the global event
                    let storyboard = UIStoryboard(name: "EventInfoView", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "EventInfoViewStoryboardID") as! EventInfoView
                    
                    let navController = UINavigationController(rootViewController: vc)
                    
                    // make modal half screen, comment this if statement out for full screen
                    // https://stackoverflow.com/a/67988976
                    if let pc =
                        navController.presentationController
                            as? UISheetPresentationController {

                        pc.detents = [.medium()]
                    }
                    
                    self.present(navController, animated: true, completion: nil)
                }
            }
        }
    }

}



// Extension to UIView provided by ARKit-CoreLocation library
extension UIView {
    // Create a colored view with label, border, and rounded corners.
    class func prettyLabeledView(text: String,
                                 backgroundColor: UIColor = .systemBackground,
                                 borderColor: UIColor = .black,
                                // adding this in myself
                                 textColor: UIColor = .white,
                                 eventID: String
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


