//
//  AuthenticationView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/27/23.
//

import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel = AuthenticationViewModel.shared
    @AppStorage("mode") var mode = "volunteer"

    
    var body: some View {
        if viewModel.isSignedIn {
            switch mode {
            case "volunteerAdmin":
                TabView {
                    AnimalView()
                        .tabItem {
                            Label("Animals", systemImage: "pawprint.fill")
//                            Image(systemName: "pawprint.fill")
                        }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
//                            Image(systemName: "gearshape.fill")
                        }
                }
            case "visitorAdmin":
                TabView {
                    VisitorView()
                        .tabItem {
                            Label("Animals", systemImage: "pawprint.fill")
                        }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                
            
            case "volunteer":
                AnimalView()
            case "visitor":
                VisitorView()
            default:
                AnimalView()
            }
        } else {
            LoginView()
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
