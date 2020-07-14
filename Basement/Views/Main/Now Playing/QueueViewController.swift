//
//  QueueViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 08/07/2020.
//

import UIKit

class QueueViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var queueTable: UITableView!
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // MARK: Methods
    // TODO: THIS HAS BEEN DUPLICATED FROM `ContentViewController.swift`
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
                        // Show user a notification that content has been added
                    case .failure(_):
                        completion?(false)
                        // Show user a notification that content has not been added due to failure
                    }
                }
            }
        }
    }
    
    // MARK: IBActions
    @IBAction private func backTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

}

extension QueueViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "History"
        case 1:
            return "Playing Next"
        default:
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return PlaybackManager.current.playback.history().count
        } else if section == 1 {
            return PlaybackManager.current.playback.playingNext().count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Content", for: indexPath) as! ContentCell
        
        if indexPath.section == 0 {
            if let data = PlaybackManager.current.playback.history().retrieve(index: indexPath.row) {
                cell.setupCell(from: data)
            }
            
            return cell
        } else if indexPath.section == 1 {
            if let data = PlaybackManager.current.playback.playingNext().retrieve(index: indexPath.row) {
                cell.setupCell(from: data)
            }
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let dataForCell = (tableView.cellForRow(at: indexPath) as? ContentCell)?.musicContent else { return nil }
        
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
        guard let dataForCell = (tableView.cellForRow(at: indexPath) as? ContentCell)?.musicContent else { return nil }
        
        // Add to Library
        let addToLibraryAction = UIContextualAction(style: .normal, title: "Add to Library", handler: { (action, view, actionPerformed) in
        })
        addToLibraryAction.backgroundColor = #colorLiteral(red: 0, green: 0.8145284057, blue: 0.5811807513, alpha: 1)
        addToLibraryAction.image = UIImage(systemName: "plus")
        
        return UISwipeActionsConfiguration(actions: [addToLibraryAction])
    }
    
    
}
