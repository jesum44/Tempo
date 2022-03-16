//
//  EventStore.swift
//  Tempo
//
//  Created by Justin Schneider on 3/16/22.
//

import Foundation

final class EventStore {
    
    static let shared = EventStore() // create one instance of the class to be shared
    private init() {}                // and make the constructor private so no other
                                     // instances can be created
    var events = [Event]()
    private let nFields = Mirror(reflecting: Event()).children.count

    private let serverUrl = "https://34.74.252.207/"

    
    func postEvent(_ event: Event) {
            let jsonObj = ["name": event.name,
                           "address": event.address,
                           "time": event.time,
                           "description": event.description]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
                print("postEvent: jsonData serialization error")
                return
            }
                    
            guard let apiUrl = URL(string: serverUrl+"events/") else {
                print("postEvents: Bad URL")
                return
            }
            
            var request = URLRequest(url: apiUrl)
            request.httpMethod = "POST"
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let _ = data, error == nil else {
                    print("postEvent: NETWORKING ERROR")
                    return
                }
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    print("postChatt: HTTP STATUS: \(httpStatus.statusCode)")
                    return
                }
            }.resume()
        }
    
    func getEvents(_ completion: ((Bool) -> ())?) {
            guard let apiUrl = URL(string: serverUrl+"events/") else {
                print("getEvents: Bad URL")
                return
            }
            
            var request = URLRequest(url: apiUrl)
            request.httpMethod = "GET"

            URLSession.shared.dataTask(with: request) { data, response, error in
                var success = false
                defer { completion?(success) }
                
                guard let data = data, error == nil else {
                    print("getEvents: NETWORKING ERROR")
                    return
                }
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    print("getEvents: HTTP STATUS: \(httpStatus.statusCode)")
                    return
                }
                
                guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String:Any] else {
                    print("getEvents: failed JSON deserialization")
                    return
                }
                let eventsReceived = jsonObj["chatts"] as? [[String?]] ?? []
                self.events = [Event]()
                for eventEntry in eventsReceived {
                    if eventEntry.count == self.nFields {
                        self.events.append(Event(name: eventEntry[0],
                                            address: eventEntry[1],
                                            time: eventEntry[2],
                                                 eventId: eventEntry[3],
                                                 description: eventEntry[4],
                                                longititude: eventEntry[5],
                                                latitude: eventEntry[6]))
                    } else {
                        print("getEvents: Received unexpected number of fields: \(eventEntry.count) instead of \(self.nFields).")
                    }
                }
                success = true // for completion(success)
            }.resume()
        }
}
