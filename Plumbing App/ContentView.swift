
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            CustomersView()
                .tabItem {
                    Label("Customers", systemImage: "person.2.fill")
                }

            PriceBookView()
                .tabItem {
                    Label("Price Book", systemImage: "book.closed.fill")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
