import FirebaseAuth
import SwiftUI
import CoreLocation
import FirebaseFirestore

struct AuthenticationView: View {
    @ObservedObject var viewModel = AuthenticationViewModel.shared
    @State private var geoRestrict = false

    var body: some View {
        if viewModel.isSignedIn {
            switch viewModel.accountType {
            case "admin":
                TabView {
                    AnimalView()
                        .tabItem {
                            Label("Volunteer", systemImage: "pawprint.fill")
                        }
                    VisitorView()
                        .tabItem {
                            Label("Visitor", systemImage: "person.2.circle.fill")
                        }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .onAppear {
                    print("Admin")
                    print(viewModel.shelterID)
                    print(viewModel.accountType)
                }

            case "volunteer":
                if geoRestrict {
                    GeoRestrictionView()
                } else {
                    TabView {
                        AnimalView()
                            .tabItem {
                                Label("Volunteer", systemImage: "pawprint.fill")
                            }
                        VisitorView()
                            .tabItem {
                                Label("Visitor", systemImage: "person.2.circle.fill")
                            }
                        VisitorSettingsView()
                            .tabItem {
                                Label("Settings", systemImage: "gearshape.fill")
                            }
                    }
                    .onAppear {
//                        checkGeorestriction()
                        print("Volunteer")
                        print(viewModel.shelterID)
                        print(viewModel.accountType)
                    }
                }

            default:
                TabView {
                    AnimalView()
                        .tabItem {
                            Label("Volunteer", systemImage: "pawprint.fill")
                        }
                    VisitorView()
                        .tabItem {
                            Label("Visitor", systemImage: "person.2.circle.fill")
                        }
                }
                .onAppear {
//                    checkGeorestriction()
                    print("Other")
                    print(viewModel.shelterID)
                    print(viewModel.accountType)
                }
            }
        } else {
            LoginView()
        }
    }
//
//    func checkGeorestriction() {
//        let locationManager = CLLocationManager()
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
//        
//        guard let currentLocation = locationManager.location else {
//            // Handle the case where location is not available
//            self.geoRestrict = true
//            return
//        }
//        
//        let db = Firestore.firestore()
//        let shelterDocRef = db.collection("shelters").document(viewModel.shelterID)
//        shelterDocRef.getDocument { document, error in
//            if let document = document, document.exists, let data = document.data() {
//                if let georestriction = data["georestriction"] as? [String: Any],
//                   let enabled = georestriction["enabled"] as? Bool, enabled,
//                   let center = georestriction["center"] as? GeoPoint,
//                   let radius = georestriction["radius"] as? Double {
//                    
//                    let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
//                    let distance = currentLocation.distance(from: centerLocation)
//                    
//                    if distance > radius {
//                        print("User outside of area")
//                        if viewModel.accountType == "volunteer" {
//                            self.geoRestrict = true
//                        } else {
//                            self.geoRestrict = false
//                        }
//                    } else {
//                        print("User inside area")
//                        self.geoRestrict = false
//                    }
//                }
//            }
//        }
//    }
}

//struct GeoRestrictionView: View {
//    var body: some View {
//        Text("You are outside the allowed area to access this app.")
//    }
//}
