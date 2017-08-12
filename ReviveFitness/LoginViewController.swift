
import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    var databaseRef: DatabaseReference!
    var users = [User]()
    var userData: [String : NSDictionary]?
    var authenticatedUser: User?
    
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
        
        // Fake user profiles
        /*
        let newUserRef = self.databaseRef.child("users").childByAutoId()
        let newUserID = newUserRef.key
        newUserRef.setValue(["name-first": "Brittani", "name-last": "Bollock", "email": "brit@gmail.com", "password": "password123", "id": newUserID, "isAdmin": "false")])
        */
        // Observe any changes in the database
        databaseRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.users = self.loadUsers(with: snapshot)
            }
        })
        self.view.addGestureRecognizer(tapGestureRecognizer)
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
        login()
    }
    
    @IBAction func createAccountButtonPressed() {
        if let url = URL(string: "http://www.revivedellrapids.com") {
            UIApplication.shared.open(url, options: [:]) {
                boolean in
            }
        }
    }
    
    @IBAction func dismissKeyboard(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    func login() {
        if attemptLogin() {
            if isProfileComplete() {
                if (authenticatedUser?.isAdmin)! {
                    performSegue(withIdentifier: "AdminPanel", sender: self)
                } else {
                    setUserData(of: authenticatedUser!)
                    performSegue(withIdentifier: "UserProfile", sender: self)
                }
            } else {
                performSegue(withIdentifier: "CompleteProfile", sender: self)
            }
        }
    }
    
    func attemptLogin() -> Bool {
        errorMessageLabel.text = ""
        for user in users {
            if user.email == emailTextField.text! {
                if user.password == passwordTextField.text! {
                    authenticatedUser = user
                    errorMessageLabel.text = ""
                    return true
                } else {
                    errorMessageLabel.text = "Incorrect password, please try again."
                    return false
                }
            }
        }
        errorMessageLabel.text = "Email not recognized, sorry!"
        authenticatedUser = nil
        return false
    }
    
    func isProfileComplete() -> Bool {
        let id = authenticatedUser?.id
        if let keys = userData?.keys {
            for eachKey in keys {
                if eachKey == id {
                    return true
                }
            }
        }
        return false
    }
    
    func loadUsers(with snapshot: DataSnapshot) -> [User] {
        
        var loadedUsers = [User]()
        
        if let snapshotDict = snapshot.value as? [String : NSDictionary] {
            if let usersDict = snapshotDict["users"] as? [String : NSDictionary] {
                for eachUserId in usersDict {
                    let userDict = usersDict[eachUserId.key]!
                    loadedUsers.append(User.init(of: userDict as! Dictionary<String, String>))
                }
            }
            
            if let usersDataDict = snapshotDict["userData"] as? [String : NSDictionary] {
                userData = usersDataDict
            }
        }
        return loadedUsers
    }
    
    func setUserData(of user: User) {
        let userDataRef = databaseRef.child("userData").child(authenticatedUser!.id)
        userDataRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                if let userDataDict = snapshot.value as? [String : String] {
                    self.authenticatedUser!.loadUserData(from: userDataDict)
                }
            }
        })
    }
    
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
        }
    }
    
    @IBAction func textFieldValueValueChanged() {
        if emailTextField.hasText && passwordTextField.hasText {
            loginButton.isEnabled = true
        } else {
            loginButton.isEnabled = false
        }
    }

}

