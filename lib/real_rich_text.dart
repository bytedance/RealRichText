import 'dart:ui' as ui show Codec, Image;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class RealRichText extends Text {
  final List<TextSpan> textSpanList;

  RealRichText(
    this.textSpanList, {
    Key key,
    TextStyle style,
    TextAlign textAlign = TextAlign.start,
    TextDirection textDirection,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    double textScaleFactor = 1.0,
    int maxLines,
    Locale locale,
  }) : super("",
            style: style,
            textAlign: textAlign,
            textDirection: textDirection,
            softWrap: softWrap,
            overflow: overflow,
            textScaleFactor: textScaleFactor,
            maxLines: maxLines,
            locale: locale);

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = style;
    if (style == null || style.inherit)
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    if (MediaQuery.boldTextOverride(context))
      effectiveTextStyle = effectiveTextStyle
          .merge(const TextStyle(fontWeight: FontWeight.bold));

    TextSpan textSpan = TextSpan(
      style: effectiveTextStyle,
      text: "",
      children: textSpanList,
    );

    // pass the context to ImageSpan to create a ImageConfiguration
    textSpan.children.forEach((f) {
      if (f is ImageSpan) {
        f.updateImageConfiguration(context);
      }
    });

    Widget result = _RichTextWrapper(
        textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
        textDirection:
            textDirection, // RichText uses Directionality.of to obtain a default if this is null.
        locale:
            locale, // RichText uses Localizations.localeOf to obtain a default if this is null
        softWrap: softWrap ?? defaultTextStyle.softWrap,
        overflow: overflow ?? defaultTextStyle.overflow,
        textScaleFactor:
            textScaleFactor ?? MediaQuery.textScaleFactorOf(context),
        maxLines: maxLines ?? defaultTextStyle.maxLines,
        text: textSpan);
    if (semanticsLabel != null) {
      result = Semantics(
          textDirection: textDirection,
          label: semanticsLabel,
          child: ExcludeSemantics(
            child: result,
          ));
    }
    return result;
  }
}

/// Since flutter engine does not support inline-image for now, we have to support this feature via a tricky solution:
/// convert image to a particular TextSpan whose text always be \u200B(a zero-width-space).
/// set letterSpacing to the required image width
/// set fontSize to the required image height / 1.15
///
class ImageSpan extends TextSpan {
  final double width;
  final double height;
  final ImageProvider imageProvider;
  final _ImageResolver _imageResolver;
  ImageSpan(
    this.imageProvider, {
    this.width = 14.0,
    this.height = 14.0,
    GestureRecognizer recognizer,
  })  : _imageResolver = _ImageResolver(imageProvider),
        super(
            style: TextStyle(
                color: Colors.transparent,
                letterSpacing: width,
                height: 1,
                fontSize: height / 1.15),
            text: "\u200B",
            children: [],
            recognizer: recognizer);

  void updateImageConfiguration(BuildContext context) {
    _imageResolver.updateImageConfiguration(context, width, height);
  }
}

typedef _ImageResolverListener = void Function();

class _ImageResolver {
  final ImageProvider imageProvider;

  ImageStream _imageStream;
  ImageConfiguration _imageConfiguration;
  ui.Image _image;
  _ImageResolverListener _listener;

  _ImageResolver(this.imageProvider);

  /// set the ImageConfiguration from outside
  void updateImageConfiguration(
      BuildContext context, double width, double height) {
    _imageConfiguration = createLocalImageConfiguration(
      context,
      size: Size(width, height),
    );
  }

  void resolve(_ImageResolverListener listener) {
    assert(_imageConfiguration != null);

    final ImageStream oldImageStream = _imageStream;
    _imageStream = imageProvider.resolve(_imageConfiguration);
    assert(_imageStream != null);

    this._listener = listener;
    if (_imageStream.key != oldImageStream?.key) {
      oldImageStream?.removeListener(_handleImageChanged);
      _imageStream.addListener(_handleImageChanged);
    }
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    _image = imageInfo.image;
    _listener?.call();
  }

  void stopListening() {
    _imageStream?.removeListener(_handleImageChanged);
  }
}

/// Just a subclass of RichText for overriding createRenderObject
/// to return a [_RealRichRenderParagraph] object
///
/// No more special purpose.
class _RichTextWrapper extends RichText {
  const _RichTextWrapper({
    Key key,
    @required TextSpan text,
    TextAlign textAlign = TextAlign.start,
    TextDirection textDirection,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    double textScaleFactor = 1.0,
    int maxLines,
    Locale locale,
  })  : assert(text != null),
        assert(textAlign != null),
        assert(softWrap != null),
        assert(overflow != null),
        assert(textScaleFactor != null),
        assert(maxLines == null || maxLines > 0),
        super(
            key: key,
            text: text,
            textAlign: textAlign,
            textDirection: textDirection,
            softWrap: softWrap,
            overflow: overflow,
            textScaleFactor: textScaleFactor,
            maxLines: maxLines,
            locale: locale);

  @override
  RenderParagraph createRenderObject(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    return _RealRichRenderParagraph(
      text,
      textAlign: textAlign,
      textDirection: textDirection ?? Directionality.of(context),
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      locale: locale ?? Localizations.localeOf(context, nullOk: true),
    );
  }
}

/// paint the image on the top of those ImageSpan's blank space
class _RealRichRenderParagraph extends RenderParagraph {
  _RealRichRenderParagraph(TextSpan text,
      {TextAlign textAlign,
      TextDirection textDirection,
      bool softWrap,
      TextOverflow overflow,
      double textScaleFactor,
      int maxLines,
      Locale locale})
      : super(
          text,
          textAlign: textAlign,
          textDirection: textDirection,
          softWrap: softWrap,
          overflow: overflow,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          locale: locale,
        );

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final Canvas canvas = context.canvas;
    final Rect bounds = offset & size;

    debugPrint("_RealRichRenderParagraph offset=$offset bounds=$bounds");

    canvas.save();
    canvas.clipRect(bounds);

    int textOffset = 0;
    text.children.forEach((textSpan) {
      if (textSpan is ImageSpan) {
        // this is the top-center point of the ImageSpan
        Offset offsetForCaret = getOffsetForCaret(
          TextPosition(offset: textOffset),
          bounds,
        );
        // this is the-top left point of the ImageSpan
        Offset topLeftOffset = Offset(
            offset.dx +
                offsetForCaret.dx -
                (textOffset == 0 ? 0 : textSpan.width / 2),
            offset.dy + offsetForCaret.dy);
        debugPrint(
            "_RealRichRenderParagraph ImageSpan, textOffset = $textOffset, topLeftOffset=$topLeftOffset");

        // if image is not ready: wait for async ImageInfo
        if (textSpan._imageResolver._image == null) {
          textSpan._imageResolver.resolve(() {
            if (owner != null) {
              markNeedsPaint();
            }
          });
          return;
        }
        // else: just paint it.
        paintImage(
          canvas: canvas,
          rect: topLeftOffset & Size(textSpan.width, textSpan.height),
          image: textSpan._imageResolver._image,
          fit: BoxFit.scaleDown,
        );
      }
      textOffset += textSpan.toPlainText().length;
    });

    canvas.restore();
  }

  @override
  void detach() {
    super.detach();
    text.children.forEach((textSpan) {
      if (textSpan is ImageSpan) {
        textSpan._imageResolver.stopListening();
      }
    });
  }

  @override
  void performLayout() {
    super.performLayout();

    debugPrint("size = $size");
  }
}
