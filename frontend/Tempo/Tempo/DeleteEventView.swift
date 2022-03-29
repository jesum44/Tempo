//
//  DeleteEventView.swift
//  Tempo
//
//  Created by Justin Schneider on 3/28/22.
//

import Foundation
import UIKit
import SwiftUI
import Alamofire

struct SwiftUIDeleteEventView: View {
    // for dismissing the view
    //@ObservedObject var delegate: SheetDismisserProtocol
    // the event that has been most recently tapped
    var event: Event = GLOBAL_CURRENT_EVENT
    
    @State private var isShareViewPresented: Bool = false
    @ObservedObject var delegate: SheetDismisserProtocol
    
    var body: some View {
            VStack {
                VStack {
                    HStack {
                        // title
                        VStack {
                            Text(event.title!)
                                .font(.largeTitle.bold())
                                .foregroundColor(.red)
                                .padding(.bottom, 5)
                        }
                    }
                    HStack {
                        // Are you sure you want to delete this event
                        VStack {
                            Text("Are you sure you want to delete this event?")
                                .font(.title3)
                                .foregroundColor(.black)
                                .padding(.bottom, 120)
                               
                        }
                        
                    }
                    HStack {
                        Spacer().frame(width: sideSpacerWidth)
                        
                        // Cancel button
                        Button(action: {
                            cancelDeletion(delegate: self.delegate)
                        }) {
                            Text("Cancel")
                            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                            .buttonStyle(PlainButtonStyle())
                            .background(.black)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                            .font(.title.bold())
                            .padding(.bottom, 5)
                    
                        }
                        
                        
                        Spacer().frame(width: sideSpacerWidth)
                    }
                    HStack {
                        Spacer().frame(width: sideSpacerWidth)
                        
                        // Cancel button
                        Button(action: {
                            deleteEvent(eventID: event.event_id!, delegate: self.delegate)
                        }) {
                            Text("Delete")
                            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                            .buttonStyle(PlainButtonStyle())
                            .background(.red)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                            .font(.title.bold())
                            .padding(.bottom, 100)
                        }
                        
                        
                        Spacer().frame(width: sideSpacerWidth)
                    }
                }
                Spacer()
            }
    }
}

func deleteEvent(eventID: String, delegate: SheetDismisserProtocol) {
    // delete event from database with DELETE http request
    let url = "https://54.175.206.175/events/" + eventID
    AF.request(url, method: .delete).response { res in
        debugPrint(res)
    }
    
    // call getNearbyEvents to refresh visible popups
    GLOBAL_AR_VIEW?.getNearbyEvents(nil)
    
    print("event deleted ~ \(eventID)")
    
    // close modal
    delegate.dismiss()
}

func cancelDeletion(delegate: SheetDismisserProtocol) {
    // close modal
    print("!!!!!!!!!!!!!!!!!!!")
    delegate.dismiss()
}

