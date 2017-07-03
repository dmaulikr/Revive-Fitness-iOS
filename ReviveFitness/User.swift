
import Foundation

class User: NSObject {
    
    let firstName: String!
    let lastName: String!
    let email: String!
    let password: String!
    let id: String!
    
    init(fname: String, lname: String, email: String, password: String, id: String) {
        self.firstName = fname
        self.lastName = lname
        self.email = email
        self.password = password
        self.id = id
    }
}
