import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MyNavigationBarController extends ChangeNotifier {
  MyNavigationBarController({
    required this.initialPage,
    this.pages,
  });
  
  final int initialPage; 
  int? pages;

  int? _page;
  int get page => _page ?? initialPage;  

  void changeCurrentPage(int newPage) {
    _page = newPage;
    notifyListeners();
  }

  void changePages(int newPages) {
    pages = newPages;
    notifyListeners();
  }
}

class MyNavigationBar extends StatefulWidget {
  const MyNavigationBar({
    required this.controller,
    required this.onLeft,
    required this.onText,
    required this.onRight,
    super.key,
  });

  final MyNavigationBarController controller;
  final void Function() onLeft;
  final void Function() onText;
  final void Function() onRight;

  @override
  State<StatefulWidget> createState() => _MyNavigationBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<MyNavigationBarController>('controller', controller))
      ..add(ObjectFlagProperty<void Function()>.has('onRight', onRight))
      ..add(ObjectFlagProperty<void Function()>.has('onText', onText))
      ..add(ObjectFlagProperty<void Function()>.has('onLeft', onLeft));
  }
  
}

class _MyNavigationBarState extends State<MyNavigationBar> {
  late int _page;
  late int? _pages;

  @override
  void initState() {
    _page = widget.controller.page;
    _pages = widget.controller.pages;

    widget.controller.addListener(() {
      setState(() {
        _page = widget.controller.page;
        _pages = widget.controller.pages;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) => BottomAppBar(
    child: Row(
      children: [
        const SizedBox(width: 20),
        IconButton(
          onPressed: widget.onLeft,
          icon: const Icon(Icons.keyboard_arrow_left),
        ),
        const Spacer(),
        TextButton(
          onPressed: widget.onText,
          child: (_pages != null) 
            ? Text('$_page/$_pages') 
            : Text('$_page'),
        ),
        const Spacer(),
        IconButton(
          onPressed: widget.onRight,
          icon: const Icon(Icons.keyboard_arrow_right),
        ),
        const SizedBox(width: 20),
      ],
    ),
  );
}
