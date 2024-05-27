import Foundation

struct Note: Codable, Equatable, Hashable {
    var id: String
    var date: Double
    var note: String
    var user: String?
    
    static let dummyNote = Note(id: UUID().uuidString, date: 0, note: "This is an example note. And it's super long. And I'm not sure what to say now but I'm going to keep typing because I need to be long")
}
