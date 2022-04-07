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
