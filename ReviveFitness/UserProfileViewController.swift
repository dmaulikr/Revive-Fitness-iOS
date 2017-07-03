
import UIKit
import Firebase

class UserProfileViewController: UIViewController, UITableViewDataSource,
UITableViewDelegate, ReportTableViewControllerDelegate {
    
    var databaseRef: DatabaseReference!
    var activeUser: User?
    var reportForToday: Report?
    
    var reports: [Report?] = [Report?]()
    
    @IBOutlet weak var weekdayTableView: UITableView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weekdayTableView.delegate = self
        weekdayTableView.dataSource = self
        
        //loadReportData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameLabel.text = activeUser?.firstName
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
        }
    }
    
    // WeekdayTableVC Data Source & Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return reports.count
        } else {
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ee" // Produces int corresponding to day (0 = monday, 1 = tuesday...)
        let dayNumberToday = Int(dateFormatter.string(from: Date()))
        
        if indexPath.section == 0 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            cell?.textLabel?.text = dateFormatter.string(from: Date())
            cell?.accessoryType = .disclosureIndicator
            if reports[dayNumberToday!] != nil {
                let disclosureLabel = cell?.viewWithTag(400) as! UILabel
                disclosureLabel.text = ""
            } else {
                let disclosureLabel = cell?.viewWithTag(400) as! UILabel
                disclosureLabel.text = "Add Report"
            }
        } else if indexPath.section == 1 {
            let dayIndexForCell = dayNumberToday! + indexPath.row + 1
            if reports[dayIndexForCell] != nil {
                let disclosureLabel = cell?.viewWithTag(400) as! UILabel
                disclosureLabel.text = ""
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
        print("Do nothing?")
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
    
    func loadReportData(from snapshot: DataSnapshot) -> [Report] {
        var newReports = [Report]()
        
        if let reportsSnapshot = snapshot.value(forKey: "reports") as? DataSnapshot {
            if let usersReportsSnapshot = reportsSnapshot.value(forKey: (activeUser?.id)!) as? DataSnapshot {
                if let userDict = usersReportsSnapshot.value as? [String : NSDictionary] {
                    for eachDay in userDict {
                        let dayDict = userDict[eachDay.key]!
                        let newReport = Report(of: dayDict as! Dictionary<String, String>)
                        newReports[newReport.submissionDay] = newReport
                    }
                }
            }
        }
        return newReports
    }
    
    func saveReport(_ report: Report) {
        let newReportRef = self.databaseRef.child("reports").child(report.userId!).child("\(report.submissionDay)")
        newReportRef.setValue(report.toAnyObject())
    }
    
}
