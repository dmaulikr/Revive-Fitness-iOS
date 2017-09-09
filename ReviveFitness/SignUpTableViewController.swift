
import UIKit
import Firebase
import FirebaseAuth

class SignUpTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var activeUser: ReviveUser?
    var potentialChallenges: [Challenge] = [Challenge]()
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordConfirmTextField: UITextField!
    
    @IBOutlet weak var createAccountButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attemptLoadChallenges()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func privacyPolicyButtonPressed() {
        if let url = URL(string: "https://www.iubenda.com/privacy-policy/8203081") {
            UIApplication.shared.open(url, options: [:]) {
                boolean in
            }
        }
    }
    
    @IBAction func firstNameFieldNextButtonPressed() {
        lastNameTextField.becomeFirstResponder()
    }
    
    @IBAction func lastNameFieldNextButtonPressed() {
        emailTextField.becomeFirstResponder()
    }
    
    @IBAction func emailFieldNextButtonPressed() {
        passwordTextField.becomeFirstResponder()
    }
    
    @IBAction func passwordFieldNextButtonPressed() {
        passwordConfirmTextField.becomeFirstResponder()
    }
    
    @IBAction func passwordConfirmFieldNextButtonPressed() {
        self.view.endEditing(true)
    }
    
    @IBAction func createAccountButtonPressed() {
        createAccount()
    }
    
    @IBAction func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismissKeyboard(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func textFieldValueValueChanged() {
        if firstNameTextField.hasText && lastNameTextField.hasText &&
            emailTextField.hasText && passwordTextField.hasText {
            createAccountButton.isEnabled = true
        } else {
            createAccountButton.isEnabled = false
        }
    }
    
    func attemptLoadChallenges() {
        let challengesRef = databaseRef.child("challengeNames")
        challengesRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.potentialChallenges = self.loadChallenges(withSnapshot: snapshot)
            }
        })
    }
    
    func loadChallenges(withSnapshot snapshot: DataSnapshot) -> [Challenge] {
        var loadedChallenges = [Challenge]()
        if let challengesDict = snapshot.value as? [String: String] {
            for eachChallenge in challengesDict {
                loadedChallenges.append(Challenge(name: eachChallenge.value, id: eachChallenge.key))
            }
        }
        return loadedChallenges
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func createAccount() {
        let errors = findErrors()
        
        if errors.isEmpty {
            Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                if error != nil {
                    self.displayAlert("Error", error!.localizedDescription, [""], false)
                } else if user != nil {
                    self.saveNewReviveUser(user!)
                    self.activeUser = ReviveUser(fname: self.firstNameTextField.text!,
                                                 lname: self.lastNameTextField.text!,
                                                 id: user!.uid,
                                                 isAdmin: false)
                    self.displayAlert("Success!", "New user with username \(self.emailTextField.text!) created. Sign up for a challenge to get started!", [""], true)
                    self.attemptLoadChallenges()
                }
            }
        } else {
            self.displayAlert("Could not create new user", "Please fix the following errors:", errors, false)
        }
    }
    
    func saveNewReviveUser(_ user: User) {
        let uid = user.uid
        let newUserRef = databaseRef.child("users").child(uid)
        newUserRef.setValue(["name-first": firstNameTextField.text!,
                             "name-last": lastNameTextField.text!,
                             "id": uid,
                             "isAdmin": "false"])
        
    }
    
    func findErrors() -> [String] {
        var errors = [String]()
        
        if emailTextField.hasText {
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
        }
        
        if passwordTextField.hasText {
            if (passwordTextField.text!.characters.count < 6 || passwordTextField.text!.characters.count > 20) {
                errors.append("\n- Password must be 6-20 characters long")
            }
            if passwordTextField.text!.characters.contains(" ") {
                errors.append("\n- Password cannot contain spaces")
            }
        } else {
            errors.append("\n- Enter a valid password")
        }
        if !firstNameTextField.hasText {
            errors.append("\n- Enter a first name")
        }
        if !lastNameTextField.hasText {
            errors.append("\n- Enter a last name")
        }
        if passwordConfirmTextField.text != passwordTextField.text {
            errors.append("\n- Password and confirm password are not identical")
        }
        
        return errors
    }
    
    func displayAlert(_ title: String, _ messageHeader: String, _ errors: [String], _ toPayment: Bool) {
        var message = messageHeader
        for eachError in errors {
            message += eachError
        }
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        if toPayment {
            let action = UIAlertAction(title: "OK", style: .default, handler: { action in
                self.performSegue(withIdentifier: "SignUpChooseChallenge", sender: self)
            })
            alert.addAction(action)
            present(alert, animated: true)
        } else {
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SignUpChooseChallenge" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! SignUpChooseChallengeTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.activeUser
            controller.challengeChoices = self.potentialChallenges
        }
    }
}
