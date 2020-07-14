//
//  ContentViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 14/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit
import Amber

class ContentViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var navigationBlur: UIVisualEffectView!
    @IBOutlet weak private var navigationHeight: NSLayoutConstraint!
    @IBOutlet weak private var navigationBar: UIView!
    @IBOutlet weak private var navigationTitle: UILabel!
    
    @IBOutlet weak private var contentTableView: UITableView!
    
    // MARK: Properties
    var content: Music.ContentContainer?
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    // MARK: Methods
    public func loadAlbumForSong(_ song: Music.Song) {
        AppleMusicAPI.currentSession.amber?.getCatalogSongByRelationship(identifier: song.streamingInformation.identifier, relationship: .albums, include: [.tracks], completion: { (result: Result<Album, AmberError>) in
            switch result {
            case .success(let album):
                if let albumTracks = album.relationships?.tracks?.data {
                    let convertedTracks = albumTracks.map({Music.Song(amber: $0.attributes)})
                    self.content = Music.Album(amber: album.attributes, songs: convertedTracks)
                } else {
                    self.content = Music.Album(amber: album.attributes)
                }
                
                DispatchQueue.main.async {
                    self.setupView() {
                        guard let indexOfRequestedSong = self.content?.songs.firstIndex(of: song) else { return }
                        let indexPathOfRequestedSong = IndexPath(row: indexOfRequestedSong, section: 0)
                        
                        self.contentTableView.scrollToRow(at: indexPathOfRequestedSong, at: .none, animated: true)
                    }
                }
            case .failure(let error):
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
    
    private func setupView(completion: (() -> Void)? = nil) {
        self.navigationHeight.constant = self.view.safeAreaInsets.top
        
        self.contentTableView.reloadData()
        self.contentTableView.contentInset.bottom = 120
        
        self.setupNotifications()
        
        if let playlist = self.content as? Music.Playlist {
            playlist.updateSongs { (_) in
                DispatchQueue.main.async {
                    self.contentTableView.reloadData()
                    completion?()
                }
            }
        } else if let album = self.content as? Music.Album {
            album.updateSongs { (_) in
                DispatchQueue.main.async {
                    self.contentTableView.reloadData()
                    completion?()
                }
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadView), name: .imageDidLoad, object: nil)
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .imageDidLoad, object: nil)
    }
    
    @objc private func reloadView() {
        self.contentTableView.reloadData()
    }
    
    private func addToSession(_ content: [Music.Content], completion: ((Bool) -> Void)? = nil) {
        // Setup session if setup and session are both nil in `SessionManager`
        if SessionManager.current.setup == nil && SessionManager.current.session == nil {
            SessionManager.current.setupSession()
        }
        
        if SessionManager.current.setup != nil && SessionManager.current.session == nil {
            // Add to setup
            if let setup = SessionManager.current.setup, setup.content.hasCommonElements(content) {
                // Inform user content is already in stream, and whether they'd like to add anyway, ignore duplicates, or cancel
                
                let duplicateAlert = UIAlertController(title: "Some content is already part of your session", message: "What would you like to do?", preferredStyle: .alert)
                
                let addAnyway = UIAlertAction(title: "Add Anyway", style: .default) { (alert) in
                    SessionManager.current.addContentToSetup(content)
                    completion?(true)
                }
                
                let ignoreDuplicates = UIAlertAction(title: "Ignore Duplicates", style: .default) { (alert) in
                    var contentToAdd = content
                    contentToAdd.removeAll(where: {setup.content.contains($0)})
                    
                    SessionManager.current.addContentToSetup(contentToAdd)
                    completion?(true)
                }
                
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                duplicateAlert.addAction(addAnyway)
                duplicateAlert.addAction(ignoreDuplicates)
                duplicateAlert.addAction(cancel)
                
                self.present(duplicateAlert, animated: true, completion: nil)
            } else {
                SessionManager.current.addContentToSetup(content)
                completion?(true)
            }
        } else {
            // Add to current session
            SessionManager.current.session?.addContent(content)
            
            if let currentSession = SessionManager.current.session {
                SessionManager.current.updateSession(currentSession) { (result) in
                    switch result {
                    case .success(_):
                        completion?(true)
                        break
                        // Show user a notification that content has been added
                    case .failure(_):
                        completion?(false)
                        break
                        // Show user a notification that content has not been added due to failure
                    }
                }
            }
        }
    }
    
    // MARK: IBActions
    @IBAction private func dismissTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func addToSessionTapped(_ sender: UIButton) {
        // TODO: Notify user that songs failed to add
        guard let songsToAdd = self.content?.songs else { return }
        
        self.addToSession(songsToAdd)
    }
    
    @IBAction private func addToLibrary(_ sender: UIButton) {
        // TODO: Add song to user library. Determine which streaming platform to add to.
    }

}

extension ContentViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.content == nil { return 0 }
        
        return (self.content?.songs.count ?? 0) + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Content Overview", for: indexPath) as! ContentOverviewCell
            guard let data = self.content else { return UITableViewCell() }
            
            cell.setupCell(from: data)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Song", for: indexPath) as! ContentCell
            
            if let data = self.content?.songs.retrieve(index: indexPath.row - 1) {
                cell.setupCell(from: data)
                cell.optionsPresentationDelegate = self
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 400
        } else {
            return 70
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row != 0,
              let dataForCell = self.content?.songs.retrieve(index: indexPath.row - 1)
        else { return nil }
        
        // Add to Session
        let addToSessionAction = UIContextualAction(style: .normal, title: "Add to Session", handler: { (action, view, actionPerformed) in
            // Perform Add to Session
            self.addToSession([dataForCell], completion: actionPerformed)
        })
        addToSessionAction.backgroundColor = .systemTeal
        addToSessionAction.image = UIImage(systemName: "badge.plus.radiowaves.right")
        
        return UISwipeActionsConfiguration(actions: [addToSessionAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row != 0,
              let dataForCell = self.content?.songs.retrieve(index: indexPath.row - 1)
        else { return nil }
        
        // Add to Library
        let addToLibraryAction = UIContextualAction(style: .normal, title: "Add to Library", handler: { (action, view, actionPerformed) in
        })
        addToLibraryAction.backgroundColor = #colorLiteral(red: 0, green: 0.8145284057, blue: 0.5811807513, alpha: 1)
        addToLibraryAction.image = UIImage(systemName: "plus")
        
        return UISwipeActionsConfiguration(actions: [addToLibraryAction])
    }
    
}

extension ContentViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        
        if offset < 200 {
            self.navigationHeight.constant = self.view.safeAreaInsets.top
            self.navigationTitle.text = ""
            
            self.navigationBlur.setNeedsLayout()
        } else if offset >= 200 && offset <= 300 {
//            self.navigationHeight.constant = self.view.safeAreaInsets.top + (self.navigationBar.frame.height / (offset - 200))
            self.navigationTitle.textColor = UIColor.tertiarySystemBackground.withAlphaComponent((offset - 200) / 100)
            
            self.navigationBlur.setNeedsLayout()
        } else {
            self.navigationHeight.constant = self.view.safeAreaInsets.top + self.navigationBar.frame.height
            self.navigationTitle.text = self.content?.name
        }
    }
    
}

extension ContentViewController: PresentableOptions {
    
    func presentOptions() {
        print("[ContentVC] Should present options for selected song")
        // Possible Options
        //   • Add to Library
        //   • Add to Session
        //   • Add to Showcase
        //   • Share
    }
    
}
