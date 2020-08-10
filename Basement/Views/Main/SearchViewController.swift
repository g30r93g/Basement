//
//  SearchViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 18/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit
import KeyboardLayoutGuide

class SearchViewController: UIViewController {
    
    // MARK: Properties
    var contentResults: [Music.Content] = []
    var userResults: [Firebase.UserProfile] = []
    
    // MARK: IBOutlets
    @IBOutlet weak private var searchField: UITextField!
    @IBOutlet weak private var searchTypeSegment: UISegmentedControl!
    @IBOutlet weak private var searchResultsLoadIndicator: UIActivityIndicatorView!
    @IBOutlet weak private var searchResultsTable: UITableView!
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchResultsTable.bottomAnchor.constraint(equalTo: self.view.keyboardLayoutGuide.topAnchor).isActive = true
        NotificationCenter.default.addObserver(self, selector: #selector(reloadView(notification:)), name: .imageDidLoad, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.addTextFieldEvents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.searchField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.removeTextFieldEvents()
    }
    
    // MARK: Methods
    private func addTextFieldEvents() {
        self.searchField.addTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
    }
    
    private func removeTextFieldEvents() {
        self.searchField.removeTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
    }
    
    @objc private func textFieldDidEdit(textField: UITextField) {
        self.search()
    }
    
    @objc private func reloadView(notification: NSNotification) {
        guard let indexPathToRefresh = notification.userInfo?["indexPath"] as? IndexPath else { return }
        
        DispatchQueue.main.async {
            self.searchResultsTable.reloadRows(at: [indexPathToRefresh], with: .fade)
        }
    }
    
    private func search() {
        // TODO: Use CrossPlatform.Search() to search for content
        let searchTerm = self.searchField.text ?? ""
        if searchTerm.isEmpty {
            self.contentResults.removeAll()
            self.userResults.removeAll()
            
            DispatchQueue.main.async { self.searchResultsTable.reloadData() }
            return
        }
        
        if self.searchTypeSegment.selectedSegmentIndex == 0 {
            // Search Apple Music
            AppleMusicAPI.currentSession.amber?.searchCatalogResources(searchTerm: searchTerm, limit: 15) { (result) in
                switch result {
                case .success(let results):
                    DispatchQueue.main.async {
                        guard searchTerm == self.searchField.text,
                              self.searchTypeSegment.selectedSegmentIndex == 0
                        else { self.contentResults.removeAll(); return }
                        
                        DispatchQueue.global(qos: .userInteractive).async {
                            self.contentResults.removeAll()
                            
                            if let songs = results.songs?.data {
                                songs.forEach({self.contentResults.append(Music.Song(amber: $0.attributes))})
                            }
                            
                            if let albums = results.albums?.data {
                                albums.forEach({self.contentResults.append(Music.Album(amber: $0.attributes))})
                            }
                            
                            if let playlists = results.playlists?.data {
                                playlists.forEach({self.contentResults.append(Music.Playlist(amber: $0.attributes))})
                            }
                            
                            self.contentResults.sort(by: {$0.name.levenshteinDistanceScore(to: searchTerm) > $1.name.levenshteinDistanceScore(to: searchTerm)})
                            
                            DispatchQueue.main.async { self.searchResultsTable.reloadData() }
                        }
                    }
                case .failure(let error):
                    print("[SearchVC] Content search on Apple Music failed - \(error)")
                }
            }
        } else if self.searchTypeSegment.selectedSegmentIndex == 1 {
            // Search for users
            Firebase.shared.searchUsers(by: searchTerm, limit: 5) { (result) in
                switch result {
                case .success(let matchingUsers):
                    DispatchQueue.main.async {
                        guard searchTerm == self.searchField.text,
                              self.searchTypeSegment.selectedSegmentIndex == 1
                        else { self.userResults.removeAll(); return }
                        
                        self.userResults = matchingUsers.sorted(by: {$0.information.username.levenshteinDistanceScore(to: searchTerm) > $1.information.username.levenshteinDistanceScore(to: searchTerm)})
                        DispatchQueue.main.async { self.searchResultsTable.reloadData() }
                    }
                case .failure(let error):
                    print("[SearchVC] Failed to search for users with username \(searchTerm) - \(error)")
                }
            }
        } else {
            return
        }
    }
    
    // MARK: IBActions
    @IBAction private func segmentValueChanged(_ sender: UISegmentedControl) {
        self.contentResults.removeAll()
        self.userResults.removeAll()
    }
    
}

extension SearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchField.resignFirstResponder()
        return true
    }
    
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.searchTypeSegment.selectedSegmentIndex {
        case 0:
            return self.contentResults.count
        case 1:
            return self.userResults.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: Display Best Match
        if indexPath.row == 0 {
            // Display best match
            let cell = tableView.dequeueReusableCell(withIdentifier: "Best Match", for: indexPath) as! BestMatchCell
            
            guard let searchTerm = self.searchField.text else { return cell }
            
            if self.searchTypeSegment.selectedSegmentIndex == 0 {
                guard let topContentMatch = self.contentResults.first else { return cell }
                cell.setupCell(from: topContentMatch)
            } else if self.searchTypeSegment.selectedSegmentIndex == 1 {
                guard let topUserMatch = self.userResults.first else { return cell }
                cell.setupCell(from: topUserMatch)
            }
            
            return cell
        } else {
            switch self.searchTypeSegment.selectedSegmentIndex {
            case 0:
                // Display content results
                let cell = tableView.dequeueReusableCell(withIdentifier: "Content", for: indexPath) as! ContentCell
                guard let data = self.contentResults.retrieve(index: indexPath.row) else { return cell }
                
                cell.setupCell(from: data)
                
                return cell
            case 1:
                // Display user
                let cell = tableView.dequeueReusableCell(withIdentifier: "User", for: indexPath) as! FriendCell
                guard let data = self.userResults.retrieve(index: indexPath.row) else { return cell }
                
                cell.setupCell(from: data)
                
                return cell
            default:
                return UITableViewCell()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 330
        } else {
            switch self.searchTypeSegment.selectedSegmentIndex {
            case 0:
                return 70
            case 1:
                return 80
            default:
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.row == 0 {
            // Best Match
            guard let cell = cell as? BestMatchCell else { return }
            
            if let musicContent = cell.musicContent {
                guard let contentVC = storyboard?.instantiateViewController(identifier: "ContentVC") as? ContentViewController else { return }
                self.navigationController?.pushViewController(contentVC, animated: true)
                
                if let contentContainer = musicContent as? Music.ContentContainer {
                    contentVC.content = contentContainer
                } else if let songToFetch = musicContent as? Music.Song {
                    contentVC.loadAlbumForSong(songToFetch)
                }
            } else if let userProfile = cell.userProfile {
                guard let profileVC = storyboard?.instantiateViewController(identifier: "ProfileVC") as? ProfileViewController else { return }
                self.navigationController?.pushViewController(profileVC, animated: true)
                
                if let topVC = self.navigationController?.topViewController as? ProfileViewController {
                    topVC.user = userProfile
                }
            }
        } else if indexPath.row > self.userResults.count {
            // Content
            guard let cell = cell as? ContentCell,
                  let content = cell.musicContent
            else { return }
            
            guard let contentVC = storyboard?.instantiateViewController(identifier: "ContentVC") as? ContentViewController else { return }
            self.navigationController?.pushViewController(contentVC, animated: true)
            
            if let topVC = self.navigationController?.topViewController as? ContentViewController {
                // Content already fetched
                if let contentContainer = content as? Music.ContentContainer {
                    topVC.content = contentContainer
                } else if let songToFetch = content as? Music.Song {
                    topVC.loadAlbumForSong(songToFetch)
                }
            }
        } else {
            // User
            guard let cell = cell as? FriendCell else { return }
            
            if let userProfile = cell.userProfile {
                guard let profileVC = storyboard?.instantiateViewController(identifier: "ProfileVC") as? ProfileViewController else { return }
                self.navigationController?.pushViewController(profileVC, animated: true)
                
                if let topVC = self.navigationController?.topViewController as? ProfileViewController {
                    topVC.user = userProfile
                }
            }
        }
    }
    
}
