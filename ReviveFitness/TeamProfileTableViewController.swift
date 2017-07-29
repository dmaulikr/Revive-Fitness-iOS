
import UIKit
import FirebaseDatabase


struct UserScore {
    let id: String
    let scoreThisWeek: Int
    var submitted = false
    
    init(id: String, score: Int) {
        self.id = id
        self.scoreThisWeek = score
    }
}

class TeamProfileTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var activeTeamId: String?
    var activeTeam: Team?
    var activeUser: User?
    var teamMemberScores = [String: UserScore]()
    var teamMemberArray = [UserScore]()
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var rankRadialView: RadialProgressView!
    @IBOutlet weak var submissionsRadialView: RadialProgressView!
    @IBOutlet weak var scoreRadialView: RadialProgressView!
    
    @IBOutlet weak var rankTopLabel: UILabel!
    @IBOutlet weak var rankBottomLabel: UILabel!
    @IBOutlet weak var submissionsTopLabel: UILabel!
    @IBOutlet weak var submissionsBottomLabel: UILabel!
    @IBOutlet weak var scoreTopLabel: UILabel!
    @IBOutlet weak var scoreBottomLabel: UILabel!
    
    var dayNumberToday: Int! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ee" // Produces int corresponding to day (1 = monday, 2 = tuesday...)
        let dayNumberToday = Int(dateFormatter.string(from: Date()))?.convertDay()
        return dayNumberToday!
        //return 7 // ALWAYS SUNDAY (for testing purposes
    }
    var weekNumberToday: Int! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ww" // Produces int corresponding to week of year
        let weekNumberToday = Int(dateFormatter.string(from: Date()))
        return weekNumberToday!
    }
    var currentYear: Int! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let currentYear = Int(dateFormatter.string(from: Date()))
        return currentYear!
    }
    var scoreThisWeek: Int! {
        var tempScore = 0
        for eachUserScore in teamMemberScores {
            tempScore += (teamMemberScores[eachUserScore.key]?.scoreThisWeek)!
        }
        return tempScore
    }
    var potentialScoreThisWeek: Int! {
        if dayNumberToday == 7 {
            return activeTeam!.numberOfMembers * 840
        } else {
            return dayNumberToday * 100 * activeTeam!.numberOfMembers
        }
    }
    var numberOfSubmissions: Int! {
        var numSubs = 0
        for eachMember in teamMemberScores {
            if eachMember.value.submitted { numSubs += 1 }
        }
        return numSubs
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addFirebaseObservers()
        
        initializeRadialViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateRadialViews()
    }
    
    // UI Functions
    
    func updateUIElements() {
        updateLabels()
        self.tableView.reloadData()
    }
    
    func updateLabels() {
        nameLabel.text = "Team \((activeTeam?.teamName)!)"
        updateRadialLabels()
    }
    
    func updateRadialLabels() {
        rankTopLabel.text = "3"
        rankBottomLabel.text = "7 teams"
        
        submissionsTopLabel.text = "\(numberOfSubmissions!)"
        submissionsBottomLabel.text = "\(teamMemberScores.count) reports"
        
        scoreTopLabel.text = "\(scoreThisWeek!)"
        scoreBottomLabel.text = "\(potentialScoreThisWeek!) pts"
    }
    
    func updateRadialViews() {
        rankRadialView.setValueAnimated(duration: 1.0, newProgressValue: 0.58)
        submissionsRadialView.setValueAnimated(duration: 1.0, newProgressValue:
            CGFloat(numberOfSubmissions) / CGFloat(teamMemberScores.count))
        scoreRadialView.setValueAnimated(duration: 1.0, newProgressValue:
            CGFloat(scoreThisWeek) / CGFloat(potentialScoreThisWeek))
    }
    
    func initializeRadialViews() {
        // Called once when view loads
        rankRadialView.progressStroke = rankTopLabel.textColor
        rankRadialView.createCircles()
        submissionsRadialView.progressStroke = submissionsTopLabel.textColor
        submissionsRadialView.createCircles()
        scoreRadialView.progressStroke = scoreTopLabel.textColor
        scoreRadialView.createCircles()
    }

    // Firebase functions
    
    func addFirebaseObservers() {
        let teamsRef = databaseRef.child("teams").child((activeTeamId)!)
        teamsRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.activeTeam = self.loadTeam(with: snapshot)
                self.updateUIElements()
            }
        })
        let teamMembersRef = databaseRef.child("teamMembers").child((activeTeamId)!)
        teamMembersRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.activeTeam?.members = self.loadTeamMembers(with: snapshot)!
                self.updateUIElements()
            }
        })
        let teamScoresRef = databaseRef.child("teamScores").child((activeTeamId)!)
        teamScoresRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.teamMemberScores = self.loadUserScores(with: snapshot)
                self.addSubmissionObservers()
                self.updateUIElements()
            }
        })
    }
    
    func addSubmissionObservers() {
        for eachMember in teamMemberScores {
            let memberSubmissionRef =
                databaseRef.child("reports").child(
                    "Year-\(currentYear!)").child(
                        "Week-\(weekNumberToday!)").child(
                            eachMember.key).child(
                                "Day-\(dayNumberToday!)")
            memberSubmissionRef.observe(.value, with: { snapshot in
                if let _ = snapshot.value {
                    self.teamMemberScores[eachMember.key]?.submitted = self.checkUserSubmission(with: snapshot)
                } else {
                    self.teamMemberScores[eachMember.key]?.submitted = false
                }
                self.updateUIElements()
                self.tableView.reloadData()
            })
        }
    }
    
    func checkUserSubmission(with snapshot: DataSnapshot) -> Bool {
        if (snapshot.value as? [String: String]) != nil {
            return true
        } else {
            return false
        }
    }
    
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
    
    func loadUserScores(with snapshot: DataSnapshot) -> [String: UserScore] {
        teamMemberArray = [UserScore]()
        var loadedUserScores = [String: UserScore]()
        if let userScoresDict = snapshot.value as? [String: String] {
            for eachUser in userScoresDict {
                loadedUserScores[eachUser.key] = (UserScore(id: eachUser.key, score: Int(eachUser.value)!))
                teamMemberArray.append(UserScore(id: eachUser.key, score: Int(eachUser.value)!))
            }
        }
        return loadedUserScores
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
        // THIS FUNCTION VERY BUGGY
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell")!
        if indexPath.row < (activeTeam?.members.count)! {
            if teamMemberArray.count == activeTeam?.members.count {
                let member = teamMemberArray[indexPath.row]
                let name = activeTeam?.members[member.id]
                cell.textLabel?.text = name
                if member.submitted {
                    cell.detailTextLabel?.text = "Remind"
                    cell.detailTextLabel?.textColor = rankTopLabel.textColor
                    cell.accessoryType = .none
                } else {
                    cell.detailTextLabel?.text = "Submitted"
                    cell.detailTextLabel?.textColor = UIColor.lightGray
                    cell.accessoryType = .checkmark
                }
            }
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
