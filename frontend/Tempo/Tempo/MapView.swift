//
//  MapView.swift
//  Tempo
//
//  Created by Hannah Salameh on 3/16/22.
//

import Foundation
import Combine
import UIKit
import SwiftUI
import GoogleMaps
import MapKit
import Alamofire
import SwiftyJSON

//class MyAnnotation: NSObject, MKAnnotation {
//    var event_id: String?
//    var coordinate: CLLocationCoordinate2D
//    let title: String?
//
//    init(event_id: String, coordinate: CLLocationCoordinate2D, title: String) {
//        self.event_id = event_id
//        self.coordinate = coordinate
//        self.title = title
//    }
//}
//
class MapView:UIViewController, ObservableObject, CLLocationManagerDelegate, MKMapViewDelegate {
    @Published var mapView = MKMapView()
    private let locManager = CLLocationManager()
    
    @Published var mapType : MKMapType = .standard
    
    @Published var searchText: String = ""
    
    @Published var events : [Event] = []
    
    
    var timer: Timer? = nil
//    let timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common, options: handleTimer).autoconnect()
    
    
    
    private var cancellables = Set<AnyCancellable>()
    
    var event: Event? = nil
    
//    override func loadView(){
//        print("in load view")
////        let mapView = MapView2()
//        mapView = MKMapView()
//        view = mapView
//    }
    
    var cancellable: Cancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Map Stuff
//        mapView.delegate = self
//        mapView.showsUserLocation = true
//
//        locManager.desiredAccuracy = kCLLocationAccuracyBest
//
//
//        locManager.delegate = self
//        locManager.startUpdatingLocation()
        
//        addSubscribers()
//        
//        // Setup timer to collect nearby events every second
//        cancellable = Timer.publish(every: 1, on: .main, in: .default)
//                .autoconnect()
//                .sink() {_ in
//                    self.updateNearbyEvents()
//                }
              
        
        let contentView = UIHostingController(rootView: MapHomeView())
        view.addSubview(contentView.view)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
//        addMapHomeView()
//        var marker: GMSMarker!
//
//        EventStore.shared.events.forEach {
//            let lat = Double( $0.latitude! )!
//            let lon = Double ($0.longitude! )!
//            marker = GMSMarker(position: CLLocationCoordinate2D(latitude: lat, longitude: lon))
//            marker.map = mapView
//            marker.userData = $0
////            marker.title = $0.title
//        }
//        addButtons()
//        addSearchBar()
        
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
        mapButton.isEnabled = false
        ARButton.isEnabled = true
        ARButton.addTarget(self, action:#selector(toggleAR), for: .touchUpInside)
        
        // add + button to view
        self.view.addSubview(button)
        self.view.addSubview(toggleContainer)
        
        toggleContainer.addArrangedSubview(mapButton)
        toggleContainer.addArrangedSubview(ARButton)
    }
    
    func addMapHomeView() {
//        let mapHomeView = HomeMapView(searchText: searchText)
        
        
        
//        let mapHomeViewController = UIHostingController(rootView: AnyView(mapHomeView))
        
//        addChild(contentView)
//
//
//
//        if let mhView = mapHomeViewController.view {
//            mhView.translatesAutoresizingMaskIntoConstraints = false
//
//            view.addSubview(mhView)
//            mhView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
//            mhView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
//            mhView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
//            mhView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
//            mhView.isOpaque = false
//
//            self.addChild(mapHomeViewController)
//        }
                                                        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = mapView.myLocation else {
//            return
//        }
//
//        mapView.camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 16.0)
//
//        manager.stopUpdatingLocation()
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
            description: event.description
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
    
//    struct SearchView: View {
//        @EnvironmentObject private var vm: MapViewModel
//
//        var body: some View {
//            VStack{
//                SearchBarView(searchText: $vm.searchText)
//            }
//
//        }
//
//
//    }
//
//    public class MapViewModel: ObservableObject {
//        @Published public var searchText: String = ""
//    }
    
}

//struct HomeMapView : View {
//    @State var searchText : String
//    
//    @StateObject var mapView = MapView()
//    
//    var body: some View {
//        
//        ZStack {
//            MapView3()
//                .environmentObject(mapView)
//                .ignoresSafeArea(.all, edges: all)
////                .environmentObject(mapData)
////                .ignoresSafeArea(.all, edges: .all)
//            VStack {
//                
//                VStack(spacing: 0) {
//                    HStack {
//                        Image(systemName: "magnifyingglass")
//                            .foregroundColor(searchText.isEmpty ? .gray : .black)
//                        
//                        TextField("Search for nearby events", text: $searchText)
//                            .disableAutocorrection(true)
//                            .keyboardType(.alphabet)
//                            .colorScheme(.light)
//                            .overlay(
//                                Image(systemName: "xmark.circle.fill")
//                                    .padding()
//                                    .foregroundColor(.gray)
//                                    .offset(x: 10)
//                                    .opacity(searchText.isEmpty ? 0.0 : 1.0)
//                                    .onTapGesture {
//                                        searchText = ""
//                                    }
//                                ,alignment: .trailing
//                            )
//                    }
//                    .padding(.vertical, 10)
//                    .padding(.horizontal)
//                    .background(Color.white)
//
//                }
//                .padding()
//                
//                
//                Spacer()
//                
//                VStack {
//                    // Creat Event
//                    Button(action: {}, label: {
//                        Image(systemName: "plus")
//                            .font(.title2)
//                            .padding(10)
//                            .background(Color.primary)
//                            .clipShape(Circle())
//                    })
//                    
//                    // Center on Location
//                    Button(action: {}, label: {
//                        Image(systemName: "location.fill")
//                            .font(.title2)
//                            .padding(10)
//                            .background(Color.primary)
//                            .clipShape(Circle())
//                    })
//                    
//                    // Toggle between satelite and regular map view
//                    Button(action: mapView.updateMapType, label: {
//                        Image(systemName: mapView.mapType == .standard ? "network" : "map")
//                            .font(.title2)
//                            .padding(10)
//                            .background(Color.primary)
//                            .clipShape(Circle())
//                    })
//                }
//                .frame(maxWidth: .infinity, alignment: .trailing)
//                .padding()
//            }
//        }
//        
//    }
//}
