import Foundation
import SwiftUI

struct PageNavigationElement: View {
    @Binding var currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack {
            Button(action: {
                currentPage = 1
            }) {
                Text("First")
            }
            .disabled(currentPage == 1)

            Button(action: {
                if currentPage > 1 {
                    currentPage -= 1
                }
            }) {
                Text("Back")
            }
            .disabled(currentPage == 1)

            Spacer()

            Text("Page \(currentPage) of \(totalPages)")

            Spacer()

            Button(action: {
                if currentPage < totalPages {
                    currentPage += 1
                }
            }) {
                Text("Next")
            }
            .disabled(currentPage == totalPages)

            Button(action: {
                currentPage = totalPages
            }) {
                Text("Last")
            }
            .disabled(currentPage == totalPages)
        }
        .padding([.horizontal, .top])
        .buttonStyle(.bordered)
    }
}
