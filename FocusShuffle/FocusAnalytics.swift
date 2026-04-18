import SwiftUI

// MARK: - Focus Mode View
struct FocusModeView: View {
    @EnvironmentObject var focusVM: FocusViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var analyticsVM: AnalyticsViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var gamificationVM: GamificationViewModel
    @State private var customTask = ""
    @State private var selectedDuration = 25
    @State private var showTaskPicker = false
    @State private var showCompleteAlert = false

    let durations = [5, 10, 15, 25, 30, 45, 60, 90]

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                HStack {
                    Text("Focus Mode")
                        .font(FSFont.display(26))
                        .foregroundStyle(LinearGradient(colors: [.fsGreen, .fsCyan], startPoint: .leading, endPoint: .trailing))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if focusVM.isRunning {
                            RunningTimerView()
                        } else {
                            SetupFocusView(
                                customTask: $customTask,
                                selectedDuration: $selectedDuration,
                                showTaskPicker: $showTaskPicker,
                                durations: durations,
                                onStart: startSession
                            )
                        }

                        // Recent sessions
                        if !focusVM.sessions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Sessions").font(FSFont.heading(16)).foregroundColor(.fsTextPrimary)
                                    .padding(.horizontal, 20)
                                ForEach(focusVM.sessions.prefix(5)) { s in
                                    SessionRow(session: s)
                                }
                            }
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .sheet(isPresented: $showTaskPicker) {
            TaskPickerSheet(selectedTask: $customTask)
        }
        .onChange(of: focusVM.isRunning) { running in
            if !running && focusVM.remainingSeconds == 0 {
                analyticsVM.recordFocusSession(focusVM.selectedDuration)
                gamificationVM.addPoints(25)
                appState.triggerHaptic(.heavy)
                showCompleteAlert = true
            }
        }
        .alert("Session Complete! 🎉", isPresented: $showCompleteAlert) {
            Button("Great!") {}
        } message: {
            Text("You focused for \(focusVM.selectedDuration) minutes on '\(focusVM.currentTask)'. +25 points!")
        }
    }

    func startSession() {
        let task = customTask.trimmingCharacters(in: .whitespaces).isEmpty ? "Deep Work" : customTask
        focusVM.start(task: task, minutes: selectedDuration)
        appState.scheduleFocusReminder(title: task, minutes: selectedDuration)
        appState.triggerHaptic(.medium)
    }
}

// MARK: - Setup Focus
struct SetupFocusView: View {
    @Binding var customTask: String
    @Binding var selectedDuration: Int
    @Binding var showTaskPicker: Bool
    let durations: [Int]
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Task input
            FSCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("What will you focus on?").font(FSFont.heading(16)).foregroundColor(.fsTextPrimary)
                    FSTextField(title: "Task or goal…", text: $customTask, icon: "target")
                    Button(action: { showTaskPicker = true }) {
                        Label("Pick from my tasks", systemImage: "list.bullet")
                            .font(FSFont.body(13)).foregroundColor(.fsElectricBlue)
                    }
                }
            }
            .padding(.horizontal, 20)

            // Duration
            FSCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Duration").font(FSFont.heading(16)).foregroundColor(.fsTextPrimary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(durations, id: \.self) { d in
                            Button(action: { selectedDuration = d }) {
                                VStack(spacing: 2) {
                                    Text("\(d)").font(FSFont.heading(18)).foregroundColor(selectedDuration == d ? .white : .fsTextPrimary)
                                    Text("min").font(FSFont.caption(10)).foregroundColor(selectedDuration == d ? .white.opacity(0.8) : .fsTextMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(selectedDuration == d ? LinearGradient.fsPrimary : LinearGradient(colors: [Color.fsDeepNavy.opacity(0.6), Color.fsDeepNavy.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            FSPrimaryButton("Start Focus Session", icon: "play.fill", gradient: LinearGradient(colors: [.fsGreen, .fsCyan], startPoint: .leading, endPoint: .trailing)) {
                onStart()
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Running Timer
struct RunningTimerView: View {
    @EnvironmentObject var focusVM: FocusViewModel
    @EnvironmentObject var appState: AppState
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 28) {
            // Timer ring
            ZStack {
                GlowCircle(color: .fsGreen, size: 260, blur: 60)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseScale)

                Circle()
                    .stroke(Color.fsCardBg, lineWidth: 14)
                    .frame(width: 220, height: 220)

                Circle()
                    .trim(from: 0, to: focusVM.progress)
                    .stroke(
                        LinearGradient(colors: [.fsGreen, .fsCyan], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: focusVM.progress)

                VStack(spacing: 8) {
                    Text(focusVM.timeString)
                        .font(FSFont.mono(44))
                        .foregroundColor(.fsTextPrimary)
                    Text(focusVM.currentTask)
                        .font(FSFont.body(14))
                        .foregroundColor(.fsTextSecond)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 160)
                }
            }
            .frame(height: 260)

            // Controls
            HStack(spacing: 20) {
                Button(action: {
                    focusVM.isPaused ? focusVM.resume() : focusVM.pause()
                    appState.triggerHaptic()
                }) {
                    Image(systemName: focusVM.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(LinearGradient.fsPrimary)
                        .clipShape(Circle())
                        .shadow(color: .fsElectricBlue.opacity(0.4), radius: 10)
                }

                Button(action: {
                    focusVM.stop()
                    appState.triggerHaptic(.light)
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.fsMagenta)
                        .frame(width: 56, height: 56)
                        .background(Color.fsMagenta.opacity(0.15))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.fsMagenta.opacity(0.3), lineWidth: 1))
                }
            }

            Text(focusVM.isPaused ? "Paused — tap play to resume" : "Stay focused. You've got this! 💪")
                .font(FSFont.body(14))
                .foregroundColor(.fsTextSecond)
        }
        .padding(.horizontal, 20)
        .onAppear { pulseScale = 1.08 }
    }
}

struct SessionRow: View {
    let session: FocusSession
    var body: some View {
        FSCard(padding: 14) {
            HStack {
                ZStack {
                    Circle().fill(session.wasCompleted ? Color.fsGreen.opacity(0.2) : Color.fsTextMuted.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: session.wasCompleted ? "checkmark.circle.fill" : "clock.badge.xmark")
                        .foregroundColor(session.wasCompleted ? .fsGreen : .fsTextMuted)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.taskTitle).font(FSFont.body(14)).foregroundColor(.fsTextPrimary).lineLimit(1)
                    Text("\(session.completedMinutes)/\(session.durationMinutes) min").font(FSFont.caption(12)).foregroundColor(.fsTextSecond)
                }
                Spacer()
                Text(session.startedAt, style: .date).font(FSFont.caption(11)).foregroundColor(.fsTextMuted)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct TaskPickerSheet: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @Binding var selectedTask: String
    @Environment(\.presentationMode) var presentation

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                Capsule().fill(Color.fsTextMuted.opacity(0.4)).frame(width: 40, height: 5).padding(.top, 12).padding(.bottom, 16)
                Text("Pick a Task").font(FSFont.heading(20)).foregroundColor(.fsTextPrimary)
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(taskVM.pendingTasks) { t in
                            Button(action: { selectedTask = t.title; presentation.wrappedValue.dismiss() }) {
                                HStack {
                                    Image(systemName: t.priority.icon).foregroundColor(t.priority.color)
                                    Text(t.title).font(FSFont.body(15)).foregroundColor(.fsTextPrimary)
                                    Spacer()
                                    PriorityBadge(priority: t.priority)
                                }
                                .padding(14)
                                .background(Color.fsCardBg)
                                .cornerRadius(14)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @EnvironmentObject var analyticsVM: AnalyticsViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var focusVM: FocusViewModel

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Text("Analytics")
                        .font(FSFont.display(26))
                        .foregroundStyle(LinearGradient(colors: [.fsGold, .fsMagenta], startPoint: .leading, endPoint: .trailing))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // Overview stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        StatCard(value: "\(analyticsVM.snapshot.totalDecisions)", label: "Total Decisions", icon: "brain.head.profile", color: .fsViolet)
                        StatCard(value: "\(Int(analyticsVM.snapshot.successRate * 100))%", label: "Success Rate", icon: "target", color: .fsGreen)
                        StatCard(value: "\(analyticsVM.snapshot.focusMinutes)", label: "Focus Minutes", icon: "timer", color: .fsCyan)
                        StatCard(value: "\(taskVM.completedTasks.count)", label: "Tasks Done", icon: "checkmark.seal.fill", color: .fsGold)
                    }
                    .padding(.horizontal, 20)

                    // Weekly bar chart
                    FSCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Weekly Activity").font(FSFont.heading(16)).foregroundColor(.fsTextPrimary)
                            HStack(alignment: .bottom, spacing: 10) {
                                ForEach(analyticsVM.snapshot.weeklyData) { d in
                                    VStack(spacing: 6) {
                                        let maxMin = analyticsVM.snapshot.weeklyData.map(\.focusMin).max() ?? 1
                                        let height = CGFloat(d.focusMin) / CGFloat(maxMin) * 80
                                        ZStack(alignment: .bottom) {
                                            RoundedRectangle(cornerRadius: 6).fill(Color.fsDeepNavy).frame(height: 80)
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(LinearGradient(colors: [.fsCyan, .fsElectricBlue], startPoint: .top, endPoint: .bottom))
                                                .frame(height: max(height, 4))
                                        }
                                        Text(d.label).font(FSFont.caption(10)).foregroundColor(.fsTextMuted)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Task completion by priority
                    FSCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Tasks by Priority").font(FSFont.heading(16)).foregroundColor(.fsTextPrimary)
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                let total = taskVM.tasks.filter { $0.priority == p }.count
                                let done  = taskVM.tasks.filter { $0.priority == p && $0.isCompleted }.count
                                let pct   = total > 0 ? CGFloat(done) / CGFloat(total) : 0
                                VStack(spacing: 4) {
                                    HStack {
                                        Label(p.label, systemImage: p.icon).font(FSFont.body(13)).foregroundColor(p.color)
                                        Spacer()
                                        Text("\(done)/\(total)").font(FSFont.mono(12)).foregroundColor(.fsTextSecond)
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.fsDeepNavy).frame(height: 8)
                                            Capsule().fill(p.color).frame(width: geo.size.width * pct, height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Focus sessions list
                    if !focusVM.sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Focus History").font(FSFont.heading(16)).foregroundColor(.fsTextPrimary)
                                .padding(.horizontal, 20)
                            ForEach(focusVM.sessions.prefix(10)) { s in SessionRow(session: s) }
                        }
                    }

                    Spacer().frame(height: 100)
                }
            }
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        FSCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
                Text(value).font(FSFont.display(28)).foregroundColor(.fsTextPrimary)
                    .shadow(color: color.opacity(0.4), radius: 4)
                Text(label).font(FSFont.caption(12)).foregroundColor(.fsTextSecond)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
