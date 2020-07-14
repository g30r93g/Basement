//
//  KeychainManager.swift
//  Basement
//
//  Created by George Nick Gorzynski on 14/07/2020.
//

import Foundation
import KeychainAccess

class KeychainManager {
    
    // MARK: Static Instance
    static let application = KeychainManager()
    
    // MARK: Properties
    private var keychain: Keychain
    
    // MARK: Initialiser
    init() {
        self.keychain = Keychain(service: "com.g30r93g.Basement", accessGroup: "com.g30r93g.Basement.authKeychain")
    }
    
    // MARK: Methods
    func saveUsernamePassword(username: String, password: String, completion: @escaping(Bool) -> Void) {
        completion(false)
    }
    
}
