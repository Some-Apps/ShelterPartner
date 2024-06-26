import Foundation

struct Animal: Codable, Identifiable, Hashable {
    var id: String
    var aggressionRating: Int?
    var name: String
    var animalType: AnimalType
    var location: String
    var alert: String
    var canPlay: Bool
    var inCage: Bool
    var startTime: Double
    var notes: [Note]
    var logs: [Log]
    var tags: [String: Int]?
    var description: String?
    var photos: [Photo]
    var symbol: String?
    var symbolColor: String?
    var sex: String?
    var age: String?
    var breed: String?
    var filters: [String]?
    var lastVolunteer: String?
    var group: String?
    var extraInfo: String?
    var fullLocation: String?
    
    var secondarySort: Int?
    var colorSort: Int?
    var behaviorSort: Int?
    
    var colorGroup: String?
    var behaviorGroup: String?
    var buildingGroup: String?

    var allPhotos: [String] {
        return photos.map { $0.url }
    }

    var playtimeLast24Hours: Int {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return logs.filter { Date(timeIntervalSince1970: $0.startTime) >= oneDayAgo }
            .reduce(0) { $0 + $1.durationInMinutes }
    }

    var playtimeLast7Days: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return logs.filter { Date(timeIntervalSince1970: $0.startTime) >= sevenDaysAgo }
            .reduce(0) { $0 + $1.durationInMinutes }
    }

    var playtimeLast30Days: Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return logs.filter { Date(timeIntervalSince1970: $0.startTime) >= thirtyDaysAgo }
            .reduce(0) { $0 + $1.durationInMinutes }
    }

    var playtimeLast90Days: Int {
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        return logs.filter { Date(timeIntervalSince1970: $0.startTime) >= ninetyDaysAgo }
            .reduce(0) { $0 + $1.durationInMinutes }
    }

    static let dummyAnimal = Animal(id: "50", aggressionRating: 1, name: "Butterscotch", animalType: .Cat, location: "A1", alert: "Likes to be brushed. And probably some other stuff too. I'm just making this really long to test out how it displays.", canPlay: true, inCage: true, startTime: Date().timeIntervalSince1970, notes: [Note.dummyNote], logs: [Log.dummyLog], tags: ["Shy": 1, "Lap Cat": 1], photos: [Photo(url: "www.google.com", privateURL: "www.google.com", timestamp: 156)])
}

