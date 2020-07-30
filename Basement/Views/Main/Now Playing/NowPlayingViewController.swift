//
//  NowPlayingViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 18/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class NowPlayingViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var backgroundImage: UIImageView!
    @IBOutlet weak private var artworkImage: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subtitleLabel: UILabel!
    @IBOutlet weak private var scrubber: UISlider!
    @IBOutlet weak private var timeLapsedLabel: UILabel!
    @IBOutlet weak private var contentDurationLabel: UILabel!
    @IBOutlet weak private var rewindButton: UIButton!
    @IBOutlet weak private var playPauseButton: UIButton!
    @IBOutlet weak private var forwardButton: UIButton!
    @IBOutlet weak private var audioRouteButton: UIButton!
    @IBOutlet weak private var listenersButton: UIButton!
    @IBOutlet weak private var queueButton: UIButton!
    
    // MARK: Properties
    private var playbackPositionTimer: Timer!
 
    // MARK: View Controller Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        Music.session.playbackDelegate = self
        self.updateView()
        
//        self.scrubber.isUserInteractionEnabled = false
        self.playbackPositionTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (_) in
            self.updatePlaybackPosition()
        })
        self.playbackPositionTimer.fire()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        Music.session.playbackDelegate = nil
    }
    
    // MARK: Methods
    private func updateView() {
        let currentPlayback = PlaybackManager.current.playback
        
        // Prevent display of now playing view if is not playing
        if currentPlayback.state == .notStarted || currentPlayback.state == .ended {
            self.dismiss(animated: true) {
                if let topVC = UIApplication.getPresentedViewController() {
                    let nowPlayingStoryboard = UIStoryboard(name: "SetupSession", bundle: nil)
                    guard let nowPlayingVC = nowPlayingStoryboard.instantiateInitialViewController() else { fatalError() }

                    topVC.present(nowPlayingVC, animated: true, completion: nil)
                }
            }
            
            return
        }
        
        self.updateNowPlayingInformation()
        
        self.updateListenerCount()
    }
    
    private func updateNowPlayingInformation() {
        let currentPlayback = PlaybackManager.current.playback
        
        // Show current song
        if let currentSong = currentPlayback.currentSong {
            self.backgroundImage.image = currentSong.streamingInformation.artwork?.image
            self.artworkImage.image = currentSong.streamingInformation.artwork?.image

            self.titleLabel.text = "\(currentSong.name)"
            self.subtitleLabel.text = "\(currentSong.artist) • Playing from \(currentSong.streamingInformation.platform.name)"
            
            let totalRuntime = currentSong.runtime / 1000
            self.contentDurationLabel.text = "\((totalRuntime / 60)):\((totalRuntime % 60).doubleDigitString())"
            
            self.timeLapsedLabel.text = "\((currentPlayback.runtime / 60)):\((currentPlayback.runtime % 60).doubleDigitString())"
            self.scrubber.minimumValue = 0
            self.scrubber.maximumValue = Float(currentSong.runtime)
        }
    }
    
    private func updateListenerCount() {
        // Show listener count
        if let session = SessionManager.current.session {
            self.listenersButton.setTitle("\(session.isHost ? session.listeners.count : session.listeners.count - 1) \(session.isHost ? "listening" : "other listeners")", for: .normal)
        }
    }
    
    private func updatePlaybackPosition() {
        let currentPlayback = PlaybackManager.current.playback
        guard let currentSong = currentPlayback.currentSong else { return }
        
        let trackRuntime = currentSong.runtime
        let playbackRuntime = currentPlayback.runtime
         
        let runtimeInSecs = playbackRuntime / 1000
        let runtimeMins = runtimeInSecs / 60
        let runtimeSecs = runtimeInSecs % 60
        
        DispatchQueue.main.async {
            if !self.scrubber.isTouchInside {
                self.scrubber.setValue(Float(playbackRuntime), animated: false)
            }
            
            self.timeLapsedLabel.text = "\(runtimeMins):\(runtimeSecs.doubleDigitString())"
        }
    }
    
    // MARK: IBActions
    @IBAction private func playPauseTapped(_ sender: UIButton) {
        switch PlaybackManager.current.playback.state {
        case .playing:
            DispatchQueue.main.async {
                self.playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
            PlaybackManager.current.performPlaybackCommand(.pause)
        case .paused:
            DispatchQueue.main.async {
                self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            }
            PlaybackManager.current.performPlaybackCommand(.play)
        default:
            break
        }
        
        self.updateNowPlayingInformation()
    }
    
    @IBAction private func rewindTapped(_ sender: UIButton) {
        if PlaybackManager.current.playback.runtime < 3000 {
            PlaybackManager.current.performPlaybackCommand(.previous)
        } else {
            PlaybackManager.current.performPlaybackCommand(.restart)
        }
        
        self.updateNowPlayingInformation()
    }
    
    @IBAction private func forwardTapped(_ sender: UIButton) {
        PlaybackManager.current.performPlaybackCommand(.next)
        self.updateNowPlayingInformation()
    }
    
    @IBAction private func playbackScrubberChangedValue(_ sender: UISlider) {
        let playbackPosition = Int(sender.value)
        
        PlaybackManager.current.performPlaybackCommand(.skip(playbackPosition))
        self.updateNowPlayingInformation()
    }
    
    @IBAction private func audioRouteTapped(_ sender: AVRoutePickerViewButton) {
        sender.presentRoutePicker()
    }
    
    @IBAction private func listenersTapped(_ sender: UIButton) {
        // Segues in storyboards to list of listeners
    }
    
    @IBAction private func queueTapped(_ semder: UIButton) {
        // Segues in storyboards to queue
    }

}
