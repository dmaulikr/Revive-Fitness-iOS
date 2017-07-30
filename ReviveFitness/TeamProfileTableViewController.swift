
import UIKit
import FirebaseDatabase

class TeamProfileTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var activeTeamId: String?
    var activeTeam: Team?
    var activeUser: User?
    var teamMembers = [TeamMember]()
    
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
        for eachMember in teamMembers {
            tempScore += eachMember.getValueScoreForThisWeek()
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
        for eachMember in teamMembers {
            if eachMember.getValueDidSubmitToday() { numSubs += 1 }
        }
        return numSubs
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addFirebaseObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initializeRadialViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateUIElements()
    }
    
    // UI Functions
    
    func updateUIElements() {
        nameLabel.text = "Team \((activeTeam?.teamName)!)"
        updateRadialLabels()
        updateRadialViews()
    }
    
    func updateRadialLabels() {
        rankTopLabel.text = "3"
        rankBottomLabel.text = "7 teams"
        
        submissionsTopLabel.text = "\(numberOfSubmissions!)"
        submissionsBottomLabel.text = "\(teamMembers.count) reports"
        
        scoreTopLabel.text = "\(scoreThisWeek!)"
        scoreBottomLabel.text = "\(potentialScoreThisWeek!) pts"
    }
    
    func updateRadialViews() {
        let rankProgress: CGFloat = 0.58
        let submissionsProgress: CGFloat = CGFloat(numberOfSubmissions) / CGFloat(teamMembers.count)
        let scoreProgress: CGFloat = CGFloat(scoreThisWeek) / CGFloat(potentialScoreThisWeek)
        
        if rankRadialView.targetProgress != rankProgress {
            rankRadialView.targetProgress = rankProgress
            rankRadialView.setValueAnimated(duration: 1.0, newProgressValue: rankProgress)
        }
        if submissionsRadialView.targetProgress != submissionsProgress {
            submissionsRadialView.targetProgress = submissionsProgress
            submissionsRadialView.setValueAnimated(duration: 1.0, newProgressValue: submissionsProgress)
        }
        if scoreRadialView.targetProgress != scoreProgress {
            scoreRadialView.targetProgress = scoreProgress
            scoreRadialView.setValueAnimated(duration: 1.0, newProgressValue: scoreProgress)
        }
    }
    
    func initializeRadialViews() {
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
                if let _ = self.activeTeam {
                    self.teamMembers = self.loadTeamMembers(with: snapshot)!
                    self.updateUIElements()
                }
            }
        })
        let teamScoresRef = databaseRef.child("teamScores").child((activeTeamId)!)
        teamScoresRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.loadTeamScores(with: snapshot)
                self.addSubmissionObservers()
            }
        })
    }
    
    func addSubmissionObservers() {
        for eachMember in teamMembers{
            let memberSubmissionRef =
                databaseRef.child("reports").child(
                    "Year-\(currentYear!)").child(
                        "Week-\(weekNumberToday!)").child(
                            eachMember.id).child(
                                "Day-\(dayNumberToday!)")
            memberSubmissionRef.observe(.value, with: { snapshot in
                if let _ = snapshot.value {
                    eachMember.setValueDidSubmitToday(with: self.checkUserSubmission(with: snapshot))
                    self.updateUIElements()
                    self.tableView.reloadData()
                } else {
                    eachMember.setValueDidSubmitToday(with: false)
                }
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
    
    func loadTeamMembers(with snapshot: DataSnapshot) -> [TeamMember]? {
        var newMembers = [TeamMember]()
        if let teamMembersDict = snapshot.value as? [String: String] {
            self.activeTeam!.members = teamMembersDict
            for eachMemberName in teamMembersDict {
                newMembers.append(TeamMember(name: eachMemberName.value, id: eachMemberName.key))
            }
            return newMembers
        } else {
            return nil
        }
    }
    
    func loadTeamScores(with snapshot: DataSnapshot) {
        if let userScoresDict = snapshot.value as? [String: String] {
            for eachUser in userScoresDict {
                if let _ = activeTeam {
                    for eachMember in teamMembers {
                        if eachMember.id == eachUser.key {
                            eachMember.setValueScoreForThisWeek(with: Int(eachUser.value)!)
                        }
                    }
                }
            }
        }
    }
    
    func shouldUpdateUIElements() -> Bool {
        var willUpdate = false
        for eachMember in teamMembers {
            if eachMember.shouldUpdateRadialViews() {
                willUpdate = true
            }
        }
        return willUpdate
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
            if let _ = activeTeam {
                if teamMembers.count == activeTeam!.members.count {
                    let member = teamMembers[indexPath.row]
                    let name = member.name
                    cell.textLabel?.text = name
                    if member.getValueDidSubmitToday() {
                        cell.detailTextLabel?.text = "Submitted"
                        cell.detailTextLabel?.textColor = UIColor.lightGray
                        cell.accessoryType = .checkmark
                    } else {
                        cell.detailTextLabel?.text = "Remind"
                        cell.detailTextLabel?.textColor = rankTopLabel.textColor
                        cell.accessoryType = .none
                    }
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
