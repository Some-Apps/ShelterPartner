//
//  PlaygroupsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/21/24.
//

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
            AnimalGridView(animals: animals, columns: columns, cardViewModel: cardViewModel, playCheck: playcheck, cardView: cardView)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct BulkOutlineButton: View {
    let viewModel: CardViewModel
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @Binding var showPopover: Bool
    var animal: Animal
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
                            viewModel.putBack(animal: animal)
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
}
