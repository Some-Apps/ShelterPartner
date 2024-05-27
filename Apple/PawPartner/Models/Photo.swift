import Foundation

struct Photo: Codable, Equatable, Hashable {
    var url: String
    var privateURL: String
    var timestamp: Double
    
    var id: UUID {
        UUID()
    }
}
