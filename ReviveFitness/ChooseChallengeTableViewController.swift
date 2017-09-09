
import UIKit
import Firebase

class ChooseChallengeTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var challengeChoices = [Challenge]()
    var allChallenges = [Challenge]()
    var activeUser: ReviveUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if challengeChoices.count == 0 {
            return 1
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if challengeChoices.count > 0 && section == 0 {
            return "Your challenges"
        } else {
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if challengeChoices.count == 0 {
            return 1
        } else {
            if section == 0 {
                return challengeChoices.count
            } else {
                return 1
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeCell")!
        if challengeChoices.count == 0 || indexPath.section == 1 {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = "Join new challenge"
        } else if indexPath.row < challengeChoices.count {
            let cellChallenge = challengeChoices[indexPath.row]
            cell.textLabel?.text = cellChallenge.name
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if challengeChoices.count > 0 &&
            indexPath.row < challengeChoices.count &&
            indexPath.section == 0 {
            
            let chosenChallenge = challengeChoices[indexPath.row]
            if let user = activeUser {
                user.activeChallenge = chosenChallenge
                setUserData(of: user, forChallenge: chosenChallenge)
            }
            activeUser?.activeChallenge = chosenChallenge
        } else if (indexPath.section == 1 && indexPath.row == 0) ||
            (challengeChoices.count == 0 && indexPath.section == 0 && indexPath.row == 0){
            performSegue(withIdentifier: "SignUpChooseChallenge", sender: self)
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
        } else if segue.identifier == "SignUpChooseChallenge" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! SignUpChooseChallengeTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.activeUser
            let filteredChallenges = filterChallenges()
            controller.challengeChoices = filteredChallenges
        }
    }
    
    func filterChallenges() -> [Challenge] {
        var filteredChallenges = [Challenge]()
        
        for eachChallenge in allChallenges {
            if !challengeChoices.contains(eachChallenge) {
                filteredChallenges.append(eachChallenge)
            }
        }
        
        return filteredChallenges
    }
    
}
