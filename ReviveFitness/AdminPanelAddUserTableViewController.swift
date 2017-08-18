
import UIKit
import Firebase

struct NameIdPair {
    let name: String
    let id: String
}

class AdminPanelAddUserTableViewController: UITableViewController {
    
    var databaseRef: DatabaseReference!
    var activeChallenge: Challenge!
    
    var allUsers = [NameIdPair]()
    var usersInChallenge = [NameIdPair]()
    var usersNotInChallenge = [NameIdPair]()
    
    var userIdListToFilter = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let usersRef = databaseRef.child("users")
        usersRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.loadAllUsers(with: snapshot)
                self.filterUsers()
                self.tableView.reloadData()
            }
        })
        
        let usersChallengesRef = databaseRef.child("usersChallenges")
        usersChallengesRef.observe(.value, with: { snapshot in
            if let _ = snapshot.value {
                self.loadChallengeUsers(with: snapshot)
                self.filterUsers()
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadAllUsers(with snapshot: DataSnapshot) {
        var loadedUsers = [NameIdPair]()
        
        if let allUsersDict = snapshot.value as? [String: NSDictionary] {
            for eachUser in allUsersDict {
                if let eachUserDict = eachUser.value as? [String: String] {
                    let fName = eachUserDict["name-first"]
                    let lName = eachUserDict["name-last"]
                    loadedUsers.append(NameIdPair.init(name: fName! + " " + lName!, id: eachUser.key))
                }
            }
        }
        self.allUsers = loadedUsers
    }
    
    func loadChallengeUsers(with snapshot: DataSnapshot) {
        var tempUserIdListToFilter = [String]()
        
        if let allUsersChallengesDict = snapshot.value as? [String: NSDictionary] {
            for eachUser in allUsersChallengesDict {
                if let usersChallenges = allUsersChallengesDict[eachUser.key] as? [String: String] {
                    let currentChallengeResults = usersChallenges[activeChallenge.id]
                    if currentChallengeResults != nil {
                        tempUserIdListToFilter.append(eachUser.key)
                    }
                }
            }
        }
        
        self.userIdListToFilter = tempUserIdListToFilter
    }
    
    func filterUsers() {
        var tempUsersInChallenge = [NameIdPair]()
        var tempUsersNotInChallenge = [NameIdPair]()
        
        for eachUser in allUsers {
            if userIdListToFilter.contains(eachUser.id) {
                tempUsersInChallenge.append(eachUser)
            } else {
                tempUsersNotInChallenge.append(eachUser)
            }
        }
        
        self.usersInChallenge = tempUsersInChallenge
        self.usersNotInChallenge = tempUsersNotInChallenge
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return usersInChallenge.count
        } else if section == 1 {
            return usersNotInChallenge.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Users in Challenge"
        } else {
            return "Users not in Challenge"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditUserCell")!
        if indexPath.section == 0 {
            let nameLabel = cell.viewWithTag(300) as! UILabel
            let removeButton = cell.viewWithTag(301) as! UIButton
            nameLabel.text = usersInChallenge[indexPath.row].name
            removeButton.setTitle("Remove", for: .normal)
        } else if indexPath.section == 1 {
            let nameLabel = cell.viewWithTag(300) as! UILabel
            let addButton = cell.viewWithTag(301) as! UIButton
            nameLabel.text = usersNotInChallenge[indexPath.row].name
            addButton.setTitle("Add", for: .normal)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
