
import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {
    
    var databaseRef: DatabaseReference!
    
    var authenticatedUser: ReviveUser?
    var authenticatedFIRUser: User?
    
    var potentialChallenges: [Challenge] = [Challenge]()
    var allChallenges: [Challenge] = [Challenge]()
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loginView: UIView!
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
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch _ as NSError {
        }
        
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
        var userInfo = notification.userInfo!
        var keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset: UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height + (loginView.frame.height * 0.5)
        scrollView.contentInset = contentInset
    }
    
    func keyboardWillHide(_ notification: Notification){
        let contentInset: UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func privacyPolicyButtonPressed() {
        if let url = URL(string: "https://www.iubenda.com/privacy-policy/8203081") {
            UIApplication.shared.open(url, options: [:]) {
                boolean in
            }
        }
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
    
    func startLoading() {
        spinner.startAnimating()
        loginButton.setTitle("", for: .normal)
    }
    
    func stopLoading() {
        spinner.stopAnimating()
        loginButton.setTitle("Login", for: .normal)
    }
    
    func displayAlert(with errors: [String]) {
        var message = ""
        for eachError in errors {
            message += eachError
        }
        let alert = UIAlertController(title: "Unable to Login",
                                      message: message,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    func attemptLogin() {
        if emailTextField.hasText && passwordTextField.hasText {
            startLoading()
            Auth.auth().signIn(withEmail: emailTextField.text!,
                               password: passwordTextField.text!) { (user, error) in
                if let error = error {
                    self.stopLoading()
                    let nsError = error as NSError
                    switch AuthErrorCode(rawValue: nsError.code)! {
                    case .operationNotAllowed:
                        self.displayAlert(with: ["Account not enabled, please contact support"])
                    case .invalidEmail:
                        self.displayAlert(with: ["Please enter a valid email address"])
                    case .userDisabled:
                        self.displayAlert(with: ["Your account is disabled, please contact support"])
                    case .wrongPassword:
                        self.displayAlert(with: ["Incorrect password, please try again"])
                    default:
                        self.displayAlert(with: ["Unknown error, please try again"])
                    }
                }
                _ = Auth.auth().addStateDidChangeListener { (auth, user) in
                    self.authenticatedFIRUser = user
                    if user != nil {
                        self.attemptLoadUser(with: user!.uid)
                    }
                }
            }
        } else {
            displayAlert(with: ["Please enter your email and password"])
        }
    }
    
    func proceedWithLogin() {
        if let user = authenticatedUser {
            if user.isAdmin {
                performSegue(withIdentifier: "AdminPanel", sender: self)
            } else {
                performSegue(withIdentifier: "ChooseChallenge", sender: self)
            }

            /*else if potentialChallenges.count > 0 {
                if potentialChallenges.count == 1 {
                    user.activeChallenge = potentialChallenges[0]
                    if user.isProfileComplete() {
                        performSegue(withIdentifier: "UserProfile", sender: self)
                    } else {
                        performSegue(withIdentifier: "CompleteProfile", sender: self)
                    }
                } else {
                    performSegue(withIdentifier: "ChooseChallenge", sender: self)
                }
            } else {
                stopLoading()
                displayAlert(with: ["You do not belong to any challenges"])
            } */

        } else {
            stopLoading()
            displayAlert(with: ["Error logging in"])
        }
    }
    
    // Load user and challenges (after login verfified)
    
    func attemptLoadUser(with id: String) {
        let userRef = databaseRef.child("users").child(id)
        userRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                if let userDict = snapshot.value as? Dictionary<String, String> {
                    self.authenticatedUser = ReviveUser.init(of: userDict)
                    self.attemptLoadChallenges(with: self.authenticatedUser!.id)
                    self.attemptLoadAllChallenges()
                } else {
                    self.authenticatedUser = nil
                }
            } else {
                self.authenticatedUser = nil
            }
        })
    }
    
    func setUserData(of user: ReviveUser, forChallenge challenge: Challenge) {
        let userDataRef = self.databaseRef.child("challenges").child(
            challenge.id).child("userData").child(user.id)
        userDataRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                if let userDataDict = snapshot.value as? [String : String] {
                    user.loadUserData(from: userDataDict)
                }
            }
            self.proceedWithLogin()
        })
    }
    
    func attemptLoadChallenges(with id: String) {
        let usersChallengesRef = databaseRef.child("usersChallenges").child(id)
        usersChallengesRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.potentialChallenges = self.loadUsersChallenges(withSnapshot: snapshot)
                if self.potentialChallenges.count == 1 {
                    self.setUserData(of: self.authenticatedUser!, forChallenge: self.potentialChallenges[0])
                } else {
                    self.proceedWithLogin()
                }
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
    
    func attemptLoadAllChallenges() {
        let challengesRef = databaseRef.child("challengeNames")
        challengesRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.allChallenges = self.loadAllChallenges(withSnapshot: snapshot)
            }
        })
    }
    
    func loadAllChallenges(withSnapshot snapshot: DataSnapshot) -> [Challenge] {
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
        stopLoading()
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
        } else if segue.identifier == "ChooseChallenge" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ChooseChallengeTableViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.authenticatedUser!
            controller.challengeChoices = self.potentialChallenges
            controller.allChallenges = self.allChallenges
        }
    }

}

