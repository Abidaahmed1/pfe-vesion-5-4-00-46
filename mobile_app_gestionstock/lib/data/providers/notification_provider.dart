import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  Timer? _pollingTimer;

  NotificationProvider(this._apiService) {
    fetchNotifications();
    _startPolling();
  }

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications() async {
    try {
      final response = await _apiService.get('/mobile/notifications');
      if (response.statusCode == 200) {
        _notifications = response.data;
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => n['lu'] == false).length;
  }

  Future<void> markAsRead(int id) async {
    try {
      await _apiService.post('/mobile/notifications/$id/read', data: {});
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['lu'] = true;
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.post('/mobile/notifications/read-all', data: {});
      for (var n in _notifications) {
        n['lu'] = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint("Error marking all notifications as read: $e");
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNotifications();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
