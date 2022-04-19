//
//  CreateEventView.swift
//  Tempo
//
//  Created by Krithik Vallem on 3/15/22.
//

import Foundation
import UIKit
import SwiftUI // the form is made in SwiftUI, and embedded into UIKit's UIViewController
import SwiftyJSON


class CreateEventView: UIViewController {
    
    // function that runs when "Back" is tapped
    @objc func closeView(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // add x button to top right in case user's don't want to create event
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(self.closeView))
        
        // add the form to the view
        addSwiftUIForm()
    }
    
    // Embedding SwiftUI inside UIViewController
    // https://stackoverflow.com/a/63502951
    func addSwiftUIForm() {
        // this lets the form dismiss the view once event is created
        // https://stackoverflow.com/a/59348371
        let delegate = SheetDismisserProtocol()
        let formView = FormView(delegate: delegate)
        let formController = UIHostingController(rootView: AnyView(formView))
        delegate.host = formController
        
        if let form = formController.view {
            form.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(form)
            form.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
            form.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
            form.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
            form.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true

            self.addChild(formController)
        }
        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}


// The actual form
// https://www.simpleswiftguide.com/swiftui-form-tutorial-how-to-create-and-use-form-in-swiftui/
struct FormView: View {
    // for dismissing the view
    @ObservedObject var delegate: SheetDismisserProtocol
    
    @State var title: String = ""
    @State var description: String = ""
    @State var address: String = ""

    @State var startTime = Date()
    // endTime init'ed as 1 hour from now
    @State var endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    
    @State var categoriesSelected: String = "" // might be extended into a list of Strings later
    var categoryOptions = [
        "Art & Culture",
        "Career & Business",
        "Community & Environment",
        "Dancing",
        "Games",
        "Health & Wellbeing",
        "Hobbies & Passions",
        "Identity & Language",
        "Movements & Politics",
        "Music",
        "Parents & Family",
        "Pets & Animals",
        "Religion & Spirituality",
        "Science & Education",
        "Social Activities",
        "Sports & Fitness",
        "Support & Coaching",
        "Technology",
        "Travel & Outdoor",
        "Writing"
    ]
    
    @State var errorMessage = ""
    
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                }
                Section {
                    TextField("Description", text: $description)
                }
                Section {
                    TextField("Full Address - Please Include City & State", text: $address)
                }
                Section {
                    Picker(selection: $categoriesSelected, label: Text("Category")) {
                        ForEach(self.categoryOptions, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    // this turns the picker from a list to a menu
                    //.pickerStyle(MenuPickerStyle())
                }
                Section {
                    DatePicker("Starts At", selection: $startTime,
                               displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Ends At", selection: $endTime,
                               displayedComponents: [.date, .hourAndMinute])
                }
                if errorMessage != "" {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                Section {
                    HStack {
                        Spacer()
                        Button("Create") {
                            Task {
                                
                                // convert categories selected into a string to make it easier
                                // to work with and avoid encoding errors later
                                let categoriesSelectedJSON = JSON(
                                    // remove [] if we decide to make it an array
                                    [self.categoriesSelected]
                                ).rawString(
                                    String.Encoding.utf8,
                                    options: JSONSerialization.WritingOptions.prettyPrinted)!

                                let parameters: [String: String] = [
                                    "title": self.title,
                                    "description": self.description,
                                    "address": self.address,
                                    "categories": categoriesSelectedJSON,
                                    "start_time":
                                        String(Int(self.startTime.timeIntervalSince1970)),
                                    "end_time":
                                        String(Int(self.endTime.timeIntervalSince1970)),
                                    
                                ]
                                    
                                let err = await makeCreateEventPostRequest(parameters)
                                // show error if one occured
                                if !err.isEmpty {
                                    if err[0] == "Status Code" {
                                        errorMessage = "Invalid Address!\nPlease try again!"
                                    } else {
                                        errorMessage = "Something went wrong!\nPlease try again!"
                                    }
                                } else {
                                    // if no error, refresh events from database
                                    GLOBAL_AR_VIEW?.getNearbyEvents(nil)
                                    // then close view and return to previous view
                                    self.delegate.dismiss()
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
                
            }
            .navigationBarTitle("Create Event")
            
        }
    }
}


// dismiss CreateEventView from within the SwiftUI Form
// based on https://stackoverflow.com/a/59348371
class SheetDismisserProtocol: ObservableObject {
    weak var host: UIHostingController<AnyView>? = nil

    func dismiss() {
        host?.dismiss(animated: true)
    }
}


// Alamofire wasn't working so I had to do this the hard way
// Make sure parameters does not have Any in the type declaration or else
//      it can't be json-encoded
// return array of strings to allow basic error handling -> empty means no error
func makeCreateEventPostRequest(_ parameters: [String: String]) async -> [String] {
    // TODO: replace this with what the backend team provides
    //let url = "https://ptsv2.com/t/13soj-1647428183/post"
    let url = "https://54.87.128.240/events/"
    
    guard let encoded = try? JSONEncoder().encode(parameters) else {
        print("JSONEncoder error")
        return ["Json Encoding"]
    }
    
    var request = URLRequest(url: URL(string: url)!)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
    
    do {
        let (data, res) = try await URLSession.shared.upload(for: request, from: encoded)
        let httpRes = res as! HTTPURLResponse
        if httpRes.statusCode != 201 {
            print("POST request status code was not 201! It was \(httpRes.statusCode)")
            return ["Status Code", "\(httpRes.statusCode)"]
        }
    } catch {
        print("POST Request error")
        return ["Post Request"]
    }
    
    // no errors, everything worked, return [false]
    return []
}



