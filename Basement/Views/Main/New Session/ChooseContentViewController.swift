//
//  ChooseContentViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit
import KeyboardLayoutGuide

class ChooseContentViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var searchField: UITextField!
    @IBOutlet weak private var resultsTable: UITableView!
    
    // MARK: Properties
    var feedbackDelegate: SelectedContentFeedback?
    
    private(set) var selected: [Music.Content] = []
    private(set) var results: [Music.Content] = [] {
        didSet {
            self.results.sort(by: {$0.name < $1.name})
            
            DispatchQueue.main.async {
                self.resultsTable.reloadData()
            }
        }
    }
    private(set) var containedResults: Music.ContentContainer? = nil {
        didSet {
            (self.containedResults as? Music.Playlist)?.updateSongs(completion: { (_) in
                DispatchQueue.main.async {
                    self.resultsTable.reloadData()
                }
            })
            (self.containedResults as? Music.Album)?.updateSongs(completion: { (_) in
                DispatchQueue.main.async {
                    self.resultsTable.reloadData()
                }
            })
        }
    }

    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.isModalInPresentation = true
        
        self.searchField.becomeFirstResponder()
        self.addTextFieldEvents()
        
        self.resultsTable.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView), name: .imageDidLoad, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.searchField.resignFirstResponder()
        self.removeTextFieldEvents()
        NotificationCenter.default.removeObserver(self, name: .imageDidLoad, object: nil)
    }
    
    // MARK: Methods
    @objc private func reloadTableView() {
        self.resultsTable.reloadData()
    }
    
    func search() {
        guard let searchTerm = self.searchField.text else { return }
        if searchTerm.isEmpty {
            self.results.removeAll()
            return
        }
        
        AppleMusicAPI.currentSession.amber?.searchCatalogResources(searchTerm: searchTerm, limit: 15) { (result) in
            switch result {
            case .success(let results):
                DispatchQueue.main.async {
                    guard searchTerm == self.searchField.text else { return }
                    
                    DispatchQueue.global(qos: .userInteractive).async {
                        self.results.removeAll()
                        
                        if let songs = results.songs?.data {
                            songs.forEach({self.results.append(Music.Song(amber: $0.attributes))})
                        }
                        
                        if let albums = results.albums?.data {
                            albums.forEach({self.results.append(Music.Album(amber: $0.attributes))})
                        }
                        
                        if let playlists = results.playlists?.data {
                            playlists.forEach({self.results.append(Music.Playlist(amber: $0.attributes))})
                        }
                        
                        self.results.sort(by: {$0.name.levenshteinDistanceScore(to: searchTerm) > $1.name.levenshteinDistanceScore(to: searchTerm)})
                    }
                }
            case .failure(let error):
                print("Search failed - \(error)")
            }
        }
    }
    
    private func addTextFieldEvents() {
        self.searchField.addTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
    }
    
    private func removeTextFieldEvents() {
        self.searchField.removeTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
    }
    
    @objc private func textFieldDidEdit(textField: UITextField) {
        if self.containedResults != nil {
            self.containedResults = nil
        }
        
        self.search()
    }
    
    // MARK: IBActions
    @IBAction private func doneTapped(_ sender: UIButton) {
        self.feedbackDelegate?.contentSelected(self.selected)
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension ChooseContentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.containedResults?.songs.count ?? self.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Result", for: indexPath) as! MatchingContentCell
        guard let data = self.containedResults?.songs.retrieve(index: indexPath.row) ?? self.results.retrieve(index: indexPath.row) else { return cell }
        
        cell.setupCell(from: data)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let data = (cell as? MatchingContentCell)?.content else { return }
        
        if data as? Music.Song != nil {
            cell.accessoryType = .none
            cell.accessoryView = nil
            
            if self.selected.contains(data) {
                let checkmarkImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                checkmarkImage.image = UIImage(systemName: "checkmark")
                checkmarkImage.tintColor = .label
                
                cell.accessoryView = checkmarkImage
            } else {
                let plusImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                plusImage.image = UIImage(systemName: "plus")
                plusImage.tintColor = .appleMusic
                
                cell.accessoryView = plusImage
            }
        } else {
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath)
        let data = self.containedResults?.songs[indexPath.row] ?? self.results[indexPath.row]
        
        if let song = data as? Music.Song {
            let checkmarkImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            checkmarkImage.image = UIImage(systemName: "checkmark")
            checkmarkImage.tintColor = .label
            
            cell?.accessoryView = checkmarkImage
            
            self.selected.append(song)
        } else if let container = data as? Music.ContentContainer {
            self.containedResults = container
        }
    }
    
}
