
import Foundation

class ReviveUser: NSObject {
    
    var firstName: String!
    var lastName: String!
    let id: String!
    let isAdmin: Bool!
    
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
    
    // Challenge this user is currently operating in
    var activeChallenge: Challenge?
    
    init(fname: String, lname: String, email: String, id: String, isAdmin: Bool) {
        self.firstName = fname
        self.lastName = lname
        self.id = id
        self.isAdmin = isAdmin
    }
    
    init(of dict: Dictionary<String, String>) {
        self.firstName = dict["name-first"]
        self.lastName = dict["name-last"]
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
    
    func isProfileComplete() -> Bool {
        return (self.birthdate != nil &&
            self.startWeight != nil &&
            self.targetWeight != nil &&
            self.startBodyFat != nil &&
            self.oldHabit != nil &&
            self.newHabit != nil &&
            self.fitnessGoal != nil)
    }
}
