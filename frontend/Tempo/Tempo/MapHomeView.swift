//
//  MapHomeView.swift
//  Tempo
//
//  Created by Casey Wentland on 4/4/22.
//

import SwiftUI
import CoreLocation
import UIKit
import MapKit

struct MapHomeView: View {
    let timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
    @StateObject var mapData = MapViewModel()
    @State var locationManager = CLLocationManager()
    
    var body: some View {
        
        ZStack {
            MapView3()
                .environmentObject(mapData)
                .ignoresSafeArea(.all, edges: .all)
            VStack {
                
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(mapData.searchText.isEmpty ? .gray : .black)
                        
                        TextField("Search for nearby events", text: $mapData.searchText)
                            .disableAutocorrection(true)
                            .keyboardType(.alphabet)
                            .colorScheme(.light)
                            .overlay(
                                Image(systemName: "xmark.circle.fill")
                                    .padding()
                                    .foregroundColor(.gray)
                                    .offset(x: 10)
                                    .opacity(mapData.searchText.isEmpty ? 0.0 : 1.0)
                                    .onTapGesture {
                                        mapData.searchText = ""
//                                        mapData.addSubscribers()
                                        // Possibly call get events again here
                                    }
                                ,alignment: .trailing
                            )
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(Color.white)
                    
                    
                    // Display Search Possibilities
                    
//                    GeometryReader { geometry in
//                        ScrollView {
//
//                            VStack(spacing: 15) {
//                                ForEach(results, id: \.event_id) { event in
//                                    Text(event.title!)
//                                        .foregroundColor(.black)
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                        .padding(.leading)
//                                    Divider()
//                                }
//                            }
//                            .padding(.top)
//                            .searchable(text: $mapData.searchText)
//                        }
//                        .frame(maxHeight: geometry.size.height >= .infinity ? .infinity : geometry.size.height)
//                        .background(Color.white)
//                    }
                    
                    
                    
                }
                
                .padding()
                
                
                Spacer()
                
                VStack {
                    // Creat Event
                    Button(action: {}, label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .padding(10)
                            .background(Color.primary)
                            .clipShape(Circle())
                    })
                    
                    // Center on Location
                    Button(action: {}, label: {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding(10)
                            .background(Color.primary)
                            .clipShape(Circle())
                    })
                    
                    // Toggle between satelite and regular map view
                    Button(action: mapData.updateMapType, label: {
                        Image(systemName: mapData.mapType == .standard ? "network" : "map")
                            .font(.title2)
                            .padding(10)
                            .background(Color.primary)
                            .clipShape(Circle())
                    })
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
            }
        }
        .onAppear(perform: {
            locationManager.delegate = mapData
            locationManager.requestWhenInUseAuthorization()
            mapData.addSubscribers()
        })
        .alert(isPresented: $mapData.permissionDenied, content: {
            Alert(title: Text("Permission Denied"), message:
                    Text("Please Enable Permission In App Settings"), dismissButton: .default(Text("Goto Settings"), action: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
        })
        .onReceive(timer) { _ in
            mapData.updateNearbyEvents()
        }
    }
    
    var results: [Event] {
        if mapData.searchText.isEmpty {
            return mapData.events
        }
        else {
            return mapData.events.filter {
                $0.title!.contains(mapData.searchText)}
        }
    }
}
                  


struct MapHomeView_Previews: PreviewProvider {
    static var previews: some View {
        MapHomeView()
    }
}
