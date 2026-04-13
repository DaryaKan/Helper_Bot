import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ChecklistStore

    var body: some View {
        CardGridView()
            .task {
                await store.fetchTasks()
            }
    }
}
