
import Foundation
import FirebaseDatabase

class WeeklyReport: NSObject {
    
    var userId: String?
    var weekId: Int?
    
    let weekScore: Int!
    
    init(weekScore: Int) {
        
        self.weekScore = weekScore
    }
    
    init(of dict: Dictionary<String, String>) {
        self.weekScore = Int(dict["weekScore"]!)
    }
    
    func toAnyObject() -> Dictionary<String, String> {
        let dict = [
            "score": "\(self.weekScore!)"
        ]
        return dict
    }
    
}
