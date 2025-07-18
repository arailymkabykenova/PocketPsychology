import SwiftUI
import Foundation

// MARK: - Simple Markdown Renderer
struct SimpleMarkdownRenderer: View {
    let markdownText: String
    let textColor: Color
    
    init(_ markdownText: String, textColor: Color = .primary) {
        self.markdownText = markdownText
        self.textColor = textColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseSimpleMarkdown(markdownText), id: \.id) { element in
                renderElement(element)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Use full available width
    }
    
    @ViewBuilder
    private func renderElement(_ element: SimpleMarkdownElement) -> some View {
        switch element.type {
        case .text:
            parseInlineContent(element.content)
                .font(.sfProRoundedSemibold(size: 17))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil) // Allow unlimited lines
                .lineSpacing(2) // Add some line spacing for better readability
            
        case .bold:
            Text(element.content)
                .font(.sfProRoundedSemibold(size: 17))
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil) // Allow unlimited lines
            
        case .italic:
            Text(element.content)
                .font(.sfProRoundedSemibold(size: 17))
                .italic()
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil) // Allow unlimited lines
            
        case .code:
            Text(element.content)
                .font(.sfProRoundedSemibold(size: 17))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                )
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil) // Allow unlimited lines
            
        case .listItem:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.sfProRoundedSemibold(size: 17))
                    .foregroundColor(textColor)
                    .padding(.top, 2)
                
                // Parse the list item content to handle bold text inline
                parseInlineContent(element.content)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil) // Allow unlimited lines
            }
            
        case .header:
            Text(element.content)
                .font(.sfProRoundedHeavy(size: 20))
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil) // Allow unlimited lines
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
    }
    
    @ViewBuilder
    private func parseInlineContent(_ text: String) -> some View {
        let elements = parseInlineElements(text)
        HStack(alignment: .top, spacing: 0) {
            ForEach(elements, id: \.id) { element in
                switch element.type {
                case .text:
                    Text(element.content)
                        .font(.sfProRoundedSemibold(size: 17))
                        .lineLimit(nil) // Allow unlimited lines
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2) // Add line spacing
                case .bold:
                    Text(element.content)
                        .font(.sfProRoundedSemibold(size: 17))
                        .fontWeight(.bold)
                        .lineLimit(nil) // Allow unlimited lines
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2) // Add line spacing
                case .italic:
                    Text(element.content)
                        .font(.sfProRoundedSemibold(size: 17))
                        .italic()
                        .lineLimit(nil) // Allow unlimited lines
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2) // Add line spacing
                case .code:
                    Text(element.content)
                        .font(.sfProRoundedSemibold(size: 17))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray5))
                        )
                        .lineLimit(nil) // Allow unlimited lines
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2) // Add line spacing
                case .listItem:
                    Text(element.content)
                        .font(.sfProRoundedSemibold(size: 17))
                        .lineLimit(nil) // Allow unlimited lines
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2) // Add line spacing
                case .header:
                    Text(element.content)
                        .font(.sfProRoundedHeavy(size: 20))
                        .fontWeight(.bold)
                        .lineLimit(nil) // Allow unlimited lines
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2) // Add line spacing
                }
            }
        }
    }
    
    private func parseInlineElements(_ text: String) -> [SimpleMarkdownElement] {
        var elements: [SimpleMarkdownElement] = []
        var currentText = ""
        var i = 0
        
        while i < text.count {
            let char = text[text.index(text.startIndex, offsetBy: i)]
            
            // Check for bold (**text**)
            if char == "*" && i + 1 < text.count && text[text.index(text.startIndex, offsetBy: i + 1)] == "*" {
                if !currentText.isEmpty {
                    elements.append(SimpleMarkdownElement(type: .text, content: currentText))
                    currentText = ""
                }
                
                // Find closing **
                var j = i + 2
                var boldContent = ""
                while j < text.count - 1 {
                    if text[text.index(text.startIndex, offsetBy: j)] == "*" && 
                       text[text.index(text.startIndex, offsetBy: j + 1)] == "*" {
                        elements.append(SimpleMarkdownElement(type: .bold, content: boldContent))
                        i = j + 2
                        break
                    }
                    boldContent += String(text[text.index(text.startIndex, offsetBy: j)])
                    j += 1
                }
                if j >= text.count - 1 {
                    // No closing ** found, treat as regular text
                    currentText += "**"
                    i += 2
                }
                continue
            }
            
            // Check for italic (*text*)
            if char == "*" {
                if !currentText.isEmpty {
                    elements.append(SimpleMarkdownElement(type: .text, content: currentText))
                    currentText = ""
                }
                
                // Find closing *
                var j = i + 1
                var italicContent = ""
                while j < text.count {
                    if text[text.index(text.startIndex, offsetBy: j)] == "*" {
                        elements.append(SimpleMarkdownElement(type: .italic, content: italicContent))
                        i = j + 1
                        break
                    }
                    italicContent += String(text[text.index(text.startIndex, offsetBy: j)])
                    j += 1
                }
                if j >= text.count {
                    // No closing * found, treat as regular text
                    currentText += "*"
                    i += 1
                }
                continue
            }
            
            // Check for inline code (`code`)
            if char == "`" {
                if !currentText.isEmpty {
                    elements.append(SimpleMarkdownElement(type: .text, content: currentText))
                    currentText = ""
                }
                
                // Find closing `
                var j = i + 1
                var codeContent = ""
                while j < text.count {
                    if text[text.index(text.startIndex, offsetBy: j)] == "`" {
                        elements.append(SimpleMarkdownElement(type: .code, content: codeContent))
                        i = j + 1
                        break
                    }
                    codeContent += String(text[text.index(text.startIndex, offsetBy: j)])
                    j += 1
                }
                if j >= text.count {
                    // No closing ` found, treat as regular text
                    currentText += "`"
                    i += 1
                }
                continue
            }
            
            currentText += String(char)
            i += 1
        }
        
        if !currentText.isEmpty {
            elements.append(SimpleMarkdownElement(type: .text, content: currentText))
        }
        
        return elements
    }
}

// MARK: - Simple Markdown Element
struct SimpleMarkdownElement: Identifiable {
    let id = UUID()
    let type: SimpleMarkdownElementType
    let content: String
    
    init(type: SimpleMarkdownElementType, content: String) {
        self.type = type
        self.content = content
    }
}

// MARK: - Simple Markdown Element Types
enum SimpleMarkdownElementType {
    case text
    case bold
    case italic
    case code
    case listItem
    case header
}

// MARK: - Simple Markdown Parser
func parseSimpleMarkdown(_ text: String) -> [SimpleMarkdownElement] {
    var elements: [SimpleMarkdownElement] = []
    var currentText = ""
    var i = 0
    
    while i < text.count {
        let char = text[text.index(text.startIndex, offsetBy: i)]
        
        // Check for headers (### text)
        if char == "#" && i + 2 < text.count {
            let nextChar = text[text.index(text.startIndex, offsetBy: i + 1)]
            let nextNextChar = text[text.index(text.startIndex, offsetBy: i + 2)]
            
            if nextChar == "#" && nextNextChar == "#" {
                if !currentText.isEmpty {
                    elements.append(SimpleMarkdownElement(type: .text, content: currentText))
                    currentText = ""
                }
                
                // Find end of line for header
                var j = i + 3
                var headerContent = ""
                while j < text.count && text[text.index(text.startIndex, offsetBy: j)] != "\n" {
                    headerContent += String(text[text.index(text.startIndex, offsetBy: j)])
                    j += 1
                }
                // Trim leading spaces
                headerContent = headerContent.trimmingCharacters(in: .whitespaces)
                elements.append(SimpleMarkdownElement(type: .header, content: headerContent))
                i = j
                continue
            }
        }
        
        // Check for bold (**text**)
        if char == "*" && i + 1 < text.count && text[text.index(text.startIndex, offsetBy: i + 1)] == "*" {
            if !currentText.isEmpty {
                elements.append(SimpleMarkdownElement(type: .text, content: currentText))
                currentText = ""
            }
            
            // Find closing **
            var j = i + 2
            var boldContent = ""
            while j < text.count - 1 {
                if text[text.index(text.startIndex, offsetBy: j)] == "*" && 
                   text[text.index(text.startIndex, offsetBy: j + 1)] == "*" {
                    elements.append(SimpleMarkdownElement(type: .bold, content: boldContent))
                    i = j + 2
                    break
                }
                boldContent += String(text[text.index(text.startIndex, offsetBy: j)])
                j += 1
            }
            if j >= text.count - 1 {
                // No closing ** found, treat as regular text
                currentText += "**"
                i += 2
            }
            continue
        }
        
        // Check for italic (*text*)
        if char == "*" {
            if !currentText.isEmpty {
                elements.append(SimpleMarkdownElement(type: .text, content: currentText))
                currentText = ""
            }
            
            // Find closing *
            var j = i + 1
            var italicContent = ""
            while j < text.count {
                if text[text.index(text.startIndex, offsetBy: j)] == "*" {
                    elements.append(SimpleMarkdownElement(type: .italic, content: italicContent))
                    i = j + 1
                    break
                }
                italicContent += String(text[text.index(text.startIndex, offsetBy: j)])
                j += 1
            }
            if j >= text.count {
                // No closing * found, treat as regular text
                currentText += "*"
                i += 1
            }
            continue
        }
        
        // Check for inline code (`code`)
        if char == "`" {
            if !currentText.isEmpty {
                elements.append(SimpleMarkdownElement(type: .text, content: currentText))
                currentText = ""
            }
            
            // Find closing `
            var j = i + 1
            var codeContent = ""
            while j < text.count {
                if text[text.index(text.startIndex, offsetBy: j)] == "`" {
                    elements.append(SimpleMarkdownElement(type: .code, content: codeContent))
                    i = j + 1
                    break
                }
                codeContent += String(text[text.index(text.startIndex, offsetBy: j)])
                j += 1
            }
            if j >= text.count {
                // No closing ` found, treat as regular text
                currentText += "`"
                i += 1
            }
            continue
        }
        
        // Check for list items
        if char == "-" || char == "*" {
            if i == 0 || text[text.index(text.startIndex, offsetBy: i - 1)] == "\n" {
                if i + 1 < text.count && text[text.index(text.startIndex, offsetBy: i + 1)] == " " {
                    if !currentText.isEmpty {
                        elements.append(SimpleMarkdownElement(type: .text, content: currentText))
                        currentText = ""
                    }
                    
                    // Find end of line
                    var j = i + 2
                    var listContent = ""
                    while j < text.count && text[text.index(text.startIndex, offsetBy: j)] != "\n" {
                        listContent += String(text[text.index(text.startIndex, offsetBy: j)])
                        j += 1
                    }
                    elements.append(SimpleMarkdownElement(type: .listItem, content: listContent))
                    i = j
                    continue
                }
            }
        }
        
        currentText += String(char)
        i += 1
    }
    
    if !currentText.isEmpty {
        elements.append(SimpleMarkdownElement(type: .text, content: currentText))
    }
    
    return elements
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SimpleMarkdownRenderer("""
        Обычный текст с **жирным** и *курсивным* форматированием.
        
        `inline code` в тексте.
        
        - **Недостаток сна**: Недостаточное количество качественного сна может привести к физической и эмоциональной усталости.
        - **Недостаток физической активности**: Парадоксально, недостаточная физическая активность также может приводить к усталости.
        - **Стресс**: Постоянный стресс истощает энергетические ресурсы организма.
        
        Еще обычный текст.
        """)
    }
    .padding()
} 