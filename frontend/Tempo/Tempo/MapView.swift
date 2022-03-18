//
//  MapView.swift
//  Tempo
//
//  Created by Hannah Salameh on 3/16/22.
//

import Foundation
import UIKit
import SwiftUI

final class MapView:UIViewController {
    override func loadView(){
        print("in load view")
        let mapView = MapView2()
        view = mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    
    
}
