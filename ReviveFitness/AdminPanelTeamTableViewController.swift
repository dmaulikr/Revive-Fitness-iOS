
import UIKit
import Firebase

struct TeamOverview {
    let name: String
    var score: String
    let potentialScore: String
    let memberCount: String
    let id: String
}

class AdminPanelTeamTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var activeChallenge: Challenge!
    var teams = [TeamOverview]()
    
    var dayNumberToday: Int! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ee" // Produces int corresponding to day (1 = monday, 2 = tuesday...)
        let dayNumberToday = Int(dateFormatter.string(from: Date()))?.convertDay()
        return dayNumberToday!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let teamRef = databaseRef.child("challenges").child(activeChallenge!.id).child("teams")
        teamRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.teams = self.loadTeams(with: snapshot)
                self.tableView.reloadData()
            }
        })
        
        let teamLeaderboardsRef = databaseRef.child("challenges").child(activeChallenge!.id).child("teamLeaderboards")
        teamLeaderboardsRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.loadTeamScores(with: snapshot)
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
    
    @IBAction func addUserButtonTapped() {
        performSegue(withIdentifier: "AdminPanelAddUser", sender: self)
    }
    
    func loadTeams(with snapshot: DataSnapshot) -> [TeamOverview] {
        var loadedTeams = [TeamOverview]()
        
        if let teamsDict = snapshot.value as? [String : NSDictionary] {
            for eachTeam in teamsDict {
                let teamDict = teamsDict[eachTeam.key]! as! Dictionary<String, String>
                let teamName = teamDict["teamName"]!
                let numberOfMembers = teamDict["numberOfMembers"]!
                let teamId = teamDict["id"]!
                
                let newTeamOverview = TeamOverview(
                    name: teamName,
                    score: "0",
                    potentialScore: "\(getPotentialScoreThisWeek(Int(numberOfMembers)!)!)",
                    memberCount: numberOfMembers + " / 12",
                    id: teamId)
                loadedTeams.append(newTeamOverview)
            }
        }
        return loadedTeams
    }
    
    func loadTeamScores(with snapshot: DataSnapshot) {
        if let leaderboardsDict = snapshot.value as? [String: String] {
            for eachTeamIndex in teams.indices {
                var tempTeam = teams[eachTeamIndex]
                tempTeam.score = leaderboardsDict[tempTeam.id]!
                teams[eachTeamIndex] = tempTeam
            }
        }
    }
    
    func getPotentialScoreThisWeek(_ numMembers: Int) -> Int! {
        if dayNumberToday == 7 {
            return numMembers * 840
        } else {
            return dayNumberToday * 100 * numMembers
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teams.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeamOverviewCell")
        if indexPath.row < teams.count {
            let team = teams[indexPath.row]
            let nameLabel = cell!.viewWithTag(200) as! UILabel
            let scoreLabel = cell!.viewWithTag(201) as! UILabel
            let membersLabel = cell!.viewWithTag(202) as! UILabel
            nameLabel.text = team.name
            scoreLabel.text = team.score + " / " + team.potentialScore
            membersLabel.text = team.memberCount
        }
        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AdminPanelAddUser" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! AdminPanelAddUserTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeChallenge = self.activeChallenge
        } else if segue.identifier == "AdminPanel" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! AdminPanelChallengeTableViewController
            controller.databaseRef = self.databaseRef
        }
    }
    
}
