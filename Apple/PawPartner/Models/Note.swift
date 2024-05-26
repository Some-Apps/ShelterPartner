//
//  Note.swift
//  HumaneSociety
//
//  Created by Jared Jones on 12/2/23.
//

import Foundation

struct Note: Codable {
    var id: String
    var date: Double
    var note: String
    var user: String?
    
    static let dummyNote = Note(id: UUID().uuidString, date: 0, note: "This is an example note. And it's super long. And I'm not sure what to say now but I'm goint to keep typing because I need to be long")
}
