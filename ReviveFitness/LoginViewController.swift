
import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    var databaseRef: DatabaseReference!
    var users = [User]()
    var authenticatedUser: User?
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        databaseRef = Database.database().reference()
        
        // Fake user profiles
        /*let newUserRef = self.databaseRef.child("users").childByAutoId()
        newUserRef.setValue(["name-first": "Dominic", "name-last": "Holmes", "email": "developer.dominicholmes@gmail.com", "password": "admin1"])
        let newUserRef2 = self.databaseRef.child("users").childByAutoId()
        newUserRef2.setValue(["name-first": "Dominic", "name-last": "Holmes", "email": "dh506605@gmail.com", "password": "user1"])*/
        
        // Observe any changes in the database
        databaseRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.users = self.loadUsers(withSnapshot: snapshot)
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func loginButtonPressed() {
        if attemptLogin() { print("~~~ LOGGED IN")} else { print("~~~ NOT LOGGED IN") }
    }
    
    /*
    func login() {
        if attemptLogin() {
            performSegue(withIdentifier: "UserProfile", sender: Any?) {
                
            }
        }
    }*/
    
    func attemptLogin() -> Bool {
        for user in users {
            if user.email == emailTextField.text! {
                if user.password == passwordTextField.text! {
                    authenticatedUser = user
                    return true
                }
            }
        }
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
                    if fname != nil && lname != nil && email != nil && password != nil {
                        let loadedUser = User(fname: fname!, lname: lname!,
                                             email: email!, password: password!)
                        loadedUsers.append(loadedUser)
                    }
                }
            }
        }
        return loadedUsers
    }

}

