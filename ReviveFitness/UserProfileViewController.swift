
import UIKit
import Firebase

class UserProfileViewController: UIViewController, UITableViewDataSource,
UITableViewDelegate, ReportTableViewControllerDelegate {
    
    var databaseRef: DatabaseReference!
    var activeUser: User?
    var reportForToday: Report?
    var reportToView: Report?
    
    var weeklyReportAvailible = false
    
    var reports: [Report?] = [Report]()
    
    var dayNumberToday: Int! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ee" // Produces int corresponding to day (1 = monday, 2 = tuesday...)
        let dayNumberToday = Int(dateFormatter.string(from: Date()))?.convertDay()
        return dayNumberToday!
    }
    
    @IBOutlet weak var weekdayTableView: UITableView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    
    @IBAction func settingsButtonTapped() {
        performSegue(withIdentifier: "EditProfile", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        weekdayTableView.delegate = self
        weekdayTableView.dataSource = self
        
        if dayNumberToday == 7 {
            weeklyReportAvailible = true
        }
        
        // TEST REPORT CREATION
        /*
        for i in 1...6 {
            let report = Report(meals: 2, snacks: 2, workoutType: 1, sleep: true, water: true, oldHabit: true, newHabit: false, communication: true, scale: true, score: 700 + i)
            report.userId = activeUser?.id
            let newReportRef = self.databaseRef.child("reports").child(report.userId!).child("Day\(i)")
            newReportRef.setValue(report.toAnyObject())
        }*/
        
        databaseRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.reports = self.updateReportData(with: snapshot)
            }
            self.weekdayTableView.reloadData()
            self.updateUIElements()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameLabel.text = activeUser?.firstName
        updateUIElements()
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
        
        if weeklyReportAvailible {
            reportButton.setTitle("Weekly Report", for: .normal)
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
        if reports.count > 0 {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Today"
        } else if section == 1 {
            return "Earlier this week"
        } else {
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayCell")
        
        if indexPath.section == 0 {
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
    
    // Firebase Report Data
    
    func updateReportData(with snapshot: DataSnapshot) -> [Report] {
        var newReports = [Report]()
        
        if let snapshotDict = snapshot.value as? [String : NSDictionary] {
            if let reportsDict = snapshotDict["reports"] as? [String : NSDictionary] {
                for eachUserId in reportsDict {
                    if let user = activeUser {
                        if eachUserId.key == user.id {
                            if let usersReportsDict = reportsDict[eachUserId.key] as? [String : NSDictionary] {
                                for eachReport in usersReportsDict {
                                    let reportDict = usersReportsDict[eachReport.key]!
                                    let newReport = Report(of: reportDict as! Dictionary<String, String>)
                                    newReports.append(newReport)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        newReports = newReports.sorted(by: { $0.submissionDay > $1.submissionDay })
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ee" // Produces int corresponding to day (0 = monday, 1 = tuesday...)
        let dayNumberToday = Int(dateFormatter.string(from: Date()))?.convertDay()
        if newReports.count > 0 {
            if dayNumberToday! == newReports[0].submissionDay {
                reportForToday = newReports[0]
            }
        }
        return newReports
    }
    
    func saveReport(_ report: Report) {
        let newReportRef = self.databaseRef.child("reports").child(report.userId!).child("Day\(report.submissionDay!)")
        newReportRef.setValue(report.toAnyObject())
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
