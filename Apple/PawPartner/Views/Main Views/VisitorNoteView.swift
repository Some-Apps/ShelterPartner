//
//  VisitorNoteView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 3/3/24.
//

import FirebaseFirestore
import SwiftUI
import Kingfisher

struct VisitorNoteView: View {
    let note: Note
    let animal: Animal
    @AppStorage("societyID") var storedSocietyID: String = ""
    
    var body: some View {
            GroupBox {
                VStack(alignment: .leading) {
                    HStack {
                        Text(note.note)
                            .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title3)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }
            }
//            .aspectRatio(5, contentMode: .fit)
            .cornerRadius(20)
    }
    
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

}
