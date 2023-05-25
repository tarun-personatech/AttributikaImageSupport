//
//  ViewController.swift
//  AttributikaImageSupport
//
//  Created by Tarun Sharma on 25/05/23.
//

import Kingfisher
import UIKit

class ViewController: UIViewController {
 @IBOutlet private var issue103Label: AttributedLabel!

 override func viewDidLoad() {
  super.viewDidLoad()
  setupTopLabels()
 }

 private func setupTopLabels() {
  let imageWithUrl40 = "<img scr=\"https://picsum.photos/40\" id=\"scissors\" bound=\"{0,-6,25,25}\" radius=\"5\"\" ></img>"
  let imagewithUrl150WithoutRadius = "<img scr=\"https://picsum.photos/150\" id=\"scissors\" bound=\"{0,-10,30,30}\"\" ></img>"
  let imagewithOnlyId = "<img id=\"scissors\" bound=\"{0,-10,30,30}\" radius=\"20\"\" ></img>"
  let imageWithoutUrlWithoutId = "<img bound=\"{0,-3,15,15}\" radius=\"2\"\" ></img>"

  let message = """
  <br>Lorem Ipsum is simply dummy text of the printing and typesetting industry.<br><br>\
  \(imageWithUrl40) - <im>imageWithUrl40</im> <br>\
  \(imagewithUrl150WithoutRadius) - <im>imagewithUrl150WithoutRadius</im> <br>\
  \(imagewithOnlyId) - <im>imagewithOnlyId</im> <br>\
  \(imageWithoutUrlWithoutId) - <im>imageWithoutUrlWithoutId</im><br><br>\
  <button>Need to register?</button> Cras. Nunc.<br>\
  @e2F If only Bradley's arm was longer. Best photo ever.<br>\
  😊 #oscars https://pic.twitter.com/C9U5NOtGap Check this <a href=\"https://github.com/psharanda/Atributika\">link</a> <br>\
  @e2F If only Bradley's arm was longer. Best photo ever. 😊 #oscars😊 https://pic.twitter.com/C9U5NOtGap<br>Check this <a href=\"https://github.com/psharanda/Atributika\">link that won't detect click here</a><br>For every retweet this gets, Pedigree will donate one bowl of dog food to dogs in need! 😊 #tweetforbowls
  """

  issue103Label.numberOfLines = 0
  issue103Label.attributedText = message.toHTML()

  issue103Label.onClick = { _, detection in
   print(detection)
  }
 }
}

extension String {
 private var buttonStyle: Style {
  return Style("button")
   .underlineStyle(.single)
   .font(.systemFont(ofSize: 20))
   .foregroundColor(.black, .normal)
   .foregroundColor(.red, .highlighted)
 }

 private var imStyle: Style {
  return Style("im")
   .foregroundColor(.systemPink, .normal)
 }

 private var link: Style {
  Style("a")
   .foregroundColor(.blue, .normal)
   .foregroundColor(.brown, .highlighted)
 }

 private var all: Style {
  Style.font(UIFont.preferredFont(forTextStyle: .body))
 }

 fileprivate func toHTML() -> AttributedText {
  return self
   .style(
    tags: [buttonStyle, imStyle, link],
    transformers: [
     TagTransformer.brTransformer,

     // Replace all the img tag with a ~ so that later when img tag is replaced with an image attachment, other
     // Style ranges are not shifted
     TagTransformer(tagName: "img", tagType: .start, replaceValue: "~"),
    ]
   )
   .styleHashtags(link)
   .styleMentions(link)
   .styleLinks(link)
   .styleAll(all)
 }
}
