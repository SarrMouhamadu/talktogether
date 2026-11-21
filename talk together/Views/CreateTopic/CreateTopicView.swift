import SwiftUI

public struct CreateTopicView: View {
    @Environment(\.dismiss) private var dismiss
    
    public let editingTopic: Topic?
    public var onTopicCreated: ((Topic) -> Void)?
    
    @State private var debateQuestion: String
    @State private var shortDescription: String
    @State private var selectedCategory: TopicCategory
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
                            // Unified Input Group (Apple Reminders Style)
                            VStack(spacing: 0) {
                                TextField("What should we debate?", text: $debateQuestion, axis: .vertical)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                    .lineLimit(2...5)
                                    .padding(AppTheme.space16)
                                
                                Rectangle()
                                    .fill(AppTheme.separator)
                                    .frame(height: 1)
                                    .padding(.leading, AppTheme.space16)
                                
                                TextField("Add context (optional)", text: $shortDescription, axis: .vertical)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                    .lineLimit(2...4)
                                    .padding(AppTheme.space16)
                            }
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                    .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                            )
                            
                            // Compact Native Category Row
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
                                    Text("Category")
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: AppTheme.space6) {
                                        Text(selectedCategory.rawValue)
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.secondaryText)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                }
                                .padding(.horizontal, AppTheme.space16)
                                .frame(height: 50)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                        .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                                )
                            }
                            
                            // Quiet Footnote
                            HStack(spacing: AppTheme.space8) {
                                Image(systemName: "checkmark.shield")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.secondaryText)
                                Text("You will moderate this session in English.")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, AppTheme.space4)
                            
                            // Submit Action
                            Button(action: submitTopic) {
                                HStack {
                                    Spacer()
                                    if isSubmitting {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(isEditing ? "Save Changes" : "Submit to Queue")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .frame(height: 50)
                                .background(isValid ? AppTheme.primaryBlue : AppTheme.primaryBlue.opacity(0.35))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
                            }
                            .disabled(!isValid || isSubmitting)
                            .padding(.top, AppTheme.space8)
                        }
                        .padding(.horizontal, AppTheme.space20)
                        .padding(.top, AppTheme.space20)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Topic" : "New Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 15))
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
                .font(.system(size: 48))
                .foregroundColor(AppTheme.successGreen)
            
            VStack(spacing: AppTheme.space8) {
                Text("Added to Queue")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text("Position #\(position) · You'll be notified when live.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppTheme.primaryBlue)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
            }
            .padding(.horizontal, AppTheme.space20)
            .padding(.bottom, AppTheme.space24)
        }
    }
    
    private func submitTopic() {
        let trimmedQ = debateQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = shortDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if var updated = editingTopic {
            updated.title = trimmedQ
            updated.debateQuestion = trimmedQ
            updated.description = trimmedDesc.isEmpty ? nil : trimmedDesc
            updated.category = selectedCategory
            onTopicCreated?(updated)
            dismiss()
            return
        }
        
        isSubmitting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let newTopic = Topic(
                title: trimmedQ,
                debateQuestion: trimmedQ,
                description: trimmedDesc.isEmpty ? nil : trimmedDesc,
                category: selectedCategory,
                creator: AuthManager.shared.currentUser ?? User.sampleModerator,
                status: .inQueue,
                queuePosition: 4
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
