import FirebaseAuth
import SwiftUI
import CoreLocation
import FirebaseFirestore

struct AuthenticationView: View {
    @ObservedObject var viewModel = AuthenticationViewModel.shared
    @AppStorage("adminMode") var adminMode = true
    @ObservedObject var locationManager = LocationManager()

    var body: some View {
        if viewModel.isSignedIn {
            switch viewModel.accountType {
            case "admin":
                if !adminMode {
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
                        print("Admin")
                        print(viewModel.shelterID)
                        print(viewModel.accountType)
                    }
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
                }
            case "volunteer":
                if let center = viewModel.locationSettings.center,
                   viewModel.locationSettings.enabled,
                   let radius = viewModel.locationSettings.radius,
                   !locationManager.isWithinBounds(center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude), radius: radius) {
                    GeoRestrictionView()
                } else {
//                    Text("TabView triggered")
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
                    VisitorSettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
            }
        } else {
            LoginView()
                .onAppear {
                    viewModel.signOut()
                }
        }
    }
}

struct DebugView: View {
    var viewModel: AuthenticationViewModel
    var locationManager: LocationManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Location settings enabled: \(viewModel.locationSettings.enabled.description)")
            if let center = viewModel.locationSettings.center {
                Text("Location center: \(center.latitude), \(center.longitude)")
            } else {
                Text("Location center is nil")
            }
            
            if let radius = viewModel.locationSettings.radius {
                Text("Location radius: \(radius)")
            } else {
                Text("Location radius is nil")
            }
            
            if viewModel.locationSettings.enabled,
               let center = viewModel.locationSettings.center,
               let radius = viewModel.locationSettings.radius,
               !locationManager.isWithinBounds(center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude), radius: radius) {
                Text("Out of bounds")
                // Your code logic here
            } else {
                Text("Location settings or radius is nil, or location settings are disabled.")
                if viewModel.locationSettings.center == nil {
                    Text("Location center is nil")
                }
                if viewModel.locationSettings.radius == nil {
                    Text("Location radius is nil")
                }
                if !viewModel.locationSettings.enabled {
                    Text("Location settings are disabled")
                }
            }
        }
    }
}
