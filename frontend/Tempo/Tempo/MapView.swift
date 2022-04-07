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
import MapKit
import iOSDropDown
import Combine


final class MapView:UIViewController, ObservableObject, CLLocationManagerDelegate, MKMapViewDelegate {
    @Published var mapView = MKMapView()
    private let locManager = CLLocationManager()
    
    @Published var mapType : MKMapType = .standard
    
    @Published var searchText: String = ""
    
    @Published var events : [Event] = []
    let dropDown = DropDown()
//    @EnvironmentObject var mapData: MapViewModel
    
    @StateObject var mapData = MapViewModel()
    
    var timer: Timer? = nil
//    let timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common, options: handleTimer).autoconnect()
    

    
    
    var event: Event? = nil
    
    override func loadView(){
        mapView = MKMapView()
        view = mapView
    }
    
    var cancellable: Cancellable?
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Map Stuff
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        
        
        locManager.delegate = self
        locManager.startUpdatingLocation()
        
        addSubscribers()
        
        
        //set default zoom of map view
        let center = CLLocationCoordinate2D(
            latitude: Double(locManager.location!.coordinate.latitude),
            longitude: Double(locManager.location!.coordinate.longitude)
        )
        
        let region = MKCoordinateRegion(center:center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        mapView.setRegion(region, animated:false)
        
        // Setup timer to collect nearby events every second
        cancellable = Timer.publish(every: 1, on: .main, in: .default)
                .autoconnect()
                .sink() {_ in
                    self.updateNearbyEvents()
                }
        
        let buttonFactory = CreateEventsButton()
        let frame = self.view.safeAreaLayoutGuide
        
        let button = buttonFactory.createButton(frame:frame)
        button.addTarget(self, action: #selector(createEventButtonTapped), for: .touchUpInside)
        
        let toggleFactory = createToggle()
        let toggleContainer = toggleFactory.createButtonContainer(screenHeight: screenHeight)
        let mapButton = toggleFactory.createMapButton(screenHeight: screenHeight)
        let ARButton = toggleFactory.createARButton(screenHeight: screenHeight)
        mapButton.isEnabled = false
        ARButton.isEnabled = true
        ARButton.addTarget(self, action:#selector(toggleAR), for: .touchUpInside)
                
        
    /* START ADD SEARCHBAR + FUNCTIONALITIES */
       navigationItem.titleView = dropDown
       dropDown.sizeToFit()
       let imageView = UIImageView()
       let glass = UIImage(systemName: "magnifyingglass")
       imageView.image = glass
       imageView.tintColor = .gray
       imageView.frame = CGRect(x: 10, y: 5, width: 45, height: 20)
       imageView.contentMode = .scaleAspectFit

       dropDown.isSearchEnable = true
       dropDown.leftViewMode = .always
       dropDown.leftView = imageView
       dropDown.borderWidth = 0.1
       dropDown.borderStyle = UITextField.BorderStyle.roundedRect
       dropDown.textColor = .black
       dropDown.arrowColor = .clear
       dropDown.selectedRowColor = .black
       dropDown.checkMarkEnabled = false
       dropDown.rowBackgroundColor = .black
       dropDown.placeholder = "Search Events"
       dropDown.frame.size.width = 300
       dropDown.frame.size.height = 4
       dropDown.backgroundColor = .white
       var events = [String]()
       for event in EventStore.shared.events{
           //print(event.title!)
           events.append(event.title!)
       }
       events.sort()
       dropDown.optionArray = events
       dropDown.didSelect{(selectedText, index, id) in
           for event in EventStore.shared.events{
               if (event.title! == selectedText){
                   self.handleEventMarkerTapped(event: event)
               }
           }
       }
       /* END ADD SEARCHBAR + FUNCTIONALITIES */
        
        self.view.addSubview(button)
        self.view.addSubview(toggleContainer)
        
        toggleContainer.addArrangedSubview(mapButton)
        toggleContainer.addArrangedSubview(ARButton)
    }
    
    func handleTimer(_ timer: Timer) {
        updateNearbyEvents()
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
    
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("here")
        guard let annotation = view.annotation as? MyAnnotation else { return }
        
        
        let getURL = "https://54.175.206.175/events/" + annotation.event_id!

        AF.request(getURL, method: .get).response { res in
            if let json = try? JSON(data: res.data!) {
                print(json)
                let event = json["event"].arrayValue
                print(event)
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
                
            

            self.present(nc, animated: true, completion: nil)
                
            }
        }
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
            description: event.description
        )
        let coord = CLLocationCoordinate2D(latitude:Double(event.latitude!)!, longitude: Double(event.longitude!)!)
        mapView.setCenter(coord, animated: true)
        
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
