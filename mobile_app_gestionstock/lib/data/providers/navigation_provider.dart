import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;
  final PageController pageController = PageController();

  int get currentIndex => _currentIndex;

  void setTab(int index) {
    _currentIndex = index;
    pageController.jumpToPage(index);
    notifyListeners();
  }
}
