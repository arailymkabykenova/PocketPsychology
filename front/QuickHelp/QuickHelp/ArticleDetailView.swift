import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(article.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack {
                            // Approach badge
                            Text(article.approachDisplayName)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(article.approachColor.opacity(0.1))
                                )
                                .foregroundColor(article.approachColor)
                            
                            // Topic badge
                            Text(article.category)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                )
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text(article.readTime)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Content
                    Text(article.content)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                    
                    // Footer
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.currentLanguage == .russian ? 
                            "Источники тем:" : "Source topics:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if let sourceTopics = article.sourceTopics {
                                ForEach(sourceTopics, id: \.self) { topic in
                                    Text(topic.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.green.opacity(0.1))
                                        )
                                        .foregroundColor(.green)
                                }
                            } else if let topic = article.topic {
                                Text(topic.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.1))
                                    )
                                    .foregroundColor(.green)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.currentLanguage == .russian ? "Закрыть" : "Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ArticleDetailView(article: Article(
        title: "Как справиться со стрессом",
        content: "Стресс - это естественная реакция организма на сложные ситуации...",
        sourceTopics: ["стресс", "психология"],
        createdAt: "2024-01-01",
        topic: "стресс",
        approach: "practical"
    ))
} 