//
//  LogView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/21/23.
//

import SwiftUI

struct LogView: View {
    let log: Log
    let animal: Animal
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    var body: some View {
        GroupBox {
            VStack(alignment:.leading) {
                let components = Calendar.current.dateComponents([.minute], from: Date(timeIntervalSince1970: log.startTime), to: Date(timeIntervalSince1970: log.endTime))
                let timeIntervalMinutes = Int(components.minute ?? 0)
                HStack {
//                    Text(dateFormatter.string(from: Date(timeIntervalSince1970: log.startTime)))
//                        .font(.title)
//                        .foregroundColor(.secondary)
//                        .italic()
//                        .fontWeight(.thin)
//                    Text("\(formattedTime(for: Date(timeIntervalSince1970: log.startTime))) - \(formattedTime(for: Date(timeIntervalSince1970: log.endTime)))")
//                        .bold()
                    Text("\(dateFormatter.string(from: Date(timeIntervalSince1970: log.startTime))) for \(timeIntervalMinutes) \(timeIntervalMinutes == 1 ? "minute" : "minutes")")
                        .font(.title)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                    Spacer()
                }
                HStack {
                    Spacer()
                }
            }
        }
        .aspectRatio(5, contentMode: .fit)
        .cornerRadius(20)
    }
    
//    private func formattedTime(for date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm"
//        return formatter.string(from: date)
//    }
//    
    private func timeDifferenceInMinutes(from startTime: Date, to endTime: Date) -> Int {
        let difference = Calendar.current.dateComponents([.minute], from: startTime, to: endTime)
        return difference.minute ?? 0
    }
}


struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView(log: Log.dummyLog, animal: Animal.dummyAnimal)
    }
}
