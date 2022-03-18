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

    private let serverUrl = "https://54.175.206.175/"

    
    func postEvent(_ event: Event) {
            let jsonObj = ["name": event.title,
                           "address": event.address,
                           "time": event.start_time,
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
    
    func getEvents(onCompleted: @escaping () -> ()) {
        let lat = 44.0
        let lon = -83.0
            guard var apiUrl = URLComponents(string: serverUrl+"events") else {
                print("getEvents: Bad URL")
                return
            }
        apiUrl.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "results", value: String(10))
        ]
        
        var request = URLRequest(url: apiUrl.url!)
            request.httpMethod = "GET"

            URLSession.shared.dataTask(with: request) { data, response, error in
               
                
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
                let eventsReceived = jsonObj["events"] as? [[Any]] ?? []
                self.events = [Event]()
                for eventEntry in eventsReceived {
                    if eventEntry.count == self.nFields {
                        self.events.append(Event(event_id: eventEntry[0] as! String?,
                                                 title: eventEntry[1] as! String?,
                                                 address: eventEntry[2] as! String?,
                                                 latitude: "\(eventEntry[3])",
                                                 longititude: "\(eventEntry[4]))",
                                                 start_time: eventEntry[5] as! String?,
                                                 end_time:  eventEntry[6] as! String?,
                                                 description: eventEntry[7] as! String?))
                    } else {
                        print("getEvents: Received unexpected number of fields: \(eventEntry.count) instead of \(self.nFields).")
                    }
                }
                onCompleted()
            }.resume()
        }
}
