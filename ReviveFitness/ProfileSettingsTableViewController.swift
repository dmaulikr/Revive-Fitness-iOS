
import UIKit
import Foundation
import FirebaseDatabase

protocol ProfileSettingsTableViewControllerDelegate: class {
    func profileSettingsTableViewControllerDidCancel(_ controller: ProfileSettingsTableViewController)
    func profileSettingsTableViewController(_ controller: ProfileSettingsTableViewController,
                                   didFinishWith updatedUser: ReviveUser)
}

class ProfileSettingsTableViewController: UITableViewController, UITextFieldDelegate {
    
    var firstTimeSettings = false
    
    var databaseRef: DatabaseReference!
    
    var activeUser: ReviveUser!
    weak var delegate: ProfileSettingsTableViewControllerDelegate?
    
    var datePickerVisible = false
    
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var startingWeightTextField: UITextField!
    @IBOutlet weak var targetWeightTextField: UITextField!
    @IBOutlet weak var bodyFatTextField: UITextField!
    @IBOutlet weak var oldHabitTextField: UITextField!
    @IBOutlet weak var newHabitTextField: UITextField!
    @IBOutlet weak var fitnessGoalTextField: UITextField!
    
    @IBOutlet weak var datePickerCell: UITableViewCell!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var birthdateLabel: UILabel!
    @IBOutlet weak var startingWeightLbsLabel: UILabel!
    @IBOutlet weak var targetWeightLbsLabel: UILabel!
    @IBOutlet weak var startingFatPercentLabel: UILabel!
    
    @IBAction func saveButton() {
        save()
    }
    
    @IBAction func cancelButton() {
        cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTextFieldDelegates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if firstTimeSettings {
            enableFirstTimeFields()
        }
        
        setInitialValues()
    }
    
    func setTextFieldDelegates() {
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        phoneTextField.delegate = self
        startingWeightTextField.delegate = self
        targetWeightTextField.delegate = self
        bodyFatTextField.delegate = self
        oldHabitTextField.delegate = self
        newHabitTextField.delegate = self
        fitnessGoalTextField.delegate = self
    }
    
    func save() {
        let errors = findErrors()
        if errors.count == 0 {
            tableView.endEditing(true)
            saveChangesToFirebase()
            updateUserInstance()
            if let _ = delegate {
                delegate?.profileSettingsTableViewController(self, didFinishWith: activeUser)
            } else {
                dismiss(animated: true, completion: nil)
            }
        } else {
            displayAlert(with: errors)
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
        targetWeightTextField.isEnabled = true
        bodyFatTextField.isEnabled = true
        oldHabitTextField.isEnabled = true
        newHabitTextField.isEnabled = true
        fitnessGoalTextField.isEnabled = true
        phoneTextField.returnKeyType = .next
        
        let enabledColor = cancelBarButton.tintColor
        startingWeightTextField.textColor = enabledColor
        targetWeightTextField.textColor = enabledColor
        bodyFatTextField.textColor = enabledColor
        oldHabitTextField.textColor = enabledColor
        newHabitTextField.textColor = enabledColor
        fitnessGoalTextField.textColor = enabledColor
        startingWeightLbsLabel.textColor = enabledColor
        targetWeightLbsLabel.textColor = enabledColor
        startingFatPercentLabel.textColor = enabledColor
    }
    
    func setInitialValues() {
        firstNameTextField.text = activeUser.firstName
        lastNameTextField.text = activeUser.lastName
        phoneTextField.text = activeUser.phone
        birthdateLabel.text = activeUser.birthdate
        if let _ = activeUser.startWeight {
            startingWeightTextField.text = "\(activeUser.startWeight!)"
        }
        if let _ = activeUser.targetWeight {
            targetWeightTextField.text = "\(activeUser.targetWeight!)"
        }
        if let _ = activeUser.startBodyFat {
            bodyFatTextField.text = "\(activeUser.startBodyFat!)"
        }
        oldHabitTextField.text = activeUser.oldHabit
        newHabitTextField.text = activeUser.newHabit
        fitnessGoalTextField.text = activeUser.fitnessGoal
    }
    
    func saveChangesToFirebase() {
        let updateUserProfileRef = self.databaseRef.child("users").child(activeUser.id)
        let updateUserDataRef = self.databaseRef.child("challenges").child(
            activeUser!.activeChallenge!.id).child("userData").child(activeUser!.id)
        updateUserProfileRef.setValue(["name-first": firstNameTextField.text!,
                                       "name-last": lastNameTextField.text!,
                                       "id": activeUser.id,
                                       "isAdmin": "\(activeUser!.isAdmin!)"
                                       ])
        updateUserDataRef.updateChildValues([
                                    "birth": birthdateLabel.text!,
                                    "phone": phoneTextField.text!,
                                    "startWeight": startingWeightTextField.text!,
                                    "targetWeight": targetWeightTextField.text!,
                                    "startBodyFat": bodyFatTextField.text!,
                                    "oldHabit": oldHabitTextField.text!,
                                    "newHabit": newHabitTextField.text!,
                                    "fitnessGoal": fitnessGoalTextField.text!])
        
        if let teamId = activeUser!.teamId {
            let teamMemberUpdateRef = self.databaseRef.child("challenges").child(
                activeUser!.activeChallenge!.id).child("teamMembers").child(
                    teamId).child(activeUser!.id)
            teamMemberUpdateRef.setValue(firstNameTextField.text! + " " + lastNameTextField.text!)
        }
    }
    
    func updateUserInstance() {
        activeUser.firstName = firstNameTextField.text
        activeUser.lastName = lastNameTextField.text
        activeUser.phone = phoneTextField.text
        activeUser.birthdate = birthdateLabel.text
        activeUser.startWeight = Int(startingWeightTextField.text!)
        activeUser.targetWeight = Int(targetWeightTextField.text!)
        activeUser.startBodyFat = Int(bodyFatTextField.text!)
        activeUser.oldHabit = oldHabitTextField.text
        activeUser.newHabit = newHabitTextField.text
        activeUser.fitnessGoal = fitnessGoalTextField.text
    }
    
    func displayAlert(with errors: [String]) {
        var message = "Please be sure you do the following:"
        for eachError in errors {
            message += eachError
        }
        let alert = UIAlertController(title: "Unable to Save Settings",
                                      message: message,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    @IBAction func returnKeyPressed(sender: UITextField) {
        if sender == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        } else if sender == lastNameTextField {
            phoneTextField.becomeFirstResponder()
        } else if sender == phoneTextField {
            lastNameTextField.resignFirstResponder()
            showDatePicker()
        } else if sender == startingWeightTextField {
            targetWeightTextField.becomeFirstResponder()
        } else if sender == targetWeightTextField {
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
        let indexPathDatePicker = IndexPath(row: 4, section: 0)
        tableView.insertRows(at: [indexPathDatePicker], with: .fade)
        datePicker.date = findStoredDate()
    }
    
    func hideDatePicker() {
        datePickerVisible = false
        let indexPathDatePicker = IndexPath(row: 4, section: 0)
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
        if indexPath.section == 0 && indexPath.row == 4 {
            return datePickerCell
        } else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if section == 0 && datePickerVisible {
            return 5
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 4 {
            return 217
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.resignFirstResponder()
        view.endEditing(true)
        
        if indexPath.section == 0 && indexPath.row == 3 {
            if datePickerVisible {
                hideDatePicker()
            } else {
                showDatePicker()
            }
        } else {
            if datePickerVisible {
                hideDatePicker()
            }
        }
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0: firstNameTextField.becomeFirstResponder()
            case 1: lastNameTextField.becomeFirstResponder()
            default: break
            }
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0: startingWeightTextField.becomeFirstResponder()
            case 1: targetWeightTextField.becomeFirstResponder()
            case 2: bodyFatTextField.becomeFirstResponder()
            case 3: oldHabitTextField.becomeFirstResponder()
            case 4: newHabitTextField.becomeFirstResponder()
            case 5: fitnessGoalTextField.becomeFirstResponder()
            default: break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            indentationLevelForRowAt indexPath: IndexPath) -> Int {
        var newIndexPath = indexPath
        if indexPath.section == 0 && indexPath.row == 4 {
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
        } else if (textField == self.bodyFatTextField) || (textField == self.startingWeightTextField) ||
                    (textField == self.targetWeightTextField){
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            if textField == self.bodyFatTextField {
                let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
                if newString.characters.count > 2 {
                    return false
                }
            } else if (textField == self.startingWeightTextField) || (textField == self.targetWeightTextField) {
                let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
                if newString.characters.count > 3 {
                    return false
                }
            }
            return allowedCharacters.isSuperset(of: characterSet)
        } else if (textField == self.firstNameTextField) || (textField == self.lastNameTextField) ||
                  (textField == self.oldHabitTextField) ||
                  (textField == self.newHabitTextField) || (textField == self.fitnessGoalTextField){
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            return newString.characters.count <= 40
        } else {
            return true
        }
    }
    
    func findErrors() -> [String] {
        var errors = [String]()
        
        /*if emailTextField.hasText {
            let emailRegEx = "[A-Z0-9a-z.-_]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
            do {
                let regex = try NSRegularExpression(pattern: emailRegEx)
                let nsString = emailTextField.text! as NSString
                let results = regex.matches(in: emailTextField.text!, range: NSRange(location: 0, length: nsString.length))
                if results.count == 0 {
                    errors.append("\n- Enter a valid email address")
                }
            } catch _ as NSError {
                errors.append("\n- Enter a valid email address")
            }
        } else {
            errors.append("\n- Enter an email address")
        } */

        if !firstNameTextField.hasText {
            errors.append("\n- Enter a first name")
        }
        if !lastNameTextField.hasText {
            errors.append("\n- Enter a last name")
        }
        if !phoneTextField.hasText {
            errors.append("\n- Enter a phone number")
        }
        if let text = birthdateLabel.text {
            if text.characters.count == 0 {
                errors.append("\n- Select a birthdate")
            }
        } else {
            errors.append("\n- Select a birthdate")
        }
        if startingWeightTextField.hasText {
            if Int(startingWeightTextField.text!)! <= 0 {
                errors.append("\n- Initial weight must be greater than 0")
            }
        } else {
            errors.append("\n- Enter an initial weight")
        }
        if targetWeightTextField.hasText {
            if Int(targetWeightTextField.text!)! <= 0 {
                errors.append("\n- Target weight must be greater than 0")
            }
        } else {
            errors.append("\n- Enter a target weight")
        }
        if bodyFatTextField.hasText {
            if Int(bodyFatTextField.text!)! <= 0 {
                errors.append("\n- Body fat % must be greater than 0")
            }
        } else {
            errors.append("\n- Enter a body fat %")
        }
        if !oldHabitTextField.hasText {
            errors.append("\n- Enter an old habit")
        }
        if !newHabitTextField.hasText {
            errors.append("\n- Enter a new habit")
        }
        if !fitnessGoalTextField.hasText {
            errors.append("\n- Enter a fitness goal")
        }
        
        return errors
    }
}
