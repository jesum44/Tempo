//
//  MapHomeView.swift
//  Tempo
//
//  Created by Casey Wentland on 4/4/22.
//

import Foundation
import SwiftUI
import CoreLocation
import UIKit
import MapKit

struct MapHomeView: View {
    let timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
    @StateObject var mapData = MapViewModel()
    @State var locationManager = CLLocationManager()
    @State var predictableValues: Array<String> = ["Event A", "Event B", "Cam's party", "Frat event"]
    @State var predictedValue: Array<String> = []
    
    var body: some View {
        
        ZStack {
            MapView3()
                .environmentObject(mapData)
                .ignoresSafeArea(.all, edges: .all)
            VStack {
                
                VStack(spacing: 0) {
                    
                    PredictingTextField(predictableValues: self.$predictableValues, predictedValues: self.$predictedValue, textFieldInput: self.$mapData.searchText)
                        .cornerRadius(0.75)
                    
                    if !mapData.searchText.isEmpty {
                        ScrollView {
                            ForEach(self.predictedValue, id: \.self) { value in
                                Text("\(value)")
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        ///Show location on map
                                    }
                                
                                Divider()
                            }
                        }
                        .background(Color.white)
                        .opacity(0.75)
                        .cornerRadius(10)
                        .frame(maxHeight: 250)
                    }
                }
                
                .padding()
                
                
                Spacer()
                
                
                Group {
                    if (mapData.searchText.isEmpty) {
                        VStack {
                            // Create Event
                            Button(action: mapData.postEvent, label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .padding(10)
                                    .background(Color.primary)
                                    .clipShape(Circle())
                                
                            })
                            .font(.system(size: 10))
                            
                            // Toggle AR
                            Button(action: mapData.toggleAR, label: {
                                Image(systemName: "binoculars.fill")
                                    .font(.title)
                                    .padding(10)
                                    .background(Color.primary)
                                    .clipShape(Circle())
                            })
                            .font(.system(size: 10))
                            
                            // Center on Location
                            Button(action: {}, label: {
                                Image(systemName: "location.fill")
                                    .font(.title)
                                    .padding(10)
                                    .background(Color.primary)
                                    .clipShape(Circle())
                            })
                            .font(.system(size: 10))
                            
                            // Toggle between satelite and regular map view
                            Button(action: mapData.updateMapType, label: {
                                Image(systemName: mapData.mapType == .standard ? "network" : "map")
                                    .font(.title)
                                    .padding(10)
                                    .background(Color.primary)
                                    .clipShape(Circle())
                            })
                            .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(7.5)
                    }
                
                    else {
                        HStack {
                            // Create Event
                            Button(action: mapData.postEvent, label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .padding(10)
                                    .background(Color.primary)
                                    .clipShape(Circle())
                                
                            })
                            .font(.system(size: 10))
                            
                            // Toggle AR
                            Button(action: mapData.toggleAR, label: {
                                Image(systemName: "binoculars.fill")
                                    .font(.title)
                                    .padding(10)
                                    .background(Color.primary)
                                    .clipShape(Circle())
                            })
                            .font(.system(size: 10))
                            
                            // Center on Location
                            Button(action: {}, label: {
                                Image(systemName: "location.fill")
                                    .font(.title)
                                    .padding(10)
                                    .background(Color.primary)
                                    .clipShape(Circle())
                            })
                            .font(.system(size: 10))
                            
                            // Toggle between satelite and regular map view
                            Button(action: mapData.updateMapType, label: {
                                Image(systemName: mapData.mapType == .standard ? "network" : "map")
                                    .font(.title)
                                    .padding(10)
                                    .background(Color.primary)
                                    .clipShape(Circle())
                            })
                            .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(7.5)
                    }
                
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
    }
}


struct PredictingTextField: View {
    
    /// All possible predictable values. Can be only one.
    @Binding var predictableValues: Array<String>
    
    /// This returns the values that are being predicted based on the predictable values
    @Binding var predictedValues: Array<String>
    
    /// Current input of the user in the TextField. This is Binded as perhaps there is the urge to alter this during live time. E.g. when a predicted value was selected and the input should be cleared
    @Binding var textFieldInput: String
    
    /// The time interval between predictions based on current input. Default is 0.1 second. I would not recommend setting this to low as it can be CPU heavy.
    @State var predictionInterval: Double?
    
    /// Placeholder in empty TextField
    var textFieldTitle: String?
    
    @State private var isBeingEdited: Bool = false
    
    init(predictableValues: Binding<Array<String>>, predictedValues: Binding<Array<String>>, textFieldInput: Binding<String>, textFieldTitle: String? = "", predictionInterval: Double? = 0.1){
        
        self._predictableValues = predictableValues
        self._predictedValues = predictedValues
        self._textFieldInput = textFieldInput
        
        self.textFieldTitle = textFieldTitle
        self.predictionInterval = predictionInterval
    }
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(self.textFieldInput.isEmpty ? .gray : .black)
                .opacity(self.textFieldInput.isEmpty ? 0.75 : 1.0)
            
            TextField("Search for nearby events...", text: self.$textFieldInput, onEditingChanged: { editing in self.realTimePrediction(status: editing)}, onCommit: { self.makePrediction()})
                .disableAutocorrection(true)
                .keyboardType(.alphabet)
                .colorScheme(.light)
                .overlay(
                    Image(systemName: "xmark.circle.fill")
                        .padding()
                        .foregroundColor(.gray)
                        .offset(x: 10)
                        .opacity(self.textFieldInput.isEmpty ? 0.0 : 1.0)
                        .onTapGesture {
                            self.textFieldInput = ""
//                                        mapData.addSubscribers()
                            // Possibly call get events again here
                        }
                    ,alignment: .trailing
                )
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(.white)
        .opacity(self.textFieldInput.isEmpty ? 0.75 : 1.0)
        .cornerRadius(0.10)
        
//        TextField(self.textFieldTitle ?? "", text: self.$textFieldInput, onEditingChanged: { editing in self.realTimePrediction(status: editing)}, onCommit: { self.makePrediction()})
    }
    
    /// Schedules prediction based on interval and only a if input is being made
    private func realTimePrediction(status: Bool) {
        self.isBeingEdited = status
        if status == true {
            Timer.scheduledTimer(withTimeInterval: self.predictionInterval ?? 1, repeats: true) { timer in
                self.makePrediction()
                
                if self.isBeingEdited == false {
                    timer.invalidate()
                }
            }
        }
    }
    
    /// Capitalizes the first letter of a String
    private func capitalizeFirstLetter(smallString: String) -> String {
        return smallString.prefix(1).capitalized + smallString.dropFirst()
    }
    
    /// Makes prediciton based on current input
    private func makePrediction() {
        self.predictedValues = []
        if !self.textFieldInput.isEmpty{
            for value in self.predictableValues {
                if self.textFieldInput.split(separator: " ").count > 1 {
                    self.makeMultiPrediction(value: value)
                } else {
                    if value.contains(self.textFieldInput) || value.contains(self.capitalizeFirstLetter(smallString: self.textFieldInput)){
                        if !self.predictedValues.contains(String(value)) {
                            self.predictedValues.append(String(value))
                        }
                    }
                }
            }
        }
    }
    
    /// Makes predictions if the input String is splittable
    private func makeMultiPrediction(value: String) {
        for subString in self.textFieldInput.split(separator: " ") {
            if value.contains(String(subString)) || value.contains(self.capitalizeFirstLetter(smallString: String(subString))){
                if !self.predictedValues.contains(value) {
                    self.predictedValues.append(value)
                }
            }
        }
    }
}
                  


struct MapHomeView_Previews: PreviewProvider {
    static var previews: some View {
        MapHomeView()
    }
}
