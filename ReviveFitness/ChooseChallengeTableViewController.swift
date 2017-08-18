
import UIKit
import Firebase

class ChooseChallengeTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var challengeChoices = [Challenge]()
    var activeUser: ReviveUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return challengeChoices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeCell")!
        if indexPath.row < challengeChoices.count {
            let cellChallenge = challengeChoices[indexPath.row]
            cell.textLabel?.text = cellChallenge.name
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < challengeChoices.count {
            let chosenChallenge = challengeChoices[indexPath.row]
            if let user = activeUser {
                user.activeChallenge = chosenChallenge
                setUserData(of: user, forChallenge: chosenChallenge)
            }
            activeUser?.activeChallenge = chosenChallenge
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setUserData(of user: ReviveUser, forChallenge challenge: Challenge) {
        let userDataRef = self.databaseRef.child("challenges").child(
            challenge.id).child("userData").child(activeUser!.id)
        userDataRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                if let userDataDict = snapshot.value as? [String : String] {
                    user.loadUserData(from: userDataDict)
                }
            }
            if user.isProfileComplete() {
                self.performSegue(withIdentifier: "UserProfile", sender: self)
            } else {
                self.performSegue(withIdentifier: "CompleteProfile", sender: self)
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UserProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ProfileTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.activeUser
        } else if segue.identifier == "CompleteProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ProfileSettingsTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.activeUser
            controller.firstTimeSettings = true
        }
    }
    
}
