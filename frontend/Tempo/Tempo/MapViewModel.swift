//
//  MapViewModel.swift
//  Tempo
//
//  Created by Casey Wentland on 4/10/22.
//

import Alamofire
import Combine
import Foundation
import MapKit
import SwiftUI
import CoreLocation
import SwiftyJSON

class MyAnnotation: NSObject, MKAnnotation {
    var event: Event?
    var coordinate: CLLocationCoordinate2D
    let title: String?
    
    init(event: Event, coordinate: CLLocationCoordinate2D, title: String) {
        self.event = event
        self.coordinate = coordinate
        self.title = title
    }
}

class MapViewModel: UIViewController, ObservableObject, CLLocationManagerDelegate, MKMapViewDelegate {
    @Published var mapView = MKMapView()
    
    @Published var region : MKCoordinateRegion!
    
    @Published var lat : Double = 0.0
    
    @Published var lon : Double = 0.0
    
    @Published var permissionDenied = false
    
    @Published var mapType : MKMapType = .standard
    
    @Published var searchText = ""
    
    // Searchable Places
    @Published var events : [Event] = []
    
    @Published var filteredEvents : [Event] = []
            
    private var cancellables = Set<AnyCancellable>()
    
    
    func updateMapType() {
        if mapType == .standard {
            mapType = .hybrid
            mapView.mapType = mapType
        }
        else {
            mapType = .standard
            mapView.mapType = mapType
        }
    }
    
    func focusLocation() {
        guard let _ = region else{return}
        
        mapView.setRegion(region, animated: true)
        mapView.setVisibleMapRect(mapView.visibleMapRect, animated: true)
    }
    
    func handleEventTapped(event: Event) {
        // Center on selected event's coordinates
        
        
        let event_coordinate = CLLocationCoordinate2D(latitude: Double(event.latitude!)!, longitude: Double(event.longitude!)!)
        
        let region = MKCoordinateRegion(center: event_coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        
        mapView.setRegion(region, animated: true)
        
        mapView.setVisibleMapRect(mapView.visibleMapRect, animated: true)
        
        let locManager = CLLocationManager()
        locManager.requestWhenInUseAuthorization()
        
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse
            || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways
        )
        {
            guard let currentLocation = locManager.location else {
                print("Error: ARView:getNearbyEvents - Unable to acquire user's location!")
                return
            }
            let lat =  String(currentLocation.coordinate.latitude)
            let lon =  String(currentLocation.coordinate.longitude)
            // get event's full info
            let getURL = "https://54.87.128.240/events/" + event.event_id! + "?lat=" + lat + "&lon=" + lon
            AF.request(getURL, method: .get).response { res in
                //let resData = String(data: res.data!, encoding: String.Encoding.utf8)!
                if let json = try? JSON(data: res.data!) {
                    let eventEntry = json["event"].arrayValue
                    // set global event to the one just tapped
                    print(eventEntry)
                    GLOBAL_CURRENT_EVENT = Event(
                        event_id: eventEntry[0].stringValue,
                        title: eventEntry[1].stringValue,
                        address: eventEntry[2].stringValue,
                        latitude: "\(eventEntry[3].stringValue)",
                        longitude: "\(eventEntry[4].stringValue)",
                        start_time: eventEntry[5].stringValue,
                        end_time:  eventEntry[6].stringValue,
                        description: eventEntry[7].stringValue,
                        distance: eventEntry[10].stringValue
                    )
                    
                    GLOBAL_IS_OWNER = json["is_owner"].boolValue
                    
        
//            GLOBAL_CURRENT_EVENT = cur_event
        
                    let topVC = self.topMostController()
                    let uiStoryboard = UIStoryboard(name: "EventInfoView", bundle: nil)

                    let vcToPresent = uiStoryboard.instantiateViewController(withIdentifier: "EventInfoViewStoryboardID") as! EventInfoView
                    
                    let navController = UINavigationController(rootViewController: vcToPresent)
                    
                    if let pc =
                        navController.presentationController
                        as? UISheetPresentationController {
                        
                        pc.detents = [.medium()]
                    }

                    topVC.present(navController, animated:true, completion: nil)
                }
            }
                    
        
//            let getURL = "https://54.87.128.240/events/" + annotation.event_id!
//
//            AF.request(getURL, method: .get).response { res in
//                if let json = try? JSON(data: res.data!) {
//                    let event = json["event"].arrayValue
//                    GLOBAL_CURRENT_EVENT = Event(
//                        event_id: event[0].stringValue,
//                        title: event[1].stringValue,
//                        address: event[2].stringValue,
//                        latitude: "\(event[3].stringValue)",
//                        longitude: "\(event[4].stringValue)",
//                        start_time: event[5].stringValue,
//                        end_time:  event[6].stringValue,
//                        description: event[7].stringValue,
//                        distance: event[8].stringValue
//                    )
//
//
//
//                    let topVC = self.topMostController()
//
//                    let uiStoryboard = UIStoryboard(name: "EventInfoView", bundle: nil)
//
//                    let vcToPresent = uiStoryboard.instantiateViewController(withIdentifier: "EventInfoViewStoryboardID") as! EventInfoView
//
//                    topVC.present(vcToPresent, animated:true, completion: nil)
//
//                }
        }
        
    }
    
    func updateNearbyEvents() {
        let locationManager = CLLocationManager()
        
        guard let currentLocation = locationManager.location else {
            print("Error: ARView:getNearbyEvents - Unable to acquire user's location!")
            return
        }
        
        EventStore.shared.getEvents(
            lat: currentLocation.coordinate.latitude,
            lon: currentLocation.coordinate.longitude
        )  { }
        
        self.events = EventStore.shared.events
    }
    
    func updateMap() {
        var customAnnotations = self.mapView.annotations.filter({!($0 is MKUserLocation)}) as! [MyAnnotation]
        
        for annotation in customAnnotations {
            if !self.filteredEvents.contains(where: { $0.event_id == annotation.event?.event_id }) {
                mapView.removeAnnotation(annotation)
            }
        }
                
        // add events to map that are in self.events and not already on the map
        customAnnotations = self.mapView.annotations.filter({!($0 is MKUserLocation)}) as! [MyAnnotation]
        
        for event in self.filteredEvents {
            if !customAnnotations.contains(where: { $0.event?.event_id == event.event_id }) {
                
                let lat = Double( event.latitude! )!
                let lon = Double( event.longitude! )!
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let pointAnnotation = MyAnnotation(event: event, coordinate: coordinate, title: event.title ?? "")
                
                mapView.addAnnotation(pointAnnotation)
            }
        }
        
    }
    
    func addSubscribers() {
        $searchText
            .combineLatest(self.$events) // anytime searchText or events change this will get published
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .map { (text, nearbyEvents) -> [Event] in
                
                guard !text.isEmpty else {
                    return nearbyEvents
                }
                
                // because Swift is case-sensitive
                let lowercasedText = text.lowercased()
                return nearbyEvents.filter { (event) -> Bool in
                     return event.title!.lowercased().contains(lowercasedText) || event.description!.lowercased().contains(lowercasedText)
                }
                
            }
            .sink { [weak self] (returnedEvents) in
                self?.filteredEvents = returnedEvents
                self?.updateMap()
            }
            .store(in: &cancellables)
            
    }
    
    func topMostController() -> UIViewController {
        var topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
        while(topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }
        return topController
        
    }
    
    func getTopMostViewController() -> UIViewController? {
        var topMostViewController = UIApplication.shared.keyWindow?.rootViewController

        while let presentedViewController = topMostViewController?.presentedViewController {
            topMostViewController = presentedViewController
        }

        return topMostViewController
    }

    func show_signIn() {
        DispatchQueue.main.async {
            self.getTopMostViewController()?.present(SignInView(), animated: true, completion: nil)
        }
    }
    
    @objc func postEvent() {
        if (!EventStore.shared.authenticated) {
            self.show_signIn()
        }
        else {
            let topVC = topMostController()
            
            let uiStoryboard = UIStoryboard(name: "CreateEvent", bundle: nil)
            
            let vcToPresent = uiStoryboard.instantiateViewController(withIdentifier: "CreateEventStoryboardID") as! CreateEventView
            
            topVC.present(vcToPresent, animated: true, completion: nil)
        }
    }
    
    @objc func toggleAR() {
        let topVC = topMostController()
        
        let arView = ARView()
        let vcToPresent = UINavigationController(rootViewController: arView)
        vcToPresent.modalPresentationStyle = .fullScreen
        topVC.present(vcToPresent, animated: true, completion: nil)

    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied:
            permissionDenied.toggle()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case
                .authorizedWhenInUse:
            manager.requestLocation()
        default:
            ()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        
        self.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        
        self.mapView.setRegion(self.region, animated: true)
        
        self.mapView.setVisibleMapRect(self.mapView.visibleMapRect, animated: true)
        
        
        // Get user's location
        self.lat = location.coordinate.latitude
        self.lon = location.coordinate.longitude
    }
    
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//                print("here as in there?")
//                guard let annotation = view.annotation as? MyAnnotation else { return }
//
//
//                let getURL = "https://54.87.128.240/events/" + annotation.event_id!
//
//                AF.request(getURL, method: .get).response { res in
//                    if let json = try? JSON(data: res.data!) {
//                        let event = json["event"].arrayValue
//                        GLOBAL_CURRENT_EVENT = Event(
//                            event_id: event[0].stringValue,
//                            title: event[1].stringValue,
//                            address: event[2].stringValue,
//                            latitude: "\(event[3].stringValue)",
//                            longitude: "\(event[4].stringValue)",
//                            start_time: event[5].stringValue,
//                            end_time:  event[6].stringValue,
//                            description: event[7].stringValue
//                        )
//
//
//
//
//
//
//                        let uiStoryboard = UIStoryboard(name: "EventInfoView", bundle: nil)
//
//                        guard let vc = uiStoryboard.instantiateViewController(withIdentifier: "EventInfoViewStoryboardID") as? EventInfoView else {return}
//
//                        let nc = UINavigationController(rootViewController: vc)
//
//                        if let pc = nc.presentationController as? UISheetPresentationController {
//                            pc.detents = [.medium()]
//                        }
//
//
////                        self.dismiss(animated: true, completion: nil)
//
//                        self.present(nc, animated: true, completion: nil)
//
////                        navigationContoller.viewControllers.last?.present(vc, animated: true)
//                    }
//                }
//
//        }
    
  
    
    
    
}
