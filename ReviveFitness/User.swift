
import Foundation

class User: NSObject {
    
    var firstName: String!
    var lastName: String!
    var email: String!
    var password: String!
    let id: String!
    
    var weekNumber: Int!
    
    var phone: String?
    var birthdate: String?
    var startWeight: Int?
    var currentWeight: Int?
    var startBodyFat: Int?
    var currentBodyFat: Int?
    var oldHabit: String?
    var newHabit: String?
    var fitnessGoal: String?
    
    init(fname: String, lname: String, email: String, password: String, id: String, weekNumber: Int) {
        self.firstName = fname
        self.lastName = lname
        self.email = email
        self.password = password
        self.id = id
        self.weekNumber = weekNumber
    }
    
    init(of dict: Dictionary<String, String>) {
        self.firstName = dict["name-first"]
        self.lastName = dict["name-last"]
        self.email = dict["email"]
        self.password = dict["password"]
        self.id = dict["id"]
        self.weekNumber = Int(dict["week"]!)
    }
    
    func loadUserData(from dict: Dictionary<String, String>) {
        self.birthdate = dict["birth"]!
        self.phone = dict["phone"]!
        self.startWeight = Int(dict["startWeight"]!)
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
    }
}
