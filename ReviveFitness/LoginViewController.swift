
import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    var databaseRef: DatabaseReference!
    var users = [User]()
    var authenticatedUser: User?
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var loginViewBottomAnchor: NSLayoutConstraint!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        databaseRef = Database.database().reference()
        
        // Fake user profiles
        /*
        let newUserRef = self.databaseRef.child("users").childByAutoId()
        let newUserID = newUserRef.key
        newUserRef.setValue(["name-first": "Dominic", "name-last": "Holmes", "email": "developer.dominicholmes@gmail.com", "password": "admin1", "id": newUserID])
        let newUserRef2 = self.databaseRef.child("users").childByAutoId()
        let newUserID2 = newUserRef2.key
        newUserRef2.setValue(["name-first": "Dominic", "name-last": "Holmes", "email": "dh506605@gmail.com", "password": "user1", "id": newUserID2])
        */
        
        // Observe any changes in the database
        databaseRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.users = self.loadUsers(withSnapshot: snapshot)
            }
        })
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
        loginViewBottomAnchor.constant = 90.0
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
    
    @IBAction func dismissKeyboard(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    func login() {
        if attemptLogin() {
            performSegue(withIdentifier: "UserProfile", sender: self)
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
                    errorMessageLabel.text = "Incorrect password, please try again"
                }
            }
        }
        errorMessageLabel.text = "Email not recognized"
        authenticatedUser = nil
        return false
    }
    
    func loadUsers(withSnapshot snapshot: DataSnapshot) -> [User] {
        
        var loadedUsers = [User]()
        
        if let snapshotDict = snapshot.value as? [String : NSDictionary] {
            if let usersDict = snapshotDict["users"] as? [String : NSDictionary] {
                for eachUserId in usersDict {
                    let userDict = usersDict[eachUserId.key]!
                    let fname = userDict["name-first"] as? String
                    let lname = userDict["name-first"] as? String
                    let email = userDict["email"] as? String
                    let password = userDict["password"] as? String
                    let id = userDict["id"] as? String
                    if fname != nil && lname != nil && email != nil && password != nil {
                        let loadedUser = User(fname: fname!, lname: lname!,
                                             email: email!, password: password!,
                                             id: id!)
                        loadedUsers.append(loadedUser)
                    }
                }
            }
        }
        return loadedUsers
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UserProfile" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! UserProfileViewController
            controller.databaseRef = self.databaseRef
            controller.activeUser = self.authenticatedUser
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
