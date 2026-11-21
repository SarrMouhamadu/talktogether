import SwiftUI

public struct CreateTopicView: View {
    @Environment(\.dismiss) private var dismiss
    
    public let editingTopic: Topic?
    public var onTopicCreated: ((Topic) -> Void)?
    
    @State private var debateQuestion: String
    @State private var shortDescription: String
    @State private var selectedCategory: TopicCategory
    @State private var hasScheduledTime: Bool
    @State private var scheduledDate: Date
    @State private var isSubmitting: Bool = false
    @State private var submittedPosition: Int? = nil
    
    public init(
        editingTopic: Topic? = nil,
        onTopicCreated: ((Topic) -> Void)? = nil
    ) {
        self.editingTopic = editingTopic
        self.onTopicCreated = onTopicCreated
        _debateQuestion = State(initialValue: editingTopic?.debateQuestion ?? "")
        _shortDescription = State(initialValue: editingTopic?.description ?? "")
        _selectedCategory = State(initialValue: editingTopic?.category ?? .society)
        let initialDate = editingTopic?.scheduledStartTime ?? Date().addingTimeInterval(30 * 60)
        _hasScheduledTime = State(initialValue: editingTopic?.scheduledStartTime != nil)
        _scheduledDate = State(initialValue: initialDate)
    }
    
    private var isEditing: Bool { editingTopic != nil }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                if let position = submittedPosition {
                    submissionSuccessView(position: position)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppTheme.space20) {
                            // 1. Question & Context Inputs
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Debate Topic")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                    .padding(.horizontal, AppTheme.space4)
                                
                                VStack(spacing: 0) {
                                    TextField(
                                        "",
                                        text: $debateQuestion,
                                        prompt: Text("What should we debate? (e.g. Is remote work more productive?)").foregroundColor(AppTheme.placeholderText),
                                        axis: .vertical
                                    )
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                    .tint(AppTheme.primaryBlue)
                                    .lineLimit(2...5)
                                    .padding(AppTheme.space16)
                                    
                                    Rectangle()
                                        .fill(AppTheme.separator)
                                        .frame(height: 1)
                                        .padding(.leading, AppTheme.space16)
                                    
                                    TextField(
                                        "",
                                        text: $shortDescription,
                                        prompt: Text("Add context, speaking points, or debate rules (optional)").foregroundColor(AppTheme.placeholderText),
                                        axis: .vertical
                                    )
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primaryText)
                                    .tint(AppTheme.primaryBlue)
                                    .lineLimit(2...4)
                                    .padding(AppTheme.space16)
                                }
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                        .stroke(AppTheme.inputBorder, lineWidth: 1.2)
                                )
                            }
                            
                            // 2. Category Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Category")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                    .padding(.horizontal, AppTheme.space4)
                                
                                Menu {
                                    ForEach(TopicCategory.allCases) { category in
                                        Button {
                                            selectedCategory = category
                                        } label: {
                                            Label(category.rawValue, systemImage: category.iconName)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: selectedCategory.iconName)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.primaryBlue)
                                            .frame(width: 20)
                                        
                                        Text(selectedCategory.rawValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppTheme.primaryText)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    .padding(.horizontal, AppTheme.space16)
                                    .frame(height: 50)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                            .stroke(AppTheme.inputBorder, lineWidth: 1.2)
                                    )
                                }
                            }
                            
                            // 3. Debate Schedule & Time Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Schedule & Time")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                    .padding(.horizontal, AppTheme.space4)
                                
                                VStack(spacing: AppTheme.space12) {
                                    Toggle(isOn: $hasScheduledTime) {
                                        HStack(spacing: AppTheme.space12) {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.system(size: 16))
                                                .foregroundColor(AppTheme.primaryBlue)
                                                .frame(width: 22)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Set Start Date & Time")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(AppTheme.primaryText)
                                                Text(hasScheduledTime ? "Choose when debate starts" : "Start immediately or join FIFO queue")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppTheme.secondaryText)
                                            }
                                        }
                                    }
                                    .tint(AppTheme.primaryBlue)
                                    
                                    if hasScheduledTime {
                                        Rectangle()
                                            .fill(AppTheme.separator)
                                            .frame(height: 1)
                                            .padding(.leading, 34)
                                        
                                        DatePicker(
                                            "Debate Starts At",
                                            selection: $scheduledDate,
                                            in: Date()...,
                                            displayedComponents: [.date, .hourAndMinute]
                                        )
                                        .datePickerStyle(.compact)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(AppTheme.primaryText)
                                        .tint(AppTheme.primaryBlue)
                                    }
                                }
                                .padding(AppTheme.space16)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                        .stroke(AppTheme.inputBorder, lineWidth: 1.2)
                                )
                            }
                            
                            // 4. Moderator Footnote
                            HStack(spacing: AppTheme.space8) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.primaryBlue)
                                Text("You are the moderator. You manage speaking turns and enforce English.")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, AppTheme.space4)
                            
                            // 5. Submit CTA
                            Button(action: submitTopic) {
                                HStack {
                                    Spacer()
                                    if isSubmitting {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(isEditing ? "Save Changes" : "Submit Topic to Queue")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .frame(height: 52)
                                .background(isValid ? AppTheme.primaryBlue : AppTheme.primaryBlue.opacity(0.35))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
                            }
                            .disabled(!isValid || isSubmitting)
                            .padding(.top, AppTheme.space8)
                            .padding(.bottom, AppTheme.space24)
                        }
                        .padding(.horizontal, AppTheme.space20)
                        .padding(.top, AppTheme.space16)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Topic" : "New Debate Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
    }
    
    private var isValid: Bool {
        debateQuestion.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }
    
    // MARK: - Minimal Confirmation
    private func submissionSuccessView(position: Int) -> some View {
        VStack(spacing: AppTheme.space20) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundColor(AppTheme.successGreen)
            
            VStack(spacing: AppTheme.space8) {
                Text("Added to Queue")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                
                if hasScheduledTime {
                    Text("Scheduled for \(formattedSuccessScheduleDate) · Position #\(position)")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText)
                } else {
                    Text("Position #\(position) · Standing by in FIFO queue")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppTheme.primaryBlue)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
            }
            .padding(.horizontal, AppTheme.space20)
            .padding(.bottom, AppTheme.space24)
        }
    }
    
    private var formattedSuccessScheduleDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' HH:mm"
        return formatter.string(from: scheduledDate)
    }
    
    private func submitTopic() {
        let trimmedQ = debateQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = shortDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalScheduledTime = hasScheduledTime ? scheduledDate : nil
        
        if var updated = editingTopic {
            updated.title = trimmedQ
            updated.debateQuestion = trimmedQ
            updated.description = trimmedDesc.isEmpty ? nil : trimmedDesc
            updated.category = selectedCategory
            updated.scheduledStartTime = finalScheduledTime
            onTopicCreated?(updated)
            dismiss()
            return
        }
        
        isSubmitting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let newTopic = Topic(
                title: trimmedQ,
                debateQuestion: trimmedQ,
                description: trimmedDesc.isEmpty ? nil : trimmedDesc,
                category: selectedCategory,
                creator: AuthManager.shared.currentUser ?? User.sampleModerator,
                status: .inQueue,
                queuePosition: 4,
                scheduledStartTime: finalScheduledTime
            )
            onTopicCreated?(newTopic)
            isSubmitting = false
            submittedPosition = 4
        }
    }
}

#Preview {
    CreateTopicView()
}
