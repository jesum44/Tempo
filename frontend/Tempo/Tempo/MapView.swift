//
//  MapView.swift
//  Tempo
//
//  Created by Hannah Salameh on 3/16/22.
//

import Foundation
import UIKit
import SwiftUI
import GoogleMaps
import Alamofire
import SwiftyJSON

final class MapView:UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    private var mapView: GMSMapView!
    private let locManager = CLLocationManager()
    
    var event: Event? = nil
    
    override func loadView(){
        print("in load view")
//        let mapView = MapView2()
        mapView = GMSMapView()
        view = mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Map Stuff
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        
        
        locManager.delegate = self
        locManager.startUpdatingLocation()
        
        var marker: GMSMarker!
        
        EventStore.shared.events.forEach {
            let lat = Double( $0.latitude! )!
            let lon = Double ($0.longitude! )!
            marker = GMSMarker(position: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            marker.map = mapView
            marker.userData = $0
//            marker.title = $0.title
        }

        // add "+" button to create an event
        let buttonFactory = CreateEventsButton()
        let frame = self.view.safeAreaLayoutGuide
        print(frame)
        
        let button = buttonFactory.createButton(frame:frame)
        print(button)
        button.addTarget(self, action: #selector(createEventButtonTapped), for: .touchUpInside)
        
        let toggleFactory = createToggle()
        let toggleContainer = toggleFactory.createButtonContainer(screenHeight: screenHeight)
        let mapButton = toggleFactory.createMapButton(screenHeight: screenHeight)
        let ARButton = toggleFactory.createARButton(screenHeight: screenHeight)
        mapButton.isEnabled = false
        ARButton.isEnabled = true
        ARButton.addTarget(self, action:#selector(toggleAR), for: .touchUpInside)
        
        // add + button to view
        self.view.addSubview(button)
        self.view.addSubview(toggleContainer)
        
        toggleContainer.addArrangedSubview(mapButton)
        toggleContainer.addArrangedSubview(ARButton)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = mapView.myLocation else {
            return
        }
        
        mapView.camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 16.0)
        
        manager.stopUpdatingLocation()
    }
    
    @objc func toggleAR(sender: UIButton!){
        sender.isEnabled = false
        
        let arView = ARView()
        let vc = UINavigationController(rootViewController: arView)
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
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            
        guard let event = marker.userData as? Event else {
            return false
        }

        handleEventMarkerTapped(event: event)
        return false
    }
    
    
    
    // runs when a event popup is tapped
    func handleEventMarkerTapped(event: Event) {
        
        // set global event to the one just tapped
        GLOBAL_CURRENT_EVENT = Event(
            event_id: event.event_id,
            title: event.title,
            address: event.address,
            latitude: event.latitude,
            longitude: event.longitude,
            start_time: event.start_time,
            end_time:  event.end_time,
            description: event.description,
            distance: event.distance
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
