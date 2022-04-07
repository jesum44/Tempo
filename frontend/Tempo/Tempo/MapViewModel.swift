//
//  MapViewModel.swift
//  Tempo
//
//  Created by Casey Wentland on 4/4/22.
//
import Alamofire
import Combine
import Foundation
import MapKit
import SwiftUI
import CoreLocation
import SwiftyJSON

class MyAnnotation: NSObject, MKAnnotation {
    var event_id: String?
    var coordinate: CLLocationCoordinate2D
    let title: String?
    
    init(event_id: String, coordinate: CLLocationCoordinate2D, title: String) {
        self.event_id = event_id
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
    
    @Published var selectedEvent: Event?
        
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
            if !self.events.contains(where: { $0.event_id == annotation.event_id }) {
                mapView.removeAnnotation(annotation)
            }
        }
                
        // add events to map that are in self.events and not already on the map
        customAnnotations = self.mapView.annotations.filter({!($0 is MKUserLocation)}) as! [MyAnnotation]
        
        for event in self.events {
            if !customAnnotations.contains(where: { $0.event_id == event.event_id }) {
                
                let lat = Double( event.latitude! )!
                let lon = Double( event.longitude! )!
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let pointAnnotation = MyAnnotation(event_id: event.event_id ?? "", coordinate: coordinate, title: event.title ?? "")
                
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
                self?.events = returnedEvents
                self?.updateMap()
            }
            .store(in: &cancellables)
            
    }
    
    func searchQuery() {
        let locManager = CLLocationManager()
        
        guard let currentLocation = locManager.location else {
            print("Error: ARView:getNearbyEvents - Unable to acquire user's location!")
            return
        }
        
        EventStore.shared.getEvents(
            lat: currentLocation.coordinate.latitude,
            lon: currentLocation.coordinate.longitude
        ) { }
        
        self.events = EventStore.shared.events
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
                print("here")
                guard let annotation = view.annotation as? MyAnnotation else { return }
    
    
                let getURL = "https://54.175.206.175/events/" + annotation.event_id!
    
                AF.request(getURL, method: .get).response { res in
                    if let json = try? JSON(data: res.data!) {
                        let event = json["event"].arrayValue
                        GLOBAL_CURRENT_EVENT = Event(
                            event_id: event[0].stringValue,
                            title: event[1].stringValue,
                            address: event[2].stringValue,
                            latitude: "\(event[3].stringValue)",
                            longitude: "\(event[4].stringValue)",
                            start_time: event[5].stringValue,
                            end_time:  event[6].stringValue,
                            description: event[7].stringValue
                        )
    
    
    
    
    
    
                        let uiStoryboard = UIStoryboard(name: "EventInfoView", bundle: nil)
    
                        guard let vc = uiStoryboard.instantiateViewController(withIdentifier: "EventInfoViewStoryboardID") as? EventInfoView else {return}
    
                        let nc = UINavigationController(rootViewController: vc)
    
                        if let pc = nc.presentationController as? UISheetPresentationController {
                            pc.detents = [.medium()]
                        }
    
    
//                        self.dismiss(animated: true, completion: nil)
    
                        self.present(nc, animated: true, completion: nil)
    
//                        navigationContoller.viewControllers.last?.present(vc, animated: true)
                    }
                }
            
        }
    
  
    
    
    
}
