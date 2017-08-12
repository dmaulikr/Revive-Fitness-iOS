
import Foundation

class User: NSObject {
    
    var firstName: String!
    var lastName: String!
    var email: String!
    var password: String!
    let id: String!
    let isAdmin: Bool!
    
    var phone: String?
    var birthdate: String?
    var startWeight: Int?
    var currentWeight: Int?
    var targetWeight: Int?
    var startBodyFat: Int?
    var currentBodyFat: Int?
    var oldHabit: String?
    var newHabit: String?
    var fitnessGoal: String?
    var teamId: String?
    
    // Optional reports and weeklyReport, used only in TeamProfile to calculate score
    var reports = [Report]()
    var weeklyReport: WeeklyReport?
    
    init(fname: String, lname: String, email: String, password: String, id: String, isAdmin: Bool) {
        self.firstName = fname
        self.lastName = lname
        self.email = email
        self.password = password
        self.id = id
        self.isAdmin = isAdmin
    }
    
    init(of dict: Dictionary<String, String>) {
        self.firstName = dict["name-first"]
        self.lastName = dict["name-last"]
        self.email = dict["email"]
        self.password = dict["password"]
        self.id = dict["id"]
        let adminBool = dict["isAdmin"]
        if adminBool == "true" {
            self.isAdmin = true
        } else {
            self.isAdmin = false
        }
    }
    
    func loadUserData(from dict: Dictionary<String, String>) {
        self.birthdate = dict["birth"]!
        self.phone = dict["phone"]!
        self.startWeight = Int(dict["startWeight"]!)
        self.targetWeight = Int(dict["targetWeight"]!)
        self.startBodyFat = Int(dict["startBodyFat"]!)
        if let currentWeight = dict["currentWeight"] {
            self.currentWeight = Int(currentWeight)
        }
        if let currentBodyFat = dict["currentBodyFat"] {
            self.currentBodyFat = Int(currentBodyFat)
        }
        self.oldHabit = dict["oldHabit"]!
        self.newHabit = dict["newHabit"]!
        self.fitnessGoal = dict["fitnessGoal"]!
        if dict.keys.contains("team") {
            self.teamId = dict["team"]
        }
    }
}
