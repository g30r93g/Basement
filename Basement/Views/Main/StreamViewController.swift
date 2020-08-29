//
//  StreamViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 22/08/2020.
//

import UIKit

class StreamViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet weak private var roomNameLabel: UILabel!
    @IBOutlet weak private var roomCodeLabel: UILabel!
    @IBOutlet weak private var numberOfListenersLabel: UILabel!
    @IBOutlet weak private var editStreamButton: RoundButton!
    @IBOutlet weak private var shareStreamButton: RoundButton!
    @IBOutlet weak private var addToQueueButton: RoundButton!
    @IBOutlet weak private var queueTableView: UITableView!
    @IBOutlet weak private var nowPlayingContainerView: UIView!
    
    // MARK: Properties
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    // MARK: Methods
    private func setupView() {
        guard let activeSession = SessionManager.current.activeSession else { fatalError("No active session detected.") }
        
        self.roomNameLabel.text = activeSession.details.name
        self.roomCodeLabel.text = "Room Code: \(activeSession.details.code)"
        self.numberOfListenersLabel.text = "Number of Listeners: \(activeSession.details.listeners)"
        
        self.queueTableView.reloadData()
    }
    
    // MARK: IBActions
    @IBAction private func editSessionTapped(_ sender: RoundButton) {
        
    }
    
    @IBAction private func shareSessionTapped(_ sender: RoundButton) {
        
    }
    
    @IBAction private func addToQueueTapped(_ sender: RoundButton) {
        
    }

}

extension StreamViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let activeSession = SessionManager.current.activeSession else { return 0 }
        
        return activeSession.playback.tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let activeSession = SessionManager.current.activeSession else { return UITableViewCell() }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Session Track", for: indexPath) as? ContentCell else { return UITableViewCell() }
        
        cell.setupCell(from: activeSession.playback.tracks)
        
        return cell
    }
    
}
