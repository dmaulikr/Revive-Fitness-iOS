
import UIKit
import Firebase

struct Challenge {
    let name: String
    let id: String
}

class AdminPanelChallengeTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var challenges = [Challenge]()
    var selectedChallenge: Challenge?
    
    @IBOutlet weak var challengeNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let challengeRef = databaseRef.child("challengeNames")
        challengeRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.challenges = self.loadChallenges(with: snapshot)
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func submitButtonPressed() {
        if let name = challengeNameTextField.text {
            let newChallengeRef = databaseRef.child("challengeNames").childByAutoId()
            newChallengeRef.setValue(name)
            displayAlert("Challenge Created", "New challenge created with name: \(name)", [""])
        }
    }
    
    func loadChallenges(with snapshot: DataSnapshot) -> [Challenge] {
        var loadedChallenges = [Challenge]()
        if let challengesDict = snapshot.value as? [String: String] {
            for eachChallenge in challengesDict {
                loadedChallenges.append(Challenge(name: eachChallenge.value, id: eachChallenge.key))
            }
            return loadedChallenges
        }
        return loadedChallenges
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Challenges"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return challenges.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeCell")
        if indexPath.row < challenges.count {
            let challengeName = challenges[indexPath.row].name
            cell?.textLabel?.text = challengeName
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedChallenge = challenges[indexPath.row]
        performSegue(withIdentifier: "AdminPanelTeam", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AdminPanelTeam" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! AdminPanelTeamTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeChallenge = selectedChallenge!
        } else if segue.identifier == "AdminPanelLogOut" {
            
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
            } catch {
            }
        }
    }
    
    func displayAlert(_ title: String, _ messageHeader: String, _ errors: [String]) {
        var message = messageHeader
        for eachError in errors {
            message += eachError
        }
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
    
}
