//
//  TrackSelectionViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 26/10/2020.
//

import UIKit

class TrackSelectionViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var searchField: UITextField!
    @IBOutlet weak private var resultsTableView: UITableView!
    
    // MARK: Properties
    public var trackSelectionDelegate: TrackSelectionDelegate? = nil
    private var results: [Music.Song] = []
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // MARK: Methods
    private func search() {
        let searchValue = self.currentSearchFieldValue()
        
        PlaybackManager.current.streamingPlatform.search(text: searchValue) { (result) in
            DispatchQueue.main.async {
                let currentSearchValue = self.currentSearchFieldValue()
                guard searchValue == currentSearchValue else { return }
                
                switch result {
                case .success(let matchingResults):
                    guard var songs = matchingResults as? [Music.Song] else { return }
                    songs.sort(by: {$0.name.levenshteinDistanceScore(to: searchValue) > $1.name.levenshteinDistanceScore(to: searchValue)})
                    
                    self.results = songs
                    
                    DispatchQueue.main.async { self.resultsTableView.reloadData() }
                case .failure(_):
                    return
                }
            }
        }
    }
    
    private func currentSearchFieldValue() -> String {
        return self.searchField.text ?? ""
    }
    
}

extension TrackSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Matching Track", for: indexPath) as? ContentCell
        else { return UITableViewCell() }
        let song = self.results[indexPath.row]
        
        cell.setupCell(from: song)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ContentCell,
              let song = cell.musicContent as? Music.Song
        else { return }
        
        self.trackSelectionDelegate?.addTrack(track: song)
        
        cell.select()
    }
    
}

extension TrackSelectionViewController: UITextFieldDelegate {
    
    @IBAction private func searchFieldChangedValue(_ sender: UITextField) {
        self.search()
    }
    
}

