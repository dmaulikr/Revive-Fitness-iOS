
import UIKit
import FirebaseDatabase

class PickTeamTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var teams = [Team]()
    var chosenTeam: Team?
    var activeUser: User?
    
    final let TEAM_LIMIT = 12
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observe any changes in the database
        let teamsRef = databaseRef.child("teams")
        teamsRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.teams = self.loadTeams(with: snapshot)
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // IBAction Functions
    
    @IBAction func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createTeamButtonTapped() {
        presentTeamCreationAlert()
    }
    
    // TableVC Data Source & Delegate Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if teams.count > 0 {
            return 2
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if teams.count > 0 {
                return teams.count
            } else {
                return 1
            }
        } else if section == 1 {
            return 1
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell!
        if indexPath.section == 0 {
            if teams.count == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "CreateTeamCell")
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "TeamCell")
                if indexPath.row < teams.count {
                    let team = teams[indexPath.row]
                    cell.textLabel?.text = team.teamName
                    cell.detailTextLabel?.text = "\(team.numberOfMembers!)/12"
                    if team.numberOfMembers >= TEAM_LIMIT {
                        cell.detailTextLabel?.textColor = UIColor.lightGray
                    }
                }
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "CreateTeamCell")
        }
        return cell
    }
    
    func loadTeams(with snapshot: DataSnapshot) -> [Team] {
        var loadedTeams = [Team]()
        
        if let teamsDict = snapshot.value as? [String : NSDictionary] {
            for eachTeam in teamsDict {
                let teamDict = teamsDict[eachTeam.key]!
                let loadedTeam = Team(of: teamDict as! Dictionary<String, String>)
                loadedTeams.append(loadedTeam)
            }
        }
        return loadedTeams
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < teams.count {
            if teams[indexPath.row].numberOfMembers < TEAM_LIMIT {
                chosenTeam = teams[indexPath.row]
                joinTeam(chosenTeam!)
                self.performSegue(withIdentifier: "TeamProfile", sender: self)
            } else {
                popFullTeamAlert(with: teams[indexPath.row].teamName)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if tableView.numberOfSections == 1 {
                return ""
            } else {
                return "Join Team"
            }
        } else {
            return ""
        }
    }
    
    // Team Creation
    
    var nameField: UITextField!
    
    func configureTextField(textField: UITextField!) {
        textField.placeholder = "Team name"
        nameField = textField
    }
    
    func presentTeamCreationAlert() {
        let alert = UIAlertController(title: "Create Team", message: "What should the team's name be?", preferredStyle: .alert)
    
        alert.addTextField(configurationHandler: configureTextField)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler:{ (UIAlertAction) in
            if let teamName = self.nameField.text {
                self.saveTeamToFirebase(with: teamName)
                self.performSegue(withIdentifier: "TeamProfile", sender: self)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveTeamToFirebase(with name: String) {
        let teamRef = databaseRef.child("teams").childByAutoId()
        let teamId = teamRef.key
        
        var initialMember = [String : String]()
        initialMember[activeUser!.id] = activeUser!.firstName + " " + activeUser!.lastName
        
        let newTeam = Team(name: name, points: 0, members: initialMember, numMembers: 1, id: teamId)
        teamRef.setValue(newTeam.toAnyObject())
        
        let teamMembersRef = databaseRef.child("teamMembers").child(newTeam.id)
        teamMembersRef.setValue(newTeam.toAnyObjectMembers())
        
        activeUser?.teamId = newTeam.id
        let userUpdateRef = self.databaseRef.child("userData").child(activeUser!.id)
        let teamUpdate = ["team": activeUser!.teamId!]
        userUpdateRef.updateChildValues(teamUpdate)
    }
    
    func joinTeam(_ team: Team) {
        let teamRef = databaseRef.child("teams").child(team.id)
        team.members[activeUser!.id] = activeUser!.firstName + " " + activeUser!.lastName
        team.numberOfMembers = team.numberOfMembers + 1
        teamRef.setValue(team.toAnyObject())
        
        let teamMembersRef = databaseRef.child("teamMembers").child(team.id)
        let teamMemberUpdate = [activeUser!.id: activeUser!.firstName + " " + activeUser!.lastName]
        teamMembersRef.updateChildValues(teamMemberUpdate)
        
        activeUser?.teamId = team.id
        let userUpdateRef = self.databaseRef.child("userData").child(activeUser!.id)
        let teamUpdate = ["team": activeUser!.teamId!]
        userUpdateRef.updateChildValues(teamUpdate)
    }
    
    // UIAlert Controllers
    
    func popFullTeamAlert(with teamName: String) {
        let alert = UIAlertController(title: "Unable to Join",
                                      message: "\(teamName) is full already - please select a different team.",
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    // Segue Control
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TeamProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! TeamProfileTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.activeUser
            controller.activeTeamId = self.activeUser?.teamId
        }
    }
}
