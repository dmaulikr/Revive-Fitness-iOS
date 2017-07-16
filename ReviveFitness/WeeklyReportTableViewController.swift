
import UIKit

protocol WeeklyReportTableViewControllerDelegate: class {
    func weeklyReportTableViewControllerDidCancel(_ controller: WeeklyReportTableViewController)
    func weeklyReportTableViewController(_ controller: WeeklyReportTableViewController,
                                   didFinishWith report: WeeklyReport)
}

class WeeklyReportTableViewController: UITableViewController {
    
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIButton!
    
    weak var delegate: WeeklyReportTableViewControllerDelegate?
    var reports: [Report?] = [Report]()
    
    @IBAction func save() {
        let report = WeeklyReport(weekScore: 800)
        delegate?.weeklyReportTableViewController(self, didFinishWith: report)
    }
    
    @IBAction func cancel() {
        delegate?.weeklyReportTableViewControllerDidCancel(self)
    }
    
    @IBAction func stepperScoreChanged(sender: UIStepper) {
        updateLabels()
    }
    
    @IBAction func updateScore() {
        updateLabels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLabels()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func updatePointsScore() {
    }
    
    func updateLabels() {
        updatePointsScore()
        tableView.reloadData()
    }
}
