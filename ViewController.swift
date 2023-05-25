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
  
  let imageWithUrl40 = "<img scr=\"https://picsum.photos/40\" id=\"scissors\" bound=\"{0,0,25,25}\" radius=\"5\"\" ></img>"
  
  let imagewithUrl150WithoutRadius = "<img scr=\"https://picsum.photos/150\" id=\"scissors\" bound=\"{0,0,30,30}\"\" ></img>"
  
  let imagewithOnlyId = "<img id=\"scissors\" bound=\"{0,0,30,30}\" radius=\"20\"\" ></img>"
  
  let imageWithoutUrlWithoutId = "<img bound=\"{0,0,15,15}\" radius=\"2\"\" ></img>"
  
  let message = """
Lorem Ipsum is simply dummy text of the printing and typesetting industry.<br>\
\(imageWithUrl40) \
<button>Need to register?</button>Cras. Nunc.<br>\
\(imagewithUrl150WithoutRadius) \
@e2F If only Bradley's arm was longer. Best photo ever.\
\(imagewithOnlyId) \
😊 #oscars https://pic.twitter.com/C9U5NOtGap Check this <a href=\"https://github.com/psharanda/Atributika\">link</a> <br>\
\(imageWithoutUrlWithoutId) elit.<br>\
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
 public func toHTML() -> AttributedText {
  
  let all = Style.font(UIFont.preferredFont(forTextStyle: .body))
  let link = Style("a")
      .foregroundColor(.blue, .normal)
      .foregroundColor(.brown, .highlighted)
  
  let style = self
   .style(
    tags: [buttonStyle, link],
    transformers: [
     TagTransformer.brTransformer,
     TagTransformer(tagName: "img", tagType: .start, replaceValue: "~"),
    ]
   )
   .styleHashtags(link)
   .styleMentions(link)
   .styleLinks(link)
   .styleAll(all)
  
  return style
 }

 private func imageStyle() -> Style {
  return Style("img")
 }

 private var buttonStyle: Style {
  return Style("button")
   .underlineStyle(.single)
   .font(.systemFont(ofSize: 20))
   .foregroundColor(.black, .normal)
   .foregroundColor(.red, .highlighted)
 }
}

