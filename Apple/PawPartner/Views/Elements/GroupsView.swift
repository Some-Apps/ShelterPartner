import SwiftUI
import AlertToast
import FirebaseFirestore

struct GroupsView: View {
    var species: String
    let groupCategory: String
    let groupSelection: String
    let columns: [GridItem]
    let cardViewModel: CardViewModel
    let cardView: (Animal) -> CardView
    @AppStorage("showBulkTakeOut") var showBulkTakeOut = false

    @State private var currentPage = 1
    @State private var finalFilterCategory = "None"
    @State private var finalFilterSelection = "None"
    @AppStorage("cardsPerPage") var cardsPerPage = 30
    @AppStorage("showFilterOptions") var showFilterOptions = false
    @State private var showLoading = false
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @ObservedObject var authViewModel = AuthenticationViewModel.shared

    var animalsInGroup: [Animal] {
        let animals: [Animal]
        if species == "Cat" {
            animals = animalViewModel.sortedGroupCats
        } else {
            animals = animalViewModel.sortedGroupDogs
        }
        
        if groupCategory == "Color" {
            return animals.filter { ($0.colorGroup ?? "No Group") == groupSelection }
        } else if groupCategory == "Building" {
            return animals.filter { ($0.buildingGroup ?? "No Group") == groupSelection }
        } else if groupCategory == "Behavior" {
            return animals.filter { ($0.behaviorGroup ?? "No Group") == groupSelection }
        } else {
            return animals
        }
        
//        let filteredAnimals = animals.filter { ($0.group ?? "No Group") == group }
//        print("Filtered \(filteredAnimals.count) animals in group \(group) for \(species)")
//        return filteredAnimals
    }

    var allAnimals: [Animal] {
        let allAnimals: [Animal]
        if species == "Cat" {
            allAnimals = animalViewModel.cats
        } else {
            allAnimals = animalViewModel.dogs
        }
        return allAnimals
    }

    var paginatedAnimals: [Animal] {
        let startIndex = (currentPage - 1) * cardsPerPage
        let endIndex = min(startIndex + cardsPerPage, filteredAnimals.count)

        guard startIndex < filteredAnimals.count else { return [] }
        let paginated = Array(filteredAnimals[startIndex..<endIndex])
        print("Paginated animals count: \(paginated.count) for page \(currentPage)")
        return paginated
    }

    var totalPages: Int {
        let total = Int(ceil(Double(filteredAnimals.count) / Double(cardsPerPage)))
        print("Total pages: \(total)")
        return total
    }

    var filterSelectionOptions: [String] {
        var options: [String] = ["None"]
        
        if finalFilterCategory == "Color" {
            for animal in animalsInGroup {
                if options.contains(animal.colorGroup ?? "None") {
                    continue
                } else {
                    options.append(animal.colorGroup ?? "None")
                }
            }
        } else if finalFilterCategory == "Building" {
            for animal in animalsInGroup {
                if options.contains(animal.buildingGroup ?? "None") {
                    continue
                } else {
                    options.append(animal.buildingGroup ?? "None")
                }
            }
        } else if finalFilterCategory == "Behavior" {
            for animal in animalsInGroup {
                if options.contains(animal.behaviorGroup ?? "None") {
                    continue
                } else {
                    options.append(animal.behaviorGroup ?? "None")
                }
            }
        }
        
        print("Filter options for category \(finalFilterCategory): \(options)")
        return options
    }

    var filteredAnimals: [Animal] {
        if finalFilterCategory == "None" || finalFilterSelection == "None" {
            return animalsInGroup
        } else {
            switch finalFilterCategory {
            case "Color":
                return animalsInGroup.filter { $0.colorGroup == finalFilterSelection }
            case "Building":
                return animalsInGroup.filter { $0.buildingGroup == finalFilterSelection }
            case "Behavior":
                return animalsInGroup.filter { $0.behaviorGroup == finalFilterSelection }
            default:
                return animalsInGroup
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                if showBulkTakeOut {
                    BulkOutlineButton(viewModel: cardViewModel, animals: animalsInGroup, showLoading: $showLoading)
                }
                if showFilterOptions {
                    HStack {
                        Text("Filter Category: ")
                        Picker("Filter Category: ", selection: $finalFilterCategory) {
                            ForEach(["None"] + authViewModel.groupOptions, id: \.self) {
                                Text($0)
                            }
                        }
                        .onChange(of: finalFilterCategory) { filter in
                            currentPage = 1
                        }
                        Text("Filter Selection: ")
                        Picker("Filter Selection: ", selection: $finalFilterSelection) {
                            ForEach(filterSelectionOptions, id: \.self) {
                                Text($0)
                            }
                        }
                        .disabled(finalFilterCategory == "None")
                        .onChange(of: finalFilterSelection) { filter in
                            currentPage = 1
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(.regularMaterial))
                    .padding()

                }
                
                if !filteredAnimals.isEmpty {
                    PageNavigationElement(currentPage: $currentPage, totalPages: totalPages)
                }
                AnimalGridView(allAnimals: allAnimals, animals: paginatedAnimals, columns: columns, cardViewModel: cardViewModel, cardView: cardView)

                if !filteredAnimals.isEmpty {
                    PageNavigationElement(currentPage: $currentPage, totalPages: totalPages)
                }
            }
        }
        .navigationTitle(groupSelection)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            currentPage = 1
            print("GroupsView appeared. Title: \(species), Group: \(groupSelection)")
        }
        .onChange(of: finalFilterCategory) { newValue in
            print("Selected filter category: \(newValue)")
        }
    }
}


struct BulkOutlineButton: View {
    let viewModel: CardViewModel
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    var animals: [Animal]
    @Binding var showLoading: Bool
    @AppStorage("minimumDuration") var minimumDuration = 5
    @AppStorage("showAllAnimals") var showAllAnimals = false

    @State private var progress: CGFloat = 0
    @AppStorage("filterPicker") var filterPicker: Bool = false
    @AppStorage("filter") var filter: String = "No Filter"
    @State private var timer: Timer? = nil
    @State private var tickCount: CGFloat = 0
    @State private var lastEaseValue: CGFloat = 0
    @State private var isPressed: Bool = false
    @AppStorage("lastSync") var lastSync: String = ""
    @AppStorage("lastLastSync") var lastLastSync: String = ""
    @State private var feedbackPress = UIImpactFeedbackGenerator(style: .rigid)
    @State private var feedbackRelease = UIImpactFeedbackGenerator(style: .light)
    @State private var tickCountPressing: CGFloat = 0
    @State private var tickCountNotPressing: CGFloat = 75 // Starts from the end.
    
//    @AppStorage("societyID") var storedSocietyID: String = ""
    @AppStorage("lastCatSync") var lastCatSync: String = ""
    @AppStorage("lastDogSync") var lastDogSync: String = ""
    @AppStorage("requireName") var requireName = false
    
    @State private var takeAllOut = false
    @State private var putAllBack = false

    let width: CGFloat = 100
    let height: CGFloat = 100
    let lineWidth: CGFloat = 25 // Adjust this value to increase the thickness of the stroke
    
    var majorityActionText: String {
        var filteredAnimals: [Animal] = []

        for animal in animals {
            if animal.canPlay {
                filteredAnimals.append(animal)
            } else if showAllAnimals {
                filteredAnimals.append(animal)
            }
        }
        let inCageCount = filteredAnimals.filter { $0.inCage }.count
        let notInCageCount = filteredAnimals.count - inCageCount
        return inCageCount > notInCageCount ? "Take Out" : "Put Back"
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.2), lineWidth: lineWidth)
                .frame(width: width, height: height)
                
            Circle()
                .trim(from: 0, to: progress)
                .stroke(majorityActionText == "Take Out" ? .orange : .teal, style: StrokeStyle(lineWidth: lineWidth))
                .frame(width: width, height: height)
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(.white)
                .scaledToFill()
                .frame(width: width, height: height)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 1 : 1.025)
                .brightness(isPressed ? -0.05 : 0)
                .shadow(color: isPressed ? Color.black.opacity(0.2) : Color.black.opacity(0.5), radius: isPressed ? 0.075 : 2, x: 0.5, y: 1)
            
            Text(majorityActionText)
                .frame(width: width, height: height)
                .multilineTextAlignment(.center)
                .font(.title)
                .bold()
                .padding()
        }
        .confirmationDialog("Confirm", isPresented: $takeAllOut) {
            Button("Yes") {
                handleAnimalStateChanges()
                print(showLoading)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    print(showLoading)
                }
            }
        } message: {
            Text("You are about to take out all of the animals in the group. Are you sure you want to continue?")
        }
        .confirmationDialog("Confirm", isPresented: $putAllBack) {
            Button("Yes") {
                handleAnimalStateChanges()
            }
        } message: {
            Text("You are about to put all of the animals in the group back. Are you sure you want to continue?")
        }
        .padding(5)
        
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            if pressing {
                isPressed = true
                feedbackPress.impactOccurred()
                tickCountPressing = 0
                lastEaseValue = easeIn(t: 0)
                timer?.invalidate() // invalidate any existing timer
                timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                    let t = tickCountPressing / 75 // total duration is now 75 ticks
                    let currentEaseValue = easeIn(t: t)
                    let increment = currentEaseValue - lastEaseValue
                    progress += increment
                    lastEaseValue = currentEaseValue
                    tickCountPressing += 1

                    if progress >= 1 {
                        timer?.invalidate()
                        progress = 0
                        print("Hold completed")
                        if majorityActionText == "Take Out" {
                            takeAllOut = true
                        } else {
                            putAllBack = true
                        }
                    } else if progress > 0.97 {
                        progress = 1
                    }
                }
            } else {
                isPressed = false
                feedbackRelease.impactOccurred()
                tickCountNotPressing = 75 // This starts decrement from the end.
                lastEaseValue = easeIn(t: 1)
                timer?.invalidate() // invalidate the current timer
                timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                    let t = tickCountNotPressing / 75
                    let currentEaseValue = easeIn(t: t)
                    let decrement = lastEaseValue - currentEaseValue
                    progress -= decrement
                    lastEaseValue = currentEaseValue
                    tickCountNotPressing -= 1

                    if progress <= 0 {
                        progress = 0
                        timer?.invalidate() // stop the timer when progress is zero
                    }
                }
            }
        }, perform: {})
    }

    func handleAnimalStateChanges() {
        showLoading = true
        let db = Firestore.firestore()
        let batch = db.batch()
        
        var filteredAnimals: [Animal] = []

        for animal in animals {
            if animal.canPlay {
                filteredAnimals.append(animal)
            } else if showAllAnimals {
                filteredAnimals.append(animal)
            }
        }
        let inCageCount = filteredAnimals.filter { $0.inCage }.count
        let notInCageCount = filteredAnimals.count - inCageCount
        let majorityInCage = inCageCount > notInCageCount
        
        for animal in filteredAnimals {
            let animalRef = db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType)s").document(animal.id)
            if majorityInCage {
                if animal.inCage && animal.canPlay && animal.alert.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                    batch.updateData(["inCage": false, "startTime": Date().timeIntervalSince1970], forDocument: animalRef)
                }
            } else {
                if !animal.inCage {
                    batch.updateData(["inCage": true], forDocument: animalRef)
                    let components = Calendar.current.dateComponents([.minute], from: Date(timeIntervalSince1970: animal.startTime), to: Date())
                    if components.minute ?? 0 >= self.minimumDuration {
                        viewModel.createLog(for: animal)
                    }
                }
            }
        }
        
        batch.commit { error in
            showLoading = false
            if let error = error {
                print("Error updating animals: \(error.localizedDescription)")
            } else {
                print("Batch update successful")
            }
        }
    }

    func easeIn(t: CGFloat) -> CGFloat {
        return t * t
    }
}
