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

struct SwiftUIEditEventView: View {
    // for dismissing the view
    //@ObservedObject var delegate: SheetDismisserProtocol
    // the event that has been most recently tapped
    var event: Event = GLOBAL_CURRENT_EVENT
    
    @State private var isShareViewPresented: Bool = false
    @ObservedObject var delegate: SheetDismisserProtocol
  

    var body: some View {
        Form {
            Section(header: Text("Title")
                        .font(.title3)
                        .foregroundColor(.black)) {
                TextField("", text: .constant(event.title!))
            }
            Section(header: Text("Description")
                        .font(.title3)
                        .foregroundColor(.black)) {
                TextField("", text: .constant(event.description!))
            }
            Section(header: Text("Address")
                        .font(.title3)
                        .foregroundColor(.black)) {
                TextField("", text: .constant(event.address!))
            }
            Section {
                DatePicker("Starts At", selection: .constant(toDate(isoDate: event.start_time! + "+0000")!),
                           displayedComponents: [.date, .hourAndMinute])
                DatePicker("Ends At", selection: .constant(toDate(isoDate: event.end_time! + "+0000")!),
                           displayedComponents: [.date, .hourAndMinute])
            }
            Section {
                HStack {
                    Spacer()
                    Button("Done") {
                        Task {
//                            toDate(isoDate: event.start_time! + "+0000")
//                            print("!!!!!")
//                            toDate(isoDate: "2016-04-14T10:44:00+0000")
                            
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

func EditEvent(eventID: String, delegate: SheetDismisserProtocol) {
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

func cancelEdit(delegate: SheetDismisserProtocol) {
    // close modal
    delegate.dismiss()
}

func toDate(isoDate: String)-> Date?{
    let dateFormatter = ISO8601DateFormatter()
    let date = dateFormatter.date(from:isoDate)!
    return date
    }
