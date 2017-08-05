
import UIKit
import Firebase

class ProfileTableViewController: UITableViewController,
ReportTableViewControllerDelegate, WeeklyReportTableViewControllerDelegate,
ProfileSettingsTableViewControllerDelegate {
    
    var databaseRef: DatabaseReference!
    var activeUser: User?
    var reportForToday: Report?
    var reportToView: Report?
    
    var weeklyReport: WeeklyReport?
    
    var weeklyReportAvailible = false
    var weeklyReportSubmitted = false
    
    var reports: [Report?] = [Report]()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var weeklyReportButton: UIButton!
    
    @IBOutlet weak var graphView: DataPointGraphView!
    @IBOutlet weak var colorKeyLabel: UILabel!
    
    @IBOutlet weak var goalRadialView: RadialProgressView!
    @IBOutlet weak var weekRadialView: RadialProgressView!
    @IBOutlet weak var todayRadialView: RadialProgressView!
    
    @IBOutlet weak var goalTopLabel: UILabel!
    @IBOutlet weak var goalBottomLabel: UILabel!
    @IBOutlet weak var weekTopLabel: UILabel!
    @IBOutlet weak var weekBottomLabel: UILabel!
    @IBOutlet weak var todayTopLabel: UILabel!
    @IBOutlet weak var todayBottomLabel: UILabel!
    @IBOutlet weak var todayDividerView: UIView!
    @IBOutlet weak var todayRadialAddReportButton: UIButton!
    
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
        if let _ = weeklyReport {
            tempScore = weeklyReport!.weekScore
            return tempScore
        }
        for eachReport in reports {
            tempScore += (eachReport?.score)!
        }
        return tempScore
    }
    
    var potentialScoreThisWeek: Int! {
        if dayNumberToday == 7 {
            return 840
        } else {
            return dayNumberToday * 100
        }
    }
    
    var currentWeightGoalProgressPercentage: CGFloat! {
        if let _ = activeUser?.currentWeight {
            let changeInWeight = CGFloat((activeUser?.targetWeight)! - (activeUser?.startWeight)!)
            let progressSoFar = CGFloat((activeUser?.targetWeight)! - (activeUser?.currentWeight)!)
            return progressSoFar / changeInWeight
        } else if (activeUser?.targetWeight)! == (activeUser?.startWeight)! {
            return 1.0
        } else {
            return 0.0
        }
    }
    
    var weightGoalProgress: Int! {
        if let _ = activeUser?.currentWeight {
            return abs((activeUser?.targetWeight)! - (activeUser?.currentWeight)!)
        } else {
            return 0
        }
    }
    
    var weightGoalType: String! {
        if (activeUser?.targetWeight)! > (activeUser?.startWeight)! {
            return "lbs gained"
        } else if (activeUser?.targetWeight)! < (activeUser?.startWeight)! {
            return "lbs lost"
        } else {
            return "lbs off"
        }
    }
    
    @IBAction func settingsButtonTapped() {
        performSegue(withIdentifier: "EditProfile", sender: self)
    }
    
    @IBAction func teamButtonTapped() {
        if activeUser!.teamId != nil {
            performSegue(withIdentifier: "TeamProfile", sender: self)
        } else {
            performSegue(withIdentifier: "PickTeam", sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addFirebaseObservers()
        
        goalRadialView.progressStroke = goalTopLabel.textColor
        goalRadialView.createCircles()
        weekRadialView.progressStroke = weekTopLabel.textColor
        weekRadialView.createCircles()
        todayRadialView.progressStroke = todayTopLabel.textColor
        todayRadialView.createCircles()
        
        colorizeColorKeyLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUIElements()
        graphView.initializeGraph()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateRadialViews()
        updateGraphView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func addFirebaseObservers() {
        if let _ = activeUser {
            let weeklyReportsRef =
                databaseRef.child("weeklyReports").child("Year-\(currentYear!)").child("Week-\(weekNumberToday!)")
            let thisWeekUserReportRef = weeklyReportsRef.child(activeUser!.id)
            thisWeekUserReportRef.observe(.value, with: { snapshot in
                if let _ = snapshot.value {
                    self.weeklyReport = self.loadWeeklyReportData(with: snapshot)
                    if let _ = self.weeklyReport {
                    } else {
                        self.weeklyReport = nil
                    }
                } else {
                    self.weeklyReport = nil
                }
                self.tableView.reloadData()
                self.updateUIElements()
                self.updateTeamScore()
            })
            
            let dailyReportsRef =
                databaseRef.child("reports").child("Year-\(currentYear!)").child("Week-\(weekNumberToday!)")
            let usersDailyReportsForThisWeek = dailyReportsRef.child(activeUser!.id)
            usersDailyReportsForThisWeek.observe(.value, with: { snapshot in
                if let _ = snapshot.value {
                    self.reports = self.loadDailyReportData(with: snapshot)
                } else {
                    self.reports = [Report]()
                }
                self.tableView.reloadData()
                self.updateUIElements()
                self.updateTeamScore()
            })
        }
    }
    
    func updateTeamScore() {
        if let teamId = activeUser?.teamId {
            let teamScoreRef = databaseRef.child("teamScores").child(teamId)
            let userTeamScoreUpdate = [activeUser!.id: "\(scoreThisWeek!)"]
            teamScoreRef.updateChildValues(userTeamScoreUpdate)
        }
    }
    
    // Weekly Report
    
    func isWeeklyReportAvailible() -> Bool {
        if let _ = activeUser {
            if weeklyReport == nil {
                if dayNumberToday == 7 {
                    if reportForToday != nil {
                        weeklyReportAvailible = true
                        return true
                    }
                }
            }
        }
        weeklyReportAvailible = false
        return false
    }
    
    // UI Functions
    
    func updateUIElements() {
        updateLabels()
        updateWeeklyReportButton()
        self.tableView.reloadData()
    }
    
    func updateLabels() {
        nameLabel.text = "Welcome, \((activeUser?.firstName)!)"
        updateRadialLabels()
    }
    
    func updateRadialLabels() {  
        if let rep = reportForToday {
            todayTopLabel.text = ("\((rep.score)!)")
            todayBottomLabel.text = "100 pts"
            todayDividerView.isHidden = false
            todayRadialAddReportButton.isHidden = true
        } else {
            todayTopLabel.text = ""
            todayBottomLabel.text = ""
            todayDividerView.isHidden = true
            todayRadialAddReportButton.isHidden = false
        }

        weekTopLabel.text = "\(scoreThisWeek!)"
        weekBottomLabel.text = "\(potentialScoreThisWeek!) pts"
        
        goalTopLabel.text = "\(Int(currentWeightGoalProgressPercentage * 100.0))%"
        goalBottomLabel.text = "\(weightGoalProgress!) \(weightGoalType!)"
    }
    
    func updateWeeklyReportButton() {
        if isWeeklyReportAvailible() {
            weeklyReportButton.isHidden = false
        } else {
            weeklyReportButton.isHidden = true
        }
    }
    
    func updateRadialViews() {
        if let rep = reportForToday {
            todayRadialView.setValueAnimated(duration: 1.0, newProgressValue: CGFloat(rep.score) / 100.0)
        } else {
            todayRadialView.setValueAnimated(duration: 1.0, newProgressValue: 0.0)
        }
        weekRadialView.setValueAnimated(duration: 1.0, newProgressValue:
            CGFloat(scoreThisWeek) / CGFloat(potentialScoreThisWeek))
        
        goalRadialView.setValueAnimated(duration: 1.0, newProgressValue: currentWeightGoalProgressPercentage)
    }
    
    func updateGraphView() {
        /*var tempDataArray = [50, 50, 50, 50, 50, 50, 50]
        for eachReport in reports {
            tempDataArray[eachReport!.submissionDay - 1] = eachReport!.score
        }
        graphView.dataToGraph = tempDataArray*/
        graphView.animateDataLines(withDuration: 0.4)
        graphView.animateDataPoints(withDuration: 0.4)
    }
    
    func colorizeColorKeyLabel() {
        colorKeyLabel.textColor = UIColor.lightGray
        let colorKeyString = NSMutableAttributedString(
            string: "Points this week versus your historical average",
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightUltraLight)])
        colorKeyString.addAttribute(
            NSForegroundColorAttributeName, value: goalTopLabel.textColor, range: NSRange(location: 7,length: 10))
        colorKeyString.addAttribute(
            NSForegroundColorAttributeName, value: UIColor.darkGray, range: NSRange(location: 29,length: 18))
        colorKeyLabel.attributedText = colorKeyString
    }
    
    // Segue Control
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CurrentDayReport" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ReportTableViewController
            controller.delegate = self
            
            if let report = reportForToday {
                controller.reportToEdit = report
            }
        } else if segue.identifier == "ViewDayReport" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ReportTableViewController
            controller.delegate = self
            
            if let _ = reportToView {
                controller.reportToEdit = reportToView
                controller.isReportViewOnly = true
            }
        } else if segue.identifier == "ProfileSettings" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ProfileSettingsTableViewController
            controller.activeUser = self.activeUser
            controller.databaseRef = self.databaseRef
            controller.delegate = self
        } else if segue.identifier == "WeeklyReport" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! WeeklyReportTableViewController
            controller.delegate = self
            controller.reports = self.reports
            
            controller.fitnessGoalInitialText = (activeUser?.fitnessGoal)!
            controller.oldHabitInitialText = (activeUser?.oldHabit)!
            controller.newHabitInitialText = (activeUser?.newHabit)!
            
            if let bodyFat = activeUser?.currentBodyFat {
                controller.initialBodyFat = bodyFat
            } else {
                controller.initialBodyFat = (activeUser?.startBodyFat!)!
            }
            if let weight = activeUser?.currentWeight {
                controller.initialWeight = weight
            } else {
                controller.initialWeight = (activeUser?.startWeight)!
            }
        } else if segue.identifier == "ViewWeeklyReport" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! WeeklyReportTableViewController
            controller.delegate = self
            if let _ = weeklyReport {
                controller.reportToView = weeklyReport!
                controller.isReportViewOnly = true
                controller.fitnessGoalInitialText = (activeUser?.fitnessGoal)!
            }
        } else if segue.identifier == "PickTeam" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! PickTeamTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.activeUser
        } else if segue.identifier == "TeamProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! TeamProfileTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.activeUser
            controller.activeTeamId = self.activeUser?.teamId
        }
    }
    
    // TableVC Data Source & Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let weeklyReportCellVisible = weeklyReport != nil || weeklyReportAvailible
        
        if indexPath.section == 0 {
            if weeklyReportCellVisible {
                if let _ = weeklyReport {
                    performSegue(withIdentifier: "ViewWeeklyReport", sender: self)
                } else {
                    performSegue(withIdentifier: "WeeklyReport", sender: self)
                }
            } else {
                performSegue(withIdentifier: "CurrentDayReport", sender: self)
            }
        } else if indexPath.section == 1 {
            if weeklyReportCellVisible {
                if reportForToday != nil {
                    reportToView = reportForToday
                } else {
                    reportToView = reports[0]
                }
                performSegue(withIdentifier: "ViewDayReport", sender: self)
            } else {
                if reportForToday != nil {
                    reportToView = reports[indexPath.row + 1]
                } else {
                    reportToView = reports[indexPath.row]
                }
                performSegue(withIdentifier: "ViewDayReport", sender: self)
            }
        } else if indexPath.section == 2 {
            if reportForToday != nil {
                reportToView = reports[indexPath.row + 1]
            } else {
                reportToView = reports[indexPath.row]
            }
            performSegue(withIdentifier: "ViewDayReport", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let weeklyReportCellVisible = weeklyReport != nil || weeklyReportAvailible
        let reportForTodayExists = reportForToday != nil
        if section == 0 {
            return 1
        } else if section == 1 {
            if weeklyReportCellVisible {
                return 1
            } else {
                if reportForTodayExists {
                    return reports.count - 1
                } else {
                    return reports.count
                }
            }
        } else if section == 2 {
            if reportForTodayExists {
                return reports.count - 1
            } else {
                return reports.count
            }
        } else {
            return 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Min: 1 (because "Today" cell is always visible), Max: 3
        var numSections = 1
        if let _ = weeklyReport { numSections += 1 }
        if (reports.count > 0 && reportForToday == nil) ||
            (reports.count > 1) { numSections += 1 }
        return numSections
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let weeklyReportCellVisible = weeklyReport != nil || weeklyReportAvailible
        if section == 0 {
            if weeklyReportCellVisible {
                return "Weekly Report"
            } else {
                return "Today"
            }
        } else if section == 1 {
            if weeklyReportCellVisible {
                return "Today"
            } else {
                return "Earlier This Week"
            }
        } else if section == 2 {
            return "Earlier This Week"
        } else {
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportCell")
        let weeklyReportCellVisible = (weeklyReport != nil) || weeklyReportAvailible
        let reportForTodayExists = reportForToday != nil
        let today = Date()
        let disclosureLabel = cell?.detailTextLabel
        
        if indexPath.section == 0 {
            if weeklyReportCellVisible {
                let monthDateFormatter = DateFormatter()
                monthDateFormatter.dateFormat = "MMMM" // Produces full month name (eg. "September")
                let weekOfMonthDateFormatter = DateFormatter()
                weekOfMonthDateFormatter.dateFormat = "W"
                cell?.textLabel?.text =
                    monthDateFormatter.string(from: today) + " - Week " + weekOfMonthDateFormatter.string(from: today)
                if let _ = weeklyReport {
                    disclosureLabel?.text = "View"
                } else {
                    disclosureLabel?.text = "Add"
                }
            } else {
                let todayDateFormatter = DateFormatter()
                todayDateFormatter.dateFormat = "EEEE"
                cell?.textLabel?.text = todayDateFormatter.string(from: today)
                if reportForTodayExists {
                    if let _ = weeklyReport {
                        disclosureLabel?.text = "View"
                    } else {
                        disclosureLabel?.text = "Edit"
                    }
                } else {
                    disclosureLabel?.text = "Add"
                }
            }
        } else if indexPath.section == 1 {
            if weeklyReportCellVisible {
                let todayDateFormatter = DateFormatter()
                todayDateFormatter.dateFormat = "EEEE"
                cell?.textLabel?.text = todayDateFormatter.string(from: today)
                if reportForTodayExists {
                    if let _ = weeklyReport {
                        disclosureLabel?.text = "View"
                    } else {
                        disclosureLabel?.text = "Edit"
                    }
                } else {
                    disclosureLabel?.text = "Add"
                }
            } else {
                var dayIndexForCell = indexPath.row
                if reportForTodayExists { dayIndexForCell += 1 }
                if reports.endIndex > dayIndexForCell {
                    cell?.textLabel?.text = getDay(for: (reports[dayIndexForCell]?.submissionDay)!)
                    disclosureLabel?.text = "View"
                }
            }
        } else if indexPath.section == 2 {
            var dayIndexForCell = indexPath.row
            if reportForTodayExists { dayIndexForCell += 1 }
            if reports.endIndex > dayIndexForCell {
                cell?.textLabel?.text = getDay(for: (reports[dayIndexForCell]?.submissionDay)!)
                disclosureLabel?.text = "View"
            }
        }
        
        return cell!
    }
    
    // ReportTableVC Delegate Methods
    
    func reportTableViewControllerDidCancel(_ controller: ReportTableViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func reportTableViewController(_ controller: ReportTableViewController,
                                   didFinishWith report: Report) {
        dismiss(animated: true, completion: nil)
        if let user = activeUser {
            report.userId = user.id
            saveReport(report)
        }
        updateUIElements()
    }
    
    // WeeklyReportTableVC Delegate Methods
    
    func weeklyReportTableViewController(_ controller: WeeklyReportTableViewController,
                                   didFinishWith report: WeeklyReport) {
        dismiss(animated: true, completion: nil)
        if let user = activeUser {
            report.userId = user.id
            report.weekId = weekNumberToday
            saveWeeklyReport(report)
        }
        updateUIElements()
    }
    
    func weeklyReportTableViewControllerDidCancel(_ controller: WeeklyReportTableViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // ProfileSettingsTableVC Delegate Methods
    
    func profileSettingsTableViewController(_ controller: ProfileSettingsTableViewController,
                                            didFinishWith updatedUser: User) {
        activeUser = updatedUser
        updateUIElements()
        dismiss(animated: true, completion: nil)
    }
    
    func profileSettingsTableViewControllerDidCancel(_ controller: ProfileSettingsTableViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Firebase Report Data
    
    func loadDailyReportData(with snapshot: DataSnapshot) -> [Report] {
        var newReports = [Report]()
        
        if let dailyReportsDict = snapshot.value as? [String : NSDictionary] {
            for eachReport in dailyReportsDict {
                let reportDict = dailyReportsDict[eachReport.key]!
                let newReport = Report(of: reportDict as! Dictionary<String, String>)
                newReports.append(newReport)
            }
        }
        
        newReports = newReports.sorted(by: { $0.submissionDay > $1.submissionDay })
        findReportForToday(from: newReports)
        return newReports
    }
    
    func loadWeeklyReportData(with snapshot: DataSnapshot) -> WeeklyReport? {
        if let weekReportDict = snapshot.value as? [String: String] {
            return WeeklyReport(of: weekReportDict)
        } else {
            return nil
        }
    }
    
    func findReportForToday(from newReports: [Report]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ee"
        let dayNumberToday = Int(dateFormatter.string(from: Date()))?.convertDay()
        if newReports.count > 0 {
            if dayNumberToday! == newReports[0].submissionDay {
                self.reportForToday = newReports[0]
            }
        }
    }
    
    func saveReport(_ report: Report) {
        let newReportRef =
            self.databaseRef.child("reports").child(
                "Year-\(currentYear!)").child(
                    "Week-\(weekNumberToday!)").child(
                        activeUser!.id).child(
                            "Day-\(report.submissionDay!)")
        
        newReportRef.setValue(report.toAnyObject())
    }
    
    func saveWeeklyReport(_ weeklyReport: WeeklyReport) {
        let weeklyReportRef = self.databaseRef.child(
            "weeklyReports").child(
                "Year-\(currentYear!)").child(
                    "Week-\(weekNumberToday!)").child(
                        weeklyReport.userId!)
        
        weeklyReportRef.setValue(weeklyReport.toAnyObject())
        
        let userUpdateRef = self.databaseRef.child("users").child(activeUser!.id)
        let weekNumberUpdate = ["week": "\(activeUser!.weekNumber + 1)"]
        userUpdateRef.updateChildValues(weekNumberUpdate)
        
        let userDataUpdateRef = self.databaseRef.child("userData").child(activeUser!.id)
        var userDataUpdate = ["currentWeight": "\(weeklyReport.newWeight!)",
        "currentBodyFat": "\(weeklyReport.newBodyFat!)"] as [String: String]
        
        if weeklyReport.changedOldHabit {
            activeUser?.oldHabit = weeklyReport.oldHabit!
            userDataUpdate["oldHabit"] = "\(weeklyReport.oldHabit!)"
        }
        if weeklyReport.changedNewHabit {
            activeUser?.newHabit = weeklyReport.newHabit!
            userDataUpdate["newHabit"] = "\(weeklyReport.newHabit!)"
        }
        
        activeUser?.currentWeight = weeklyReport.newWeight!
        activeUser?.currentBodyFat = weeklyReport.newBodyFat!
        
        userDataUpdateRef.updateChildValues(userDataUpdate)
    }
    
    func getDay(for number: Int) -> String {
        switch number {
        case 1:
            return "Monday"
        case 2:
            return "Tuesday"
        case 3:
            return "Wednesday"
        case 4:
            return "Thursday"
        case 5:
            return "Friday"
        case 6:
            return "Saturday"
        case 7:
            return "Sunday"
        default:
            return "None"
        }
    }
    
}
