
import UIKit
import Foundation
import FirebaseDatabase

protocol ProfileSettingsTableViewControllerDelegate: class {
    func profileSettingsTableViewControllerDidCancel(_ controller: ProfileSettingsTableViewController)
    func profileSettingsTableViewController(_ controller: ProfileSettingsTableViewController,
                                   didFinishWith updatedUser: User)
}

class ProfileSettingsTableViewController: UITableViewController, UITextFieldDelegate {
    
    var firstTimeSettings = false
    
    var databaseRef: DatabaseReference!
    
    var activeUser: User!
    weak var delegate: ProfileSettingsTableViewControllerDelegate?
    
    var datePickerVisible = false
    
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var startingWeightTextField: UITextField!
    @IBOutlet weak var bodyFatTextField: UITextField!
    @IBOutlet weak var oldHabitTextField: UITextField!
    @IBOutlet weak var newHabitTextField: UITextField!
    @IBOutlet weak var fitnessGoalTextField: UITextField!
    
    @IBOutlet weak var datePickerCell: UITableViewCell!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var birthdateLabel: UILabel!
    
    @IBAction func saveButton() {
        save()
    }
    
    @IBAction func cancelButton() {
        cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if firstTimeSettings {
            enableFirstTimeFields()
        }
        
        setInitialValues()
    }
    
    func save() {
        if fieldsFilled() {
            saveChangesToFirebase()
            updateUserInstance()
            if let _ = delegate {
                delegate?.profileSettingsTableViewController(self, didFinishWith: activeUser)
            } else {
                dismiss(animated: true, completion: nil)
            }
        } else {
            displayError()
        }
    }
    
    func cancel() {
        if let _ = delegate {
            delegate?.profileSettingsTableViewControllerDidCancel(self)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func enableFirstTimeFields() {
        cancelBarButton.isEnabled = false
        startingWeightTextField.isEnabled = true
        bodyFatTextField.isEnabled = true
        oldHabitTextField.isEnabled = true
        newHabitTextField.isEnabled = true
        fitnessGoalTextField.isEnabled = true
        phoneTextField.returnKeyType = .next
        
        let enabledColor = emailTextField.textColor!
        startingWeightTextField.textColor = enabledColor
        bodyFatTextField.textColor = enabledColor
        oldHabitTextField.textColor = enabledColor
        newHabitTextField.textColor = enabledColor
        fitnessGoalTextField.textColor = enabledColor
    }
    
    func setInitialValues() {
        firstNameTextField.text = activeUser.firstName
        lastNameTextField.text = activeUser.lastName
        emailTextField.text = activeUser.email
        passwordTextField.text = activeUser.password
        phoneTextField.text = activeUser.phone
        birthdateLabel.text = activeUser.birthdate
        if let _ = activeUser.startWeight {
            startingWeightTextField.text = "\(activeUser.startWeight!)"
        }
        if let _ = activeUser.startBodyFat {
            bodyFatTextField.text = "\(activeUser.startBodyFat!)"
        }
        oldHabitTextField.text = activeUser.oldHabit
        newHabitTextField.text = activeUser.newHabit
        fitnessGoalTextField.text = activeUser.fitnessGoal
    }
    
    func fieldsFilled() -> Bool {
        return (firstNameTextField.hasText && lastNameTextField.hasText &&
        emailTextField.hasText && passwordTextField.hasText &&
        phoneTextField.hasText && birthdateLabel.text != "" &&
        startingWeightTextField.hasText && bodyFatTextField.hasText &&
        oldHabitTextField.hasText && newHabitTextField.hasText &&
        fitnessGoalTextField.hasText)
    }
    
    func saveChangesToFirebase() {
        let updateUserProfileRef = self.databaseRef.child("users").child(activeUser.id)
        let updateUserDataRef = self.databaseRef.child("userData").child(activeUser.id)
        updateUserProfileRef.setValue(["name-first": firstNameTextField.text!,
                                       "name-last": lastNameTextField.text!,
                                       "email": emailTextField.text!,
                                       "password": passwordTextField.text!,
                                       "id": activeUser.id,
                                       "week": "\(activeUser.weekNumber!)"])
        updateUserDataRef.setValue(["phone": phoneTextField.text!,
                                    "birth": birthdateLabel.text!,
                                    "startWeight": startingWeightTextField.text!,
                                    "startBodyFat": bodyFatTextField.text!,
                                    "oldHabit": oldHabitTextField.text!,
                                    "newHabit": newHabitTextField.text!,
                                    "fitnessGoal": fitnessGoalTextField.text!,
                                    "team": activeUser.teamId])
    }
    
    func updateUserInstance() {
        activeUser.firstName = firstNameTextField.text
        activeUser.lastName = lastNameTextField.text
        activeUser.email = emailTextField.text
        activeUser.password = passwordTextField.text
        activeUser.birthdate = birthdateLabel.text
        activeUser.phone = phoneTextField.text
        activeUser.startWeight = Int(startingWeightTextField.text!)
        activeUser.startBodyFat = Int(bodyFatTextField.text!)
        activeUser.oldHabit = oldHabitTextField.text
        activeUser.newHabit = newHabitTextField.text
        activeUser.fitnessGoal = fitnessGoalTextField.text
    }
    
    func displayError() {
        let alert = UIAlertController(title: "Fields Required",
                                      message: "Each field is required - please check that you entered all information. Thanks!",
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    @IBAction func returnKeyPressed(sender: UITextField) {
        if sender == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if sender == passwordTextField {
            firstNameTextField.becomeFirstResponder()
        } else if sender == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        } else if sender == lastNameTextField {
            phoneTextField.becomeFirstResponder()
        } else if sender == phoneTextField {
            phoneTextField.resignFirstResponder()
            showDatePicker()
        } else if sender == startingWeightTextField {
            bodyFatTextField.becomeFirstResponder()
        } else if sender == bodyFatTextField {
            oldHabitTextField.becomeFirstResponder()
        } else if sender == oldHabitTextField {
            newHabitTextField.becomeFirstResponder()
        } else if sender == newHabitTextField {
            fitnessGoalTextField.becomeFirstResponder()
        } else if sender == fitnessGoalTextField {
            fitnessGoalTextField.resignFirstResponder()
            save()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SaveProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ProfileTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.activeUser
        }
    }
    
    // Date Picker Methods
    
    func showDatePicker() {
        datePickerVisible = true
        let indexPathDatePicker = IndexPath(row: 4, section: 1)
        tableView.insertRows(at: [indexPathDatePicker], with: .fade)
        datePicker.date = findStoredDate()
    }
    
    func hideDatePicker() {
        datePickerVisible = false
        let indexPathDatePicker = IndexPath(row: 4, section: 1)
        tableView.deleteRows(at: [indexPathDatePicker], with: .fade)
    }
    
    func findStoredDate() -> Date {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if let birthdateLabelText = birthdateLabel.text {
            if let date = formatter.date(from: birthdateLabelText) {
                return date
            } else {
            return Date()
            }
        } else {
            return Date()
        }
    }
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        let birthDate = sender.date
        updateDateLabel(birthDate)
    }
    
    func updateDateLabel(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        birthdateLabel.text = formatter.string(from: date)
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 && indexPath.row == 4 {
            return datePickerCell
        } else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if section == 1 && datePickerVisible {
            return 5
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 4 {
            return 217
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.resignFirstResponder()
        
        if indexPath.section == 1 && indexPath.row == 3 {
            if datePickerVisible {
                hideDatePicker()
            } else {
                showDatePicker()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            indentationLevelForRowAt indexPath: IndexPath) -> Int {
        var newIndexPath = indexPath
        if indexPath.section == 1 && indexPath.row == 4 {
            newIndexPath = IndexPath(row: 0, section: indexPath.section)
        }
        return super.tableView(tableView, indentationLevelForRowAt: newIndexPath)
    }
    
    // Validations
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        // Formats phone text field with ( ) -
        if (textField == self.phoneTextField){
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let components = newString.components(separatedBy: NSCharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.character(at: 0) == (1 as unichar)
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11 {
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                
                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if hasLeadingOne {
                formattedString.append("1 ")
                index += 1
            }
            if (length - index) > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@ - ", prefix)
                index += 3
            }
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            return false
        // Formats text to accept only integers
        } else if (textField == self.bodyFatTextField) || (textField == self.startingWeightTextField) {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        // Restricts length of password field to 12 characters
        } else if textField == self.passwordTextField {
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            return !(newString.characters.count > 12)
        // Restricts length of other text fields to 50 characters
        } else if (textField == self.firstNameTextField) || (textField == self.lastNameTextField) ||
                  (textField == self.emailTextField) || (textField == self.oldHabitTextField) ||
                  (textField == self.newHabitTextField) || (textField == self.fitnessGoalTextField){
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            return !(newString.characters.count > 50)
        } else {
            return true
        }
    }
}
