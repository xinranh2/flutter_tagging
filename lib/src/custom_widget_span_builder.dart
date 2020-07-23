import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:flutter_tagging/flutter_tagging.dart';


///
class CustomSpanBuilder extends SpecialTextSpanBuilder {
  CustomSpanBuilder(this.controller, this.context,{this.chipConfiguration, this.onDelete});

  final TextEditingController controller;
  final BuildContext context;

  //use to create inline widget
  final ChipConfiguration chipConfiguration;

  final onDelete;

  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle,SpecialTextGestureTapCallback onTap, int index}) {
    if (flag == null || flag == '') {
      return null;
    }

    if (!flag.startsWith(' ')) {
      return CustomWidgetText(textStyle, onTap,
          start: index,
          context: context,
          controller: controller,
          startFlag: flag,
          onDelete: onDelete,
      );
    }
    return null;
  }
}

class CustomWidgetText extends SpecialText {
  CustomWidgetText(TextStyle textStyle, SpecialTextGestureTapCallback onTap,
      {this.start,
        this.controller,
        this.context,
        String startFlag,
        this.onDelete,
      })
      : super(startFlag, ' ', textStyle, onTap: onTap);

  final TextEditingController controller;
  final int start;
  final BuildContext context;
  final onDelete;

  @override
  bool isEnd(String value) {
    return super.isEnd(value);
  }

  @override
  InlineSpan finishText() {
    final String text = toString();
    //onTextFinished(text);

    return ExtendedWidgetSpan(
      actualText: text,
      start: start,
      alignment: ui.PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.only(right: 5.0, top: 2.0, bottom: 2.0),
        child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(5.0)),
            child: Container(
              padding: const EdgeInsets.all(5.0),
              color: Colors.orange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    text.trim(),
                    //style: textStyle?.copyWith(color: Colors.orange),
                  ),
                  const SizedBox(
                    width: 5.0,
                  ),
                  InkWell(
                    child: Icon(
                      Icons.close,
                      size: 15.0,
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