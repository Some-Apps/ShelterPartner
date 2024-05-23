import SwiftUI

struct PlaygroupsView: View {
    var title: String
    var animals: [Animal]
    let columns: [GridItem]
    let cardViewModel: CardViewModel
    let playcheck: (Animal) -> Bool
    let cardView: (Animal) -> CardView
    
    var body: some View {
        ScrollView {
            BulkOutlineButton(viewModel: cardViewModel, animals: animals)
            AnimalGridView(animals: animals, columns: columns, cardViewModel: cardViewModel, playCheck: playcheck, cardView: cardView)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct BulkOutlineButton: View {
    let viewModel: CardViewModel
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    var animals: [Animal]
    @State private var progress: CGFloat = 0
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
    
    @AppStorage("societyID") var storedSocietyID: String = ""
    @AppStorage("lastCatSync") var lastCatSync: String = ""
    @AppStorage("lastDogSync") var lastDogSync: String = ""
    @AppStorage("requireName") var requireName = false

    let width: CGFloat = 100
    let height: CGFloat = 100
    let lineWidth: CGFloat = 25 // Adjust this value to increase the thickness of the stroke
    
    var majorityActionText: String {
        let inCageCount = animals.filter { $0.inCage }.count
        let notInCageCount = animals.count - inCageCount
        return inCageCount > notInCageCount ? "Take Out" : "Put Back"
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.2), lineWidth: lineWidth)
                .frame(width: width, height: height)
                
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: lineWidth))
                .frame(width: width, height: height)
                .rotationEffect(.degrees(-90))

            Image(systemName: "photo.circle.fill")
                .resizable()
                .foregroundStyle(.white)
                .scaledToFill()
                .frame(width: width, height: height)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 1 : 1.025)
                .brightness(isPressed ? -0.05 : 0)
                .shadow(color: isPressed ? Color.black.opacity(0.2) : Color.black.opacity(0.5), radius: isPressed ? 0.075 : 2, x: 0.5, y: 1)
            
            Text(majorityActionText)
        }
        .padding(5)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            if pressing {
                isPressed = true
                self.tickCountPressing = 0
                self.lastEaseValue = self.easeIn(t: 0)
                timer?.invalidate() // invalidate any existing timer
                timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                    let t = self.tickCountPressing / 75 // total duration is now 75 ticks
                    let currentEaseValue = self.easeIn(t: t)
                    let increment = currentEaseValue - self.lastEaseValue
                    self.progress += increment
                    self.lastEaseValue = currentEaseValue
                    self.tickCountPressing += 1

                    if self.progress >= 1 {
                        timer?.invalidate()
                        self.progress = 0
                        print("Hold completed")
                        handleAnimalStateChanges()
                    } else if self.progress > 0.97 {
                        self.progress = 1
                    }
                }
            } else {
                isPressed = false
                self.tickCountNotPressing = 75 // This starts decrement from the end.
                self.lastEaseValue = self.easeIn(t: 1)
                timer?.invalidate() // invalidate the current timer
                timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                    let t = self.tickCountNotPressing / 75
                    let currentEaseValue = self.easeIn(t: t)
                    let decrement = self.lastEaseValue - currentEaseValue
                    self.progress -= decrement
                    self.lastEaseValue = currentEaseValue
                    self.tickCountNotPressing -= 1

                    if self.progress <= 0 {
                        self.progress = 0
                        timer?.invalidate() // stop the timer when progress is zero
                    }
                }
            }
        }, perform: {})

    }
    
    func handleAnimalStateChanges() {
        DispatchQueue.main.async {
            let inCageCount = animals.filter { $0.inCage }.count
            let notInCageCount = animals.count - inCageCount
            let majorityInCage = inCageCount > notInCageCount

            for animal in animals {
                if majorityInCage {
                    if animal.inCage && animal.canPlay && animal.alert.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                        viewModel.takeOut(animal: animal)

//                        if requireName {
//                            animalViewModel.animal = animal
//                            animalViewModel.showRequireName.toggle()
//                        } else {
//                            viewModel.takeOut(animal: animal)
//                        }
                    }
                } else {
                    if !animal.inCage {
                        viewModel.putBack(animal: animal)
                    }
                }
            }
        }
    }

    func easeIn(t: CGFloat) -> CGFloat {
        return t * t
    }
}
