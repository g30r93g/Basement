//
//  SessionViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 26/10/2020.
//

import UIKit
import SDWebImage

class SessionViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var sessionTitle: UILabel!
    @IBOutlet weak private var hostLabel: UILabel!
    @IBOutlet weak private var joinCode: UILabel!
    
    @IBOutlet weak private var nowPlayingView: UIView!
    @IBOutlet weak private var nowPlayingViewHeight: NSLayoutConstraint!
    @IBOutlet weak private var nowPlayingArtwork: UIImageView!
    @IBOutlet weak private var nowPlayingTrackName: UILabel!
    @IBOutlet weak private var nowPlayingTrackDetails: UILabel!
    @IBOutlet weak private var nowPlayingPosition: UISlider!
    @IBOutlet weak private var nowPlayingCurrentTimePosition: UILabel!
    @IBOutlet weak private var nowPlayingEndTimePosition: UILabel!
    @IBOutlet weak private var nowPlayingPreviousButton: UIButton!
    @IBOutlet weak private var nowPlayingPlayButton: UIButton!
    @IBOutlet weak private var nowPlayingNextButton: UIButton!
    
    @IBOutlet weak private var detailSegmentControl: UISegmentedControl!
    @IBOutlet weak private var detailTableView: UITableView!
    
    // MARK: Properties
    private var updateTimer: Timer!
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setupUpdateTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.removeUpdateTimer()
    }
    
    // MARK: Methods
    private func setupView() {
        guard let session = SessionManager.current.activeSession else {
            self.sessionTitle.text = "Error displaying active session."
            return
        }
        SessionManager.current.sessionUpdateDelegate = self
        
        self.setupHeader(from: session)
        self.updateNowPlaying()
        self.updatePlaybackPositioning()
        
        BasementProfile.shared.fetchCurrentUser(completion: { (result) in
            switch result {
            case .success(let profile):
                if profile.details == session.details.host {
                    self.hostFeatures()
                } else {
                    self.userFeatures()
                }
            case .failure(_):
                break
            }
        })

        
        DispatchQueue.main.async { self.detailTableView.reloadData() }
    }
    
    private func setupHeader(from session: SessionManager.Session) {
        self.sessionTitle.text = session.details.title
        self.hostLabel.text = "Hosted by @\(session.details.host.username)"
        self.joinCode.text = "Join Code: \(session.joinDetails.code)"
    }
    
    private func hostFeatures() {
        DispatchQueue.main.async {
            self.detailTableView.isEditing = true
            
            self.nowPlayingPreviousButton.isHidden = false
            self.nowPlayingPlayButton.isHidden = false
            self.nowPlayingNextButton.isHidden = false
            
            self.nowPlayingViewHeight.constant = 220
        }
    }
    
    private func userFeatures() {
        DispatchQueue.main.async {
            // Update table
            self.detailTableView.isEditing = false
            
            self.nowPlayingPreviousButton.isHidden = true
            self.nowPlayingPlayButton.isHidden = true
            self.nowPlayingNextButton.isHidden = true
            
            self.nowPlayingViewHeight.constant = 160
        }
    }
    
    private func updateNowPlaying() {
        guard let nowPlaying = PlaybackManager.current.nowPlaying,
              let track = nowPlaying.streamInformation as? Music.Song
        else { return }
        
        self.nowPlayingArtwork.sd_setImage(with: track.streamingInformation.artworkURL, placeholderImage: nil, options: [])
        self.nowPlayingTrackName.text = track.name
        self.nowPlayingTrackDetails.text = "\(track.artist) • \(track.album)"
        self.nowPlayingPosition.minimumValue = 0
        self.nowPlayingPosition.maximumValue = Float(track.runtime)
        self.nowPlayingEndTimePosition.text = "\(track.runtime.minutes().doubleDigitString()):\(track.runtime.seconds().doubleDigitString())"
        
        self.detailTableView.reloadData()
    }
    
    private func updatePlaybackPositioning() {
        let playbackPosition = PlaybackManager.current.playbackPosition
        
        self.nowPlayingCurrentTimePosition.text = "\(playbackPosition.minutes().doubleDigitString()):\(playbackPosition.seconds().doubleDigitString())"
        
        UIView.animate(withDuration: 1.1) {
            self.nowPlayingPosition.setValue(Float(playbackPosition), animated: true)
        }
    }
    
    private func setupUpdateTimer() {
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (_) in
            DispatchQueue.main.async {
                self.updateNowPlaying()
                self.updatePlaybackPositioning()
            }
        })
    }
    
    private func removeUpdateTimer() {
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (_) in
            DispatchQueue.main.async {
                self.updatePlaybackPositioning()
            }
        })
    }
    
    // MARK: IBActions
    @IBAction private func nowPlayingPreviousButtonTapped(_ sender: UIButton) {
        SessionManager.current.uploadPlaybackStateChange(command: .previous) { (_) in
            self.updateNowPlaying()
        }
    }
    
    @IBAction private func nowPlayingPlayButtonTapped(_ sender: UIButton) {
        let hasStarted = PlaybackManager.current.hasStarted
        let isPlaying = PlaybackManager.current.isPlaying
            
        SessionManager.current.uploadPlaybackStateChange(command: hasStarted ? (isPlaying ? .pause : .play) : .start) { (result) in
            switch result {
            case .success(_):
                let updatedIsPlaying = PlaybackManager.current.isPlaying
                
                sender.setImage(UIImage(systemName: updatedIsPlaying ? "pause.fill" : "play.fill"), for: .normal)
                self.updateNowPlaying()
            case .failure(_):
                break
            }
        }
    }
    
    @IBAction private func nowPlayingNextButtonTapped(_ sender: UIButton) {
        SessionManager.current.uploadPlaybackStateChange(command: .next) { (_) in
            self.updateNowPlaying()
        }
    }
    
    @IBAction private func detailSegmentValueChanged(_ sender: UISegmentedControl) {
        DispatchQueue.main.async { self.detailTableView.reloadData() }
    }

}

extension SessionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let listeners = SessionManager.current.activeSession?.listeners,
              let queue = PlaybackManager.current.queue
        else { return 0 }
        
        return self.detailSegmentControl.selectedSegmentIndex == 0 ? queue.count : listeners.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.detailSegmentControl.selectedSegmentIndex {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "Queued Track", for: indexPath) as? ContentCell,
                  let queuedItem = PlaybackManager.current.queue?[indexPath.row]
            else { return UITableViewCell() }
            
            cell.setupCell(from: queuedItem.streamInformation)
            
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Listener", for: indexPath)
            guard let listener = SessionManager.current.activeSession?.listeners[indexPath.row] else { return cell }
            
            cell.textLabel?.text = listener.userDetails.username
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard var queue = PlaybackManager.current.queue else { return }
        let movedItem = queue[sourceIndexPath.row]
        
        queue.remove(at: sourceIndexPath.row)
        queue.insert(SessionManager.Track(playbackIndex: destinationIndexPath.row, streamInformation: movedItem.streamInformation),
                         at: destinationIndexPath.row)
        
        PlaybackManager.current.updateQueue(with: queue) { (_) in
            tableView.reloadData()
        }
    }
    
}

extension SessionViewController: SessionUpdateDelegate {
    
    func listenersUpdated() {
        self.detailTableView.reloadData()
    }
    
}
