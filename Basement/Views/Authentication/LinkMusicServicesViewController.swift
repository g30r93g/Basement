//
//  LinkMusicServicesViewController.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 16/05/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

class LinkMusicServicesViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var continueButton: UIButton!

	// MARK: Properties
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(authSuccessful), name: .appleMusicAuthSuccessful, object: nil)
        
        self.updateInteractions()
	}
	
	// MARK: Methods
    private func updateInteractions() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.continueButton.alpha = StreamingPlatform.appleMusic.isLinked || StreamingPlatform.spotify.isLinked ? 1 : 0
            }
            self.continueButton.isUserInteractionEnabled = StreamingPlatform.appleMusic.isLinked || StreamingPlatform.spotify.isLinked
        }
    }
    
    @objc private func authSuccessful() {
        self.updateInteractions()
    }
	
	// MARK: IBActions
    @IBAction private func continueTapped(_ sender: UIButton) {
        if StreamingPlatform.appleMusic.isLinked || StreamingPlatform.spotify.isLinked {
            self.performSegue(withIdentifier: "Add Friends", sender: self)
        }
    }
    
    @IBAction private func linkAppleMusic(_ sender: UIButton) {
        AppleMusicAPI.currentSession.performAuth(shouldSetup: false) { (result) in
            switch result {
            case .success(_):
                print("Apple music linked!")
            case .failure(let error):
                print("Apple music failed to link - \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction private func linkSpotify(_ sender: UIButton) {
        
    }
	
}
