import SwiftUI
import Kingfisher

struct CardView: View {
    let animal: Animal
    @Binding var showAnimalAlert: Bool
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject var viewModel: CardViewModel
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @AppStorage("mode") var mode = "volunteer"
    @AppStorage("filterPicker") var filterPicker: Bool = false
    @State private var showViewInfo = false
    @State private var lastUpdate = Date()
    @State private var showAddNote = false
    @State private var showEditInfo = false
    @State private var showPopover = false
    @State private var isAnimating: Bool = false

    @AppStorage("societyID") var societyID = ""
    @AppStorage("QRMode") var QRMode = true
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
            return "\(minutes) \(minutes != 1 ? "minutes" : "minute")"
        }()
        
        VStack(alignment: .leading) {
            HStack {
                OutlinedButton(viewModel: viewModel, showPopover: $showPopover, animal: animal)
                    .onAppear {
                        if !animal.inCage {
                            if Date().timeIntervalSince1970 - animal.startTime > 7200 {
                                viewModel.silentPutBack(animal: animal)
                            }
                        }
                    }
                VStack(alignment: .leading, spacing: (animal.tags != nil && animal.tags != [:]) ? 3 : 14) {
                    if animal.tags != nil && animal.tags != [:] {
                        HStack {
                            ForEach(topTags(for: animal, count: 1), id: \.self) {
                                Text($0)
                            }
                        }
                        .font(.callout)
                        .padding(.horizontal, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.2), radius: 0.5, x: 0.5, y: 1)
                    }
                    Text(animal.name + " ")
                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .title2 : .largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text("\(animal.location)")
                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .title3 : .title2)
                        .fontWeight(.heavy)
                        .opacity(0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    if animal.inCage {
                        Text(timeSinceLastLetOut)
                            .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .body)
                            .fontWeight(.bold)
                            .opacity(0.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    } else {
                        Text(timeElapsed)
                            .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .body)
                            .fontWeight(.bold)
                            .opacity(0.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    
                    // Extra Info
                    if let extraInfo = animal.extraInfo {
                        Text(extraInfo)
                            .font(.body)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)
                            .padding(.top, 5)
                    }
                    
                }
                .layoutPriority(1)
                .padding(.leading, 10)
                
                Spacer()
                
                HStack {
                    if animal.animalType == .Dog && (societyID == "ChIJ8WVKpxEfAIgRIMOBoCkxBtY" || societyID == "ChIJgbjU6bBRBogRKBb3KxOJGn8") {
                        Image(systemName: animal.aggressionRating == 1 ? "1.circle.fill" : animal.aggressionRating == 2 ? "2.square.fill" : animal.aggressionRating == 3 ? "3.circle.fill" : "")
                            .font(.title)
                            .foregroundColor(animal.aggressionRating == 1 ? .green : animal.aggressionRating == 2 ? .orange : animal.aggressionRating == 3 ? .red : .primary.opacity(0.2))
                    }
                    if let symbol = animal.symbol, let symbolColor = animal.symbolColor {
                        Image(systemName: symbol)
                            .foregroundStyle(symbolColor == "red" ? .red : symbolColor == "green" ? .green : symbolColor == "green" ? .blue: symbolColor == "white" ? .white : symbolColor == "gray" ? .gray : .clear)
                            .font(.title)
                    }
                    VStack {
                        NavigationLink(destination: ViewInfoView(animal: animal), label: {
                            Image(systemName: "ellipsis.circle")
                        })
                        Spacer()
                        if QRMode {
                            Button {
                                animalViewModel.animal = animal
                                animalViewModel.showQRCode = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                    animalViewModel.showQRCode = false
                                }
                            } label: {
                                Image(systemName: "qrcode")
                            }
                        }
                        Spacer()
                        Button {
                            DispatchQueue.main.async {
                                animalViewModel.animal = animal
                                animalViewModel.showAddNote = true
                            }
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .title2 : .title)
                    .fontWeight(.black)
                    .foregroundStyle(.primary.opacity(0.2))
                }
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
            ViewInfoView(animal: animal)
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteView(animal: animal)
                .onDisappear {
                    showAddNote = false
                }
        }
    }
    
    func topTags(for animal: Animal, count: Int = 3) -> [String] {
        // Sort the tags based on their count and get the top 'count' tags
        let sortedTags = animal.tags?.sorted { $0.value > $1.value }
            .map { $0.key }
            .prefix(count)
        
        return Array(sortedTags ?? [])
    }
}




struct OutlinedButton: View {
    let viewModel: CardViewModel
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @Binding var showPopover: Bool
    var animal: Animal
    @State private var isImageCached: Bool = false

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
    
    @AppStorage("societyID") var storedSocietyID: String = ""
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
    
//    private var urlWithCacheBuster: URL? {
//        guard let baseURL = imageURL else { return nil }
//
//        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
//        let queryItem = URLQueryItem(name: "lastSync", value: lastSync.isEmpty ? "\(Date().timeIntervalSince1970)" : lastSync)
//        components?.queryItems = [queryItem]
//
//        return components?.url
//    }


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
                .onAppear {
                    checkIfImageIsCached()
                }
            KFImage(imageURL)
                        .placeholder {
                            Image(systemName: "photo.circle")
                                .resizable()
                                .scaledToFill()
                                .foregroundStyle(.tertiary)
                                .frame(width: width, height: height)
                                .clipShape(Circle())
                                .scaleEffect(isPressed ? 1 : 1.025)
                                .brightness(isPressed ? -0.05 : 0)
                                .shadow(color: isPressed ? Color.black.opacity(0.2) : Color.black.opacity(0.5), radius: isPressed ? 0.075 : 2, x: 0.5, y: 1)
                        }
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 150, height: 150))
                                      |> RoundCornerImageProcessor(cornerRadius: 15))
                        .scaleFactor(UIScreen.main.scale)
                        .cacheOriginalImage()
                        .resizable()
                        
                        .onSuccess { result in
                            print("Task done for: \(result.source.url?.absoluteString ?? "")")
                        }
                        .onFailure { error in
                            print("Job failed: \(error.localizedDescription)")
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipShape(Circle())
                        .scaleEffect(isPressed ? 1 : 1.025)
                        .brightness(isPressed ? -0.05 : 0)
                        .shadow(color: isPressed ? Color.black.opacity(0.2) : Color.black.opacity(0.5), radius: isPressed ? 0.075 : 2, x: 0.5, y: 1)
//            if let url = imageURL {
//                KFImage(url)
//                    .placeholder {
//                        Image("placeholderImage")
//                            .resizable()
//                            .scaledToFit()
//                    }
//                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: width, height: height))
//                                  |> RoundCornerImageProcessor(cornerRadius: 20))
//                    .scaleFactor(UIScreen.main.scale)
//                    .cacheOriginalImage()
//                    .onSuccess { result in
//                        print("Task done for: \(result.source.url?.absoluteString ?? "")")
//                    }
//                    .onFailure { error in
//                        print("Job failed: \(error.localizedDescription)")
//                    }
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: width, height: height)
//                    .clipShape(Circle())
//                    .scaleEffect(isPressed ? 1 : 1.025)
//                    .brightness(isPressed ? -0.05 : 0)
//                    .shadow(color: isPressed ? Color.black.opacity(0.2) : Color.black.opacity(0.5), radius: isPressed ? 0.075 : 2, x: 0.5, y: 1)
//                KFImage(url)
//                    .setProcessor(ResizingImageProcessor(referenceSize: CGSize(width: width, height: height), mode: .aspectFill))
//                    .resizable()
//                    .onSuccess { result in
//                        // The image has been cached successfully
//                        print("Image cached successfully: \(result.cacheType)")
//                    }
//                    .onFailure { error in
//                        print("Image loading failed: \(error)")
//                    }
//                    .onProgress { receivedSize, totalSize in
//                        print("Loading progress: \(receivedSize)/\(totalSize)")
//                    }
//                    .scaledToFill()
//                    .frame(width: width, height: height)
//                    .clipShape(Circle())
//                    .scaleEffect(isPressed ? 1 : 1.025)
//                    .brightness(isPressed ? -0.05 : 0)
//                    .shadow(color: isPressed ? Color.black.opacity(0.2) : Color.black.opacity(0.5), radius: isPressed ? 0.075 : 2, x: 0.5, y: 1)
//            }
        }
        .confirmationDialog("Test", isPresented: $showLogTooShort) {
//            Button("Leave Out", role: .cancel) { }
            Button("Put Back") {
                viewModel.putBack(animal: animal)
            }
        } message: {
            Text("\(animal.name) was not let out for the minimum duration of \(viewModel.minimumDuration) minutes. If you tap \"Put Back\", this visit will be ignored")
        }
        .padding(5)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            if pressing {
//                feedbackPress.impactOccurred()
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
                                        animalViewModel.animal = animal
                                        animalViewModel.showRequireName.toggle()
                                    } else {
                                        viewModel.takeOut(animal: animal)
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
//                feedbackRelease.impactOccurred()
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
    
    private func checkIfImageIsCached() {
        guard let imageURL = imageURL else {
            return
        }
        
        let cache = ImageCache.default
        cache.retrieveImage(forKey: imageURL.absoluteString) { result in
            switch result {
            case .success(let value):
                if value.image != nil {
                    self.isImageCached = true
                } else {
                    self.isImageCached = false
                }
            case .failure:
                self.isImageCached = false
            }
        }
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

//
//
//#Preview {
//    CardView(animal: Animal.dummyAnimal, showAnimalAlert: .constant(false), viewModel: CardViewModel(), animalViewModel: AnimalViewModel())
//}
