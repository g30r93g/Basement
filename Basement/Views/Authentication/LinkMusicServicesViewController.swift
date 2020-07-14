//
//  LinkMusicServicesViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 16/05/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

class LinkMusicServicesViewController: UIViewController {
	
	// MARK: IBOutlets
    @IBOutlet weak private var appleMusicLinkImage: UIImageView!
    @IBOutlet weak private var appleMusicActivity: UIActivityIndicatorView!
    @IBOutlet weak private var spotifyLinkImage: UIImageView!
    @IBOutlet weak private var spotifyActivity: UIActivityIndicatorView!
	@IBOutlet weak private var continueButton: UIButton!

	// MARK: Properties
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
        
        self.updateInteractions()
	}
	
	// MARK: Methods
    private func updateInteractions() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                let platformHasLinked = StreamingPlatform.appleMusic.isLinked || StreamingPlatform.spotify.isLinked
                self.continueButton.alpha = platformHasLinked ? 1 : 0
            }
            self.continueButton.isUserInteractionEnabled = StreamingPlatform.appleMusic.isLinked || StreamingPlatform.spotify.isLinked
            
            self.appleMusicLinkImage.image = StreamingPlatform.appleMusic.isLinked ? UIImage(systemName: "checkmark") : UIImage(systemName: "plus")
            self.spotifyLinkImage.image = StreamingPlatform.spotify.isLinked ? UIImage(systemName: "checkmark") : UIImage(systemName: "plus")
        }
    }
	// MARK: IBActions
    @IBAction private func continueTapped(_ sender: UIButton) {
        if StreamingPlatform.appleMusic.isLinked || StreamingPlatform.spotify.isLinked {
            self.performSegue(withIdentifier: "Add Friends", sender: self)
        }
    }
    
    @IBAction private func linkAppleMusic(_ sender: UIButton) {
        self.appleMusicActivity.startAnimating()
        
        StreamingPlatform.performLink(for: .appleMusic) { (result) in
            switch result {
            case .success(_):
                print("Apple music linked!")
            case .failure(let error):
                print("Apple music failed to link - \(error.localizedDescription)")
            }
            
            self.appleMusicActivity.stopAnimating()
            self.updateInteractions()
        }
    }
    
    @IBAction private func linkSpotify(_ sender: UIButton) {
        self.spotifyActivity.startAnimating()
        
        StreamingPlatform.performLink(for: .spotify) { (result) in
            switch result {
            case .success(_):
                print("Spotify linked!")
            case .failure(let error):
                print("Spotify failed to link - \(error.localizedDescription)")
            }
            
            self.spotifyActivity.stopAnimating()
            self.updateInteractions()
        }
    }
	
}
