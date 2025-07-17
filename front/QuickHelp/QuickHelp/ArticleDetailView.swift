import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    // Function to split content into logical paragraphs
    private func splitContentIntoParagraphs(_ content: String) -> [String] {
        // First, try to split by double newlines (existing paragraphs)
        var paragraphs = content.components(separatedBy: "\n\n")
        
        // If we only have one paragraph, try to split by single newlines
        if paragraphs.count <= 1 {
            paragraphs = content.components(separatedBy: "\n")
        }
        
        // If still only one paragraph, try to split by sentences
        if paragraphs.count <= 1 {
            // Split by common sentence endings and clean up
            let sentences = content.components(separatedBy: ". ")
                .flatMap { $0.components(separatedBy: "! ") }
                .flatMap { $0.components(separatedBy: "? ") }
                .flatMap { $0.components(separatedBy: ".\n") }
                .flatMap { $0.components(separatedBy: "!\n") }
                .flatMap { $0.components(separatedBy: "?\n") }
            paragraphs = sentences.compactMap { sentence in
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
        }
        
        // If we have too many small paragraphs, try to group them
        if paragraphs.count > 8 {
            var groupedParagraphs: [String] = []
            var currentGroup = ""
            
            for paragraph in paragraphs {
                let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // If this is a bullet point, add it to current group
                if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                    if currentGroup.isEmpty {
                        currentGroup = trimmed
                    } else {
                        currentGroup += "\n" + trimmed
                    }
                } else {
                    // If we have a current group, save it
                    if !currentGroup.isEmpty {
                        groupedParagraphs.append(currentGroup)
                        currentGroup = ""
                    }
                    
                    // Start new group with current paragraph
                    if currentGroup.isEmpty {
                        currentGroup = trimmed
                    } else if currentGroup.count + trimmed.count < 200 { // Group if total length is reasonable
                        currentGroup += "\n\n" + trimmed
                    } else {
                        groupedParagraphs.append(currentGroup)
                        currentGroup = trimmed
                    }
                }
            }
            
            if !currentGroup.isEmpty {
                groupedParagraphs.append(currentGroup)
            }
            
            paragraphs = groupedParagraphs
        }
        
        // Clean up paragraphs and remove empty ones
        return paragraphs.compactMap { paragraph in
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header with gradient background
                    VStack(alignment: .leading, spacing: 16) {
                        // Approach and topic badges
                        HStack(spacing: 8) {
                            Text(article.approachDisplayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(article.approachColor.opacity(0.15))
                                )
                                .foregroundColor(article.approachColor)
                            
                            Text(article.category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.15))
                                )
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(article.readTime)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        // Title
                        Text(article.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                        
                        // Reading time and approach info
                        HStack {
                            Image(systemName: article.approachIcon)
                                .font(.title3)
                                .foregroundColor(article.approachColor)
                            
                            Text("\(article.approachDisplayName) \(localizationManager.currentLanguage == .russian ? "подход" : "approach")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                article.approachColor.opacity(0.05),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: 24) {
                        // Main content with better formatting
                        VStack(alignment: .leading, spacing: 20) {
                            // Split content into logical paragraphs
                            let paragraphs = splitContentIntoParagraphs(article.content)
                            ForEach(paragraphs, id: \.self) { paragraph in
                                if !paragraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    let cleanParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                                        .replacingOccurrences(of: "**", with: "") // Remove markdown bold
                                        .replacingOccurrences(of: "*", with: "") // Remove markdown italic
                                    
                                    Text(cleanParagraph)
                                        .font(.sfProRoundedSemibold(size: 17))
                                        .lineSpacing(10)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .padding(.bottom, 16)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        
                        // Key points section (if content has bullet points)
                        if article.content.contains("•") || article.content.contains("-") {
                            KeyPointsSection(content: article.content)
                                .padding(.horizontal, 24)
                        }
                        
                        // Action steps section
                        ActionStepsSection(content: article.content)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                    }
                }
            }
            .background(Color.themeBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(.close)) {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Key Points Section
struct KeyPointsSection: View {
    let content: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var keyPoints: [String] {
        let lines = content.components(separatedBy: .newlines)
        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                let cleanPoint = trimmed.replacingOccurrences(of: "^[•\\-*]\\s*", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "**", with: "") // Remove markdown bold
                    .replacingOccurrences(of: "*", with: "") // Remove markdown italic
                return cleanPoint
            }
            return nil
        }
    }
    
    var body: some View {
        if !keyPoints.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(localizationManager.localizedString(.keyPoints))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(keyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .padding(.top, 2)
                            
                            Text(point)
                                .font(.body)
                                .lineSpacing(6)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Action Steps Section
struct ActionStepsSection: View {
    let content: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var actionSteps: [String] {
        let lines = content.components(separatedBy: .newlines)
        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().contains("шаг") || 
               trimmed.lowercased().contains("действие") ||
               trimmed.lowercased().contains("упражнение") {
                let cleanStep = trimmed
                    .replacingOccurrences(of: "**", with: "") // Remove markdown bold
                    .replacingOccurrences(of: "*", with: "") // Remove markdown italic
                return cleanStep
            }
            return nil
        }
    }
    
    var body: some View {
        if !actionSteps.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(localizationManager.localizedString(.practicalSteps))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(actionSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 16) {
                            Text("\(index + 1)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(Color.blue)
                                )
                            
                            Text(step)
                                .font(.body)
                                .lineSpacing(6)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}



#Preview {
    ArticleDetailView(article: Article(
        title: "Как справиться со стрессом",
        content: "Стресс - это естественная реакция организма на сложные ситуации. В этой статье мы рассмотрим эффективные методы борьбы со стрессом.\n\n• Глубокое дыхание помогает успокоиться\n• Регулярные физические упражнения снижают уровень стресса\n• Медитация улучшает эмоциональное состояние\n\nШаг 1: Найдите тихое место для практики\nШаг 2: Сядьте удобно и закройте глаза\nШаг 3: Сделайте глубокий вдох и медленный выдох",
        sourceTopics: ["стресс", "психология"],
        createdAt: "2024-01-01",
        topic: "стресс",
        approach: "practical"
    ))
} 