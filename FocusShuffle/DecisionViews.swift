import SwiftUI

struct DecisionModeView: View {
    @EnvironmentObject var decisionVM: DecisionViewModel
    @EnvironmentObject var analyticsVM: AnalyticsViewModel
    @EnvironmentObject var gamificationVM: GamificationViewModel
    @State private var showNew = false
    @State private var selectedDecision: FSDecision? = nil

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                HStack {
                    Text("Decision Mode")
                        .font(FSFont.display(26))
                        .foregroundStyle(LinearGradient(colors: [.fsMagenta, .fsViolet], startPoint: .leading, endPoint: .trailing))
                    Spacer()
                    Button(action: { showNew = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.fsElectricBlue)
                            .padding(10)
                            .background(Color.fsCardBg)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if decisionVM.decisions.isEmpty {
                            EmptyStateCard(message: "No decisions yet. Create one!", icon: "lightbulb.fill")
                                .padding(.horizontal, 20)
                        } else {
                            ForEach(decisionVM.decisions) { d in
                                DecisionCard(decision: d)
                                    .onTapGesture { selectedDecision = d }
                                    .padding(.horizontal, 20)
                            }
                        }
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .sheet(isPresented: $showNew) { NewDecisionSheet() }
        .sheet(item: $selectedDecision) { d in DecisionDetailView(decision: d) }
    }
}

// MARK: - Decision Card
struct DecisionCard: View {
    @EnvironmentObject var decisionVM: DecisionViewModel
    let decision: FSDecision
    @State private var showDelete = false

    var body: some View {
        FSCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.fsViolet)
                    Text(decision.question)
                        .font(FSFont.heading(15))
                        .foregroundColor(.fsTextPrimary)
                        .lineLimit(2)
                    Spacer()
                    Button(action: { showDelete = true }) {
                        Image(systemName: "trash").foregroundColor(.fsTextMuted).font(.system(size: 14))
                    }
                }
                HStack(spacing: 8) {
                    ForEach(decision.options.prefix(3)) { opt in
                        Text(opt.title)
                            .font(FSFont.caption(11))
                            .foregroundColor(.fsTextSecond)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.fsDeepNavy.opacity(0.5))
                            .cornerRadius(8)
                    }
                    if decision.options.count > 3 {
                        Text("+\(decision.options.count - 3)")
                            .font(FSFont.caption(11)).foregroundColor(.fsTextMuted)
                    }
                }
                if let rec = decision.recommendedOption {
                    HStack {
                        Image(systemName: "crown.fill").foregroundColor(.fsGold).font(.system(size: 12))
                        Text("Best: \(rec.title)").font(FSFont.caption(12)).foregroundColor(.fsGold)
                    }
                }
                Text(decision.createdAt, style: .date)
                    .font(FSFont.caption(11)).foregroundColor(.fsTextMuted)
            }
        }
        .alert("Delete Decision", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { decisionVM.delete(decision) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - New Decision Sheet
struct NewDecisionSheet: View {
    @EnvironmentObject var decisionVM: DecisionViewModel
    @EnvironmentObject var analyticsVM: AnalyticsViewModel
    @EnvironmentObject var gamificationVM: GamificationViewModel
    @Environment(\.presentationMode) var presentation
    @State private var question = ""
    @State private var options: [DecisionOption] = [
        DecisionOption(title: "Option A", description: "", weight: 3),
        DecisionOption(title: "Option B", description: "", weight: 2),
    ]
    @State private var notes = ""
    @State private var showValidation = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Capsule().fill(Color.fsTextMuted.opacity(0.4)).frame(width: 40, height: 5).padding(.top, 12)
                    Text("New Decision").font(FSFont.heading(22)).foregroundColor(.fsTextPrimary)

                    FSCard {
                        VStack(spacing: 16) {
                            FSTextField(title: "What are you deciding? *", text: $question, icon: "questionmark.circle.fill")
                            FSTextField(title: "Notes (optional)", text: $notes, icon: "note.text")
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Options").font(FSFont.heading(16)).foregroundColor(.fsTextPrimary)
                                .padding(.horizontal, 20)
                            Spacer()
                            Button(action: addOption) {
                                Label("Add", systemImage: "plus.circle.fill")
                                    .font(FSFont.body(14)).foregroundColor(.fsElectricBlue)
                            }
                            .padding(.horizontal, 20)
                        }

                        ForEach($options) { $opt in
                            FSCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        FSTextField(title: "Title", text: $opt.title, icon: "circle.fill")
                                        if options.count > 2 {
                                            Button(action: { options.removeAll { $0.id == opt.id } }) {
                                                Image(systemName: "minus.circle.fill").foregroundColor(.fsMagenta)
                                            }
                                        }
                                    }
                                    FSTextField(title: "Description", text: $opt.description, icon: "text.alignleft")
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("Weight:").font(FSFont.caption(13)).foregroundColor(.fsTextSecond)
                                            Spacer()
                                            Text(String(format: "%.1f", opt.weight)).font(FSFont.mono(13)).foregroundColor(.fsViolet)
                                        }
                                        Slider(value: $opt.weight, in: 1...5, step: 0.5).accentColor(.fsViolet)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    if showValidation {
                        Text("Please enter your question and at least 2 options")
                            .font(FSFont.caption(13)).foregroundColor(.fsMagenta)
                    }

                    FSPrimaryButton("Create Decision", icon: "checkmark.seal.fill", gradient: LinearGradient(colors: [.fsMagenta, .fsViolet], startPoint: .leading, endPoint: .trailing)) { save() }
                        .padding(.horizontal, 20)

                    FSSecondaryButton("Cancel") { presentation.wrappedValue.dismiss() }.padding(.horizontal, 20)
                    Spacer().frame(height: 40)
                }
            }
        }
    }

    func addOption() {
        let count = options.count + 1
        let labels = ["A","B","C","D","E","F"]
        let label = count <= labels.count ? labels[count-1] : "\(count)"
        options.append(DecisionOption(title: "Option \(label)", description: "", weight: 2.5))
    }

    func save() {
        guard !question.trimmingCharacters(in: .whitespaces).isEmpty,
              options.count >= 2 else { showValidation = true; return }
        var decision = FSDecision(question: question, options: options, notes: notes)
        decision.recommendedOptionId = decisionVM.recommend(for: decision)
        decisionVM.add(decision)
        analyticsVM.recordDecision(wasSuccessful: true)
        gamificationVM.addPoints(20)
        presentation.wrappedValue.dismiss()
    }
}

// MARK: - Decision Detail
struct DecisionDetailView: View {
    @EnvironmentObject var decisionVM: DecisionViewModel
    @Environment(\.presentationMode) var presentation
    var decision: FSDecision
    @State private var shuffledOptions: [DecisionOption] = []
    @State private var selectedOptionId: String? = nil
    @State private var isShuffling = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Capsule().fill(Color.fsTextMuted.opacity(0.4)).frame(width: 40, height: 5).padding(.top, 12)

                    Text(decision.question)
                        .font(FSFont.heading(20)).foregroundColor(.fsTextPrimary)
                        .multilineTextAlignment(.center).padding(.horizontal, 24)

                    // Options with weights
                    ForEach(decision.options) { opt in
                        OptionWeightCard(option: opt, isRecommended: opt.id == decision.recommendedOptionId, isSelected: selectedOptionId == opt.id) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedOptionId = opt.id
                            }
                            var updated = decision
                            updated.chosenOptionId = opt.id
                            decisionVM.update(updated)
                        }
                        .padding(.horizontal, 20)
                    }

                    if let recId = decision.recommendedOptionId, let rec = decision.options.first(where: { $0.id == recId }) {
                        FSCard {
                            HStack {
                                Image(systemName: "crown.fill").foregroundColor(.fsGold).font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Recommended Choice").font(FSFont.caption(12)).foregroundColor(.fsTextSecond)
                                    Text(rec.title).font(FSFont.heading(18)).foregroundColor(.fsGold)
                                    Text("Highest weight: \(String(format: "%.1f", rec.weight))/5.0")
                                        .font(FSFont.caption(13)).foregroundColor(.fsTextSecond)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if !decision.notes.isEmpty {
                        FSCard {
                            HStack {
                                Image(systemName: "note.text").foregroundColor(.fsElectricBlue)
                                Text(decision.notes).font(FSFont.body(14)).foregroundColor(.fsTextPrimary)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
    }
}

struct OptionWeightCard: View {
    let option: DecisionOption
    let isRecommended: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            FSCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(option.title).font(FSFont.heading(16)).foregroundColor(.fsTextPrimary)
                        Spacer()
                        if isRecommended {
                            Image(systemName: "crown.fill").foregroundColor(.fsGold)
                        }
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.fsGreen)
                        }
                    }
                    if !option.description.isEmpty {
                        Text(option.description).font(FSFont.caption(13)).foregroundColor(.fsTextSecond)
                    }
                    HStack {
                        Text("Weight").font(FSFont.caption(12)).foregroundColor(.fsTextMuted)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.fsDeepNavy).frame(height: 6)
                                Capsule()
                                    .fill(isRecommended ? LinearGradient(colors: [.fsGold, Color(hex: "#FF8C00")], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.fsViolet, .fsElectricBlue], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * CGFloat(option.weight / 5.0), height: 6)
                            }
                        }
                        .frame(height: 6)
                        Text(String(format: "%.1f", option.weight)).font(FSFont.mono(12)).foregroundColor(.fsViolet)
                    }
                    if !option.pros.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(option.pros, id: \.self) { pro in
                                Label(pro, systemImage: "plus.circle.fill").font(FSFont.caption(11)).foregroundColor(.fsGreen)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.fsGreen.opacity(0.6) : isRecommended ? Color.fsGold.opacity(0.4) : Color.clear, lineWidth: 2)
        )
    }
}
