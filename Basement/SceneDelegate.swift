//
//  SceneDelegate.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        self.window?.overrideUserInterfaceStyle = .dark
        self.determineStoryboard()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if SpotifyAPI.currentSession.appRemote.connectionParameters.accessToken != nil {
            SpotifyAPI.currentSession.appRemote.connect()
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        if SpotifyAPI.currentSession.appRemote.isConnected {
            SpotifyAPI.currentSession.appRemote.disconnect()
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        let appRemote = SpotifyAPI.currentSession.appRemote
        let parameters = appRemote.authorizationParameters(from: url)

        if parameters?["code"] != nil {
            SpotifyAPI.currentSession.spotifyKitManager.saveToken(from: url)
        } else if let error = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print("[SceneDelegate/Spotify] Failed to obtain authorization from Spotify SDK - \(error)")
        }
    }
    
    private func determineStoryboard() {
        var storyboard: UIStoryboard {
            if Firebase.isSignedIn {
                return UIStoryboard(name: "Main", bundle: nil)
            } else {
                return UIStoryboard(name: "Authentication", bundle: nil)
            }
        }
        
        let initialVC = storyboard.instantiateInitialViewController()
        self.window?.rootViewController = initialVC
        self.window?.makeKeyAndVisible()
    }

}
