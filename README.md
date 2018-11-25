# RealRichText

A Tricky Solution for Implementing **Inline-Image-In-Text** Feature in Flutter.

<img src="https://github.com/limengyun2008/RealRichText/blob/master/doc/example.png" width="320">

## Getting Started

According to the related Flutter Issues([#2022](https://github.com/flutter/flutter/issues/2022)) , Inline-Image-In-Text is a long-time(2 years) missing feature since RichText(or the underlying Paragraph) does only support pure text. But we can solve this problem in a simple/tricky way:

1. Regarde the images as a particular blank TextSpan, convert image's width and height to textspan's letterSpacing and fontSize. the origin paragraph will do the layout operation and leave the desired image space for us.
2. Override the paint function，calculate the right offset via the getOffsetForCaret() api to draw the image over the space.

## Usage

The only thing you have to do is converting your origin text to a TextSpan/ImageSpan List first.

```Dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:real_rich_text/real_rich_text.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: RealRichText([
            TextSpan(
              text: "A Text Link",
              style: TextStyle(color: Colors.red, fontSize: 14),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  debugPrint("Link Clicked.");
                },
            ),
            ImageSpan(
              AssetImage("packages/real_rich_text/images/emoji_9.png"),
              width: 24,
              height: 24,
            ),
            ImageSpan(
              AssetImage("packages/real_rich_text/images/emoji_10.png"),
              width: 24,
              height: 24,
            ),
            TextSpan(
              text: "哈哈哈",
              style: TextStyle(color: Colors.yellow, fontSize: 14),
            ),
            TextSpan(
              text: "@Somebody",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  debugPrint("Link Clicked");
                },
            ),
            TextSpan(
              text: " #RealRichText# ",
              style: TextStyle(color: Colors.blue, fontSize: 14),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  debugPrint("Link Clicked");
                },
            ),
            TextSpan(
              text: "showing a bigger image",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            ImageSpan(
              AssetImage("packages/real_rich_text/images/emoji_10.png"),
              width: 40,
              height: 40,
            ),
            TextSpan(
              text: "and seems working perfect……",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
          ]),
        ),
      ),
    );
  }
}
```

## Note

ImageSpan must set the width & height properties.

if your image's width or height is not specific, you can wrap two RealRichText in a StatefulWidget, one for showing placeholder image and the other for showing the actual image when it is ready.
