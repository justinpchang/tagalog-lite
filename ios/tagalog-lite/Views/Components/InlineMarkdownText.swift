import SwiftUI

struct InlineMarkdownText: View {
    enum Style {
        case title1
        case title2
        case title3
        case body
    }

    let markdown: String
    let style: Style

    var body: some View {
        Text(Self.attributed(from: markdown))
            .font(font)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var font: Font {
        switch style {
        case .title1: return .system(size: 30, weight: .heavy, design: .rounded)
        case .title2: return .system(size: 22, weight: .bold, design: .rounded)
        case .title3: return .system(size: 18, weight: .semibold, design: .rounded)
        case .body: return .system(size: 17, weight: .regular, design: .rounded)
        }
    }

    static func attributed(from markdown: String) -> AttributedString {
        // Minimal renderer:
        // - Use Apple's markdown parser for **bold** and _italic_
        // - Special-case <u>...</u> and apply underline to the inner segment
        // (matches `web/viewer.js` behavior)
        let s = markdown
        let pattern = #"<u>(.*?)</u>"#

        guard let re = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (try? AttributedString(markdown: s)) ?? AttributedString(s)
        }

        let ns = s as NSString
        let matches = re.matches(in: s, range: NSRange(location: 0, length: ns.length))
        if matches.isEmpty {
            return (try? AttributedString(markdown: s)) ?? AttributedString(s)
        }

        var out = AttributedString()
        var cursor = 0

        func appendMarkdown(_ piece: String, underline: Bool) {
            var seg = (try? AttributedString(markdown: piece)) ?? AttributedString(piece)
            if underline {
                seg.underlineStyle = .single
            }
            out.append(seg)
        }

        for m in matches {
            let whole = m.range(at: 0)
            let inner = m.range(at: 1)

            if cursor < whole.location {
                let before = ns.substring(with: NSRange(location: cursor, length: whole.location - cursor))
                appendMarkdown(before, underline: false)
            }

            let innerText = ns.substring(with: inner)
            appendMarkdown(innerText, underline: true)

            cursor = whole.location + whole.length
        }

        if cursor < ns.length {
            let tail = ns.substring(with: NSRange(location: cursor, length: ns.length - cursor))
            appendMarkdown(tail, underline: false)
        }

        return out
    }
}


