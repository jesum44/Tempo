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


class SignInView: UIViewController {
    
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
        let formView = AuthView(delegate: delegate)
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
struct AuthView: View {
    // for dismissing the view

    @ObservedObject var delegate: SheetDismisserProtocol
    
    @State var username = ""
    @State var password = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text ("Sign Up")) {
                    TextField("Username", text: $username)
                    TextField("Password", text: $password)
                }
                .font(.title3)
                .foregroundColor(.blue)
                Section {
                    HStack {
                        Spacer()
                        Button("Already have an account? Log in") {
                            Task {
                                
                              
                            }
                        }
                        .font(.title3)
                        Spacer()
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Button("Continue as guest") {
                            Task {
                                self.delegate.dismiss()

                              
                            }
                        }
                        .font(.title3)
                        Spacer()
                    }
                }
                           
                            
            }
            .navigationBarTitle("Tempo")
        }
    }
}


// dismiss CreateEventView from within the SwiftUI Form
// based on https://stackoverflow.com/a/59348371



// Alamofire wasn't working so I had to do this the hard way
// Make sure parameters does not have Any in the type declaration or else
//      it can't be json-encoded
// return array of strings to allow basic error handling -> empty means no error
//func makeCreateEventPostRequest(_ parameters: [String: String]) async -> [String] {
//    // TODO: replace this with what the backend team provides
//    //let url = "https://ptsv2.com/t/13soj-1647428183/post"
//    let url = "https://54.175.206.175/events/"
//
//    guard let encoded = try? JSONEncoder().encode(parameters) else {
//        print("JSONEncoder error")
//        return ["Json Encoding"]
//    }
//
//    var request = URLRequest(url: URL(string: url)!)
//    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//    request.httpMethod = "POST"
//
//    do {
//        let (data, res) = try await URLSession.shared.upload(for: request, from: encoded)
//        let httpRes = res as! HTTPURLResponse
//        if httpRes.statusCode != 201 {
//            print("POST request status code was not 201! It was \(httpRes.statusCode)")
//            return ["Status Code", "\(httpRes.statusCode)"]
//        }
//    } catch {
//        print("POST Request error")
//        return ["Post Request"]
//    }
//
//    // no errors, everything worked, return [false]
//    return []
//}



