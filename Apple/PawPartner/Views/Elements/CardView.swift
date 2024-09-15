import SwiftUI
import Kingfisher
import FirebaseFirestore


struct CardView: View {
    let animal: Animal
    @Binding var showAnimalAlert: Bool
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject var viewModel: CardViewModel
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @AppStorage("mode") var mode = "volunteer"
    @AppStorage("filterPicker") var filterPicker: Bool = false
    @AppStorage("enableAutomaticPutBack") var enableAutomaticPutBack = false
    @AppStorage("automaticPutBackHours") var automaticPutBackHours = 3
    @State private var showViewInfo = false
    @State private var lastUpdate = Date()
    @State private var showAddNote = false
    @State private var showEditInfo = false
    @State private var showPopover = false
    @State private var isAnimating: Bool = false
    @State private var showLocationPopover = false

    @AppStorage("societyID") var societyID = ""
    @AppStorage("allowPhotoUploads") var allowPhotoUploads = true
    @AppStorage("accountType") var accountType = "volunteer"

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var backgroundColor: Color {
        if animal.canPlay {
            if animal.inCage {
                // light blue
                return Color(red: 137/255, green: 207/255, blue: 240/255)
            } else {
                // orange
                return Color(red: 235/255, green: 202/255, blue: 150/255)
            }
        } else {
            return Color(red: 200/255, green: 200/255, blue: 200/255)
        }
    }
    
    var body: some View {
        let _ = lastUpdate
        
        let timeSinceLastLetOut: String = {
            if let lastLog = animal.logs.last,
               Int(animal.logs.last!.startTime) - Int(animal.logs.last!.endTime) != 0 {
                return Date().timeDifference(from: Date(timeIntervalSince1970: lastLog.endTime))
            }
            return "No Logs"
        }()
        
        let timeElapsed: String = {
            let interval = Date().timeIntervalSince(Date(timeIntervalSince1970: animal.startTime))
            let minutes = Int(interval) / 60
            let hours = minutes / 60
            let days = hours / 24
            
            if days > 0 {
                return "\(days) \(days != 1 ? "days" : "day")"
            } else if hours > 0 {
                return "\(hours) \(hours != 1 ? "hours" : "hour")"
            } else {
                return "\(minutes) \(minutes != 1 ? "minutes" : "minute")"
            }
        }()

        
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .center) {
                        Menu {
                            Text(animal.name)
                        } label: {
                            Text(animal.name)
                                .font(.title)
                                .bold()
                                .underline()
                                .foregroundStyle(.black)
                        }
                            
                        Menu {
                            NavigationLink(destination: ViewInfoView(viewModel: ViewInfoViewModel(animal: animal)), label: {
                                Label("Details", systemImage: "ellipsis.circle")
                            })
                            if allowPhotoUploads && (accountType == "admin") {
                                Button {
                                    animalViewModel.animal = animal
                                    animalViewModel.showQRCode = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                        animalViewModel.showQRCode = false
                                    }
                                } label: {
                                    Label("QR Code", systemImage: "qrcode")
                                }
                            }
                            Button {
                                DispatchQueue.main.async {
                                    animalViewModel.animal = animal
                                    animalViewModel.showAddNote = true
                                }
                            } label: {
                                Label("Add Note", systemImage: "square.and.pencil")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(.black.opacity(0.5))
                                .font(.title)
                        }
                        if let symbol = animal.symbol, let symbolColor = animal.symbolColor {
                            Image(systemName: symbol)
                                .foregroundStyle(
                                    symbolColor == "red" ? .red :
                                        symbolColor == "brown" ? .brown :
                                        symbolColor == "green" ? .green :
                                        symbolColor == "blue" ? .blue :
                                        symbolColor == "white" ? .white :
                                        symbolColor == "gray" ? .gray :
                                        symbolColor == "black" ? .black :
                                        symbolColor == "silver" ? .gray :
                                        symbolColor == "yellow" ? .yellow :
                                        symbolColor == "pink" ? Color(red: 255/255, green: 105/255, blue: 180/255) :
                                        symbolColor == "orange" ? .orange :
                                        symbolColor == "purple" ? .purple :
                                            .clear)
                                .font(.title)
                        }
                    }
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)


                    VStack(alignment: .leading) {
                        if animal.tags != nil && animal.tags != [:] {
                            HStack {
                                Image(systemName: "tag")
                                ForEach(topTags(for: animal, count: 3), id: \.self) {
                                    Text($0)
                                        .background(.ultraThinMaterial)
//                                        .clipShape(.containerRelative)
                                }
                            }
                            .lineLimit(1)
                        }
                        Label(animal.location, systemImage: "mappin.circle")
                        .foregroundStyle(.black)
                        .onTapGesture {
                            showLocationPopover.toggle()
                        }
                        .popover(isPresented: $showLocationPopover, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                            Text(animal.fullLocation ?? animal.location)
                                .presentationCompactAdaptation((.popover))
                        }

                        if let medicalGroup = animal.medicalGroup {
                            if !medicalGroup.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Label(medicalGroup, systemImage: "stethoscope.circle")
                            }
                        }
                        if let behaviorGroup = animal.behaviorGroup {
                            if !behaviorGroup.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Label(behaviorGroup, systemImage: "face.dashed")
                            }
                        }
                        if let adoptionGroup = animal.adoptionGroup {
                            if !adoptionGroup.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Label(adoptionGroup, systemImage: "bag.circle")
                            }
                        }
                        if let extraInfo = animal.extraInfo {
                            if !extraInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Label(extraInfo, systemImage: "square.grid.2x2")
                            }
                        }
                        
                        if animal.inCage {
                            Label(timeSinceLastLetOut, systemImage: "clock")
                        } else {
                            Label(timeElapsed, systemImage: "clock")
                        }
                    }
                    .opacity(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.trailing)
                }
                .layoutPriority(1)
                .padding(.leading, 10)
                Spacer()
                
                    OutlinedButton(viewModel: viewModel, showPopover: $showPopover, animal: animal)
                    .onAppear {
                        if !animal.inCage && enableAutomaticPutBack {
                            if Date().timeIntervalSince1970 - animal.startTime > Double(automaticPutBackHours * 3600) {
                                viewModel.silentPutBack(animal: animal)
                            }
                        }
                    }
                    .disabled(!animal.canPlay)
                
            }
            .onReceive(timer) { _ in
                self.lastUpdate = Date()
            }
            .onChange(of: scenePhase) { _ in
                self.lastUpdate = Date()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20)
            .foregroundColor(backgroundColor)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 2))
        .sheet(isPresented: $showViewInfo) {
            ViewInfoView(viewModel: ViewInfoViewModel(animal: animal))
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteView(animal: animal)
                .onDisappear {
                    showAddNote = false
                }
        }
    }
    
    func topTags(for animal: Animal, count: Int = 3) -> [String] {
        let sortedTags = animal.tags?.sorted { $0.value > $1.value }
            .map { $0.key }
            .prefix(count)
        
        return Array(sortedTags ?? [])
    }
}





struct OutlinedButton: View {
    let viewModel: CardViewModel
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    @Binding var showPopover: Bool
    var animal: Animal
    @State private var isImageCached: Bool = false
    @AppStorage("requireReason") var requireReason = false
    @AppStorage("requireLetOutType") var requireLetOutType = false

    @State private var progress: CGFloat = 0
    @State private var timer: Timer? = nil
    @State private var tickCount: CGFloat = 0
    @State private var lastEaseValue: CGFloat = 0
    @State private var isPressed: Bool = false
    @State private var showAddNote: Bool = false
    @State private var toastAddNote: Bool = false
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
    
    @State private var showLogTooShort = false

    var imageURL: URL? {
        if let photo = animal.allPhotos.first {
            return URL(string: photo)
        }
        return nil
    }


    let width: CGFloat = 100
    let height: CGFloat = 100
    let lineWidth: CGFloat = 25
    

    var body: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.2), lineWidth: lineWidth)
                .frame(width: width, height: height)
                
            Circle()
                .trim(from: 0, to: progress)
                .stroke(animal.inCage ? .orange : .teal, lineWidth: lineWidth)
                .frame(width: width, height: height)
                .rotationEffect(.degrees(-90))
//
            Image(systemName: "photo.circle.fill")
                .resizable()
                .foregroundStyle(.white)
                .scaledToFill()
                .frame(width: width, height: height)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 1 : 1.025)
                .brightness(isPressed ? -0.05 : 0)
                .shadow(color: isPressed ? Color.black.opacity(0.2) : Color.black.opacity(0.5), radius: isPressed ? 0.075 : 2, x: 0.5, y: 1)
                .sheet(isPresented: $showAddNote) {
                    AddNoteView(animal: animal)
                }
            KFImage(imageURL)
                .setProcessor(ResizingImageProcessor(referenceSize: CGSize(width: width*1.5, height: height*1.5), mode: .aspectFill))
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 1 : 1.025)
                .brightness(isPressed ? -0.05 : 0)
                .shadow(color: isPressed ? Color.black.opacity(0.2) : Color.black.opacity(0.5), radius: isPressed ? 0.075 : 2, x: 0.5, y: 1)
        }
        .confirmationDialog("Test", isPresented: $showLogTooShort) {
//            Button("Leave Out", role: .cancel) { }
            Button("Put Back") {
                if requireReason {
                    animalViewModel.animal = animal
                    animalViewModel.showRequireReason = true
                } else {
                    viewModel.putBack(animal: animal)
                }
            }
        } message: {
            Text("\(animal.name) was not let out for the minimum duration of \(viewModel.minimumDuration) minutes. If you tap \"Put Back\", this visit may be ignored")
        }
        .padding(5)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            if pressing {
                feedbackPress.impactOccurred()
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
                        if animal.inCage {
                            if animal.canPlay {
                                if animal.alert.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                                    animalViewModel.animal = animal
                                    withAnimation {
                                        animalViewModel.showAnimalAlert.toggle()
                                    }
                                    
                                } else {
                                    if requireName {
                                        if !authViewModel.name.isEmpty {
                                            let db = Firestore.firestore()
                                            db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
                                                "lastVolunteer": authViewModel.name,
                                            ]){ err in
                                                if let err = err {
                                                    print("Error updating document: \(err)")
                                                } else {
                                                    print("Document successfully updated")
                                                }
                                            }
                                            if requireLetOutType {
                                                animalViewModel.animal = animal
                                                animalViewModel.showRequireLetOutType = true
                                            } else {
                                                viewModel.takeOut(animal: animal)
                                            }
                                        } else {
                                            animalViewModel.animal = animal
                                            animalViewModel.showRequireName = true
                                        }
                                    } else {
                                        if requireLetOutType {
                                            animalViewModel.animal = animal
                                            animalViewModel.showRequireLetOutType = true
                                        } else {
                                            viewModel.takeOut(animal: animal)
                                        }
                                    }
                                }
                            }
                        } else {
                            let components = Calendar.current.dateComponents([.minute], from: Date(timeIntervalSince1970: animal.startTime), to: Date())
                            if components.minute ?? 0 >= viewModel.minimumDuration {
                                viewModel.putBack(animal: animal)
                            } else {
                                showLogTooShort = true
                            }
                        }
                    } else if self.progress > 0.97 {
                        self.progress = 1
                    }
                }
            } else {
                feedbackRelease.impactOccurred()
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
    
    func easeIn(t: CGFloat) -> CGFloat {
        return t * t
    }
}


extension Date {
    func timeDifference(from date: Date) -> String {
        let interval = self.timeIntervalSince(date)
        let minutes = Int(interval) / 60
        
        if minutes >= 1440 {
            let hours = minutes / 60
            let days = hours / 24
            return "\(days) \(days > 1 ? "days" : "day") ago"
        } else if minutes >= 60 {
            let hours = minutes / 60
            return "\(hours) \(hours > 1 ? "hours" : "hour") ago"
        } else {
            return "\(minutes) \(minutes != 1 ? "minutes" : "minute") ago"
        }
    }
}
