import Foundation

struct MarkdownDetector {

    private struct Pattern {
        let regex: NSRegularExpression
        let weight: Int
    }

    private let patterns: [Pattern]

    init() {
        let patternDefs: [(String, Int, NSRegularExpression.Options)] = [
            // Headings: ^#{1,6}\s+.+
            ("^#{1,6}\\s+.+", 3, [.anchorsMatchLines]),
            // Bold: **text**
            ("\\*\\*[^*]+\\*\\*", 2, []),
            // Italic: *text* (not preceded/followed by *)
            ("(?<!\\*)\\*[^*]+\\*(?!\\*)", 1, []),
            // Links: [text](url)
            ("\\[([^\\]]+)\\]\\(([^)]+)\\)", 3, []),
            // Images: ![alt](url)
            ("!\\[([^\\]]*?)\\]\\(([^)]+)\\)", 3, []),
            // Unordered lists: - item, * item, + item
            ("^\\s*[-*+]\\s+.+", 2, [.anchorsMatchLines]),
            // Ordered lists: 1. item
            ("^\\s*\\d+\\.\\s+.+", 2, [.anchorsMatchLines]),
            // Code blocks: ```
            ("^```", 4, [.anchorsMatchLines]),
            // Inline code: `code`
            ("`[^`]+`", 2, []),
            // Blockquotes: > text
            ("^>\\s+.+", 2, [.anchorsMatchLines]),
            // Tables: |---|
            ("\\|[-:]+\\|", 4, []),
            // Task lists: - [ ] or - [x]
            ("^\\s*-\\s+\\[[ xX]\\]\\s+", 4, [.anchorsMatchLines]),
            // Strikethrough: ~~text~~
            ("~~[^~]+~~", 3, []),
            // Horizontal rules: --- or *** or ___
            ("^-{3,}$|^\\*{3,}$|^_{3,}$", 2, [.anchorsMatchLines]),
            // Footnotes: [^1]
            ("\\[\\^\\d+\\]", 3, [])
        ]

        self.patterns = patternDefs.compactMap { def in
            guard let regex = try? NSRegularExpression(pattern: def.0, options: def.2) else {
                return nil
            }
            return Pattern(regex: regex, weight: def.1)
        }
    }

    func detect(text: String, threshold: Int) -> Bool {
        return score(text: text) >= threshold
    }

    func score(text: String) -> Int {
        guard !text.isEmpty else { return 0 }

        let range = NSRange(text.startIndex..., in: text)
        var totalScore = 0

        for pattern in patterns {
            let matchCount = pattern.regex.numberOfMatches(in: text, options: [], range: range)
            // Cap each pattern's contribution at weight * 3 matches
            let cappedMatches = min(matchCount, 3)
            totalScore += cappedMatches * pattern.weight
        }

        return totalScore
    }
}
