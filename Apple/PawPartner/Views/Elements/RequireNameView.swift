//
//  RequireNameView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/3/24.
//

import SwiftUI
import FirebaseFirestore

struct RequireNameView: View {
    
    @State private var name: String = ""
    @ObservedObject var cardViewModel = CardViewModel()
    @ObservedObject var viewModel = AnimalViewModel.shared
    @AppStorage("societyID") var storedSocietyID: String = ""
    @FocusState private var focusField: Bool
    let animal: Animal

    var body: some View {
        VStack {
            Text("Please enter your name")
            TextField("Name", text: $name)
                .focused($focusField)
                .onChange(of: viewModel.showRequireName) { show in
                    if show {
                        focusField = true
                    }
                }
                .onDisappear {
                    focusField = false
                }
            HStack {
                Button("Nevermind") {
                    viewModel.showRequireName = false
                    focusField = false
                }
                Button("Submit") {
                    viewModel.showRequireName = false
                    let db = Firestore.firestore()
                    db.collection("Societies").document(storedSocietyID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
                        "lastVolunteer": name,
                    ]){ err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                    cardViewModel.takeOut(animal: animal)
                    name = ""
                    focusField = false
                }
                .tint(.green)
                .disabled(name.count < 1)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: 350)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(radius: 8)
        )
        
    }
}

