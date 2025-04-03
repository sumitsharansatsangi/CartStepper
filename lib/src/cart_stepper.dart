import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'stepper_style.dart';

const _animateDuration = Duration(milliseconds: 300);

const _textStyle = TextStyle(
  fontWeight: FontWeight.w400,
  fontFamily: "Quicksand",
  fontStyle: FontStyle.normal,
);

VM _as<VM extends num>(num? value) {
  value ??= 0.0;

  if (value is VM) return value;
  if (0 is VM) {
    return value.toInt() as VM;
  }
  return value.toDouble() as VM;
}

/// Cart stepper widget
class CartStepper<VM extends num> extends StatefulWidget {
  const CartStepper({
    super.key,

    /// value
    VM? value,
    @Deprecated('use value instead') VM? count,

    /// step value
    VM? stepper,
    required this.didChangeCount,
    this.size = 30.0,
    this.axis = Axis.horizontal,
    this.numberSize = 3,
    this.format,
    this.editKeyboardType,
    this.elevation,
    this.alwaysExpanded = false,
    this.style,
  }) : _value = (value ?? count ?? (0 is VM ? 0 : 0.0)) as VM,
       _stepper = (stepper ?? (0 is VM ? 1 : 1.0)) as VM;

  final VM _value;

  final VM _stepper;

  /// size of the stepper button,normally it's min(with,height)
  final double size;

  /// number length of the value
  final double numberSize;

  final NumberFormat? format;

  final TextInputType? editKeyboardType;

  /// widget direction
  final Axis axis;

  /// value callback
  final ValueChanged<VM> didChangeCount;

  /// always expanded while value is 0
  final bool alwaysExpanded;

  /// elevation of [PhysicalModel]
  final double? elevation;

  /// widget style
  final CartStepperStyle? style;

  @override
  State<CartStepper<VM>> createState() => _CartStepperState<VM>();
}

class _CartStepperState<VM extends num> extends State<CartStepper<VM>> {
  bool _editMode = false;
  String lastText = '';
  late final TextEditingController _controller;
  late final FocusNode _focusNode =
      FocusNode()..addListener(() {
        if (_editMode && !_focusNode.hasFocus) {
          setState(() {
            _editMode = false;
          });
        }
      });

  num defaultValue = 0;

  bool get isVertical => widget.axis == Axis.vertical;

  @override
  void initState() {
    super.initState();
    lastText = format(widget._value);
    _controller = TextEditingController(text: lastText);
  }

  String format(VM? value) {
    if (value == null) return '';
    if (widget.format != null) {
      return widget.format!.format(value);
    }
    return value.toString();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  VM? parseValue(String text) {
    num? value;
    if (text.isEmpty) {
      value = 0;
    } else {
      if (0 is VM) {
        value = int.tryParse(text);
      } else {
        value = double.tryParse(text);
      }
    }

    return _as(value);
  }

  void _setValue(VM newValue) {
    if (_editMode) {
      setState(() {
        _editMode = false;
      });
    }
    widget.didChangeCount(newValue);
  }

  void _buttonSetValue(VM newValue) {
    _setValue(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? CartStepperTheme.of(context);

    final isExpanded = _editMode || widget.alwaysExpanded || widget._value > 0;

    final textStyle = _textStyle
        .merge(
          Theme.of(context).textTheme.bodyMedium?.merge(style.textStyle) ??
              style.textStyle,
        )
        .copyWith(
          height: 1.25,
          fontSize: widget.size * 0.5,
          color:
              isExpanded ? style.activeForegroundColor : style.foregroundColor,
        );
    final borderRadius = BorderRadius.all(
      style.radius ?? Radius.circular(widget.size),
    );

    List<Widget> childs = [
      InkResponse(
        radius: widget.size,
        borderRadius: borderRadius,
        highlightShape: BoxShape.rectangle,
        onTap: () {
          _buttonSetValue(_as(widget._value + widget._stepper));
        },
        child: SizedBox(
          width: isVertical ? widget.size : null,
          height: isVertical ? null : widget.size,
          child: AspectRatio(
            aspectRatio: isExpanded ? style.buttonAspectRatio : 1,
            child: Center(
              child: Icon(
                style.iconPlus ?? CupertinoIcons.add,
                color:
                    isExpanded
                        ? style.activeForegroundColor
                        : style.foregroundColor,
              ),
            ),
          ),
        ),
      ),
    ];
    if (isExpanded) {
      childs.add(
        GestureDetector(
          onTap: () {
            setState(() {
              lastText = format(widget._value);
              _controller.text = lastText;
              _editMode = !_editMode;
              _focusNode.requestFocus();
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width:
                  isVertical
                      ? widget.size
                      : widget.size * widget.numberSize * .5,
              child:
                  _editMode
                      ? EditableText(
                        controller: _controller,
                        focusNode: _focusNode,
                        textAlign: TextAlign.center,
                        keyboardType:
                            widget.editKeyboardType ?? TextInputType.number,
                        style: textStyle,
                        cursorColor: style.activeForegroundColor,
                        backgroundCursorColor: style.activeBackgroundColor,
                        inputFormatters: [
                          if (0 is VM) FilteringTextInputFormatter.digitsOnly,
                        ],
                        onEditingComplete: () {
                          setState(() {
                            _editMode = false;
                          });
                        },
                        onChanged: (String value) {
                          VM? newValue = parseValue(_controller.text);
                          if (newValue == null) {
                            _controller.text = lastText;
                            _controller.selection = TextSelection.collapsed(
                              offset: lastText.length,
                            );
                          } else {
                            value = widget.format?.format(newValue) ?? value;
                            lastText = value;
                            widget.didChangeCount(newValue);
                          }
                        },
                      )
                      : Text(format(widget._value), softWrap: false),
            ),
          ),
        ),
      );
      childs.add(
        InkResponse(
          radius: widget.size,
          borderRadius: borderRadius,
          highlightShape: BoxShape.rectangle,
          onTap: () {
            _buttonSetValue(
              _as(
                math.max((widget._value - widget._stepper), _as(defaultValue)),
              ),
            );
          },
          child: SizedBox(
            width: isVertical ? widget.size : null,
            height: isVertical ? null : widget.size,
            child: AspectRatio(
              aspectRatio: style.buttonAspectRatio,
              child: Center(
                child: Icon(
                  style.iconMinus ?? CupertinoIcons.minus,
                  color: style.activeForegroundColor,
                ),
              ),
            ),
          ),
        ),
      );
      if (style.border != null) {
        if (isVertical) {
          childs[0] = DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: style.border!.top.color),
              ),
            ),
            child: childs[0],
          );
          childs[2] = DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: style.border!.top.color)),
            ),
            child: childs[2],
          );
        } else {
          childs[0] = DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: style.border!.top.color)),
            ),
            child: childs[0],
          );
          childs[2] = DecoratedBox(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: style.border!.top.color)),
            ),
            child: childs[2],
          );
        }
      }
    }

    Widget body = AnimatedPhysicalModel(
      duration: _animateDuration,
      curve: Curves.easeIn,
      shape: style.shape,
      borderRadius: borderRadius,
      shadowColor: style.shadowColor ?? const Color.fromARGB(255, 0, 0, 0),
      color: isExpanded ? style.activeBackgroundColor : style.backgroundColor,
      elevation: widget.elevation ?? style.elevation,
      child:
          isVertical
              ? Column(mainAxisSize: MainAxisSize.min, children: childs)
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: childs.reversed.toList(),
              ),
    );

    if (style.border != null) {
      body = AnimatedContainer(
        duration: _animateDuration,
        curve: Curves.easeIn,
        decoration: BoxDecoration(
          border: style.border,
          borderRadius: borderRadius,
        ),
        child: body,
      );
    }
    return DefaultTextStyle(
      style: textStyle,
      child: IconTheme.merge(
        data: style.iconTheme.copyWith(size: widget.size * .6),
        child: body,
      ),
    );
  }
}

typedef CartStepperInt = CartStepper<int>;
typedef CartStepperDouble = CartStepper<double>;
