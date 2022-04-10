//
//  UserID.swift
//  Tempo
//
//  Created by Sam Korman on 4/10/22.
//

import Foundation


final class UserID {
    static let shared = UserID() // create one instance of the class to be shared
    private init(){}                // and make the constructor private so no other
                                    // instances can be created
    
//    var expiration = Date(timeIntervalSince1970: 0.0)
    private var field: String?
    var id: String? {
        get { field }
        set(newValue) { field = newValue }
    }
    
    
    func open() {
        let searchFor = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrDescription: "UserID",
            kSecReturnData: true,
            kSecReturnAttributes: true,
        ] as CFDictionary
        
        var itemRef: AnyObject?
        let searchStatus = SecItemCopyMatching(searchFor, &itemRef)

        let df = DateFormatter()
        df.dateFormat="yyyy-MM-dd HH:mm:ss '+'SSSS"

        switch (searchStatus) {
        case errSecSuccess: // found keychain
            if let item = itemRef as? NSDictionary,
               let data = item[kSecValueData] as? Data {
//               let dateStr = item[kSecAttrLabel] as? String,
//               let date = df.date(from: dateStr) {
//                id = String(data: data, encoding: .utf8)
//                expiration = date
            } else {
                print("Keychain has null entry!")
            }
        case errSecItemNotFound:// biometric check
            let accessControl = SecAccessControlCreateWithFlags(nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .userPresence,
                nil)!

            let item = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrDescription: "UserID",
//                kSecAttrLabel: df.string(from: expiration),
                kSecAttrAccessControl: accessControl  // biometric check
            ] as CFDictionary

            let addStatus = SecItemAdd(item, nil)
            if (addStatus != 0) {
                print("UserID.open add: \(String(describing: SecCopyErrorMessageString(addStatus, nil)!))")
            }
        default:
            print("UserID.open search: \(String(describing: SecCopyErrorMessageString(searchStatus, nil)!))")
        }
    }
    

    func save() {
        
        let item = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrDescription: "UserID",
        ] as CFDictionary
        
        let updates = [
            kSecValueData: id?.data(using: .utf8) as Any
        ] as CFDictionary
        
        let updateStatus = SecItemUpdate(item, updates)
        if (updateStatus != 0) {
            print("UserID.save: \(String(describing: SecCopyErrorMessageString(updateStatus, nil)!))")
        }
    }
    
    func delete() {
        let item = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrDescription: "UserID",
        ] as CFDictionary
        
        let delStatus = SecItemDelete(item)
        if (delStatus != 0) {
            print("UserID.delete: \(String(describing: SecCopyErrorMessageString(delStatus, nil)!))")
        }
    }
}
