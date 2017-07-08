
import UIKit

protocol ReportTableViewControllerDelegate: class {
    func reportTableViewControllerDidCancel(_ controller: ReportTableViewController)
    func reportTableViewController(_ controller: ReportTableViewController,
                                   didFinishWith report: Report)
}

class ReportTableViewController: UITableViewController {
    
    @IBOutlet weak var mealStepper: UIStepper!
    @IBOutlet weak var snackStepper: UIStepper!
    
    @IBOutlet weak var workoutSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var mealScoreLabel: UILabel!
    @IBOutlet weak var snackScoreLabel: UILabel!
    @IBOutlet weak var pointsScoreLabel: UILabel!
    
    @IBOutlet weak var sleepSwitch: UISwitch!
    @IBOutlet weak var waterSwitch: UISwitch!
    @IBOutlet weak var oldHabitSwitch: UISwitch!
    @IBOutlet weak var newHabitSwitch: UISwitch!
    @IBOutlet weak var communicationSwitch: UISwitch!
    @IBOutlet weak var scaleSwitch: UISwitch!
    
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIButton!
    
    weak var delegate: ReportTableViewControllerDelegate?
    weak var reportToEdit: Report?
    
    var isReportViewOnly = false
    var mealScore = 5
    var snackScore = 0
    var pointsScore = 0
    
    @IBAction func save() {
        if isReportViewOnly {
            delegate?.reportTableViewControllerDidCancel(self)
        } else {
            let report = Report(meals: mealScore, snacks: snackScore,
                                workoutType: workoutSegmentedControl.selectedSegmentIndex,
                                sleep: sleepSwitch.isOn, water: waterSwitch.isOn,
                                oldHabit: oldHabitSwitch.isOn, newHabit: newHabitSwitch.isOn,
                                communication: communicationSwitch.isOn,
                                scale: scaleSwitch.isOn, score: pointsScore)
        
            delegate?.reportTableViewController(self, didFinishWith: report)
        }
    }
    
    @IBAction func cancel() {
        delegate?.reportTableViewControllerDidCancel(self)
    }
    
    @IBAction func stepperScoreChanged(sender: UIStepper) {
        updateLabels()
    }
    
    @IBAction func updateScore() {
        updateLabels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let report = reportToEdit {
            self.navigationItem.title = "Edit Report"
            
            sleepSwitch.setOn(report.sleep, animated: false)
            waterSwitch.setOn(report.water, animated: false)
            oldHabitSwitch.setOn(report.oldHabit, animated: false)
            newHabitSwitch.setOn(report.newHabit, animated: false)
            communicationSwitch.setOn(report.communication, animated: false)
            scaleSwitch.setOn(report.scale, animated: false)
            
            mealStepper.value = Double(report.meals)
            snackStepper.value = Double(report.snacks)
            
            workoutSegmentedControl.selectedSegmentIndex = report.workoutType
            
            if isReportViewOnly {
                disableUIElements()
                self.navigationItem.title = "View Report"
                saveBarButton.title = "Done"
                cancelBarButton.title = "< Back"
                saveButton.setTitle("Done", for: .normal)
            }
            
        }
        updateLabels()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func updatePointsScore() {
        pointsScore = 0
        
        if sleepSwitch.isOn { pointsScore += 15 }
        if waterSwitch.isOn { pointsScore += 10 }
        if oldHabitSwitch.isOn { pointsScore += 10 }
        if newHabitSwitch.isOn { pointsScore += 10 }
        if communicationSwitch.isOn { pointsScore += 5 }
        
        pointsScore += (6 * mealScore)
        pointsScore -= (10 * snackScore)
        
        if workoutSegmentedControl.selectedSegmentIndex == 2 {
            pointsScore += 20
        } else if workoutSegmentedControl.selectedSegmentIndex == 1 {
            pointsScore += 10
        }
        
        if scaleSwitch.isOn { pointsScore -= 10 }
    }
    
    func updateLabels() {
        mealScore = Int(mealStepper.value)
        snackScore = Int(snackStepper.value)
        mealScoreLabel.text = String(mealScore)
        snackScoreLabel.text = String(snackScore)
        updatePointsScore()
        pointsScoreLabel.text = String(pointsScore) + " / 100"
        tableView.reloadData()
    }
    
    func disableUIElements() {
        sleepSwitch.isEnabled = false
        waterSwitch.isEnabled = false
        oldHabitSwitch.isEnabled = false
        newHabitSwitch.isEnabled = false
        communicationSwitch.isEnabled = false
        scaleSwitch.isEnabled = false
        mealStepper.isEnabled = false
        snackStepper.isEnabled = false
        workoutSegmentedControl.isEnabled = false
        
    }
}
