//
//  SelectTrackListViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 26/10/2020.
//

import UIKit

protocol TrackSelectionDelegate {
    
    func addTrack(track: Music.Song)
    
}

class TrackListViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var trackListTable: UITableView!
    @IBOutlet weak private var addTracksButton: RoundButton!
    @IBOutlet weak private var startSessionButton: LoadingButton!
    
    // MARK: Properties
    var sessionName: String!
    var sessionVisibility: SessionManager.SessionVisibility!
    var trackList: [SessionManager.Track] = []
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.trackListTable.isEditing = true
    }
    
    // MARK: Methods
    private func startSession() {
        guard !self.trackList.isEmpty else { return }
        
        DispatchQueue.main.async { self.startSessionButton.startLoading() }
        
        BasementProfile.shared.fetchCurrentUser { (result) in
            switch result {
            case .success(let hostProfile):
                let sessionID = UUID().uuidString
                let sessionDetails = SessionManager.SessionDetails(sessionID: sessionID, title: self.sessionName, host: hostProfile.details, startedAt: Date(), endedAt: nil)
                let joinDetails = SessionManager.JoinDetails(visibility: self.sessionVisibility, code: String().randomString())
                
                SessionManager.current.startSession(details: sessionDetails, joinDetails: joinDetails, tracks: self.trackList) { (sessionResult) in
                    switch sessionResult {
                    case .success(_):
                        self.transitionToSession()
                    case .failure(_):
                        break
                    }
                    DispatchQueue.main.async { self.startSessionButton.stopLoading() }
                }
            case .failure(_):
                DispatchQueue.main.async { self.startSessionButton.stopLoading() }
            }
        }
    }
    
    private func addTracks() {
        DispatchQueue.main.async { self.performSegue(withIdentifier: "Add Tracks", sender: self) }
    }
    
    private func transitionToSession() {
        DispatchQueue.main.async { self.performSegue(withIdentifier: "Start Session", sender: self) }
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Add Tracks" {
            guard let presentingVC = segue.destination as? TrackSelectionViewController else { return }
            
            presentingVC.trackSelectionDelegate = self
        }
    }
    
    // MARK: IBActions
    @IBAction private func addTracksTapped(_ sender: RoundButton) {
        self.addTracks()
    }
    
    @IBAction private func startSessionTapped(_ sender: LoadingButton) {
        self.startSession()
    }
    
}

extension TrackListViewController: TrackSelectionDelegate {
    
    func addTrack(track: Music.Song) {
        let trackToAdd = SessionManager.Track(playbackIndex: self.trackList.count, content: track)
        
        self.trackList.append(trackToAdd)
        Haptics.success()
        
        DispatchQueue.main.async { self.trackListTable.reloadData() }
    }

}

extension TrackListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.trackList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Selected Track", for: indexPath) as? ContentCell else { return UITableViewCell() }
        let song = self.trackList[indexPath.row].content
        
        cell.setupCell(from: song)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedItem = self.trackList[sourceIndexPath.row]
        
        trackList.remove(at: sourceIndexPath.row)
        trackList.insert(SessionManager.Track(playbackIndex: destinationIndexPath.row, content: movedItem.content),
                         at: destinationIndexPath.row)
    }
    
}
