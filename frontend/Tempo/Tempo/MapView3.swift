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
    class Coordinator: NSObject, MKMapViewDelegate {
        func topMostController() -> UIViewController {
            var topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            while(topController.presentedViewController != nil) {
                topController = topController.presentedViewController!
            }
            return topController
            
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
                
                

                    let topVC = self.topMostController()
                    
                    let uiStoryboard = UIStoryboard(name: "EventInfoView", bundle: nil)
                    
                    let vcToPresent = uiStoryboard.instantiateViewController(withIdentifier: "EventInfoViewStoryboardID") as! EventInfoView

                    topVC.present(vcToPresent, animated:true, completion: nil)
                    
//                    let nc = UINavigationController(rootViewController: vc)
//
//                    if let pc = nc.presentationController as? UISheetPresentationController {
//                        pc.detents = [.medium()]
//                    }
                        
                    
//                    self.dismiss(animated: true, completion: nil)
//                    
//                    self.present(nc, animated: true, completion: nil)
//                    
//                    navigationContoller.viewControllers.last?.present(vc, animated: true)
                }
            }
        }
    }
}


