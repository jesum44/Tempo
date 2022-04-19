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
import SwiftyJSON

struct SwiftUIEditEventView: View {
    // for dismissing the view
    @ObservedObject var delegate: SheetDismisserProtocol
    // the event that has been most recently tapped
    var event: Event = GLOBAL_CURRENT_EVENT
    
    @State private var isShareViewPresented: Bool = false
    @State var title: String = ""
    @State var description: String = ""
    @State var address: String = ""
    @State var startTime = Date()
    @State var endTime = Date()
    @State var toDeleteEvent: Int? = nil
    @State var errorMessage = ""
    var body: some View {
        Form {
            Section(header: Text("Title")
                        .font(.title3)
                        .foregroundColor(.black)) {
                TextField("", text: $title).onAppear{self.title = title == "" ? event.title! : title}
                .submitLabel(.done)
            }
            Section(header: Text("Description")
                        .font(.title3)
                        .foregroundColor(.black)) {
                TextField("", text: $description).onAppear{self.description = description == "" ? event.description! : description}
                .submitLabel(.done)
            }
            Section(header: Text("Address")
                        .font(.title3)
                        .foregroundColor(.black)) {
                TextField("", text: $address).onAppear{self.address = address == "" ? event.address! : address}
                .submitLabel(.done)
            }
            Section {
                DatePicker("Starts At", selection: $startTime,
                           displayedComponents: [.date, .hourAndMinute]).onAppear {
                    self.startTime = (toDate(isoDate: event.start_time! + "+0000")!)
                }
                DatePicker("Ends At", selection: $endTime,
                           displayedComponents: [.date, .hourAndMinute]).onAppear {
                    self.endTime = (toDate(isoDate: event.end_time! + "+0000")!)
                }
            }
            Section {
                HStack {
                    Spacer()
                    Button("Done") {
                        Task {
                            await handleDone(title: title, description: description, address: address, startTime: startTime, endTime: endTime, eventId: event.event_id!)
                            closeModal(delegate: self.delegate)
                        }
                    }
                    
                    Spacer()
                }
            }
            Section {
                // delete button
                HStack {
                    Spacer()
                    NavigationLink(destination: SwiftUIDeleteEventView(delegate: delegate), tag: 1, selection: $toDeleteEvent) {
                        Button("Delete Event") {
                            self.toDeleteEvent = 1
                        }
                    }
                    Spacer()
                }
            }
        }
        .navigationBarTitle("Edit Event")
        .navigationBarBackButtonHidden(true)
    }
}

func EditEvent(eventID: String, delegate: SheetDismisserProtocol) {
    // delete event from database with DELETE http request
    let url = "https://54.87.128.240/events/" + eventID + "/"
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

func editEventPutRequest(_ parameters: [String: String], eventId: String) async -> [String] {
    
    let url = "https://54.87.128.240/events/" + eventId + "/"
    guard let encoded = try? JSONEncoder().encode(parameters) else {
        print("JSONEncoder error")
        return ["Json Encoding"]
    }
    
    var request = URLRequest(url: URL(string: url)!)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "PUT"
    do {
        let (data, res) = try await URLSession.shared.upload(for: request, from: encoded)
        let httpRes = res as! HTTPURLResponse
        if httpRes.statusCode != 201 {
            print("PUT request status code was not 201! It was \(httpRes.statusCode)")
            return ["Status Code", "\(httpRes.statusCode)"]
        }
    } catch {
        print("PUT Request error")
        return ["Put Request"]
    }
    
    // no errors, everything worked, return [false]
    return []
}

func handleDone(title: String, description: String, address: String, startTime: Date, endTime: Date, eventId: String)  async {
    let parameters: [String: String] = [
        "title": title,
        "description": description,
        "address": address,
        "start_time":
            String(Int(startTime.timeIntervalSince1970)),
        "end_time":
            String(Int(endTime.timeIntervalSince1970)),
    ]
    let err = await editEventPutRequest(parameters, eventId: eventId)
    
    if !err.isEmpty {
       //error occured
    } else {
        await GLOBAL_AR_VIEW?.getNearbyEvents(nil)
    }
}

func closeModal(delegate: SheetDismisserProtocol) {
    delegate.dismiss()
}
