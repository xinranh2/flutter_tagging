// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tagging/src/custom_widget_span_builder.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'configurations.dart';
import 'taggable.dart';

///
class FlutterTagging<T extends Taggable> extends StatefulWidget {
  /// Called every time the value changes.
  ///  i.e. when items are selected or removed.
  final VoidCallback onChanged;

  /// The configuration of the [TextField] that the [FlutterTagging] widget displays.
  final TextFieldConfiguration textFieldConfiguration;

  /// Called with the search pattern to get the search suggestions.
  ///
  /// This callback must not be null. It is be called by the FlutterTagging widget
  /// and provided with the search pattern. It should return a [List]
  /// of suggestions either synchronously, or asynchronously (as the result of a
  /// [Future].
  /// Typically, the list of suggestions should not contain more than 4 or 5
  /// entries. These entries will then be provided to [itemBuilder] to display
  /// the suggestions.
  ///
  /// Example:
  /// ```dart
  /// findSuggestions: (pattern) async {
  ///   return await _getSuggestions(pattern);
  /// }
  /// ```
  final FutureOr<List<T>> Function(String) findSuggestions;

  /// The configuration of [Chip]s that are displayed for selected tags.
  final ChipConfiguration Function(T) configureChip;

  /// The configuration of suggestions displayed when [findSuggestions] finishes.
  final SuggestionConfiguration Function(T) configureSuggestion;

  /// The configuration of selected tags like their spacing, direction, etc.
  final WrapConfiguration wrapConfiguration;

  /// Defines an object for search pattern.
  ///
  /// If null, tag addition feature is disabled. CANNOT be null for our purposes
  final T Function(String) additionCallback;

  /// Called when add to tag button is pressed.
  ///
  /// Api Calls to add the tag can be called here.
  final FutureOr<T> Function(T) onAdded;

  /// Called when waiting for [findSuggestions] to return.
  final Widget Function(BuildContext) loadingBuilder;

  /// Called when [findSuggestions] returns an empty list.
  final Widget Function(BuildContext) emptyBuilder;

  /// Called when [findSuggestions] throws an exception.
  final Widget Function(BuildContext, Object) errorBuilder;

  /// Called to display animations when [findSuggestions] returns suggestions.
  ///
  /// It is provided with the suggestions box instance and the animation
  /// controller, and expected to return some animation that uses the controller
  /// to display the suggestion box.
  final dynamic Function(BuildContext, Widget, AnimationController)
      transitionBuilder;

  /// The configuration of suggestion box.
  final SuggestionsBoxConfiguration suggestionsBoxConfiguration;

  /// The duration that [transitionBuilder] animation takes.
  ///
  /// This argument is best used with [transitionBuilder] and [animationStart]
  /// to fully control the animation.
  ///
  /// Defaults to 500 milliseconds.
  final Duration animationDuration;

  /// The value at which the [transitionBuilder] animation starts.
  ///
  /// This argument is best used with [transitionBuilder] and [animationDuration]
  /// to fully control the animation.
  ///
  /// Defaults to 0.25.
  final double animationStart;

  /// If set to true, no loading box will be shown while suggestions are
  /// being fetched. [loadingBuilder] will also be ignored.
  ///
  /// Defaults to false.
  final bool hideOnLoading;

  /// If set to true, nothing will be shown if there are no results.
  /// [emptyBuilder] will also be ignored.
  ///
  /// Defaults to false.
  final bool hideOnEmpty;

  /// If set to true, nothing will be shown if there is an error.
  /// [errorBuilder] will also be ignored.
  ///
  /// Defaults to false.
  final bool hideOnError;

  /// The duration to wait after the user stops typing before calling
  /// [findSuggestions].
  ///
  /// This is useful, because, if not set, a request for suggestions will be
  /// sent for every character that the user types.
  ///
  /// This duration is set by default to 300 milliseconds.
  final Duration debounceDuration;

  /// If set to true, suggestions will be fetched immediately when the field is
  /// added to the view.
  ///
  /// But the suggestions box will only be shown when the field receives focus.
  /// To make the field receive focus immediately, you can set the `autofocus`
  /// property in the [textFieldConfiguration] to true.
  ///
  /// Defaults to false.
  final bool enableImmediateSuggestion;

  ///
  final List<T> initialItems;

  ///flag for whether tags will show up inside the search bar or not
  final bool wrapWithinTextField;

  ///needed for when tags are inside the search bar
  final SpecialTextSpanBuilder specialTextSpanBuilder;

  ///configuration for tags that are inside the search bar
  final TagConfiguration infieldTagConfiguration;

  /// the tag's text padding that needs to be adjusted for
  final double tagTextPadding;

  /// Creates a [FlutterTagging] widget.
  FlutterTagging({
    @required this.initialItems,
    @required this.findSuggestions,
    @required this.configureChip,
    @required this.configureSuggestion,
    @required this.tagTextPadding,
    this.onChanged,
    this.additionCallback, //need this for wrapping tags in text field
    this.enableImmediateSuggestion = false,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.wrapConfiguration = const WrapConfiguration(),
    this.textFieldConfiguration = const TextFieldConfiguration(),
    this.suggestionsBoxConfiguration = const SuggestionsBoxConfiguration(),
    this.transitionBuilder,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.hideOnEmpty = false,
    this.hideOnError = false,
    this.hideOnLoading = false,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationStart = 0.25,
    this.onAdded,
    this.wrapWithinTextField = false,
    this.specialTextSpanBuilder,
    this.infieldTagConfiguration, //must not be null if wrapping tags in text field
  })  : assert(initialItems != null),
        assert(findSuggestions != null),
        assert(configureChip != null),
        assert(configureSuggestion != null),
        assert(!wrapWithinTextField || (wrapWithinTextField && additionCallback != null)),
        assert(!wrapWithinTextField || (wrapWithinTextField && infieldTagConfiguration != null)),
        assert(!wrapWithinTextField || (wrapWithinTextField && tagTextPadding != null)),
        assert(!wrapWithinTextField || (wrapWithinTextField && textFieldConfiguration.decoration.contentPadding != null));

  @override
  _FlutterTaggingState<T> createState() => _FlutterTaggingState<T>();
}

class _FlutterTaggingState<T extends Taggable>
    extends State<FlutterTagging<T>> {
  TextEditingController _textController;
  FocusNode _focusNode;
  T _additionItem;
  SpecialTextSpanBuilder _specialTextSpanBuilder;
  List<String> _chosenTags = [];
  String stringTags = '';
  double currentTextPadding = 0;

  @override
  void initState() {
    super.initState();
    currentTextPadding = 0.0;
    _textController =
        widget.textFieldConfiguration.controller ?? TextEditingController();
    _textController.addListener(_setCursorBack);
    _focusNode = widget.textFieldConfiguration.focusNode ?? FocusNode();
    _specialTextSpanBuilder = widget.specialTextSpanBuilder ?? CustomSpanBuilder(
        _textController,
        context,
      onDelete: _deleteTag,
      tagConfiguration: widget.infieldTagConfiguration.copyWith(
        textPadding: EdgeInsets.all(widget.tagTextPadding), //set tag's text padding here
      ),
    );
  }

  ///listens to all activity to text field and prevents user from clicking anywhere inside text
  _setCursorBack() {
    _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length));
  }

  ///removes where the textfield's text differs from the widget's array BUT ONLY THE FIRST THING THAT DIFFERS....
  void _deleteTag() {
    List splitText = _textController.value.text.split((' '));
    splitText.removeWhere((element) => element == ' ');
    //print('split text: $splitText compare with ${_chosenTags}');
    for (int i = 0; i < _chosenTags.length; i++) {
      if (_chosenTags[i] != splitText[i]) {
        //this might be an error area
        setState(() {
          _chosenTags.removeAt(i);
          widget.initialItems.removeAt(i);
        });
        break;
      }
    }
    if (widget.wrapWithinTextField) {
      adjustContentPadding();
    }

    if (widget.onChanged != null) {
      widget.onChanged();
    }
  }

  //called whenever user initiates change to textfield
  _onTextChange(String text) {
    if (text.length < stringTags.length) {
      _deleteTag(); //deletes when user presses backspace
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    stringTags = '';

    //if we are putting the tags inside the textfield, we want to update the string array every build
    //and update the textfield's text based on that string array
    if (widget.wrapWithinTextField) {
      _chosenTags = widget.initialItems.map<String>( //make string list of item names
              (item) {
            var conf = widget.configureChip(item);
            return (conf.label as Text).data;
          }).toList();

      for (var tag in _chosenTags) {
        stringTags += '$tag ';
      }

      _textController.value = TextEditingValue(
        text: stringTags, //sets the text in the textfield to be the string of the tags
        selection: TextSelection.fromPosition(
          TextPosition(offset: stringTags.length),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TypeAheadField<T>(
          getImmediateSuggestions: widget.enableImmediateSuggestion,
          specialTextSpanBuilder: widget.wrapWithinTextField ? _specialTextSpanBuilder : null,
          debounceDuration: widget.debounceDuration,
          hideOnEmpty: widget.hideOnEmpty,
          hideOnError: widget.hideOnError,
          hideOnLoading: widget.hideOnLoading,
          animationStart: widget.animationStart,
          animationDuration: widget.animationDuration,
          autoFlipDirection:
              widget.suggestionsBoxConfiguration.autoFlipDirection,
          direction: widget.suggestionsBoxConfiguration.direction,
          hideSuggestionsOnKeyboardHide:
              widget.suggestionsBoxConfiguration.hideSuggestionsOnKeyboardHide,
          keepSuggestionsOnLoading:
              widget.suggestionsBoxConfiguration.keepSuggestionsOnLoading,
          keepSuggestionsOnSuggestionSelected: widget
              .suggestionsBoxConfiguration.keepSuggestionsOnSuggestionSelected,
          suggestionsBoxController:
              widget.suggestionsBoxConfiguration.suggestionsBoxController,
          suggestionsBoxDecoration:
              widget.suggestionsBoxConfiguration.suggestionsBoxDecoration,
          suggestionsBoxVerticalOffset:
              widget.suggestionsBoxConfiguration.suggestionsBoxVerticalOffset,
          errorBuilder: widget.errorBuilder,
          transitionBuilder: widget.transitionBuilder,
          loadingBuilder: (context) =>
              widget.loadingBuilder ??
              SizedBox(
                height: 3.0,
                child: LinearProgressIndicator(),
              ),
          noItemsFoundBuilder: widget.emptyBuilder,
          textFieldConfiguration: widget.textFieldConfiguration.copyWith(
            decoration://widget.wrapWithinTextField ?
            widget.textFieldConfiguration.decoration.copyWith(
                contentPadding: widget.textFieldConfiguration.decoration.contentPadding.subtract(EdgeInsets.fromLTRB(
                    0, currentTextPadding, 0, currentTextPadding),)
            ), //: widget.textFieldConfiguration.decoration,
            focusNode: _focusNode,
            controller: _textController,
            enabled: widget.textFieldConfiguration.enabled,
            onChanged: widget.wrapWithinTextField ? (text) {
              _onTextChange(text);
              print(widget.textFieldConfiguration.decoration);
            } : widget.textFieldConfiguration.onChanged,
          ),
          suggestionsCallback: (query) async {
            String cleanedQuery = query;
            try {
              cleanedQuery = query.substring(stringTags.length); //attempt to not search for tags within textfield
            } catch (e) {
              if (stringTags.length > query.length) {
                cleanedQuery = ''; //if a tag was removed, stringTags is not yet updated, just set search to ''
              } else {
                cleanedQuery = query;
              }
            }
            var suggestions = await widget.findSuggestions(cleanedQuery);
            suggestions.removeWhere(widget.initialItems.contains);
            if (widget.additionCallback != null && cleanedQuery.isNotEmpty) {
              var additionItem = widget.additionCallback(cleanedQuery.trimRight());
              if (!suggestions.contains(additionItem) &&
                  !widget.initialItems.contains(additionItem)) {
                //if within textfield: check if addition item ends in space, if so add it to initial items
                if (widget.wrapWithinTextField && cleanedQuery.endsWith(' ')) {
                  //if we want to remove the items in the suggestion box that have the same name as what is typed:
                  //code would be here
                  if (widget.onAdded != null) {
                    var _item = await widget.onAdded(additionItem); //so onAdded method must return the item?
                    if (_item != null) {
                      widget.initialItems.add(_item);
                    }
                  } else {
                    widget.initialItems.add(additionItem);
                  }
                  if (widget.onChanged != null) {
                    widget.onChanged();
                  }
                  adjustContentPadding();
                  //setState(() {});
                } else {
                  _additionItem = additionItem;
                  suggestions.insert(0, additionItem);
                }
              } else {
                _additionItem = null;
              }
            }
            return suggestions;
          },
          itemBuilder: (context, item) {
            var conf = widget.configureSuggestion(item);
            return ListTile(
              key: ObjectKey(item),
              title: conf.title,
              subtitle: conf.subtitle,
              leading: conf.leading,
              trailing: InkWell(
                splashColor: conf.splashColor ?? Theme.of(context).splashColor,
                borderRadius: conf.splashRadius,
                onTap: () async {
                  if (widget.onAdded != null) {
                    var _item = await widget.onAdded(item); //so onAdded method must return the item?
                    if (_item != null) {
                      widget.initialItems.add(_item);
                    }
                  } else {
                    widget.initialItems.add(item);
                  }
                  if (widget.wrapWithinTextField) {
                    adjustContentPadding();
                  }
                  //setState(() {});
                  if (widget.onChanged != null) {
                    widget.onChanged();
                  }
                  _textController.clear();
                  _focusNode.unfocus();
                },
                child: Builder(
                  builder: (context) {
                    if (_additionItem != null && _additionItem == item) {
                      return conf.additionWidget;
                    } else {
                      return SizedBox(width: 0);
                    }
                  },
                ),
              ),
            );
          },
          onSuggestionSelected: (suggestion) {
            if (_additionItem != suggestion) {
              setState(() {
                widget.initialItems.add(suggestion);
              });
              if (widget.wrapWithinTextField) {
                adjustContentPadding();
              }
              if (widget.onChanged != null) {
                widget.onChanged();
              }
              _textController.clear();
            }
          },
        ),
        widget.wrapWithinTextField? Container() : Wrap(
          alignment: widget.wrapConfiguration.alignment,
          crossAxisAlignment: widget.wrapConfiguration.crossAxisAlignment,
          runAlignment: widget.wrapConfiguration.runAlignment,
          runSpacing: widget.wrapConfiguration.runSpacing,
          spacing: widget.wrapConfiguration.spacing,
          direction: widget.wrapConfiguration.direction,
          textDirection: widget.wrapConfiguration.textDirection,
          verticalDirection: widget.wrapConfiguration.verticalDirection,
          children: widget.initialItems.map<Widget>((item) {
            var conf = widget.configureChip(item);
            return Chip(
              label: conf.label,
              shape: conf.shape,
              avatar: conf.avatar,
              backgroundColor: conf.backgroundColor,
              clipBehavior: conf.clipBehavior,
              deleteButtonTooltipMessage: conf.deleteButtonTooltipMessage,
              deleteIcon: conf.deleteIcon,
              deleteIconColor: conf.deleteIconColor,
              elevation: conf.elevation,
              labelPadding: conf.labelPadding,
              labelStyle: conf.labelStyle,
              materialTapTargetSize: conf.materialTapTargetSize,
              padding: conf.padding,
              shadowColor: conf.shadowColor,
              onDeleted: () {
                setState(() {
                  widget.initialItems.remove(item);
                });
                if (widget.onChanged != null) {
                  widget.onChanged();
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void adjustContentPadding() {
    if (widget.initialItems.isNotEmpty) {
      setState(() {
        currentTextPadding = widget.tagTextPadding;
      }); //to adjust textfield content padding
    } else {
      setState(() {
        currentTextPadding = 0;
      });
    }
  }
}
