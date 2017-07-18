
import UIKit
import Firebase

class UserProfileViewController: UIViewController, UITableViewDataSource,
UITableViewDelegate, ReportTableViewControllerDelegate, WeeklyReportTableViewControllerDelegate {
    
    var databaseRef: DatabaseReference!
    var activeUser: User?
    var reportForToday: Report?
    var reportToView: Report?
    
    var weeklyReport: WeeklyReport?
    
    var weeklyReportAvailible = false
    var weeklyReportSubmitted = false
    
    var reports: [Report?] = [Report]()
    
    var dayNumberToday: Int! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ee" // Produces int corresponding to day (1 = monday, 2 = tuesday...)
        let dayNumberToday = Int(dateFormatter.string(from: Date()))?.convertDay()
        return dayNumberToday!
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
    
    @IBOutlet weak var weekdayTableView: UITableView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var weeklyReportButton: UIButton!
    
    @IBAction func settingsButtonTapped() {
        performSegue(withIdentifier: "EditProfile", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        weekdayTableView.delegate = self
        weekdayTableView.dataSource = self
        
        addFirebaseObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameLabel.text = activeUser?.firstName
        updateUIElements()
    }
    
    func addFirebaseObservers() {
        if let _ = activeUser {
            let weeklyReportsRef = databaseRef.child("weeklyReports").child("Year-\(currentYear)").child("Week-\(weekNumberToday)")
            let thisWeekUserReportRef = weeklyReportsRef.child(activeUser!.id)
            thisWeekUserReportRef.observe(.value, with: { snapshot in
                if let _ = snapshot.value {
                    self.weeklyReport = self.loadWeeklyReportData(with: snapshot)
                } else {
                    self.weeklyReport = nil
                }
                self.weekdayTableView.reloadData()
                self.updateUIElements()
            })
            
            let dailyReportsRef = databaseRef.child("reports").child("Year-\(currentYear)").child("Week-\(weekNumberToday)")
            let usersDailyReportsForThisWeek = dailyReportsRef.child(activeUser!.id)
            usersDailyReportsForThisWeek.observe(.value, with: { snapshot in
                if let _ = snapshot.value {
                    self.reports = self.loadDailyReportData(with: snapshot)
                } else {
                    self.reports = [Report]()
                }
                self.weekdayTableView.reloadData()
                self.updateUIElements()
            })
        }
    }
    
    // Weekly Report
    
    func isWeeklyReportAvailible() -> Bool {
        if let _ = activeUser {
            if activeUser?.weekNumber == weekNumberToday {
                if dayNumberToday == 7 {
                    return true
                }
            }
        }
        return false
    }
    
    // UI Functions
    
    func updateUIElements() {
        updateLabels()
        updateTableCells()
    }
    
    func updateLabels() {
        if let report = reportForToday {
            reportButton.setTitle("Edit Report", for: .normal)
            scoreLabel.text = String(report.score) + " / 100"
        } else {
            reportButton.setTitle("Add Report", for: .normal)
            scoreLabel.text = "0 / 100"
        }
    }
    
    func updateTableCells() {
        weekdayTableView.reloadData()
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
        } else if segue.identifier == "EditProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ProfileSettingsTableViewController
            controller.activeUser = self.activeUser
            controller.databaseRef = self.databaseRef
        } else if segue.identifier == "WeeklyReport" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! WeeklyReportTableViewController
            controller.delegate = self
            controller.reports = self.reports
        }
    }
    
    // WeekdayTableVC Data Source & Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            performSegue(withIdentifier: "CurrentDayReport", sender: self)
        } else {
            if reportForToday != nil {
                reportToView = reports[indexPath.row + 1]
            } else {
                reportToView = reports[indexPath.row]
            }
            performSegue(withIdentifier: "ViewDayReport", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if weeklyReportSubmitted { return 1 }
        
        if section == 0 {
            return 1
        } else if section == 1 {
            if let _ = reportForToday {
                return reports.count - 1
            } else {
                return reports.count
            }
        } else {
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if weeklyReportSubmitted { return 1 }
        
        if reports.count > 0 {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if weeklyReportSubmitted {
                return "Weekly Report"
            } else {
                return "Today"
            }
        } else if section == 1 {
            return "Earlier this week"
        } else {
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayCell")

        if indexPath.section == 0 && !weeklyReportSubmitted {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            cell?.textLabel?.text = dateFormatter.string(from: Date())
            cell?.accessoryType = .disclosureIndicator
            if let _ = reportForToday {
                let disclosureLabel = cell?.viewWithTag(400) as! UILabel
                disclosureLabel.text = "Edit"
            } else {
                let disclosureLabel = cell?.viewWithTag(400) as! UILabel
                disclosureLabel.text = "Add"
            }
        } else if indexPath.section == 1 {
            var dayIndexForCell = indexPath.row
            if let _ = reportForToday { dayIndexForCell += 1 }
            if reports.endIndex > dayIndexForCell {
                let disclosureLabel = cell?.viewWithTag(400) as! UILabel
                cell?.textLabel?.text = getDay(for: (reports[dayIndexForCell]?.submissionDay)!)
                disclosureLabel.text = "View"
                cell?.accessoryType = .disclosureIndicator
            } else {
                let disclosureLabel = cell?.viewWithTag(400) as! UILabel
                disclosureLabel.text = "No report"
                cell?.accessoryType = .none
            }
        } else if indexPath.section == 0 && indexPath.row == 0 && weeklyReportSubmitted {
            if let _ = weeklyReport {
                let disclosureLabel = cell?.viewWithTag(400) as! UILabel
                disclosureLabel.text = "View"
                cell?.textLabel?.text = "Week \(weeklyReport!.weekId!) Report"
                cell?.accessoryType = .disclosureIndicator
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
        let weekNumberUpdate = ["week": activeUser!.weekNumber + 1]
        userUpdateRef.updateChildValues(weekNumberUpdate)
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
