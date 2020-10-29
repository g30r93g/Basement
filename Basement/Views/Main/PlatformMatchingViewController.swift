//
//  PlatformMatchingViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 29/10/2020.
//

import UIKit

class PlatformMatchingViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var sourceLabel: UILabel!
    @IBOutlet weak private var sourceImageView: UIImageView!
    @IBOutlet weak private var destinationLabel: UILabel!
    @IBOutlet weak private var destinationImageView: UIImageView!
    
    @IBOutlet weak private var matchingTracksLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak private var tracksTableView: UITableView!
    @IBOutlet weak private var startSessionButton: UIButton!
    
    // MARK: Properties
    var sessionName: String!
    var sessionVisibility: SessionManager.SessionVisibility!
    var trackList: [SessionManager.Track]!
    var matchStatus: [Bool] = [] {
        didSet {
            DispatchQueue.main.async { self.matchingTracksLoadingIndicator.stopAnimating(); self.updateTableView() }
        }
    }
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.setupView()
    }
    
    // MARK: Methods
    private func setupView() {
        self.startSessionButton.isUserInteractionEnabled = false
        self.startSessionButton.alpha = 0
        
        self.matchingTracksLoadingIndicator.startAnimating()
        
        BasementProfile.shared.fetchCurrentUser { (result) in
            switch result {
            case .success(let profile):
                guard let connectedService = profile.details.connectedService else { break }
                let connectedServiceName = connectedService.platform.textualRepresentation()
                
                let destinationService: StreamingPlatform.Platforms = connectedService.platform == .appleMusic ? .appleMusic : .spotify
                let destinationServiceName = destinationService.textualRepresentation()
                
                self.sourceLabel.text = connectedServiceName
                self.sourceImageView.image = UIImage(named: connectedServiceName)
                
                self.destinationLabel.text = destinationServiceName
                self.destinationImageView.image = UIImage(named: destinationServiceName)
            case .failure(_):
                break
            }
        }
        
        self.updateTableView()
    }
    
    private func updateTableView() {
        DispatchQueue.main.async {
            self.tracksTableView.reloadData()
        }
    }
    
    private func beginMatching() {
        BasementProfile.shared.fetchCurrentUser { (result) in
            switch result {
            case .success(let profile):
                guard let source = profile.details.connectedService?.platform else { return }
                let tracksToMatch = self.trackList.compactMap({$0.content as? Music.Song})
                
                PlatformMatcher().matchTrackList(tracksToMatch, source: source) { (result) in
                    switch result {
                    case .success(let matchedTracks, let failedTracks):
                        // Iterate through matched and failed tracks and map to content
                        
                        // Update Table View
                        self.updateTableView()
                    case .failure(_):
                        self.updateTableView()
                    }
                }
            case .failure(_):
                break
            }
        }
    }
    
    // MARK: IBActions
    @IBAction private func startSessionTapped(_ sender: UIButton) {
        
    }
    
}

extension PlatformMatchingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
}
