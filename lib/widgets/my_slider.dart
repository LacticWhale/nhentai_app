import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MySlider extends StatefulWidget {
  const MySlider({
    required this.start,
    required this.end,
    required this.divisions,
    super.key,
  });

  final double start;
  final double end;
  final int divisions;

  @override
  State<StatefulWidget> createState() => _MySliderState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('start', start))
      ..add(IntProperty('divisions', divisions))
      ..add(DoubleProperty('end', end));
  }
  
}

class _MySliderState extends State<MySlider> {
  late double _value;
  late double _min;
  late double _max;

  @override
  void initState() {
    _value = widget.start;
    _min = widget.start;
    _max = widget.end;
    
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Slider(
        value: _value,
        // min: widget.start,
        // max: widget.end,
        min: _min,
        max: _max,
        // divisions: _divisions,
        onChanged:(value) {
          setState(() {
            // if((value.start - _min).abs() <= 10)
            //   _min = _start - _start + 0.2;
            _value = value;
          });
        },
        onChangeEnd: (value) {
          setState(() {
            // var before = _start - _min;
            // var between = _end - _start;
            // var after = _max - _end;

            // // between - 60%
            // _min = max(_start - max(between * 9/10, widget.end * 0.1), widget.start);
            // _max = min(_end + max(between * 9/10, widget.end * 0.1), widget.end);

            // if(_min == _max)
            //   _max += 1; 

            // _min = max(_start - widget.end * 0.2, widget.start);
            // _max = min(_end + widget.end * 0.2, widget.end);
            // _start = value.start;
            // _end = value.end;
          });
        },
      ),
      Text('${_value.ceil()}'),
      Text('${_min.ceil()} : ${_max.ceil()}'),
    ]
  ,);

}
