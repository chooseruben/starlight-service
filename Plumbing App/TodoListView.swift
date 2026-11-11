
import SwiftUI

struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted = false
}

struct TodoListView: View {

    @State private var tasks: [TodoItem] = Self.loadTasks()
    @AppStorage("pendingTaskCount") private var pendingTaskCount = 3
    @State private var newTask = ""

    private static let storageKey = "savedPlumbingTasks"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("To-Do List")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(tasks.filter { !$0.isCompleted }.count) Pending")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach($tasks) { $task in
                HStack(spacing: 12) {
                    
                    Button {
                        task.isCompleted.toggle()
                    } label: {
                        Image(systemName: task.isCompleted
                              ? "checkmark.circle.fill"
                              : "circle")
                        .font(.title2)
                        .foregroundStyle(
                            task.isCompleted ? .green : .gray
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Text(task.title)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(
                            task.isCompleted ? .secondary : .primary
                        )
                    
                    Spacer()
                    
                    Button {
                        deleteTask(id: task.id)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
            }
            
            HStack {
                TextField("Add a new task...", text: $newTask)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTask)
                
                Button {
                    addTask()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(
                    newTask.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            updatePendingCount()
        }
        .onChange(of: tasks) { _, updatedTasks in
            saveTasks(updatedTasks)
            updatePendingCount()
        }
    }
        
    private func updatePendingCount() {
        pendingTaskCount = tasks.filter { !$0.isCompleted }.count
    }

    private func addTask() {
        let title = newTask.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !title.isEmpty else { return }

        tasks.append(TodoItem(title: title))
        newTask = ""
    }

    private func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
    }

    private func saveTasks(_ tasks: [TodoItem]) {
        guard let data = try? JSONEncoder().encode(tasks) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Self.storageKey
        )
    }

    private static func loadTasks() -> [TodoItem] {
        if let data = UserDefaults.standard.data(
            forKey: storageKey
        ) {
            return (try? JSONDecoder().decode(
                [TodoItem].self,
                from: data
            )) ?? []
        }

        return [
            TodoItem(title: "Call customer about estimate"),
            TodoItem(title: "Order replacement water heater"),
            TodoItem(title: "Send invoice to Maria")
        ]
    }
}

#Preview {
    TodoListView()
}
