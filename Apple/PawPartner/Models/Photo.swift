//
//  Photo.swift
//  HumaneSociety
//
//  Created by Jared Jones on 2/1/24.
//

import Foundation

struct Photo: Codable, Hashable {
    var url: String
    var privateURL: String
    var timestamp: Double
    
    var id: UUID {
        UUID()
    }
}
