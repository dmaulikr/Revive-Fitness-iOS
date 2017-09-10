
import UIKit
import Firebase

class SignUpChooseChallengeTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var challengeChoices = [Challenge]()
    var activeUser: ReviveUser?
    var chosenChallenge: Challenge?
    
    var allChallenges: [Challenge]?
    var usersChallenges: [Challenge]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        chosenChallenge = nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return challengeChoices.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Challenges"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeCell")!
        if indexPath.row < challengeChoices.count {
            let cellChallenge = challengeChoices[indexPath.row]
            cell.textLabel?.text = cellChallenge.name
            cell.detailTextLabel?.text = "$40"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < challengeChoices.count {
            chosenChallenge = challengeChoices[indexPath.row]
            performSegue(withIdentifier: "ChallengePayment", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChallengePayment" {
            if let _ = chosenChallenge {
                let navigationController = segue.destination as! UINavigationController
                let controller = navigationController.topViewController as! ChallengePaymentViewController
                controller.databaseRef = self.databaseRef
                controller.activeUser = self.activeUser
                controller.challenge = self.chosenChallenge!
                controller.challengeChoices = self.usersChallenges
                controller.allChallenges = self.allChallenges
            }
        }
    }
    
}
