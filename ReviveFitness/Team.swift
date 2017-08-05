
import Foundation

class Team: NSObject {
    
    var teamName: String!
    var members = [String: String]()
    var numberOfMembers: Int!
    let id: String!
    
    init(name: String, members: [String: String], numMembers: Int, id: String) {
        self.teamName = name
        self.members = members
        self.numberOfMembers = numMembers
        self.id = id
    }
    
    init(of dict: Dictionary<String, String>) {
        self.teamName = dict["teamName"]!
        self.numberOfMembers = Int(dict["numberOfMembers"]!)
        self.id = dict["id"]!
    }
    
    func loadTeamMembers(from dict: Dictionary<String, String>) {
        for eachMemberId in dict {
            members[eachMemberId.key] = dict[eachMemberId.key]
        }
    }
    
    func toAnyObject() -> Dictionary<String, String> {
        let dict = [
            "teamName": self.teamName!,
            "id": self.id!,
            "numberOfMembers": "\(self.numberOfMembers!)"
        ]
        return dict
    }
    
    func toAnyObjectMembers() -> Dictionary<String, String> {
        return members
    }
}
