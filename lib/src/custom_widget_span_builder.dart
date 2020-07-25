import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:flutter_tagging/flutter_tagging.dart';


///
class CustomSpanBuilder extends SpecialTextSpanBuilder {
  CustomSpanBuilder(this.controller, this.context,{@required this.tagConfiguration, this.onDelete});

  final TextEditingController controller;
  final BuildContext context;

  //use to create inline widget
  final TagConfiguration tagConfiguration;

  ///when the close icon is clicked
  final onDelete;

  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle,SpecialTextGestureTapCallback onTap, int index}) {
    if (flag == null || flag == '') {
      return null;
    }
      //do we need to check for a space before the word?
      return CustomWidgetText(
        textStyle,
        onTap,
          start: index,
          context: context,
          controller: controller,
          startFlag: flag,
          onDelete: onDelete,
          tagConfiguration: tagConfiguration,
      );
    return null;
  }
}

class CustomWidgetText extends SpecialText {
  CustomWidgetText(TextStyle textStyle, SpecialTextGestureTapCallback onTap,
      {this.start,
        this.controller,
        this.context,
        String startFlag,
        @required this.onDelete,
        @required this.tagConfiguration,
      })
      : super(startFlag, ' ', textStyle, onTap: onTap);

  final TextEditingController controller;
  final int start;
  final BuildContext context;
  final onDelete;
  final TagConfiguration tagConfiguration;

  @override
  bool isEnd(String value) {
    return super.isEnd(value);
  }

  @override
  InlineSpan finishText() {
    final String text = toString();
    return ExtendedWidgetSpan(
      actualText: text,
      start: start,
      alignment: ui.PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.only(right: 5.0, top: 2.0, bottom: 2.0),
        child: ClipRRect(
            borderRadius: tagConfiguration.borderRadius ?? const BorderRadius.all(Radius.circular(5.0)),
            child: Container(
              padding: tagConfiguration.padding ?? const EdgeInsets.all(5.0),
              color: tagConfiguration.tagColor ?? Theme.of(context).primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    text.trim(),
                    style: tagConfiguration.textStyle ?? textStyle,
                  ),
                  const SizedBox(
                    width: 5.0,
                  ),
                  InkWell(
                    child: tagConfiguration.closeIcon ?? Icon(
                      Icons.close,
                      size: 15.0,
                      color: tagConfiguration.closeIconColor ?? Colors.black,
                    ),
                    onTap: () {
                      controller.value = controller.value.copyWith(
                          text: controller.text
                              .replaceRange(start, start + text.length, ''),
                          selection: TextSelection.fromPosition(
                              TextPosition(offset: start))
                      );

                      onDelete();
                    },
                  )
                ],
              ),
            )),
      ),
      deleteAll: true,
    );
  }
}