
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
    var startWeight: String?
    var startBodyFat: String?
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
}
