import SwiftUI
import FirebaseFirestore

struct RequireLetOutTypeView: View {
    
    @ObservedObject var cardViewModel = CardViewModel()
    @ObservedObject var viewModel = AnimalViewModel.shared
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    @FocusState private var focusField: Bool
    let animal: Animal

    var body: some View {
        VStack {
            Text("Please select why you are letting this animal out.")
            
            if authViewModel.letOutTypes.isEmpty {
                Text("No reasons available.")
                    .foregroundColor(.red)
            } else {
                Picker("Reason", selection: $cardViewModel.letOutType) {
                    Text("").tag("")
                    ForEach(authViewModel.letOutTypes, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.wheel)
            }
            
            HStack {
                Button("Nevermind") {
                    viewModel.showRequireLetOutType = false
                    focusField = false
                    cardViewModel.letOutType = ""
                }
                .italic()
                .tint(.accentColor)
                
                Button("Submit") {
                    cardViewModel.takeOut(animal: animal)
                    let db = Firestore.firestore()
                    db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
                        "lastLetOutType": cardViewModel.letOutType,
                    ]){ err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                    viewModel.showRequireLetOutType = false
                    focusField = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        cardViewModel.letOutType = ""
                    }
                }
                .tint(.green)
                .disabled(cardViewModel.letOutType.isEmpty)
                .bold()
            }
            .buttonStyle(.bordered)
            .font(.title)
        }
        .padding()
        .frame(maxWidth: 500)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(radius: 8)
        )
        .padding()
    }
}
