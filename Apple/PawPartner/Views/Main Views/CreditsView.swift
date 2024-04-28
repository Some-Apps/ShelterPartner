//
//  CreditsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 7/3/23.
//

import SwiftUI

struct CreditsView: View {
    var body: some View {
        VStack {
            List {
                HStack {
                    Text("Jared Jones")
                    Spacer()
                    Text("Developer")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Marathon County Humane Society")
                    Spacer()
                    Text("Initial Tester")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("PetHealth Inc")
                    Spacer()
                    Text("PetPoint Integration Help")
                        .foregroundColor(.secondary)
                }
//                HStack {
//                    Text("John Russell Seal")
//                    Spacer()
//                    Text("Animations")
//                        .foregroundColor(.secondary)
//                }
            }
        }
        .navigationTitle("Credits")
    }
}

