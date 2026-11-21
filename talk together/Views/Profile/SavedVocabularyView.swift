import SwiftUI

public struct SavedVocabularyView: View {
    @Bindable public var debateManager: DebateManager
    @State private var newExpressionText: String = ""
    
    public init(debateManager: DebateManager) {
        self.debateManager = debateManager
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Quick Add Input Field
            HStack(spacing: AppTheme.space12) {
                Image(systemName: "character.book.closed")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.secondaryText)
                
                TextField("Add new idiom or expression...", text: $newExpressionText)
                    .font(.system(size: 14))
                    .onSubmit {
                        submitNewExpression()
                    }
                
                if !newExpressionText.isEmpty {
                    Button(action: submitNewExpression) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            }
            .padding(.horizontal, AppTheme.space16)
            .frame(height: 50)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
            .padding(.horizontal, AppTheme.space16)
            .padding(.top, AppTheme.space16)
            
            // List of saved vocabulary
            List {
                Section {
                    ForEach(debateManager.currentUser.savedVocabulary, id: \.self) { item in
                        HStack(spacing: AppTheme.space12) {
                            Circle()
                                .fill(AppTheme.primaryBlue.opacity(0.12))
                                .frame(width: 8, height: 8)
                            
                            Text(item)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.primaryText)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let item = debateManager.currentUser.savedVocabulary[index]
                            debateManager.removeVocabularyItem(item)
                        }
                    }
                } header: {
                    Text("Saved Idioms & Phrases (\(debateManager.currentUser.savedVocabulary.count))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                } footer: {
                    Text("Swipe left to remove any expression.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Vocabulary Notebook")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func submitNewExpression() {
        debateManager.addVocabularyItem(newExpressionText)
        newExpressionText = ""
    }
}
