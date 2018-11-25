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
