
import Foundation
import FirebaseDatabase

class WeeklyReport: NSObject {
    
    var userId: String?
    var weekId: Int?
    
    let date: String!
    
    let weekScore: Int!
    
    init(weekScore: Int) {
        
        self.weekScore = weekScore
        
        let dateFormatterForDate = DateFormatter()
        dateFormatterForDate.dateFormat = "MM-dd-yyyy"
        self.date = dateFormatterForDate.string(from: Date())
    }
    
    init(of dict: Dictionary<String, String>) {
        self.weekScore = Int(dict["score"]!)
        self.date = dict["submissionDate"]!
    }
    
    func toAnyObject() -> Dictionary<String, String> {
        let dict = [
            "score": "\(self.weekScore!)",
            "submissionDate": self.date
        ]
        return dict as! Dictionary<String, String>
    }
    
}
