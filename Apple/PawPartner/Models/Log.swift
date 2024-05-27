//
//  Log.swift
//  HumaneSociety
//
//  Created by Jared Jones on 12/2/23.
//

import Foundation

struct Log: Codable, Equatable, Hashable {
    var id: String
    var startTime: Double
    var endTime: Double
    var user: String?
    
    var durationInMinutes: Int {
        let startTimeDate = Date(timeIntervalSince1970: startTime)
        let components = Calendar.current.dateComponents([.minute], from: startTimeDate, to: Date())
        return components.minute ?? 0
    }

    
    static let dummyLog = Log(id: "ABC", startTime: Date().timeIntervalSince1970, endTime: Date().timeIntervalSince1970)
}
