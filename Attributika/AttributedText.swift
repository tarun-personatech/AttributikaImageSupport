/**
 *  Atributika
 *
 *  Copyright (c) 2017 Pavel Sharanda. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation

public enum DetectionType {
 case tag(Tag)
 case hashtag(String)
 case mention(String)
 case regex(String)
 case phoneNumber(String)
 case link(URL)
 case textCheckingType(String, NSTextCheckingResult.CheckingType)
 case range
}

public struct Detection {
 public let type: DetectionType
 public let style: Style
 public let range: Range<String.Index>
 let level: Int
}

public protocol AttributedTextProtocol {
 var string: String { get }
 var detections: [Detection] { get }
 var baseStyle: Style { get }
}

extension AttributedTextProtocol {
 func makeAttributedString(getAttributes: (Style) -> [AttributedStringKey: Any]) -> NSAttributedString {
  let attributedString = NSMutableAttributedString(string: string, attributes: getAttributes(baseStyle))

  let sortedDetections = detections.sorted {
   $0.level < $1.level
  }

  var map: [NSAttributedString: NSRange] = [:]

  sortedDetections.forEach { d in
   let attrs = getAttributes(d.style)
   if !attrs.isEmpty {
    attributedString.addAttributes(attrs, range: NSRange(d.range, in: string))
   }

   switch d.type {
   case let .tag(tag) where tag.name == "img":

    let bounds = CGRect(string: tag.attributes["bound"])

    let attributes = AsynTextAttachmentAttributes(
     imageName: tag.attributes["id"],
     imageURL: URL(string: tag.attributes["scr"] ?? ""),
     origin: bounds?.origin,
     displaySize: bounds?.size,
     maximumDisplayWidth: CGFloat(string: tag.attributes["maxWidth"]),
     radius: CGFloat(string: tag.attributes["radius"])
    )

    let attachment = AsyncTextAttachment(attributes: attributes)
    let imageAttributedString = NSMutableAttributedString(attachment: attachment)
     
     // Don't change original attributedString string here as doing that will ruin the range of other tags/styles
     // the Just store the range and image attributed string
    map[imageAttributedString] = NSRange(d.range, in: attributedString.string)

   default:
    break
   }
  }

  // Replace all the ~ with actual image attributed string
  map.forEach { imageAttrString, range in
   attributedString.replaceCharacters(in: range, with: imageAttrString)
  }

  return attributedString
 }
}

public final class AttributedText: AttributedTextProtocol {
 public let string: String
 public let detections: [Detection]
 public let baseStyle: Style

 public init(string: String, detections: [Detection], baseStyle: Style) {
  self.string = string
  self.detections = detections
  self.baseStyle = baseStyle
 }

 public private(set) lazy var attributedString: NSAttributedString = makeAttributedString { $0.attributes }

 public private(set) lazy var disabledAttributedString: NSAttributedString = makeAttributedString { $0.disabledAttributes }
}

public extension AttributedTextProtocol {
 /// style the whole string
 func styleAll(_ style: Style) -> AttributedText {
  return AttributedText(string: string, detections: detections, baseStyle: baseStyle.merged(with: style))
 }

 /// style things like #xcode #mentions
 func styleHashtags(_ style: Style) -> AttributedText {
  let ranges = string.detectHashTags()
  let ds = ranges.map { Detection(type: .hashtag(String(string[(string.index($0.lowerBound, offsetBy: 1)) ..< $0.upperBound])), style: style, range: $0, level: Int.max) }
  return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
 }

 /// style things like @John @all
 func styleMentions(_ style: Style) -> AttributedText {
  let ranges = string.detectMentions()
  let ds = ranges.map { Detection(type: .mention(String(string[(string.index($0.lowerBound, offsetBy: 1)) ..< $0.upperBound])), style: style, range: $0, level: Int.max) }
  return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
 }

 func style(regex: String, options: NSRegularExpression.Options = [], style: Style) -> AttributedText {
  let ranges = string.detect(regex: regex, options: options)
  let ds = ranges.map { Detection(type: .regex(regex), style: style, range: $0, level: Int.max) }
  return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
 }

 func style(textCheckingTypes: NSTextCheckingResult.CheckingType, style: Style) -> AttributedText {
  let ranges = string.detect(textCheckingTypes: textCheckingTypes)
  let ds = ranges.map { Detection(type: .textCheckingType(String(string[$0]), textCheckingTypes), style: style, range: $0, level: Int.max) }
  return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
 }

 func stylePhoneNumbers(_ style: Style) -> AttributedText {
  let ranges = string.detect(textCheckingTypes: [.phoneNumber])
  let ds = ranges.map { Detection(type: .phoneNumber(String(string[$0])), style: style, range: $0, level: Int.max) }
  return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
 }

 func styleLinks(_ style: Style) -> AttributedText {
  let ranges = string.detect(textCheckingTypes: [.link])

  #if swift(>=4.1)
   let ds = ranges.compactMap { range in
    URL(string: String(string[range])).map { Detection(type: .link($0), style: style, range: range, level: Int.max) }
   }
  #else
   let ds = ranges.flatMap { range in
    URL(string: String(string[range])).map { Detection(type: .link($0), style: style, range: range) }
   }
  #endif

  return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
 }

 func style(range: Range<String.Index>, style: Style) -> AttributedText {
  let d = Detection(type: .range, style: style, range: range, level: Int.max)
  return AttributedText(string: string, detections: detections + [d], baseStyle: baseStyle)
 }
}

extension String: AttributedTextProtocol {
 public var string: String {
  return self
 }

 public var detections: [Detection] {
  return []
 }

 public var baseStyle: Style {
  return Style()
 }

 public func style(tags: [Style], transformers: [TagTransformer] = [TagTransformer.brTransformer], tuner: (Style, Tag) -> Style = { s, _ in s }) -> AttributedText {
  let (string, tagsInfo) = detectTags(transformers: transformers)

  var ds: [Detection] = []

  tagsInfo.forEach { t in

   if let style = (tags.first { style in style.name.lowercased() == t.tag.name.lowercased() }) {
    ds.append(Detection(type: .tag(t.tag), style: tuner(style, t.tag), range: t.range, level: t.level))
   } else {
    ds.append(Detection(type: .tag(t.tag), style: Style(), range: t.range, level: t.level))
   }
  }

  return AttributedText(string: string, detections: ds, baseStyle: baseStyle)
 }

 public func style(tags: Style..., transformers: [TagTransformer] = [TagTransformer.brTransformer], tuner: (Style, Tag) -> Style = { s, _ in s }) -> AttributedText {
  return style(tags: tags, transformers: transformers, tuner: tuner)
 }

 public var attributedString: NSAttributedString {
  return makeAttributedString { $0.attributes }
 }

 public var disabledAttributedString: NSAttributedString {
  return makeAttributedString { $0.disabledAttributes }
 }
}

extension NSAttributedString: AttributedTextProtocol {
 public var detections: [Detection] {
  var ds: [Detection] = []

  enumerateAttributes(in: NSMakeRange(0, length), options: []) { attributes, range, _ in
   if let range = Range(range, in: self.string) {
    ds.append(Detection(type: .range, style: Style("", attributes), range: range, level: Int.max))
   }
  }

  return ds
 }

 public var baseStyle: Style {
  return Style()
 }

 public var attributedString: NSAttributedString {
  return makeAttributedString { $0.attributes }
 }

 public var disabledAttributedString: NSAttributedString {
  return makeAttributedString { $0.disabledAttributes }
 }
}
