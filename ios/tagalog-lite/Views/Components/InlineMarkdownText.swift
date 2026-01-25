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
  let appendixKeys: Set<String>
  let baseColor: Color

  init(
    markdown: String,
    style: Style,
    appendixKeys: Set<String> = [],
    baseColor: Color = .primary
  ) {
    self.markdown = markdown
    self.style = style
    self.appendixKeys = appendixKeys
    self.baseColor = baseColor
  }

  var body: some View {
    Text(Self.attributed(from: markdown, appendixKeys: appendixKeys, baseColor: baseColor))
      .font(font)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var font: Font {
    switch style {
    case .title1: return .system(size: 24, weight: .heavy, design: .rounded)
    case .title2: return .system(size: 18, weight: .bold, design: .rounded)
    case .title3: return .system(size: 16, weight: .semibold, design: .rounded)
    case .body: return .system(size: 14, weight: .regular, design: .rounded)
    }
  }

  static func attributed(
    from markdown: String,
    appendixKeys: Set<String> = [],
    baseColor: Color = .primary
  ) -> AttributedString {
    // Minimal renderer:
    // - Use Apple's markdown parser for **bold** and _italic_
    // - Special-case <u>...</u> and apply underline to the inner segment
    // (matches `web/viewer.js` behavior)
    // Fix common spacing issues produced by the exporter, e.g. "**word **next"
    // which Apple's markdown parser won't treat as bold.
    var s = markdown
    s = s.replacingOccurrences(
      of: #"\*\*\s*([^*]+?)\s*\*\*"#,
      with: "**$1**",
      options: .regularExpression
    )
    s = s.replacingOccurrences(
      of: #"_\s*([^_]+?)\s*_"#,
      with: "_$1_",
      options: .regularExpression
    )
    let pattern = #"<u>(.*?)</u>"#

    guard let re = try? NSRegularExpression(pattern: pattern, options: []) else {
      var base = (try? AttributedString(markdown: s)) ?? AttributedString(s)
      base.foregroundColor = baseColor
      return applyAppendixStyling(to: base, appendixKeys: appendixKeys)
    }

    let ns = s as NSString
    let matches = re.matches(in: s, range: NSRange(location: 0, length: ns.length))
    if matches.isEmpty {
      var base = (try? AttributedString(markdown: s)) ?? AttributedString(s)
      base.foregroundColor = baseColor
      return applyAppendixStyling(to: base, appendixKeys: appendixKeys)
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

    var styled = out
    styled.foregroundColor = baseColor
    return applyAppendixStyling(to: styled, appendixKeys: appendixKeys)
  }

  private static func applyAppendixStyling(
    to base: AttributedString,
    appendixKeys: Set<String>
  ) -> AttributedString {
    var out = base
    let baseString = String(out.characters)
    let pattern = #"\bAppendix\s+([A-Za-z0-9]+)\b"#
    guard let re = try? NSRegularExpression(pattern: pattern, options: []) else {
      return base
    }

    let fullRange = NSRange(location: 0, length: (baseString as NSString).length)
    re.enumerateMatches(in: baseString, range: fullRange) { match, _, _ in
      guard
        let match,
        match.numberOfRanges >= 2,
        let matchRange = Range(match.range(at: 0), in: baseString),
        let keyRange = Range(match.range(at: 1), in: baseString)
      else { return }
      let key = String(baseString[keyRange]).lowercased()
      let start = baseString.distance(from: baseString.startIndex, to: matchRange.lowerBound)
      let end = baseString.distance(from: baseString.startIndex, to: matchRange.upperBound)
      let aStart = out.index(out.startIndex, offsetByCharacters: start)
      let aEnd = out.index(out.startIndex, offsetByCharacters: end)
      let aRange = aStart..<aEnd

      if appendixKeys.contains(key), let url = URL(string: "appendix://\(key)") {
        out[aRange].link = url
        out[aRange].foregroundColor = .blue
      } else {
        out[aRange].foregroundColor = .red
      }
    }

    return out
  }
}
