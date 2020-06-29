//
//  MiniPlayerView.swift
//  Vibe
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
    @IBOutlet weak private var numberOfVibers: UILabel!
    @IBOutlet weak private var artwork: UIImageView!
    @IBOutlet weak private var songArtistLabel: UILabel!
    @IBOutlet weak private var platformLabel: UILabel!
    @IBOutlet weak internal var playPauseButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        Music.session.playbackDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(updateMiniPlayerHandler), name: .requestMiniPlayerUpdate, object: nil)
    }
    
    // MARK: Methods
    @objc private func updateMiniPlayerHandler() {
        self.updateNowPlaying()
    }
    
    public func updateNumberOfVibers(to number: Int) {
        switch number {
        case 0:
            self.numberOfVibers.text = "You're a sole viber"
        case 1:
            self.numberOfVibers.text = "1 viber"
        default:
            self.numberOfVibers.text = "\(number) vibers"
        }
    }
    
    public func updateNowPlaying(with information: Music.Song? = nil) {
        if let info = information {
            self.songArtistLabel.text = "\(info.name) • \(info.artist)"
            self.platformLabel.text = "Playing from \(info.streamingInformation.platform.name)"
        } else {
            if let setup = VibeManager.current.currentVibeSetup {
                print("\((setup.content.first as? Music.Song)?.artist ?? "")")
                self.songArtistLabel.text = "Tap to continue vibe setup"
                self.platformLabel.text = "\(setup.content.count) song\(setup.content.count == 1 ? " by \((setup.content.first as? Music.Song)?.artist ?? "")" : "s") selected"
            } else {
                self.songArtistLabel.text = "Tap to setup a vibe"
                self.platformLabel.text = ""
            }
        }
    }
    
    public func setPlaybackState(to state: Music.PlaybackState) {
        switch state {
        case .playing:
            // Show Pause Button
            self.playPauseButton?.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            UIView.animate(withDuration: 0.4) {
                self.numberOfVibers.alpha = 1
                self.playbackViewHeight.constant = 100
            }
        case .paused:
            // Show Play Button
            self.playPauseButton?.setImage(UIImage(systemName: "play.fill"), for: .normal)
            UIView.animate(withDuration: 0.4) {
                self.numberOfVibers.alpha = 1
                self.playbackViewHeight.constant = 100
            }
        case .notPlaying:
            // Hide Viber Count
            self.playPauseButton?.setImage(UIImage(systemName: "arrow.right"), for: .normal)
            
            UIView.animate(withDuration: 0.4) {
                self.updateNowPlaying(with: nil)
                self.numberOfVibers.alpha = 0
                self.playbackViewHeight.constant = 80
            }
        }
    }
    
    // MARK: IBActions
    @IBAction private func playPauseButtonTapped(_ sender: UIButton) {
        switch Music.session.nowPlaying.currentState {
        case .playing:
            self.setPlaybackState(to: .paused)
        case .paused:
            self.setPlaybackState(to: .playing)
        case .notPlaying:
            self.setPlaybackState(to: .notPlaying)
        }
    }
    
    @IBAction private func miniPlayerTapped(_ sender: UIButton) {
        switch Music.session.nowPlaying.currentState {
        case .playing, .paused:
            if let topVC = UIApplication.getPresentedViewController() {
                guard let nowPlayingVC = UIStoryboard(name: "NowPlaying", bundle: nil).instantiateInitialViewController() else { fatalError() }
                
                topVC.present(nowPlayingVC, animated: true, completion: nil)
            }
        case .notPlaying:
            if let topVC = UIApplication.getPresentedViewController() {
                let newVibeStoryboard = UIStoryboard(name: "NewVibe", bundle: nil)
                guard let newVibeTopVC = newVibeStoryboard.instantiateInitialViewController() else { fatalError() }
                
                topVC.present(newVibeTopVC, animated: true, completion: nil)
            }
        }
        
    }
    
}

extension MiniPlayerView: PlaybackDelegate {
    
    func playbackStateChanged(to state: Music.PlaybackState, nowPlaying: Music.NowPlaying?) {
        switch state {
        case .playing:
            self.setPlaybackState(to: .paused)
        case .paused:
            self.setPlaybackState(to: .playing)
        default:
            self.setPlaybackState(to: .notPlaying)
        }
        
        self.updateNowPlaying(with: nowPlaying?.currentSong)
    }
    
    func didUpdateContent(nowPlaying: Music.NowPlaying?) {
        self.updateNowPlaying(with: nowPlaying?.currentSong)
    }
    
}

public extension Notification.Name {
    static let requestMiniPlayerUpdate = Notification.Name(rawValue: "requestMiniPlayerUpdate")
}
