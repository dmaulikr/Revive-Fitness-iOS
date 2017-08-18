
import UIKit
import FirebaseDatabase

class TeamProfileTableViewController: UITableViewController {
    
    let primaryDataColor = UIColor(red: 255.0 / 255.0, green: 21.0 / 255.0, blue: 0.0 / 255.0, alpha: 1.0)
    let primaryLineColor = UIColor(red: 255.0 / 255.0, green: 21.0 / 255.0, blue: 0.0 / 255.0, alpha: 0.5)
    
    var databaseRef: DatabaseReference!
    var activeTeamId: String?
    var activeTeam: Team?
    var activeUser: ReviveUser?
    var teamMembers = [TeamMember]()
    var teamRankings = [0, 1]
    var didWaitForViewToAppear = false
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var colorKeyLabel: UILabel!
    @IBOutlet weak var graphView: DataPointGraphView!
    
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
        
        let today = Date() // Account for week starting on monday, not sunday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        
        let weekNumberToday = Int(dateFormatter.string(from: yesterday!))
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
    
    var dailyScores: [Int] {
        var tempScores = [0, 0, 0, 0, 0, 0, 0]
        for eachMember in teamMembers {
            for i in 0..<7 {
                tempScores[i] += eachMember.getValueScore(forDay: i)
            }
        }
        return tempScores
    }
    var historicalDailyScores: [Int] {
        var tempScores = [0, 0, 0, 0, 0, 0, 0]
        for eachMember in teamMembers {
            for i in 0..<7 {
                tempScores[i] += eachMember.getHistoricalValueScore(forDay: i)
            }
        }
        return tempScores
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addFirebaseObservers()
        colorizeColorKeyLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initializeRadialViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didWaitForViewToAppear = true
        updateUIElements()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // UI Functions
    
    func updateUIElements() {
        nameLabel.text = "Team \((activeTeam?.teamName)!)"
        setGraphViewValues()
        updateRadialLabels()
        if didWaitForViewToAppear {
            updateRadialLabels()
            updateRadialViews()
            updateGraphView()
        }
    }
    
    func updateRadialLabels() {
        var rankSuffix = ""
        
        switch teamRankings[0] {
        case 1: rankSuffix = "st"
        case 2: rankSuffix = "nd"
        case 3: rankSuffix = "rd"
        default: rankSuffix = "th"
        }
        
        rankTopLabel.text = "\(teamRankings[0])\(rankSuffix)"
        rankBottomLabel.text = "\(teamRankings[1]) teams"
        
        submissionsTopLabel.text = "\(numberOfSubmissions!)"
        submissionsBottomLabel.text = "\(teamMembers.count) reports"
        
        scoreTopLabel.text = "\(scoreThisWeek!)"
        scoreBottomLabel.text = "\(potentialScoreThisWeek!) pts"
    }
    
    func updateRadialViews() {
        
        let teamRank = CGFloat(teamRankings[0] - 1)
        let numberOfTeams = CGFloat(teamRankings[1])
        let rankProgress: CGFloat = 1.0 - (teamRank * (1.0 / numberOfTeams))
        
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
    
    func setGraphViewValues() {
        graphView.dataToGraph = dailyScores
        graphView.secondaryDataToGraph = historicalDailyScores
        graphView.clearGraph()
        graphView.primaryDataColor = self.primaryDataColor
        graphView.primaryLineColor = self.primaryLineColor
        graphView.initializeGraph()
    }
    
    func updateGraphView() {
        graphView.animateDataLines(withDuration: 0.4)
        graphView.animateDataPoints(withDuration: 0.4)
    }
    
    func colorizeColorKeyLabel() {
        colorKeyLabel.textColor = UIColor.lightGray
        let colorKeyString = NSMutableAttributedString(
            string: "Team points this week versus last week",
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightUltraLight)])
        colorKeyString.addAttribute(
            NSForegroundColorAttributeName, value: rankTopLabel.textColor, range: NSRange(location: 12,length: 9))
        colorKeyString.addAttribute(
            NSForegroundColorAttributeName, value: UIColor.darkGray, range: NSRange(location: 29,length: 9))
        colorKeyLabel.attributedText = colorKeyString
    }

    // Firebase functions
    
    func addFirebaseObservers() {
        let teamsRef = databaseRef.child("challenges").child(activeUser!.activeChallenge!.id).child("teams").child((activeTeamId)!)
        teamsRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.activeTeam = self.loadTeam(with: snapshot)
                self.updateUIElements()
            }
        })
        let teamMembersRef = databaseRef.child("challenges").child(activeUser!.activeChallenge!.id).child("teamMembers").child((activeTeamId)!)
        teamMembersRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                if let _ = self.activeTeam {
                    self.teamMembers = self.loadTeamMembers(with: snapshot)!
                    self.updateUIElements()
                }
            }
        })
        let teamScoresRef = databaseRef.child("challenges").child(activeUser!.activeChallenge!.id).child("teamScores").child(
            (activeTeamId)!).child("Year-\(currentYear!)").child("Week-\(self.weekNumberToday!)")
        for i in 0..<7 {
            teamScoresRef.child("Day-\(i + 1)").observe(.value, with: { snapshot in
                if let _ = snapshot.value {
                    self.loadTeamScores(with: snapshot, forDay: i)
                    self.addSubmissionObservers()
                
                    let teamLeaderboardRef = self.databaseRef.child("challenges").child(
                        self.activeUser!.activeChallenge!.id).child("teamLeaderboards")
                    let leaderboardUpdate = [self.activeTeamId!: "\(self.scoreThisWeek!)"]
                    teamLeaderboardRef.updateChildValues(leaderboardUpdate)
                }
            })
        }
        let teamHistoricalScoresRef = databaseRef.child("challenges").child(activeUser!.activeChallenge!.id).child("teamScores").child(
            (activeTeamId)!).child("Year-\(currentYear!)").child("Week-\(self.weekNumberToday! - 1)")
        for i in 0..<7 {
            teamHistoricalScoresRef.child("Day-\(i + 1)").observe(.value, with: { snapshot in
                if let _ = snapshot.value {
                    self.loadHistoricalTeamScores(with: snapshot, forDay: i)
                }
            })
        }
        let teamLeaderboardRef = self.databaseRef.child("challenges").child(activeUser!.activeChallenge!.id).child("teamLeaderboards")
        teamLeaderboardRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.teamRankings = self.updateLeaderboards(with: snapshot)
                self.updateUIElements()
            }
        })
    }
    
    func addSubmissionObservers() {
        for eachMember in teamMembers{
            let memberSubmissionRef =
                databaseRef.child("challenges").child(activeUser!.activeChallenge!.id).child("reports").child(
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
    
    func updateLeaderboards(with snapshot: DataSnapshot) -> [Int] {
        var ranking = 1
        var rankingSize = 0
        if let leaderboardsDict = snapshot.value as? [String: String] {
            for eachValue in leaderboardsDict {
                if let points = Int(eachValue.value) {
                    if points > self.scoreThisWeek {
                        ranking += 1
                    }
                    rankingSize += 1
                }
            }
        }
        if rankingSize == 0 { rankingSize = 1 }
        return [ranking, rankingSize]
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
    
    func loadTeamScores(with snapshot: DataSnapshot, forDay day: Int) {
        if let userScoresDict = snapshot.value as? [String: String] {
            for eachUser in userScoresDict {
                if let _ = activeTeam {
                    for eachMember in teamMembers {
                        if eachMember.id == eachUser.key {
                            eachMember.setValueScore(forDay: day, toValue: Int(eachUser.value)!)
                        }
                    }
                }
            }
        }
    }
    func loadHistoricalTeamScores(with snapshot: DataSnapshot, forDay day: Int) {
        if let userScoresDict = snapshot.value as? [String: String] {
            for eachUser in userScoresDict {
                if let _ = activeTeam {
                    for eachMember in teamMembers {
                        if eachMember.id == eachUser.key {
                            eachMember.setHistoricalValueScore(forDay: day, toValue: Int(eachUser.value)!)
                        }
                    }
                }
            }
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
            if let _ = activeTeam {
                if teamMembers.count == activeTeam!.members.count {
                    let member = teamMembers[indexPath.row]
                    let name = member.name
                    cell.textLabel?.text = name
                    if member.getValueDidSubmitToday() {
                        cell.detailTextLabel?.text = "\(member.getValueScore(forDay: dayNumberToday - 1)) pts"
                        cell.detailTextLabel?.textColor = rankTopLabel.textColor
                        cell.accessoryType = .checkmark
                    } else {
                        cell.detailTextLabel?.text = "Not submitted"
                        cell.detailTextLabel?.textColor = UIColor.lightGray
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
