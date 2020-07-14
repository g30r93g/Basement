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
    
    // MARK: View Controller Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        Music.session.playbackDelegate = self
        self.updateView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        Music.session.playbackDelegate = nil
    }
    
    // MARK: Methods
    private func updateView() {
        // Prevent display of now playing view if is not playing
        if PlaybackManager.current.playback.state == .notPlaying {
            self.dismiss(animated: true) {
                if let topVC = UIApplication.getPresentedViewController() {
                    let nowPlayingStoryboard = UIStoryboard(name: "SetupSession", bundle: nil)
                    guard let nowPlayingVC = nowPlayingStoryboard.instantiateInitialViewController() else { fatalError() }

                    topVC.present(nowPlayingVC, animated: true, completion: nil)
                }
            }
            
            return
        }
        
        // Show current song
        let currentPlayback = PlaybackManager.current.playback
        if let currentSong = currentPlayback.currentSong {
            self.backgroundImage.image = currentSong.streamingInformation.artwork?.image
            self.artworkImage.image = currentSong.streamingInformation.artwork?.image

            self.titleLabel.text = "\(currentSong.name)"
            self.subtitleLabel.text = "\(currentSong.artist) • Playing from \(currentSong.streamingInformation.platform.name)"
            
            let runtime = currentSong.runtime / 1000
            self.contentDurationLabel.text = "\((runtime / 60).twoDigits()):\((runtime % 60).twoDigits())"
            
            self.timeLapsedLabel.text = "\((currentPlayback.currentPlaybackRuntime / 60).twoDigits()):\((currentPlayback.currentPlaybackRuntime % 60).twoDigits())"
            self.scrubber.minimumValue = 0
            self.scrubber.maximumValue = Float(currentSong.runtime)
        }
        
        // Show listener count
        if let session = SessionManager.current.session {
            self.listenersButton.setTitle("\(session.isHost ? session.listeners.count : session.listeners.count - 1) \(session.isHost ? "listening" : "other listeners")", for: .normal)
        }
    }
    
    // MARK: IBActions
    @IBAction private func playPauseTapped(_ sender: UIButton) {
        switch PlaybackManager.current.playback.state {
        case .playing:
            self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            PlaybackManager.current.performPlaybackCommand(.pause)
        case .paused:
            self.playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            PlaybackManager.current.performPlaybackCommand(.play)
        default:
            break
        }
    }
    
    @IBAction private func rewindTapped(_ sender: UIButton) {
        if PlaybackManager.current.playback.currentPlaybackRuntime < 3000 {
            PlaybackManager.current.performPlaybackCommand(.previous)
        } else {
            PlaybackManager.current.performPlaybackCommand(.restart)
        }
    }
    
    @IBAction private func forwardTapped(_ sender: UIButton) {
        PlaybackManager.current.performPlaybackCommand(.next)
    }
    
    @IBAction private func playbackScrubberChangedValue(_ sender: UISlider) {
        PlaybackManager.current.performPlaybackCommand(.skip(Int(sender.value)))
    }
    
    @IBAction private func audioRouteTapped(_ sender: AVRoutePickerViewButton) {
        sender.presentRoutePicker()
    }
    
    @IBAction private func listenersTapped(_ sender: UIButton) {
        
    }
    
    @IBAction private func queueTapped(_ semder: UIButton) {
        
    }

}
