import SwiftUI
import WebKit
import Combine

// MARK: - Task List View
struct TaskListView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var gamificationVM: GamificationViewModel
    @Environment(\.presentationMode) var presentation
    @State private var showAdd = false
    @State private var editingTask: FSTask? = nil
    @State private var filterPriority: TaskPriority? = nil
    @State private var showCompleted = false

    var filteredTasks: [FSTask] {
        var list = showCompleted ? taskVM.tasks : taskVM.pendingTasks
        if let p = filterPriority { list = list.filter { $0.priority == p } }
        return list.sorted { $0.priority.score > $1.priority.score }
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Nav
                HStack {
                    Button(action: { presentation.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.fsTextSecond)
                            .padding(10)
                            .background(Color.fsCardBg)
                            .clipShape(Circle())
                    }
                    Text("Task Priority")
                        .font(FSFont.heading(20))
                        .foregroundColor(.fsTextPrimary)
                    Spacer()
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.fsElectricBlue)
                            .padding(10)
                            .background(Color.fsCardBg)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Stats bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(label: "All", count: taskVM.pendingTasks.count, active: filterPriority == nil) {
                            filterPriority = nil
                        }
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            FilterChip(label: p.label, count: taskVM.pendingTasks.filter { $0.priority == p }.count, active: filterPriority == p, color: p.color) {
                                filterPriority = filterPriority == p ? nil : p
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 12)

                Toggle(isOn: $showCompleted) {
                    Text("Show Completed")
                        .font(FSFont.body(14))
                        .foregroundColor(.fsTextSecond)
                }
                .toggleStyle(SwitchToggleStyle(tint: .fsElectricBlue))
                .padding(.horizontal, 20)
                .padding(.top, 10)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            TaskDetailCard(task: task, onEdit: { editingTask = task })
                        }
                        if filteredTasks.isEmpty {
                            EmptyStateCard(message: "No tasks here", icon: "checkmark.circle")
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddTaskSheet() }
        .sheet(item: $editingTask) { task in EditTaskSheet(task: task) }
    }
}
struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

struct FilterChip: View {
    let label: String
    let count: Int
    let active: Bool
    var color: Color = .fsElectricBlue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label)
                    .font(FSFont.body(13))
                Text("\(count)")
                    .font(FSFont.mono(11))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)
            }
            .foregroundColor(active ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(active ? color : color.opacity(0.12))
            .cornerRadius(20)
        }
    }
}

struct TaskDetailCard: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var gamificationVM: GamificationViewModel
    let task: FSTask
    let onEdit: () -> Void
    @State private var showDelete = false

    var body: some View {
        FSCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(action: { taskVM.toggle(task); if !task.isCompleted { gamificationVM.addPoints(10) } }) {
                        ZStack {
                            Circle().stroke(task.priority.color, lineWidth: 2).frame(width: 26, height: 26)
                            if task.isCompleted {
                                Circle().fill(task.priority.color).frame(width: 26, height: 26)
                                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.title)
                            .font(FSFont.heading(15))
                            .foregroundColor(task.isCompleted ? .fsTextMuted : .fsTextPrimary)
                            .strikethrough(task.isCompleted)
                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(FSFont.caption(13))
                                .foregroundColor(.fsTextSecond)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Menu {
                        Button("Edit", action: onEdit)
                        Button("Delete", role: .destructive) { showDelete = true }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.fsTextMuted)
                            .padding(8)
                    }
                }

                HStack(spacing: 10) {
                    PriorityBadge(priority: task.priority)
                    Label(task.category, systemImage: "tag.fill")
                        .font(FSFont.caption(12))
                        .foregroundColor(.fsTextMuted)
                    Spacer()
                    Label("\(task.estimatedMinutes) min", systemImage: "clock.fill")
                        .font(FSFont.caption(12))
                        .foregroundColor(.fsTextMuted)
                }

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(FSFont.caption(12))
                        .foregroundColor(.fsTextSecond)
                        .padding(10)
                        .background(Color.fsDeepNavy.opacity(0.5))
                        .cornerRadius(8)
                }
            }
        }
        .alert("Delete Task", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { taskVM.delete(task) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Add Task Sheet
struct AddTaskSheet: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var gamificationVM: GamificationViewModel
    @Environment(\.presentationMode) var presentation
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var category = "Work"
    @State private var estimatedMinutes: Double = 30
    @State private var notes = ""
    @State private var showValidation = false

    let categories = ["Work", "Health", "Personal", "Learning", "Finance", "Social"]

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    // Handle
                    Capsule()
                        .fill(Color.fsTextMuted.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)

                    Text("New Task")
                        .font(FSFont.heading(22))
                        .foregroundColor(.fsTextPrimary)

                    FSCard {
                        VStack(spacing: 16) {
                            FSTextField(title: "Task title *", text: $title, icon: "pencil")
                            FSTextField(title: "Description", text: $description, icon: "text.alignleft")

                            // Priority
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Priority").font(FSFont.caption(13)).foregroundColor(.fsTextSecond)
                                HStack(spacing: 8) {
                                    ForEach(TaskPriority.allCases, id: \.self) { p in
                                        Button(action: { priority = p }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: p.icon).font(.system(size: 11))
                                                Text(p.label).font(FSFont.caption(12))
                                            }
                                            .foregroundColor(priority == p ? .white : p.color)
                                            .padding(.horizontal, 10).padding(.vertical, 7)
                                            .background(priority == p ? p.color : p.color.opacity(0.15))
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                            }

                            // Category
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category").font(FSFont.caption(13)).foregroundColor(.fsTextSecond)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(categories, id: \.self) { c in
                                            Button(action: { category = c }) {
                                                Text(c)
                                                    .font(FSFont.caption(13))
                                                    .foregroundColor(category == c ? .white : .fsTextSecond)
                                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                                    .background(category == c ? Color.fsElectricBlue : Color.fsDeepNavy.opacity(0.6))
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                            }

                            // Duration
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Estimated Time").font(FSFont.caption(13)).foregroundColor(.fsTextSecond)
                                    Spacer()
                                    Text("\(Int(estimatedMinutes)) min").font(FSFont.mono(14)).foregroundColor(.fsElectricBlue)
                                }
                                Slider(value: $estimatedMinutes, in: 5...240, step: 5)
                                    .accentColor(.fsElectricBlue)
                            }

                            // Notes
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes").font(FSFont.caption(13)).foregroundColor(.fsTextSecond)
                                TextEditor(text: $notes)
                                    .font(FSFont.body(14))
                                    .foregroundColor(.fsTextPrimary)
                                    .frame(minHeight: 60)
                                    .padding(10)
                                    .background(Color.fsDeepNavy.opacity(0.5))
                                    .cornerRadius(10)
                                    .colorScheme(.dark)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if showValidation {
                        Text("Please enter a task title")
                            .font(FSFont.caption(13))
                            .foregroundColor(.fsMagenta)
                    }

                    FSPrimaryButton("Add Task", icon: "plus.circle.fill") { save() }
                        .padding(.horizontal, 20)

                    FSSecondaryButton("Cancel") { presentation.wrappedValue.dismiss() }
                        .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
            }
        }
    }

    func save() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            showValidation = true; return
        }
        let task = FSTask(
            title: title, description: description, priority: priority,
            category: category, estimatedMinutes: Int(estimatedMinutes), notes: notes
        )
        taskVM.add(task)
        gamificationVM.addPoints(5)
        presentation.wrappedValue.dismiss()
    }
}

// MARK: - Edit Task Sheet
struct EditTaskSheet: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @Environment(\.presentationMode) var presentation
    @State var task: FSTask

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Capsule().fill(Color.fsTextMuted.opacity(0.4)).frame(width: 40, height: 5).padding(.top, 12)
                    Text("Edit Task").font(FSFont.heading(22)).foregroundColor(.fsTextPrimary)

                    FSCard {
                        VStack(spacing: 16) {
                            FSTextField(title: "Title", text: $task.title, icon: "pencil")
                            FSTextField(title: "Description", text: $task.description, icon: "text.alignleft")

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Priority").font(FSFont.caption(13)).foregroundColor(.fsTextSecond)
                                HStack(spacing: 8) {
                                    ForEach(TaskPriority.allCases, id: \.self) { p in
                                        Button(action: { task.priority = p }) {
                                            Text(p.label).font(FSFont.caption(12))
                                                .foregroundColor(task.priority == p ? .white : p.color)
                                                .padding(.horizontal, 10).padding(.vertical, 7)
                                                .background(task.priority == p ? p.color : p.color.opacity(0.15))
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    FSPrimaryButton("Save Changes", icon: "checkmark") {
                        taskVM.update(task)
                        presentation.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
            }
        }
    }
}
