//
//  ConnectMusicServiceViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/08/2020.
//

import UIKit

class ConnectMusicServiceViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var appleMusicConnectButton: LoadingButton!
    @IBOutlet weak private var spotifyConnectButton: LoadingButton!
    
    // MARK: Properties
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    // MARK: Methods
    private func setupView() { }
    
    private func showConnectionError(platform: StreamingPlatform.Platform) {
        let alert = UIAlertController(title: "Failed to link \(platform.rawValue)", message: "Please try again later.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: IBActions
    @IBAction private func connectAppleMusic() {
        self.appleMusicConnectButton.startLoading()
        
        AppleMusicAPI.currentSession.performAuth(shouldSetup: true) { (result) in
            switch result {
            case .success(_):
                self.performSegue(withIdentifier: "Streaming Service Connected", sender: self)
            case .failure(_):
                self.showConnectionError(platform: .appleMusic)
            }
            
            self.appleMusicConnectButton.stopLoading()
        }
    }
    
    @IBAction private func connectSpotify() {
        self.spotifyConnectButton.startLoading()
        
        self.showConnectionError(platform: .spotify)
        
        self.spotifyConnectButton.stopLoading()
    }

}
