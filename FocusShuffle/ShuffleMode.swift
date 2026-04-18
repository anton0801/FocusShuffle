import SwiftUI

// MARK: - Shuffle Mode Container
struct ShuffleModeContainerView: View {
    @State private var step: ShuffleStep = .addItems
    @State private var items: [ShuffleItem] = []
    @State private var shuffledItems: [ShuffleItem] = []
    @State private var chosenIndex: Int? = nil
    @State private var resultItem: ShuffleItem? = nil
    @State private var sourceMode: ShuffleSource = .custom
    @State private var newItemText = ""
    @State private var newItemPriority: TaskPriority = .medium
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var decisionVM: DecisionViewModel
    @EnvironmentObject var gamificationVM: GamificationViewModel

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Shuffle Mode")
                        .font(FSFont.display(26))
                        .foregroundStyle(LinearGradient(colors: [.fsCyan, .fsViolet], startPoint: .leading, endPoint: .trailing))
                    Spacer()
                    Button(action: resetShuffle) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.fsTextSecond)
                            .padding(10)
                            .background(Color.fsCardBg)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Step indicator
                ShuffleStepIndicator(currentStep: step)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        switch step {
                        case .addItems:
                            AddItemsStep(
                                items: $items,
                                newItemText: $newItemText,
                                newItemPriority: $newItemPriority,
                                sourceMode: $sourceMode,
                                onNext: { shuffledItems = items.shuffled(); step = .shuffling }
                            )
                        case .shuffling:
                            ShufflingStep(items: shuffledItems, onProceed: { step = .pick })
                        case .pick:
                            PickStep(items: shuffledItems, onChose: { idx in
                                chosenIndex = idx
                                resultItem = bestOption()
                                step = .result
                                gamificationVM.addPoints(15)
                            })
                        case .result:
                            ResultStep(
                                items: shuffledItems,
                                chosenIndex: chosenIndex,
                                bestItem: resultItem,
                                onAgain: resetShuffle
                            )
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 20)
                }
            }
        }
    }

    func bestOption() -> ShuffleItem? {
        shuffledItems.max(by: { $0.score < $1.score })
    }

    func resetShuffle() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            step = .addItems
            items = []
            shuffledItems = []
            chosenIndex = nil
            resultItem = nil
            newItemText = ""
        }
    }
}

enum ShuffleStep: Int, CaseIterable {
    case addItems = 0, shuffling, pick, result
    var label: String {
        switch self {
        case .addItems:  return "Add"
        case .shuffling: return "Shuffle"
        case .pick:      return "Pick"
        case .result:    return "Result"
        }
    }
}

enum ShuffleSource: String, CaseIterable {
    case custom = "Custom"
    case tasks  = "My Tasks"
    case decision = "Decision"
}

// MARK: - Step Indicator
struct ShuffleStepIndicator: View {
    let currentStep: ShuffleStep
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ShuffleStep.allCases, id: \.rawValue) { step in
                let active = step.rawValue <= currentStep.rawValue
                HStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(active ? Color.fsElectricBlue : Color.fsCardBg)
                            .frame(width: 28, height: 28)
                        Text("\(step.rawValue + 1)")
                            .font(FSFont.body(12))
                            .foregroundColor(active ? .white : .fsTextMuted)
                    }
                    if step.rawValue < ShuffleStep.allCases.count - 1 {
                        Rectangle()
                            .fill(active ? Color.fsElectricBlue.opacity(0.5) : Color.fsCardBg)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: step.rawValue < ShuffleStep.allCases.count - 1 ? .infinity : nil)
            }
        }
    }
}

// MARK: - Add Items Step
struct AddItemsStep: View {
    @Binding var items: [ShuffleItem]
    @Binding var newItemText: String
    @Binding var newItemPriority: TaskPriority
    @Binding var sourceMode: ShuffleSource
    let onNext: () -> Void
    @EnvironmentObject var taskVM: TaskViewModel

    var body: some View {
        VStack(spacing: 20) {
            // Source selector
            FSCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Options")
                        .font(FSFont.heading(16))
                        .foregroundColor(.fsTextPrimary)

                    Picker("Source", selection: $sourceMode) {
                        ForEach(ShuffleSource.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if sourceMode == .custom {
                        VStack(spacing: 10) {
                            FSTextField(title: "Option / Task title", text: $newItemText, icon: "pencil")
                            HStack {
                                Text("Priority:")
                                    .font(FSFont.caption(13))
                                    .foregroundColor(.fsTextSecond)
                                Spacer()
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    Button(action: { newItemPriority = p }) {
                                        Text(p.label)
                                            .font(FSFont.caption(11))
                                            .foregroundColor(newItemPriority == p ? .white : p.color)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(newItemPriority == p ? p.color : p.color.opacity(0.15))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            Button(action: addCustomItem) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Option")
                                }
                                .font(FSFont.body(14))
                                .foregroundColor(.fsElectricBlue)
                            }
                            .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    } else if sourceMode == .tasks {
                        ForEach(taskVM.pendingTasks.prefix(5)) { task in
                            let isAdded = items.contains { $0.id == task.id }
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title).font(FSFont.body(14)).foregroundColor(.fsTextPrimary)
                                    PriorityBadge(priority: task.priority)
                                }
                                Spacer()
                                Button(action: {
                                    if isAdded { items.removeAll { $0.id == task.id } }
                                    else { items.append(ShuffleItem(id: task.id, label: task.title, subtitle: task.category, priority: task.priority, score: Double(task.priority.score))) }
                                }) {
                                    Image(systemName: isAdded ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isAdded ? .fsGreen : .fsTextMuted)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            // Items list
            if !items.isEmpty {
                FSCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Options (\(items.count))")
                            .font(FSFont.heading(15))
                            .foregroundColor(.fsTextPrimary)
                        ForEach(items) { item in
                            HStack {
                                Image(systemName: item.priority.icon)
                                    .foregroundColor(item.priority.color)
                                Text(item.label)
                                    .font(FSFont.body(14))
                                    .foregroundColor(.fsTextPrimary)
                                Spacer()
                                Button(action: { items.removeAll { $0.id == item.id } }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.fsTextMuted)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            FSPrimaryButton("Start Shuffle", icon: "shuffle") {
                guard items.count >= 2 else { return }
                onNext()
            }
            .padding(.horizontal, 20)
            .opacity(items.count >= 2 ? 1 : 0.5)

            if items.count < 2 {
                Text("Add at least 2 options to shuffle")
                    .font(FSFont.caption(13))
                    .foregroundColor(.fsTextMuted)
            }
        }
    }

    func addCustomItem() {
        let text = newItemText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        items.append(ShuffleItem(label: text, subtitle: "", priority: newItemPriority, score: Double(newItemPriority.score)))
        newItemText = ""
    }
}

// MARK: - Shuffling Step
struct ShufflingStep: View {
    let items: [ShuffleItem]
    let onProceed: () -> Void
    @State private var isAnimating = false
    @State private var positions: [Int] = []
    @State private var shuffleCount = 0
    @State private var done = false

    var body: some View {
        VStack(spacing: 30) {
            FSCard {
                VStack(spacing: 16) {
                    Text("Shuffling…")
                        .font(FSFont.heading(20))
                        .foregroundColor(.fsTextPrimary)
                    Text("Train your attention")
                        .font(FSFont.body(14))
                        .foregroundColor(.fsTextSecond)

                    // Show up to 3 thimbles
                    HStack(spacing: 20) {
                        ForEach(0..<min(items.count, 3), id: \.self) { i in
                            let posIdx = positions.indices.contains(i) ? positions[i] : i
                            ThimbleView(
                                color: thimbleColors[i % thimbleColors.count],
                                hasBall: i == 0 && done,
                                label: done ? (items.indices.contains(i) ? items[i].label : "") : ""
                            )
                            .offset(x: CGFloat(posIdx - 1) * 5)
                            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: positions)
                        }
                    }
                    .frame(height: 120)

                    if done {
                        Text("Reveal complete — now pick!")
                            .font(FSFont.body(14))
                            .foregroundColor(.fsGreen)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("Watching carefully? 👀")
                            .font(FSFont.caption(13))
                            .foregroundColor(.fsTextSecond)
                    }
                }
            }
            .padding(.horizontal, 20)

            if done {
                FSPrimaryButton("I'm Ready to Pick", icon: "hand.point.up.fill") { onProceed() }
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear { startShuffle() }
    }

    let thimbleColors: [Color] = [.fsElectricBlue, .fsViolet, .fsCyan]

    func startShuffle() {
        positions = Array(0..<min(items.count, 3))
        let swaps = 12
        for i in 0...swaps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                withAnimation {
                    positions = positions.shuffled()
                    shuffleCount += 1
                }
                if i == swaps {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation { done = true }
                    }
                }
            }
        }
    }
}

// MARK: - Pick Step
struct PickStep: View {
    let items: [ShuffleItem]
    let onChose: (Int) -> Void
    @State private var hoveredIndex: Int? = nil
    @State private var appeared = false

    let thimbleColors: [Color] = [.fsElectricBlue, .fsViolet, .fsCyan, .fsMagenta, .fsGold]

    var body: some View {
        VStack(spacing: 28) {
            FSCard {
                VStack(spacing: 8) {
                    Image(systemName: "hand.point.up.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.fsCyan)
                    Text("Tap a Thimble")
                        .font(FSFont.heading(22))
                        .foregroundColor(.fsTextPrimary)
                    Text("Which one holds the best option?")
                        .font(FSFont.body(14))
                        .foregroundColor(.fsTextSecond)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)

            // Thimbles grid
            let cols = items.count <= 3 ? items.count : 3
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: cols), spacing: 20) {
                ForEach(items.indices, id: \.self) { i in
                    Button(action: { onChose(i) }) {
                        VStack(spacing: 8) {
                            ThimbleView(
                                color: thimbleColors[i % thimbleColors.count],
                                hasBall: false,
                                label: ""
                            )
                            .scaleEffect(hoveredIndex == i ? 1.1 : 1.0)
                            .shadow(
                                color: thimbleColors[i % thimbleColors.count].opacity(hoveredIndex == i ? 0.7 : 0.2),
                                radius: hoveredIndex == i ? 20 : 6
                            )
                            Text("Option \(i + 1)")
                                .font(FSFont.caption(12))
                                .foregroundColor(.fsTextSecond)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            hoveredIndex = pressing ? i : nil
                        }
                    }, perform: {})
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            for i in items.indices {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.1)) {
                    appeared = true
                }
            }
        }
    }
}

// MARK: - Result Step
struct ResultStep: View {
    let items: [ShuffleItem]
    let chosenIndex: Int?
    let bestItem: ShuffleItem?
    let onAgain: () -> Void
    @State private var revealed = false
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 24) {
            // Best choice reveal
            FSCard {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.fsGold.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .scaleEffect(glowPulse ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glowPulse)
                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.fsGold)
                    }

                    Text("Best Option")
                        .font(FSFont.heading(14))
                        .foregroundColor(.fsTextSecond)

                    if let best = bestItem {
                        Text(best.label)
                            .font(FSFont.display(26))
                            .foregroundColor(.fsTextPrimary)
                            .multilineTextAlignment(.center)
                            .scaleEffect(revealed ? 1 : 0.6)
                            .opacity(revealed ? 1 : 0)

                        PriorityBadge(priority: best.priority)

                        if !best.subtitle.isEmpty {
                            Text(best.subtitle)
                                .font(FSFont.body(13))
                                .foregroundColor(.fsTextSecond)
                        }
                    }

                    if let ci = chosenIndex, let chosen = items.indices.contains(ci) ? items[ci] : nil {
                        Divider().background(Color.fsTextMuted.opacity(0.3))
                        HStack {
                            Text("You picked:")
                                .font(FSFont.caption(13))
                                .foregroundColor(.fsTextSecond)
                            Text(chosen.label)
                                .font(FSFont.body(13))
                                .foregroundColor(.fsTextPrimary)
                            Spacer()
                            if chosen.id == bestItem?.id {
                                Label("Great pick!", systemImage: "checkmark.circle.fill")
                                    .font(FSFont.caption(12))
                                    .foregroundColor(.fsGreen)
                            } else {
                                Text("See best above ↑")
                                    .font(FSFont.caption(12))
                                    .foregroundColor(.fsTextMuted)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)

            // All options ranking
            VStack(alignment: .leading, spacing: 12) {
                Text("All Options (by priority)")
                    .font(FSFont.heading(15))
                    .foregroundColor(.fsTextPrimary)
                    .padding(.horizontal, 20)

                ForEach(items.sorted { $0.score > $1.score }) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.priority.icon)
                            .foregroundColor(item.priority.color)
                        Text(item.label)
                            .font(FSFont.body(14))
                            .foregroundColor(item.id == bestItem?.id ? .fsGold : .fsTextPrimary)
                        Spacer()
                        if item.id == bestItem?.id {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.fsGold)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(14)
                    .background(item.id == bestItem?.id ? Color.fsGold.opacity(0.1) : Color.fsCardBg)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(item.id == bestItem?.id ? Color.fsGold.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
            }

            FSPrimaryButton("Shuffle Again", icon: "shuffle", gradient: .fsCyanViolet) { onAgain() }
                .padding(.horizontal, 20)
        }
        .onAppear {
            glowPulse = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                revealed = true
            }
        }
    }
}
