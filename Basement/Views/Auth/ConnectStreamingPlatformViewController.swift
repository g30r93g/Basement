//
//  ConnectStreamingPlatformViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 26/10/2020.
//

import UIKit

class ConnectStreamingPlatformViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var connectAppleMusicButton: UIButton!
    @IBOutlet weak private var connectAppleMusicSpinner: UIActivityIndicatorView!
    @IBOutlet weak private var connectSpotifyButton: UIButton!
    @IBOutlet weak private var connectSpotifySpinner: UIActivityIndicatorView!
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // MARK: Methods
    private func connectAppleMusic() {
        DispatchQueue.main.async { self.connectAppleMusicSpinner.startAnimating() }
        
        PlaybackManager.current.streamingPlatform.authorize(for: .appleMusic) { (result) in
            switch result {
            case .success(_):
                Firebase.firestore.updateConnectedService(to: BasementProfile.ConnectedService(platform: .appleMusic, username: "")) { (uploadResult) in
                    switch uploadResult {
                    case .success(_):
                        self.completePlatformConnection()
                    case .failure(_):
                        return
                    }
                    
                    DispatchQueue.main.async { self.connectAppleMusicSpinner.stopAnimating() }
                }
            case .failure(_):
                DispatchQueue.main.async { self.connectAppleMusicSpinner.stopAnimating() }
            }
        }
    }
    
    private func connectSpotify() {
        
    }
    
    private func completePlatformConnection() {
        self.performSegue(withIdentifier: "Streaming Platform Connection Successful", sender: self)
    }
    
    // MARK: IBActions
    @IBAction private func appleMusicTapped(_ sender: UIButton) {
        self.connectAppleMusic()
    }
    
    @IBAction private func spotifyTapped(_ sender: UIButton) {
        self.connectSpotify()
    }
    
}
