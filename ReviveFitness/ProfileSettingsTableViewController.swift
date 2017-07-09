
import UIKit
import Foundation
import FirebaseDatabase

class ProfileSettingsTableViewController: UITableViewController {
    
    var firstTimeSettings = false
    
    var databaseRef: DatabaseReference!
    var activeUser: User!
    
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var startingWeightTextField: UITextField!
    @IBOutlet weak var bodyFatTextField: UITextField!
    @IBOutlet weak var oldHabitTextField: UITextField!
    @IBOutlet weak var newHabitTextField: UITextField!
    @IBOutlet weak var fitnessGoalTextField: UITextField!
    
    
    @IBAction func saveButton() {
        save()
    }
    
    @IBAction func cancelButton() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if firstTimeSettings {
            enableFirstTimeFields()
        }
        
        setInitialValues()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func save() {
        performSegue(withIdentifier: "SaveProfile", sender: self)
    }
    
    func enableFirstTimeFields() {
        cancelBarButton.isEnabled = false
        ageTextField.isEnabled = true
        startingWeightTextField.isEnabled = true
        bodyFatTextField.isEnabled = true
        oldHabitTextField.isEnabled = true
        newHabitTextField.isEnabled = true
        fitnessGoalTextField.isEnabled = true
    }
    
    func setInitialValues() {
        firstNameTextField.text = activeUser.firstName
        lastNameTextField.text = activeUser.lastName
        emailTextField.text = activeUser.email
        passwordTextField.text = activeUser.password
        phoneTextField.text = activeUser.phone
        ageTextField.text = activeUser.age
        startingWeightTextField.text = activeUser.startWeight
        bodyFatTextField.text = activeUser.startBodyFat
        oldHabitTextField.text = activeUser.oldHabit
        newHabitTextField.text = activeUser.newHabit
        fitnessGoalTextField.text = activeUser.fitnessGoal
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SaveProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! UserProfileViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.activeUser
        }
    }
}
