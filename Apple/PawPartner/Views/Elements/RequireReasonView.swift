import SwiftUI
import FirebaseFirestore

struct RequireReasonView: View {
    
    @ObservedObject var cardViewModel = CardViewModel()
    @ObservedObject var viewModel = AnimalViewModel.shared
    @ObservedObject var settingsViewModel = SettingsViewModel.shared
    @AppStorage("societyID") var storedSocietyID: String = ""
    @FocusState private var focusField: Bool
    let animal: Animal

    var body: some View {
        VStack {
            Text("Please select the reason you put this animal back before the minimum duration.")
            Picker("Reason", selection: $cardViewModel.shortReason) {
                Text("").tag("") // Ensure the empty string option is included
                ForEach(settingsViewModel.earlyReasons, id: \.self) {
                    Text($0)
                }
            }

            .pickerStyle(.wheel)
            HStack {
                Button("Nevermind") {
                    viewModel.showRequireReason = false
                    focusField = false
                    cardViewModel.shortReason = ""
                }
                .italic()
                .tint(.accentColor)
                Button("Submit") {
                    cardViewModel.putBack(animal: animal)
                    viewModel.showRequireReason = false
                    focusField = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        cardViewModel.shortReason = ""
                    }
                }
                .tint(.green)
                .disabled(cardViewModel.shortReason.count < 1)
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

