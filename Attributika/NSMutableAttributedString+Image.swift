//
//  NSMutableAttributedString+Image.swift
//  AttributikaImageSupport
//
//  Created by Tarun Sharma on 25/05/23.
//

import Foundation
import UIKit

public extension NSMutableAttributedString {
 #if os(iOS)

  /// Initialize a new text attachment with a remote image resource.
  /// Image will be loaded asynchronously after the text appear inside the control.
  ///
  /// - Parameters:
  ///   - imageURL: url of the image. If url is not valid resource will be not downloaded.
  ///   - bounds: set a non `nil` value to express set the rect of attachment.
 convenience init?(imageAttributes: AsynTextAttachmentAttributes) {
   let attachment = AsyncTextAttachment(attributes: imageAttributes)
   self.init(attachment: attachment)
  }

 #endif

 #if os(iOS) || os(OSX)

  /// Initialize a new text attachment with local image contained into the assets.
  ///
  /// - Parameters:
  ///   - imageNamed: name of the image into the assets; if `nil` resource will be not loaded.
  ///   - bounds: set a non `nil` value to express set the rect of attachment.
  convenience init?(imageNamed: String?, bounds: String? = nil) {
   guard let imageNamed = imageNamed else {
    return nil
   }

   let image = UIImage(named: imageNamed)
   self.init(image: image, bounds: bounds)
  }

  /// Initialize a new attributed string from an image.
  ///
  /// - Parameters:
  ///   - image: image to use.
  ///   - bounds: location and size of the image, if `nil` the default bounds is applied.
  convenience init?(image: UIImage?, bounds: String? = nil) {
   guard let image = image else {
    return nil
   }

   #if os(OSX)
    let attachment = NSTextAttachment(data: image.pngData()!, ofType: "png")
   #else
    var attachment: NSTextAttachment!
    if #available(iOS 13.0, *) {
     // Due to a bug (?) in UIKit we should use two methods to allocate the text attachment
     // in order to render the image as template or original. If we use the
     // NSTextAttachment(image: image) with a .alwaysOriginal rendering mode it will be
     // ignored.
     if image.renderingMode == .alwaysTemplate {
      attachment = NSTextAttachment(image: image)
     } else {
      attachment = NSTextAttachment()
      attachment.image = image.withRenderingMode(.alwaysOriginal)
     }
    } else {
     // It does not work on iOS12, return empty set.s
     // attachment = NSTextAttachment(data: image.pngData()!, ofType: "png")
     attachment = NSTextAttachment()
     attachment.image = image.withRenderingMode(.alwaysOriginal)
    }
   #endif

   if let boundsRect = CGRect(string: bounds) {
    attachment.bounds = boundsRect
   }

   self.init(attachment: attachment)
  }

 #endif
}
