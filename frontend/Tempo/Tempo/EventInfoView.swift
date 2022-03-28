//
//  EventInfoView.swift
//  Tempo
//
//  Created by Krithik Vallem on 3/26/22.
//

import Foundation
import UIKit
import SwiftUI // the form is made in SwiftUI, and embedded into UIKit's UIViewController
import SwiftyJSON



class EventInfoView: UIViewController {
    
    // function that runs when "Back" is tapped
    @objc func closeView(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // add x button to top right in case user's don't want to create event
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(self.closeView))
        
        // add the swift ui view to the current view
        addSwiftUIEventInfoView()
    }
    
    // Embedding SwiftUI inside UIViewController
    // https://stackoverflow.com/a/63502951
    func addSwiftUIEventInfoView() {
        // this lets the form dismiss the view once event is created
        // https://stackoverflow.com/a/59348371
        let delegate = SheetDismisserProtocol()
        
        let eventInfoView = SwiftUIEventInfoView(delegate: delegate)
        let eventInfoViewController = UIHostingController(rootView: AnyView(eventInfoView))
        delegate.host = eventInfoViewController
        
        if let eiView = eventInfoViewController.view {
            eiView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(eiView)
            eiView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
            eiView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
            eiView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
            eiView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true

            self.addChild(eventInfoViewController)
        }
        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

// spacing on left/right sides of ui
let sideSpacerWidth = 20.0;
// spacing between rows
let vstackSpacing = 20.0;

// The actual form
// https://www.simpleswiftguide.com/swiftui-form-tutorial-how-to-create-and-use-form-in-swiftui/
struct SwiftUIEventInfoView: View {
    // for dismissing the view
    @ObservedObject var delegate: SheetDismisserProtocol
    // the event that has been most recently tapped
    var event: Event = GLOBAL_CURRENT_EVENT
    
    @State private var isShareViewPresented: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: vstackSpacing) {
                    HStack {
                        Spacer().frame(width: sideSpacerWidth)
                        // title
                        VStack(alignment: .leading) {
                            Text(event.title!)
                                .font(.title)
                        }
                        Spacer()
                        // share button
                        VStack(alignment: .trailing) {
                            Button(action: {
                                self.isShareViewPresented = true
                            }) {
                                Label("", systemImage: "paperplane")
                            }
                            .sheet(isPresented: $isShareViewPresented, onDismiss: {
                                print("Share Sheet Dismissed")
                            }, content: {
                                ActivityViewController(itemsToShare: [
                                    getShareEventMessage(event)
                                ])
                            })
                        }
                        Spacer().frame(width: sideSpacerWidth)
                    }
                    
                    HStack {
                        Spacer().frame(width: sideSpacerWidth)
                        // address
                        VStack(alignment: .leading) {
                            Text(event.address!)
                        }
                        Spacer()
                        // edit button
                        VStack(alignment: .trailing) {
                            Button("Edit Event") {
                                editEvent(event.event_id!)
                            }
                        }
                        Spacer().frame(width: sideSpacerWidth)
                    }
                    
                    HStack {
                        Spacer().frame(width: sideSpacerWidth)
                        // time
                        VStack(alignment: .leading) {
                            Text(formatTimeString(event.start_time!))
                        }
                        Spacer()
                        // delete button
                        VStack(alignment: .trailing) {
                            Button("Delete Event") {
                                deleteEvent(event.event_id!)
                            }
                        }
                        Spacer().frame(width: sideSpacerWidth)
                    }
                    
                    
                    HStack {
                        Spacer().frame(width: sideSpacerWidth)
                        // description
                        VStack(alignment: .leading, spacing: vstackSpacing) {
                            Text(event.description!)
                        }
                        // no width to push description to left just like in Figma
                        Spacer()
                    }
                    
                    HStack {
                        Spacer().frame(width: sideSpacerWidth)
                        
                        // directions button
                        Button("Directions") {
                            openMapsAndGetDirections(
                                event.address!,
                                event.latitude!,
                                event.longititude!
                            )
                        }
                        .frame(maxWidth: .infinity, minHeight: 40) // extend across screen horizontally
                        .buttonStyle(PlainButtonStyle())
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        
                        
                        Spacer().frame(width: sideSpacerWidth)
                    }
                }
            }
            Spacer()
        }
    }
}



func editEvent(_ eventID: String) {
    // add event editing stuff here
    print("event being edited ~ \(eventID)")
    
    // should probably call deleteEvent() + createEvent()
}

func deleteEvent(_ eventID: String) {
    // add event deleting stuff here
    print("event being deleted ~ \(eventID)")
}


// seems like the api returns iso8601 timestrings not millisecond timestamps
func formatTimeString(_ timeString: String) -> String {
    print(timeString)
    
    var newTimeString = timeString
    // if the timestrings are missing the 'Z' at the end then add that in manually
    if !timeString.hasSuffix("Z") {
        newTimeString += "Z"
    }
    
    let dateParser = ISO8601DateFormatter()
    let date = dateParser.date(from: newTimeString)
    
    let dateFormatter = DateFormatter()
    dateFormatter.locale = NSLocale.current
    dateFormatter.dateFormat = "h:mm a 'on' M/dd/yyyy" // something like '3:18 PM on 3/28/22'
    dateFormatter.amSymbol = "AM"
    dateFormatter.pmSymbol = "PM"
    return dateFormatter.string(from: date!)
}


func openMapsAndGetDirections(_ address: String, _ lat: String, _ lon: String) {
    // https://stackoverflow.com/a/32040919
    if (UIApplication.shared.canOpenURL(NSURL(string:"comgooglemaps://")! as URL)) {
        UIApplication.shared.open(URL(
            string: "comgooglemaps://?saddr=&daddr=\(lat),\(lon)&directionsmode=walking"
        )!)
    } else {
        // open apple maps if no google maps
        // dirflg=w means walking
        UIApplication.shared.open(URL(
            string: "http://maps.apple.com/?dirflg=w&daddr=\(lat),\(lon)"
        )!)
    }
    // should probably handle case when theres neither google maps nor apple maps
    // will do later
}


func getShareEventMessage(_ event: Event) -> String {
    // I just copied most of what we put in the Figma
    
    return (
        "Event: \(event.title!)"
        + "\nTime: \(formatTimeString(event.start_time!))"
        + "\nDescription: \(event.description!)"
    )
}


// creates share event modal
// https://swifttom.com/2020/02/06/how-to-share-content-in-your-app-using-uiactivityviewcontroller-in-swiftui/
struct ActivityViewController: UIViewControllerRepresentable {

    var itemsToShare: [Any]
    var servicesToShareItem: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: itemsToShare, applicationActivities: servicesToShareItem)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}

}
