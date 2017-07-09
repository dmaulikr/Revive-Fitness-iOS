
import Foundation

class User: NSObject {
    
    var firstName: String!
    var lastName: String!
    var email: String!
    var password: String!
    let id: String!
    
    var phone: String?
    var age: String?
    var startWeight: String?
    var startBodyFat: String?
    var oldHabit: String?
    var newHabit: String?
    var fitnessGoal: String?
    
    init(fname: String, lname: String, email: String, password: String, id: String) {
        self.firstName = fname
        self.lastName = lname
        self.email = email
        self.password = password
        self.id = id
    }
}
