library cart_stepper;

import 'package:cart_stepper/src/stepper_style.dart';
import 'package:flutter/material.dart';

/// Cart stepper widget
class CartStepper<VM extends num> extends StatefulWidget {
  final VM _count;

  final VM _stepper;

  /// size of the stepper button,normally it's min(with,height)
  final double size;

  /// number length of the value
  final double numberSize;

  /// widget direction
  final Axis axis;

  /// value callback
  final void Function(VM count) didChangeCount;

  /// elevation of [PhysicalModel]
  final double elevation;

  /// widget style
  final CartStepperStyle? style;

  const CartStepper({
    Key? key,

    /// value
    VM? count,

    /// step value
    VM? stepper,
    required this.didChangeCount,
    this.size = 30.0,
    this.axis = Axis.horizontal,
    this.numberSize = 2,
    this.elevation = 2,
    this.style,
  })  : _count = (count ?? 0) as VM,
        _stepper = (stepper ?? 1) as VM,
        super(key: key);
  @override
  State<CartStepper<VM>> createState() => _CartStepperState<VM>();
}

class _CartStepperState<VM extends num> extends State<CartStepper<VM>> {
  bool _editMode = false;
  String lastText = '';
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    lastText = widget._count.toString();
    _controller = TextEditingController(text: lastText);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  VM? parseValue(String text) {
    if (text.isEmpty) return 0 as VM;
    double? value = double.tryParse(text);
    if (value == null) return null;
    if (value is VM) return value as VM;
    return value.toInt() as VM;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = widget.style ??
        // ? not fixed util 3.0.3
        Theme.of(context).extension<CartStepperTheme?>()?.style ??
        CartStepperStyle.fromColorScheme(colorScheme);

    final isExpanded = _editMode || widget._count > 0;

    List<Widget> childs = [
      Expanded(
        child: IconButton(
          iconSize: widget.size * 0.6,
          padding: EdgeInsets.all(widget.size * 0.2),
          icon: Icon(
            Icons.add,
            color: isExpanded
                ? style.activeForegroundColor
                : style.deActiveForegroundColor,
          ),
          onPressed: () {
            setState(() {
              _editMode = false;
            });
            widget.didChangeCount((widget._count + widget._stepper) as VM);
          },
        ),
      ),
    ];
    if (isExpanded) {
      childs.add(
        Container(
          alignment: Alignment.center,
          width: widget.axis == Axis.vertical
              ? widget.size
              : widget.size * widget.numberSize * .5,
          child: GestureDetector(
            onTap: () {
              setState(() {
                lastText = widget._count.toString();
                _controller.text = lastText;
                _editMode = !_editMode;
                _focusNode.requestFocus();
              });
            },
            child: _editMode
                ? EditableText(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: TextStyle(color: style.activeForegroundColor),
                    cursorColor: style.activeForegroundColor,
                    backgroundCursorColor: style.activeBackgroundColor,
                    onEditingComplete: () {
                      setState(() {
                        _editMode = false;
                      });
                    },
                    onChanged: (String value) {
                      VM? newValue = parseValue(_controller.text);
                      if (newValue == null) {
                        _controller.text = lastText;
                        _controller.selection =
                            TextSelection.collapsed(offset: lastText.length);
                      } else {
                        lastText = value;
                        widget.didChangeCount(newValue);
                      }
                    },
                  )
                : Text(
                    widget._count.toString(),
                    softWrap: false,
                    style: TextStyle(
                      color: style.activeForegroundColor,
                      fontWeight: FontWeight.w400,
                      fontFamily: "Quicksand",
                      fontStyle: FontStyle.normal,
                      fontSize: widget.size * 0.5,
                    ),
                  ),
          ),
        ),
      );
      childs.add(Expanded(
        child: IconButton(
          iconSize: widget.size * 0.6,
          padding: EdgeInsets.all(widget.size * 0.2),
          icon: Icon(
            Icons.remove,
            color: style.activeForegroundColor,
          ),
          onPressed: () {
            setState(() {
              _editMode = false;
            });
            if (widget._count > 0) {
              widget.didChangeCount((widget._count - widget._stepper) as VM);
            }
          },
        ),
      ));
    }

    double width = widget.size;
    double height = width;
    if (isExpanded) {
      if (widget.axis == Axis.vertical) {
        height *= 2 + widget.numberSize * .5;
      } else {
        width *= 2 + widget.numberSize * .5;
      }
    }

    return AnimatedPhysicalModel(
      shape: style.shape,
      borderRadius: BorderRadius.all(style.radius ?? Radius.circular(height)),
      shadowColor: style.shadowColor ?? const Color.fromARGB(255, 0, 0, 0),
      color: isExpanded
          ? style.activeBackgroundColor
          : style.deActiveBackgroundColor,
      elevation: widget.elevation,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
      child: SizedBox(
        width: width,
        height: height,
        child: widget.axis == Axis.vertical
            ? Column(
                children: childs,
              )
            : Row(
                children: childs.reversed.toList(),
              ),
      ),
    );
  }
}

typedef CartStepperInt = CartStepper<int>;
typedef CartStepperDouble = CartStepper<double>;
