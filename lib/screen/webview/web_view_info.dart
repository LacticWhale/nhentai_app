import 'package:flutter_bloc/flutter_bloc.dart';

class WebViewState {
  WebViewState(this.cookie, this.path);
  
  String cookie;
  String path;
}

abstract class WebViewEvent { }

class WebViewUpdatePath extends WebViewEvent {
  WebViewUpdatePath({required this.newPath});

  final String newPath;
}

class WebViewUpdateCookie extends WebViewEvent {
  WebViewUpdateCookie({required this.newCookie});

  final String newCookie;
}


class WebViewBloc extends Bloc<WebViewEvent, WebViewState> {
  WebViewBloc(super.initialState) {
    on<WebViewUpdateCookie>((event, emit) => emit(state..cookie = event.newCookie));
    on<WebViewUpdatePath>((event, emit) => emit(state..path = event.newPath));
  }
}
