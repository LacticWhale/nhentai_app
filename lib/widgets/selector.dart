import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Selector extends StatefulWidget {
  const Selector({
    required this.pages,
    required this.page,
    required this.onJump,
    super.key,
  });

  final int pages;
  final int page;
  final void Function(int page) onJump;

  @override
  State<StatefulWidget> createState() => _SelectorState();
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('pages', pages))
      ..add(IntProperty('page', page))
      ..add(ObjectFlagProperty<void Function(int page)>.has('onJump', onJump));
  }
}

class _SelectorState extends State<Selector> {
  int? _currentSliderPage;
  
  final _textController = TextEditingController(); 

  late int _pages;
  late int _page;
  late void Function(int page) _onJump;

  @override
  void initState() {
    _pages = widget.pages;
    _page = widget.page;
    _onJump = widget.onJump;
    
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            min: 1,
            max: _pages.toDouble(),
            divisions: _pages,
            onChanged: (value) {
              _textController.clear();
              setState(() => _currentSliderPage = value.toInt());
            },
            value: (_currentSliderPage ??= _page).toDouble(),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_currentSliderPage! > 1) {
                    setState(() {
                      _currentSliderPage = _currentSliderPage! - 1;
                    });
                  }
                },
                icon: const Icon(Icons.arrow_back_ios),
              ),
              const Spacer(),
              Flexible(
                fit: FlexFit.loose,
                child: TextField(
                  controller: _textController,
                  onSubmitted: (value) => setState(() {
                    final page = int.tryParse(value) ?? 0;
                    _currentSliderPage = max(1, min(_pages, page));
                  }),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '${_currentSliderPage == 0 ? _page : _currentSliderPage}',
                  ),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              Text('/$_pages',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (_currentSliderPage! < _pages) {
                    setState(() {
                      _currentSliderPage = _currentSliderPage! + 1;
                    });
                  }
                },
                icon: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: () {
                if (Navigator.canPop(context)) 
                  Navigator.pop(context);
                
                _onJump(_currentSliderPage!);
              },
              child: const Text('Select'),
            ),
          ),
        ],
      ),
    );
}
