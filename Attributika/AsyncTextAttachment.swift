 //
 //  SwiftRichString
 //  Elegant Strings & Attributed Strings Toolkit for Swift
 //
 //  Created by Daniele Margutti.
 //  Copyright © 2018 Daniele Margutti. All rights reserved.
 //
 //    Web: http://www.danielemargutti.com
 //    Email: hello@danielemargutti.com
 //    Twitter: @danielemargutti
 //
 //
 //    Permission is hereby granted, free of charge, to any person obtaining a copy
 //    of this software and associated documentation files (the "Software"), to deal
 //    in the Software without restriction, including without limitation the rights
 //    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 //    copies of the Software, and to permit persons to whom the Software is
 //    furnished to do so, subject to the following conditions:
 //
 //    The above copyright notice and this permission notice shall be included in
 //    all copies or substantial portions of the Software.
 //
 //    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 //    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 //    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 //    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 //    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 //    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 //    THE SOFTWARE.

 #if os(OSX)
  import AppKit
 #else
  import Kingfisher
  import MobileCoreServices
  import UIKit
 #endif

 #if os(iOS)

  public struct AsynTextAttachmentAttributes {
   /// An image name that will be created from the main bundle.
   /// This image will be displayed if remote image url is not present or
   /// while the remote image is donloading
   public var imageName: String?

   /// Remote URL for the image
   public var imageURL: URL?

   /// To specify an absolute origin.
   public var origin: CGPoint? = .zero

   /// To specify an absolute display size.
   public var displaySize: CGSize?

   /// if determining the display size automatically this can be used to specify a maximum width. If it is not set then the text container's width will be used
   public var maximumDisplayWidth: CGFloat?
   
   public let radius: CGFloat?

   /// If both, imageName and imageURL are not present then an image will be created from this color and shown
   public var defaultImageColor: UIColor = .lightGray
  }

  @objc public protocol AsyncTextAttachmentDelegate {
   /// Called when the image has been loaded
   func textAttachmentDidLoadImage(textAttachment: AsyncTextAttachment, displaySizeChanged: Bool)
  }

  /// An image text attachment that gets loaded from a remote URL
  public class AsyncTextAttachment: NSTextAttachment {
   
   let attributes: AsynTextAttachmentAttributes
   
   /// A delegate to be informed of the finished download
   public weak var delegate: AsyncTextAttachmentDelegate?

   /// Remember the text container from delegate message, the current one gets updated after the download
   weak var textContainer: NSTextContainer?

   /// The download task to keep track of whether we are already downloading the image
   private var downloadTask: URLSessionDataTask!

   /// The size of the downloaded image. Used if we need to determine display size
   private var originalImageSize: CGSize?

   private var downloadedImage: UIImage?

   /// Designated initializer
   public init(attributes: AsynTextAttachmentAttributes, delegate: AsyncTextAttachmentDelegate? = nil) {
    self.attributes = attributes
    self.delegate = delegate
    super.init(data: nil, ofType: nil)
   }

   @available(*, unavailable)
   public required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
   }

   override public var image: UIImage? {
    didSet {
     originalImageSize = image?.size
    }
   }

   // MARK: - Helpers

   private func startDownloadingTheImage() {
    guard let imageURL = attributes.imageURL else {
     return
    }

    var kfOptions: KingfisherOptionsInfo = []
    if let radius = attributes.radius {
     let processor = RoundCornerImageProcessor(cornerRadius: radius, targetSize: attributes.displaySize)
     kfOptions.append(.processor(processor))
    }

    var displaySizeChanged = false

    KingfisherManager.shared.retrieveImage(
     with: imageURL,
     options: kfOptions
    ) { [weak self] result in
     guard let self = self else { return }
     
     switch result {
     case let .success(value):
      let image = value.image
      let imageSize = image.size

       if self.attributes.displaySize == nil {
       displaySizeChanged = true
      }

      self.originalImageSize = imageSize
      self.downloadedImage = image

      DispatchQueue.main.async {
       // tell layout manager so that it should refresh
       if displaySizeChanged {
        self.textContainer?.layoutManager?.setNeedsLayout(forAttachment: self)
       } else {
        self.textContainer?.layoutManager?.setNeedsDisplay(forAttachment: self)
       }

       // notify the optional delegate
       self.delegate?.textAttachmentDidLoadImage(textAttachment: self, displaySizeChanged: displaySizeChanged)
      }
     case let .failure(error):
      print("Job failed: \(error.localizedDescription)")
     }
    }
   }

   override public func image(forBounds _: CGRect, textContainer: NSTextContainer?, characterIndex _: Int) -> UIImage? {
    // if downloaded image is present return that
    // if no then start kf, and return placeholder image
    let returnImage = UIImage(named: attributes.imageName ?? "xyz") ??
    UIImage(color: attributes.defaultImageColor, size: attributes.displaySize ?? CGSize(width: 15, height: 15))?
     .kf.image(
     withRadius: .point(2.0),
     fit: attributes.displaySize ?? CGSize(width: 15, height: 15),
     roundingCorners: .all,
     backgroundColor: nil)
    
    
    if let downloadedImage {
     return downloadedImage
    } else {
     self.textContainer = textContainer
     startDownloadingTheImage()
    }

    return returnImage
   }

   override public func attachmentBounds(for _: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition _: CGPoint, characterIndex _: Int) -> CGRect {
    if let displaySize = attributes.displaySize {
     return CGRect(origin: attributes.origin ?? .zero, size: displaySize)
    }

    if let imageSize = originalImageSize {
     let maxWidth = attributes.maximumDisplayWidth ?? lineFrag.size.width
     let factor = maxWidth / imageSize.width

     return CGRect(origin: attributes.origin ?? .zero, size: CGSize(width: Int(imageSize.width * factor), height: Int(imageSize.height * factor)))
    }

    return CGRect.zero
   }
  }

  public extension NSLayoutManager {
   /// Determine the character ranges for an attachment
   private func rangesForAttachment(attachment: NSTextAttachment) -> [NSRange]? {
    guard let attributedString = self.textStorage else {
     return nil
    }

    // find character range for this attachment
    let range = NSRange(location: 0, length: attributedString.length)

    var refreshRanges = [NSRange]()

    attributedString.enumerateAttribute(NSAttributedString.Key.attachment, in: range, options: []) { value, effectiveRange, _ in

     guard let foundAttachment = value as? NSTextAttachment, foundAttachment == attachment
     else {
      return
     }

     // add this range to the refresh ranges
     refreshRanges.append(effectiveRange)
    }

    if refreshRanges.isEmpty {
     return nil
    }

    return refreshRanges
   }

   /// Trigger a relayout for an attachment
   func setNeedsLayout(forAttachment attachment: NSTextAttachment) {
    guard let ranges = rangesForAttachment(attachment: attachment) else {
     return
    }

    // invalidate the display for the corresponding ranges
    for range in ranges.reversed() {
     self.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)

     // also need to trigger re-display or already visible images might not get updated
     self.invalidateDisplay(forCharacterRange: range)
    }
   }

   /// Trigger a re-display for an attachment
   func setNeedsDisplay(forAttachment attachment: NSTextAttachment) {
    guard let ranges = rangesForAttachment(attachment: attachment) else {
     return
    }

    // invalidate the display for the corresponding ranges
    for range in ranges.reversed() {
     self.invalidateDisplay(forCharacterRange: range)
    }
   }
  }

 #endif


 public extension UIImage {
  convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
   let rect = CGRect(origin: .zero, size: size)
   UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
   color.setFill()
   UIRectFill(rect)
   let image = UIGraphicsGetImageFromCurrentImageContext()
   UIGraphicsEndImageContext()

   guard let cgImage = image!.cgImage else { return nil }
   self.init(cgImage: cgImage)
  }
 }
