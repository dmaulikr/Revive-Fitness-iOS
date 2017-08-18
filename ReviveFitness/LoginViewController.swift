
import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    var databaseRef: DatabaseReference!
    
    var authenticatedUser: ReviveUser?
    var authenticatedFIRUser: User?
    
    var potentialChallenges: [Challenge] = [Challenge]()
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var loginViewBottomAnchor: NSLayoutConstraint!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    
    var weekNumberToday: Int! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ww" // Produces int corresponding to week of year
        
        let today = Date() // Account for week starting on monday, not sunday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        
        let weekNumberToday = Int(dateFormatter.string(from: yesterday!))
        return weekNumberToday!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        databaseRef = Database.database().reference()
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        //let newChallengeRef = databaseRef.child("challengeNames").childByAutoId()
        //newChallengeRef.setValue("Revive Challenge")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillShow(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize =  (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                loginViewBottomAnchor.constant = keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(_ notification: Notification){
        loginViewBottomAnchor.constant = 0.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func emailFieldNextButtonPressed() {
        passwordTextField.becomeFirstResponder()
    }
    
    @IBAction func loginButtonPressed() {
        attemptLogin()
    }
    
    @IBAction func createAccountButtonPressed() {
        performSegue(withIdentifier: "SignUp", sender: self)
    }
    
    @IBAction func dismissKeyboard(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func textFieldValueValueChanged() {
        if emailTextField.hasText && passwordTextField.hasText {
            loginButton.isEnabled = true
        } else {
            loginButton.isEnabled = false
        }
    }
    
    
    func attemptLogin() {
        if emailTextField.hasText && passwordTextField.hasText {
            Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                if error != nil {
                    self.errorMessageLabel.text = error.debugDescription
                    print(error.debugDescription)
                }
                _ = Auth.auth().addStateDidChangeListener { (auth, user) in
                    self.authenticatedFIRUser = user
                    if user != nil {
                        // TEMP WAY TO CREATE USER
                        //let userCreateRef = self.databaseRef.child("users").child(user!.uid)
                        //userCreateRef.setValue(["name-first": "Dominic", "name-last": "Holmes", "id": user!.uid, "isAdmin": "true"])
                        self.attemptLoadUser(with: user!.uid)
                        self.attemptLoadChallenges(with: user!.uid)
                    }
                }
            }
        }
    }
    
    func proceedWithLogin() {
        if let user = authenticatedUser {
            if user.isAdmin {
                performSegue(withIdentifier: "AdminPanel", sender: self)
            } else if potentialChallenges.count > 0 {
                if potentialChallenges.count == 1 {
                    user.activeChallenge = potentialChallenges[0]
                    if user.isProfileComplete() {
                        performSegue(withIdentifier: "UserProfile", sender: self)
                    } else {
                        performSegue(withIdentifier: "CompleteProfile", sender: self)
                    }
                }
                performSegue(withIdentifier: "ChooseChallenge", sender: self)
            } else {
                errorMessageLabel.text = "Please wait for your account to be added to a challenge."
            }
        } else {
            print("TRIED LOGIN")
            errorMessageLabel.text = "Please wait for your account to be verified by Revive (< 1 day)."
        }
    }
    
    // Load user and challenges (after login verfified)
    
    func attemptLoadUser(with id: String) {
        let userRef = databaseRef.child("users").child(id)
        userRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                if let userDict = snapshot.value as? Dictionary<String, String> {
                    self.authenticatedUser = ReviveUser.init(of: userDict)
                    self.setUserData(of: self.authenticatedUser!)
                    self.proceedWithLogin()
                } else {
                    self.authenticatedUser = nil
                }
            } else {
                self.authenticatedUser = nil
            }
        })
    }
    
    func setUserData(of user: ReviveUser) {
        let userDataRef = databaseRef.child("userData").child(user.id)
        userDataRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                if let userDataDict = snapshot.value as? [String : String] {
                    user.loadUserData(from: userDataDict)
                }
            }
        })
    }
    
    func attemptLoadChallenges(with id: String) {
        let usersChallengesRef = databaseRef.child("usersChallenges").child(id)
        usersChallengesRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.potentialChallenges = self.loadUsersChallenges(withSnapshot: snapshot)
            }
        })
    }
    
    func loadUsersChallenges(withSnapshot snapshot: DataSnapshot) -> [Challenge] {
        var loadedChallenges = [Challenge]()
        if let challengesDict = snapshot.value as? [String: String] {
            for eachChallenge in challengesDict {
                loadedChallenges.append(Challenge(name: eachChallenge.value, id: eachChallenge.key))
            }
        }
        return loadedChallenges
    }
    
    // Segue control
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UserProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ProfileTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.authenticatedUser
        } else if segue.identifier == "CompleteProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ProfileSettingsTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.authenticatedUser
            controller.firstTimeSettings = true
        } else if segue.identifier == "AdminPanel" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! AdminPanelChallengeTableViewController
            controller.databaseRef = self.databaseRef
        } else if segue.identifier == "SignUp" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! SignUpTableViewController
            controller.databaseRef = self.databaseRef
        }
    }

}

