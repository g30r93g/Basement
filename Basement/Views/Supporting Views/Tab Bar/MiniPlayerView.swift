//
//  MiniPlayerView.swift
//  Basement
//
//  Created by George Nick Gorzynski on 13/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class MiniPlayerView: RoundView {
    
    // MARK: IBOutlets
    @IBOutlet weak internal var nowPlayingButton: UIButton!
    @IBOutlet weak private var playbackView: UIView!
    @IBOutlet weak private var playbackViewHeight: NSLayoutConstraint!
    @IBOutlet weak private var numberOfListeners: UILabel!
    @IBOutlet weak private var artwork: UIImageView!
    @IBOutlet weak private var songArtistLabel: UILabel!
    @IBOutlet weak private var platformLabel: UILabel!
    @IBOutlet weak internal var playPauseButton: UIButton!
    
    // MARK: Properties
    override func awakeFromNib() {
        super.awakeFromNib()
        
        PlaybackManager.current.miniPlayerDelegate = self
        SessionManager.current.sessionUpdateDelegate = self
        
        self.updateContent()
    }
    
    // MARK: Methods
    private func updateContent() {
        if PlaybackManager.current.playback.state == .notStarted && SessionManager.current.session == nil {
            self.displaySetupText()
        } else if let currentSong = PlaybackManager.current.playback.currentSong {
            self.displaySong(currentSong)
            self.updateNumberOfListeners(to: SessionManager.current.session?.listeners.count ?? 0)
        }
        
        self.updatePlaybackControls()
    }
    
    public func updateNumberOfListeners(to listenerCount: Int) {
        self.numberOfListeners.text = "\(listenerCount == 0 ? "No other" : "\(listenerCount)") listener\(listenerCount != 1 ? "s" : "")"
    }
    
    private func displaySong(_ song: Music.Song) {
        self.artwork.image = song.streamingInformation.artwork?.image
        self.songArtistLabel.text = "\(song.name) • \(song.artist)"
        self.platformLabel.text = "Playing from \(song.streamingInformation.platform.name)"
    }
    
    private func displaySetupText() {
        if let setup = SessionManager.current.setup {
            self.songArtistLabel.text = "Tap to finish setting up your new session"
            self.platformLabel.text = "\(setup.content.isEmpty ? "No" : "\(setup.content.count)") song\(setup.content.count == 1 ? " by \((setup.content.first as? Music.Song)?.artist ?? "")" : "s") selected"
        } else if let session = SessionManager.current.session {
            self.songArtistLabel.text = "Press play to start session"
            self.platformLabel.text = "\(session.content.count) song\(session.content.count == 1 ? "" : "s") queued"
            
            if let streamingPlatform = session.content.first?.streamingInformation.platform.name {
                self.platformLabel.text! += " from \(streamingPlatform)"
            }
        } else {
            self.songArtistLabel.text = "Tap to start a new session"
            self.platformLabel.text = ""
        }
    }
    
    private func updatePlaybackControls() {
        switch PlaybackManager.current.playback.state {
        case .playing:
            // Show Pause Button
            self.playPauseButton?.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            UIView.animate(withDuration: 0.4) {
                self.numberOfListeners.alpha = 1
                self.playbackViewHeight.constant = 100
            }
        case .paused:
            // Show Play Button
            self.playPauseButton?.setImage(UIImage(systemName: "play.fill"), for: .normal)
            UIView.animate(withDuration: 0.4) {
                self.numberOfListeners.alpha = 1
                self.playbackViewHeight.constant = 100
            }
        case .notStarted, .ended:
            // Hide Listener Count
            self.playPauseButton?.setImage(UIImage(systemName: "arrow.right"), for: .normal)
            
            UIView.animate(withDuration: 0.4) {
                self.numberOfListeners.alpha = 0
                self.playbackViewHeight.constant = 80
            }
        }
    }
    
    // MARK: IBActions
    @IBAction private func playPauseButtonTapped(_ sender: UIButton) {
        let playbackState = PlaybackManager.current.playback.state
        
        guard playbackState == .playing || playbackState == .paused else { return }
        DispatchQueue.main.async {
            self.playPauseButton.setImage(UIImage(systemName: playbackState == .playing ? "pause.fill" : "play.fill"), for: .normal)
        }
        
        PlaybackManager.current.performPlaybackCommand(playbackState == .playing ? .pause : .play)
    }
    
    @IBAction private func miniPlayerTapped(_ sender: UIButton) {
        switch PlaybackManager.current.playback.state {
        case .playing, .paused:
            if let topVC = UIApplication.getPresentedViewController() {
                guard let nowPlayingVC = UIStoryboard(name: "NowPlaying", bundle: nil).instantiateInitialViewController() else { fatalError() }
                
                topVC.present(nowPlayingVC, animated: true, completion: nil)
            }
        case .notStarted, .ended:
            if let topVC = UIApplication.getPresentedViewController() {
                let newVibeStoryboard = UIStoryboard(name: "NewSession", bundle: nil)
                guard let newVibeTopVC = newVibeStoryboard.instantiateInitialViewController() else { fatalError() }
                
                self.updateContent()
                
                topVC.present(newVibeTopVC, animated: true, completion: nil)
            }
        }
        
    }
    
}

extension MiniPlayerView: MiniPlayerDelegate {
    
    func playbackStateUpdated(to state: PlaybackManager.State) {
        self.updateContent()
    }
    
}

extension MiniPlayerView: SessionUpdateDelegate {
    
    func queueDidChangeInSetup() {
        self.updateContent()
    }
    
    func didStartSessionSetup() {
        self.updateContent()
    }
    
    func didInitialiseSession() {
        self.updateContent()
    }
    
    func didJoinSession() {
        self.updateContent()
    }
    
    func sessionUpdate(isHost: Bool) {
        self.updateContent()
    }
    
}
