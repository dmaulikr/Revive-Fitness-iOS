
import Foundation
import FirebaseDatabase

class WeeklyReport: NSObject {
    
    var userId: String?
    var weekId: Int?
    
    let submissionDate: String!
    
    let weekScore: Int!
    let changedOldHabit: Bool!
    let changedNewHabit: Bool!
    let oldHabit: String!
    let newHabit: String!
    let didCompleteGoal: Bool!
    let newWeight: Int!
    let newBodyFat: Int!
    
    init(weekScore: Int, changedOld: Bool, changedNew: Bool,
         oldHabit: String, newHabit: String, completedGoal: Bool,
         newWeight: Int, newBodyFat: Int) {
        
        self.weekScore = weekScore
        self.changedOldHabit = changedOld
        self.changedNewHabit = changedNew
        self.oldHabit = oldHabit
        self.newHabit = newHabit
        self.didCompleteGoal = completedGoal
        self.newWeight = newWeight
        self.newBodyFat = newBodyFat
        
        let dateFormatterForDate = DateFormatter()
        dateFormatterForDate.dateFormat = "MM-dd-yyyy"
        self.submissionDate = dateFormatterForDate.string(from: Date())
    }
    
    init(of dict: Dictionary<String, String>) {
        self.weekScore = Int(dict["weekScore"]!)
        self.newWeight = Int(dict["newWeight"]!)
        self.newBodyFat = Int(dict["newBodyFat"]!)
        self.oldHabit = dict["oldHabit"]!
        self.newHabit = dict["newHabit"]!
        self.submissionDate = dict["submissionDate"]!
        self.changedOldHabit = (dict["changedOld"]!).toBool()
        self.changedNewHabit = (dict["changedNew"]!).toBool()
        self.didCompleteGoal = (dict["completedGoal"]!).toBool()
    }
    
    func toAnyObject() -> Dictionary<String, String> {
        let dict = [
            "weekScore": "\(self.weekScore!)",
            "newWeight": "\(self.newWeight!)",
            "newBodyFat": "\(self.newBodyFat!)",
            "oldHabit": self.oldHabit!,
            "newHabit": self.newHabit!,
            "submissionDate": self.submissionDate!,
            "changedOld": self.changedOldHabit.toString()!,
            "changedNew": self.changedNewHabit.toString()!,
            "completedGoal": self.didCompleteGoal.toString()!
        ] as [String : String]
        return dict
    }
    
}
