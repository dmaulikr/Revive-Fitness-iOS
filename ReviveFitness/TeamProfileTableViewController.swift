
import UIKit
import FirebaseDatabase

class TeamProfileTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var activeTeamId: String?
    var activeTeam: Team?
    var activeUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observe any changes in the database
        let teamsRef = databaseRef.child("teams").child((activeTeamId)!)
        teamsRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.activeTeam = self.loadTeam(with: snapshot)
            }
        })
        let teamMembersRef = databaseRef.child("teamMembers").child((activeTeamId)!)
        teamMembersRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.activeTeam?.members = self.loadTeamMembers(with: snapshot)!
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // Firebase functions
    
    func loadTeam(with snapshot: DataSnapshot) -> Team? {
        if let teamDict = snapshot.value as? [String: String] {
            return Team(of: teamDict)
        } else {
            return nil
        }
    }
    
    func loadTeamMembers(with snapshot: DataSnapshot) -> [String: String]? {
        if let teamMembersDict = snapshot.value as? [String: String] {
            return teamMembersDict
        } else {
            return nil
        }
    }
    
    // Segue Control
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UserProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ProfileTableViewController
            controller.activeUser = self.activeUser
            controller.databaseRef = self.databaseRef
        }
    }
    
    // TableVC Data Source & Delegate Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _ = activeTeam {
            return activeTeam!.members.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell")!
        if indexPath.row < (activeTeam?.members.count)! {
            let user = activeUser // CHANGE THIS TO TEAM USERS
            cell.textLabel?.text = (user?.firstName)! + " " + (user?.lastName)!
            cell.detailTextLabel?.text = "Remind"
            cell.detailTextLabel?.textColor = UIColor.lightGray
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Members"
    }
}
