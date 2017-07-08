
import Foundation
import FirebaseDatabase

class Report: NSObject {
    
    let submissionDay: Int!
    
    let meals: Int! // 0 <= m <= 5
    let snacks: Int! // 0 <= s <= 5
    let workoutType: Int! // Always should be 0, 1, or 2
    
    let sleep: Bool!
    let water: Bool!
    let oldHabit: Bool!
    let newHabit: Bool!
    let communication: Bool!
    let scale: Bool!
    
    var userId: String?
    
    let score: Int!
    
    init(meals: Int, snacks: Int, workoutType: Int, sleep: Bool,
         water: Bool, oldHabit: Bool, newHabit: Bool, communication: Bool,
         scale: Bool, score: Int) {
        
        self.meals = meals
        self.snacks = snacks
        self.workoutType = workoutType
        self.sleep = sleep
        self.water = water
        self.oldHabit = oldHabit
        self.newHabit = newHabit
        self.communication = communication
        self.scale = scale
        self.score = score
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ee"
        self.submissionDay = Int(dateFormatter.string(from: Date()))
    }
    
    init(of dict: Dictionary<String, String>) {
        self.sleep = dict["sleep"]?.toBool()
        self.water = dict["water"]?.toBool()
        self.oldHabit = dict["oldHabit"]?.toBool()
        self.newHabit = dict["newHabit"]?.toBool()
        self.communication = dict["communication"]?.toBool()
        self.submissionDay = Int(dict["submissionDay"]!)
        self.scale = dict["scale"]?.toBool()
        self.snacks = Int(dict["snacks"]!)
        self.meals = Int(dict["meals"]!)
        self.workoutType = Int(dict["workoutType"]!)
        self.score = Int(dict["score"]!)
    }
    
    func toAnyObject() -> Dictionary<String, String> {
        let dict = [
            "sleep": self.sleep.toString()!,
            "water": self.water.toString()!,
            "oldHabit": self.oldHabit.toString()!,
            "newHabit": self.newHabit.toString()!,
            "communication": self.communication.toString()!,
            "scale": self.scale.toString()!,
            "score": "\(self.score!)",
            "meals": "\(self.meals!)",
            "snacks": "\(self.snacks!)",
            "workoutType": "\(self.workoutType!)",
            "submissionDay": "\(self.submissionDay!)"
        ]
        return dict
    }
    
}

extension String {
    func toBool() -> Bool? {
        switch self {
        case "True", "true", "yes", "1":
            return true
        case "False", "false", "no", "0":
            return false
        default:
            return nil
        }
    }
}

extension Bool {
    func toString() -> String? {
        switch self {
        case true:
            return "true"
        case false:
            return "false"
        }
    }
}
