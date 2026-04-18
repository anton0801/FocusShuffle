import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var gamificationVM: GamificationViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var showSettings = false
    @State private var showNotes = false
    @State private var showAchievements = false
    @State private var showDecisions = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.fsPrimary)
                                .frame(width: 80, height: 80)
                                .shadow(color: .fsElectricBlue.opacity(0.5), radius: 12)
                            Text(appState.currentUser?.avatarInitials ?? "??")
                                .font(FSFont.display(28))
                                .foregroundColor(.white)
                        }
                        VStack(spacing: 4) {
                            Text(appState.currentUser?.name ?? "User")
                                .font(FSFont.heading(22)).foregroundColor(.fsTextPrimary)
                            Text(appState.currentUser?.email ?? "")
                                .font(FSFont.body(14)).foregroundColor(.fsTextSecond)
                        }

                        // Points + streak
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(gamificationVM.totalPoints)")
                                    .font(FSFont.display(24)).foregroundColor(.fsGold)
                                    .shadow(color: .fsGold.opacity(0.4), radius: 4)
                                Text("Points").font(FSFont.caption(12)).foregroundColor(.fsTextSecond)
                            }
                            Divider().background(Color.fsTextMuted).frame(height: 30)
                            VStack {
                                Text("\(gamificationVM.currentStreak)")
                                    .font(FSFont.display(24)).foregroundColor(.fsMagenta)
                                    .shadow(color: .fsMagenta.opacity(0.4), radius: 4)
                                Text("Day Streak").font(FSFont.caption(12)).foregroundColor(.fsTextSecond)
                            }
                            Divider().background(Color.fsTextMuted).frame(height: 30)
                            VStack {
                                Text("\(taskVM.completedTasks.count)")
                                    .font(FSFont.display(24)).foregroundColor(.fsGreen)
                                    .shadow(color: .fsGreen.opacity(0.4), radius: 4)
                                Text("Completed").font(FSFont.caption(12)).foregroundColor(.fsTextSecond)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.fsCardBg.opacity(0.8))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Quick actions
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        QuickActionCard(title: "Decisions", icon: "brain.head.profile", color: .fsViolet, count: "\(decisionCount)") { showDecisions = true }
                        QuickActionCard(title: "Notes", icon: "note.text", color: .fsElectricBlue, count: nil) { showNotes = true }
                        QuickActionCard(title: "Achievements", icon: "trophy.fill", color: .fsGold, count: "\(gamificationVM.achievements.filter(\.isUnlocked).count)/\(gamificationVM.achievements.count)") { showAchievements = true }
                        QuickActionCard(title: "Settings", icon: "gear", color: .fsTextSecond, count: nil) { showSettings = true }
                    }
                    .padding(.horizontal, 20)

                    // Achievements preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Achievements").font(FSFont.heading(16)).foregroundColor(.fsTextPrimary)
                            .padding(.horizontal, 20)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(gamificationVM.achievements) { a in
                                    AchievementBadge(achievement: a)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer().frame(height: 100)
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showNotes) { NotesView() }
        .sheet(isPresented: $showAchievements) { AchievementsView() }
        .sheet(isPresented: $showDecisions) { DecisionModeView() }
    }

    var decisionCount: String {
        // accessed from EnvironmentObject via parent
        return ""
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let count: String?
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            FSCard(padding: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
                        Spacer()
                        if let c = count {
                            Text(c).font(FSFont.mono(12)).foregroundColor(.fsTextMuted)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.fsDeepNavy.opacity(0.5)).cornerRadius(8)
                        }
                    }
                    Text(title).font(FSFont.heading(15)).foregroundColor(.fsTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scaleEffect(pressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { pressed = true } }
            .onEnded { _ in withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { pressed = false } })
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color.opacity(0.2) : Color.fsCardBg)
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(achievement.isUnlocked ? achievement.color.opacity(0.5) : Color.clear, lineWidth: 2))
                if achievement.isUnlocked {
                    Image(systemName: achievement.icon).font(.system(size: 26)).foregroundColor(achievement.color)
                } else {
                    Image(systemName: "lock.fill").font(.system(size: 22)).foregroundColor(.fsTextMuted)
                }
            }
            Text(achievement.title)
                .font(FSFont.caption(11)).foregroundColor(achievement.isUnlocked ? .fsTextPrimary : .fsTextMuted)
                .multilineTextAlignment(.center).frame(width: 70)
        }
        .opacity(achievement.isUnlocked ? 1 : 0.5)
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @EnvironmentObject var gamificationVM: GamificationViewModel
    @Environment(\.presentationMode) var presentation

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                Capsule().fill(Color.fsTextMuted.opacity(0.4)).frame(width: 40, height: 5).padding(.top, 12).padding(.bottom, 16)
                Text("Achievements").font(FSFont.heading(22)).foregroundColor(.fsTextPrimary).padding(.bottom, 16)
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(gamificationVM.achievements) { a in
                            FSCard(padding: 16) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(a.isUnlocked ? a.color.opacity(0.2) : Color.fsDeepNavy)
                                            .frame(width: 56, height: 56)
                                        Image(systemName: a.isUnlocked ? a.icon : "lock.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(a.isUnlocked ? a.color : .fsTextMuted)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(a.title).font(FSFont.heading(15)).foregroundColor(a.isUnlocked ? .fsTextPrimary : .fsTextMuted)
                                        Text(a.description).font(FSFont.caption(13)).foregroundColor(.fsTextSecond)
                                        if a.isUnlocked, let date = a.unlockedAt {
                                            Text("Unlocked \(date, style: .date)").font(FSFont.caption(11)).foregroundColor(a.color)
                                        }
                                    }
                                    Spacer()
                                    if a.isUnlocked {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.fsGreen)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .opacity(a.isUnlocked ? 1 : 0.6)
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }
}

// MARK: - Notes View
struct NotesView: View {
    @AppStorage("notesData") private var notesData: Data = Data()
    @State private var notes: [FSNote] = []
    @State private var showAdd = false
    @State private var editNote: FSNote? = nil
    @Environment(\.presentationMode) var presentation

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { presentation.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.down").foregroundColor(.fsTextSecond).padding(10).background(Color.fsCardBg).clipShape(Circle())
                    }
                    Text("Notes").font(FSFont.heading(20)).foregroundColor(.fsTextPrimary)
                    Spacer()
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus").foregroundColor(.fsElectricBlue).padding(10).background(Color.fsCardBg).clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20).padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        if notes.isEmpty {
                            EmptyStateCard(message: "No notes yet. Write something!", icon: "note.text")
                                .padding(.horizontal, 20)
                        } else {
                            ForEach(notes) { note in
                                NoteCard(note: note, onEdit: { editNote = note }, onDelete: { deleteNote(note) })
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 16).padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showAdd) { NoteEditorSheet(note: nil, onSave: { saveNote($0) }) }
        .sheet(item: $editNote) { n in NoteEditorSheet(note: n, onSave: { saveNote($0) }) }
        .onAppear { loadNotes() }
    }

    func loadNotes() {
        notes = (try? JSONDecoder().decode([FSNote].self, from: notesData)) ?? []
    }
    func saveNote(_ note: FSNote) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) { notes[idx] = note }
        else { notes.insert(note, at: 0) }
        persist()
    }
    func deleteNote(_ note: FSNote) { notes.removeAll { $0.id == note.id }; persist() }
    func persist() { notesData = (try? JSONEncoder().encode(notes)) ?? Data() }
}

struct NoteCard: View {
    let note: FSNote
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        FSCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(note.title).font(FSFont.heading(15)).foregroundColor(.fsTextPrimary)
                    Spacer()
                    Menu {
                        Button("Edit", action: onEdit)
                        Button("Delete", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis").foregroundColor(.fsTextMuted)
                    }
                }
                Text(note.content).font(FSFont.caption(13)).foregroundColor(.fsTextSecond).lineLimit(3)
                HStack {
                    if !note.tags.isEmpty {
                        ForEach(note.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)").font(FSFont.caption(11)).foregroundColor(.fsElectricBlue)
                        }
                    }
                    Spacer()
                    Text(note.updatedAt, style: .date).font(FSFont.caption(11)).foregroundColor(.fsTextMuted)
                }
            }
        }
    }
}

struct NoteEditorSheet: View {
    let note: FSNote?
    let onSave: (FSNote) -> Void
    @Environment(\.presentationMode) var presentation
    @State private var title: String
    @State private var content: String
    @State private var tagsText: String

    init(note: FSNote?, onSave: @escaping (FSNote) -> Void) {
        self.note = note; self.onSave = onSave
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _tagsText = State(initialValue: note?.tags.joined(separator: ", ") ?? "")
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Capsule().fill(Color.fsTextMuted.opacity(0.4)).frame(width: 40, height: 5).padding(.top, 12)
                    Text(note == nil ? "New Note" : "Edit Note").font(FSFont.heading(20)).foregroundColor(.fsTextPrimary)
                    FSCard {
                        VStack(spacing: 16) {
                            FSTextField(title: "Title", text: $title, icon: "pencil")
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Content").font(FSFont.caption(13)).foregroundColor(.fsTextSecond)
                                TextEditor(text: $content)
                                    .font(FSFont.body(14)).foregroundColor(.fsTextPrimary)
                                    .frame(minHeight: 120).padding(10)
                                    .background(Color.fsDeepNavy.opacity(0.5)).cornerRadius(10).colorScheme(.dark)
                            }
                            FSTextField(title: "Tags (comma separated)", text: $tagsText, icon: "tag.fill")
                        }
                    }
                    .padding(.horizontal, 20)
                    FSPrimaryButton("Save Note", icon: "checkmark") { saveAndDismiss() }.padding(.horizontal, 20)
                    FSSecondaryButton("Cancel") { presentation.wrappedValue.dismiss() }.padding(.horizontal, 20)
                    Spacer().frame(height: 40)
                }
            }
        }
    }

    func saveAndDismiss() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var updated = note ?? FSNote(title: "", content: "")
        updated.title = title; updated.content = content
        updated.tags = tags; updated.updatedAt = Date()
        onSave(updated)
        presentation.wrappedValue.dismiss()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentation
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HStack {
                        Button(action: { presentation.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.down").foregroundColor(.fsTextSecond).padding(10).background(Color.fsCardBg).clipShape(Circle())
                        }
                        Text("Settings").font(FSFont.heading(20)).foregroundColor(.fsTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 16)

                    // Appearance
                    SettingsSection(title: "Appearance") {
                        VStack(spacing: 0) {
                            SettingsRow(title: "Theme") {
                                Picker("Theme", selection: $appState.themePreference) {
                                    Text("Dark").tag("dark")
                                    Text("Light").tag("light")
                                    Text("System").tag("system")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 180)
                            }
                        }
                    }

                    // Notifications & Experience
                    SettingsSection(title: "Experience") {
                        VStack(spacing: 0) {
                            SettingsToggleRow(title: "Notifications", subtitle: "Focus reminders & alerts", icon: "bell.fill", color: .fsElectricBlue, isOn: $appState.notificationsEnabled)
                            Divider().background(Color.fsTextMuted.opacity(0.2)).padding(.leading, 56)
                            SettingsToggleRow(title: "Haptic Feedback", subtitle: "Vibration on interactions", icon: "hand.tap.fill", color: .fsViolet, isOn: $appState.hapticEnabled)
                            Divider().background(Color.fsTextMuted.opacity(0.2)).padding(.leading, 56)
                            SettingsToggleRow(title: "Sound Effects", subtitle: "UI sounds", icon: "speaker.wave.2.fill", color: .fsCyan, isOn: $appState.soundEnabled)
                        }
                    }

                    // Account
                    SettingsSection(title: "Account") {
                        VStack(spacing: 0) {
                            if let user = appState.currentUser {
                                SettingsInfoRow(title: "Name", value: user.name, icon: "person.fill")
                                Divider().background(Color.fsTextMuted.opacity(0.2)).padding(.leading, 56)
                                SettingsInfoRow(title: "Email", value: user.email, icon: "envelope.fill")
                                Divider().background(Color.fsTextMuted.opacity(0.2)).padding(.leading, 56)
                            }
                            Button(action: { showLogoutConfirm = true }) {
                                SettingsActionRow(title: "Log Out", icon: "arrow.right.circle.fill", color: .fsGold)
                            }
                            .buttonStyle(PlainButtonStyle())
                            Divider().background(Color.fsTextMuted.opacity(0.2)).padding(.leading, 56)
                            Button(action: { showDeleteConfirm = true }) {
                                SettingsActionRow(title: "Delete Account", icon: "trash.fill", color: .fsMagenta)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // App info
                    SettingsSection(title: "About") {
                        VStack(spacing: 0) {
                            SettingsInfoRow(title: "Version", value: "1.0.0", icon: "info.circle.fill")
                            Divider().background(Color.fsTextMuted.opacity(0.2)).padding(.leading, 56)
                            SettingsInfoRow(title: "Build", value: "100", icon: "hammer.fill")
                        }
                    }

                    Spacer().frame(height: 60)
                }
            }
        }
        .alert("Log Out", isPresented: $showLogoutConfirm) {
            Button("Log Out", role: .destructive) {
                presentation.wrappedValue.dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { appState.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure you want to log out?") }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Delete Account", role: .destructive) {
                presentation.wrappedValue.dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { appState.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will permanently delete your account and all data. This cannot be undone.") }
    }
}

// Settings sub-views
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    init(title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(FSFont.caption(12)).foregroundColor(.fsTextMuted).padding(.horizontal, 20).padding(.leading, 4)
            FSCard(padding: 0) { content }.padding(.horizontal, 20)
        }
    }
}

struct SettingsRow<T: View>: View {
    let title: String
    let trailing: T
    init(title: String, @ViewBuilder trailing: () -> T) { self.title = title; self.trailing = trailing() }
    var body: some View {
        HStack {
            Text(title).font(FSFont.body(15)).foregroundColor(.fsTextPrimary)
            Spacer()
            trailing
        }
        .padding(16)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.2)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(FSFont.body(15)).foregroundColor(.fsTextPrimary)
                Text(subtitle).font(FSFont.caption(12)).foregroundColor(.fsTextSecond)
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding(14)
    }
}

struct SettingsInfoRow: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(.fsTextSecond).frame(width: 30)
            Text(title).font(FSFont.body(15)).foregroundColor(.fsTextPrimary)
            Spacer()
            Text(value).font(FSFont.caption(14)).foregroundColor(.fsTextSecond)
        }
        .padding(16)
    }
}

struct SettingsActionRow: View {
    let title: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(color).frame(width: 30)
            Text(title).font(FSFont.body(15)).foregroundColor(color)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.fsTextMuted)
        }
        .padding(16)
    }
}
