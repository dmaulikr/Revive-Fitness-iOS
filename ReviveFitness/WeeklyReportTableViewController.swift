
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
    @IBOutlet weak var scoreLabel: UILabel!
    
    
    @IBOutlet weak var oldHabitSwitch: UISwitch!
    @IBOutlet weak var newHabitSwitch: UISwitch!
    @IBOutlet weak var oldHabitTextField: UITextField!
    @IBOutlet weak var newHabitTextField: UITextField!
    @IBOutlet weak var fitnessGoalLabel: UILabel!
    @IBOutlet weak var fitnessGoalSwitch: UISwitch!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var bodyFatLabel: UILabel!
    @IBOutlet weak var weightStepper: UIStepper!
    @IBOutlet weak var bodyFatStepper: UIStepper!
    
    var weekScore = 0
    let fitnessGoalMultiplier = 1.2
    var fitnessGoalInitialText = ""
    var oldHabitInitialText = ""
    var newHabitInitialText = ""
    var initialWeight = 1
    var initialBodyFat = 1
    
    weak var delegate: WeeklyReportTableViewControllerDelegate?
    var reports: [Report?] = [Report]()
    
    @IBAction func save() {
        let report = WeeklyReport(weekScore: weekScore,
                                  changedOld: oldHabitSwitch.isOn, changedNew: newHabitSwitch.isOn,
                                  oldHabit: oldHabitTextField.text!, newHabit: newHabitTextField.text!,
                                  completedGoal: fitnessGoalSwitch.isOn,
                                  newWeight: Int(weightStepper.value),
                                  newBodyFat: Int(bodyFatStepper.value))
        delegate?.weeklyReportTableViewController(self, didFinishWith: report)
    }
    
    @IBAction func cancel() {
        delegate?.weeklyReportTableViewControllerDidCancel(self)
    }
    
    @IBAction func stepperScoreChanged(sender: UIStepper) {
        updateLabels()
    }
    
    @IBAction func habitSwitchChanged() {
        oldHabitTextField.isEnabled = oldHabitSwitch.isOn
        newHabitTextField.isEnabled = newHabitSwitch.isOn
        updateLabels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setInitialValues()
        updateLabels()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setInitialValues() {
        fitnessGoalLabel.text = fitnessGoalInitialText
        oldHabitTextField.text = oldHabitInitialText
        newHabitTextField.text = newHabitInitialText
        weightStepper.stepValue = Double(initialWeight)
        bodyFatStepper.stepValue = Double(initialBodyFat)
    }
    
    func updatePointsScore() {
        weekScore = 0
        
        for eachReport in reports {
            if let _ = eachReport {
                weekScore += eachReport!.score
            }
        }
        
        if oldHabitSwitch.isOn { weekScore -= 10 }
        if newHabitSwitch.isOn { weekScore -= 10 }
        
        if fitnessGoalSwitch.isOn {
            weekScore = Int((Double(weekScore) * fitnessGoalMultiplier).rounded())
        }
    }
    
    func updateLabels() {
        updatePointsScore()
        
        scoreLabel.text = "\(weekScore) / \(Int(700.0 * fitnessGoalMultiplier))"
        weightLabel.text = "\(Int(weightStepper.value)) lbs"
        weightLabel.textColor = fitnessGoalSwitch.onTintColor
        bodyFatLabel.text = "\(Int(bodyFatStepper.value))%"
        bodyFatLabel.textColor = fitnessGoalSwitch.onTintColor
        
        tableView.reloadData()
    }
}
