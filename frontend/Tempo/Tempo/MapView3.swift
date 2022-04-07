//
//  MapView3.swift
//  Tempo
//
//  Created by Casey Wentland on 4/4/22.
//

import Foundation
import SwiftUI
import MapKit
import Alamofire
import SwiftyJSON
import UIKit


struct MapView3: UIViewRepresentable {
    
    @EnvironmentObject var mapData: MapViewModel
    
    func makeCoordinator() -> Coordinator {
        return MapView3.Coordinator()
    }
    func makeUIView(context: Context) -> MKMapView {
        let view = mapData.mapView
        
        view.showsUserLocation = true
        view.delegate = context.coordinator
        
//        let annotationTap = UITapGestureRecognizer(target: self, action: Selector("tapRecognized"))
//        annotationTap.numberOfTapsRequired = 1
//        view.addGestureRecognizer(annotationTap)
        
        return view
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        
    }
    class Coordinator: UIViewController, MKMapViewDelegate {
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
    }
}


