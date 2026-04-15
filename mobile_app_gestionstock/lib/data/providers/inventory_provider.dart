import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InventoryProvider with ChangeNotifier {
  final ApiService _apiService;

  List<dynamic> _lines = [];
  bool _isLoading = false;
  String? _error;
  bool _hasActiveInventory = false;
  String? _activeInventoryName;

  Timer? _pollingTimer;

  List<dynamic> get lines => _lines;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveInventory => _hasActiveInventory;
  String? get activeInventoryName => _activeInventoryName;

  int get countValid => _lines.where((l) => l['statut'] == 'VALIDE' || l['statut'] == 'LigneStatut.VALIDE').length;
  int get countRefused => _lines.where((l) => l['statut'] == 'REFUSE' || l['statut'] == 'LigneStatut.REFUSE').length;
  int get countReaudit =>
      _lines.where((l) => l['statut'] == 'A_RECOMPTER' || l['statut'] == 'LigneStatut.A_RECOMPTER').length;
  int get countToScan => _lines.where((l) => l['statut'] == 'A_SCANNER' || l['statut'] == 'LigneStatut.A_SCANNER' || l['statut'] == null).length;
  int get countPendingAudit =>
      _lines.where((l) => l['statut'] == 'EN_ATTENTE_AUDIT' || l['statut'] == 'LigneStatut.EN_ATTENTE_AUDIT').length;
  
  int get countPending => countToScan + countPendingAudit;

  double get percentValid => _lines.isEmpty ? 0 : countValid / _lines.length;
  double get percentRefused =>
      _lines.isEmpty ? 0 : countRefused / _lines.length;
  double get percentReaudit =>
      _lines.isEmpty ? 0 : countReaudit / _lines.length;
  double get percentToScan => _lines.isEmpty ? 0 : countToScan / _lines.length;
  double get percentPendingAudit =>
      _lines.isEmpty ? 0 : countPendingAudit / _lines.length;
  double get percentPending =>
      _lines.isEmpty ? 0 : countPending / _lines.length;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  InventoryProvider(this._apiService) {
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      // Only poll if the app is active and we care about updates
      fetchLines(silent: true);
    });
  }

  Future<void> fetchLines({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final invRes = await _apiService.get('/mobile/inventaires/active');
      if (invRes.statusCode == 200 &&
          invRes.data != null &&
          invRes.data.toString().isNotEmpty) {
        final invId = invRes.data['id'];
        _activeInventoryName = invRes.data['nom'];
        _hasActiveInventory = true;

        final linesRes = await _apiService.get(
          '/mobile/inventaires/$invId/lignes',
        );
        if (linesRes.statusCode == 200) {
          _lines = linesRes.data;
        } else if (!silent) {
          _error = "Erreur de chargement des lignes";
          _lines = [];
        }
      } else {
        _hasActiveInventory = false;
        _activeInventoryName = null;
        _lines = [];
      }
    } catch (e) {
      if (!silent) {
        String msg = e.toString().toLowerCase();
        if (msg.contains('socketexception') ||
            msg.contains('failed host lookup') ||
            msg.contains('connection error')) {
          _error = "Serveur inaccessible. Vérifiez votre connexion.";
        } else {
          _error = "Une erreur est survenue lors du chargement des stocks";
        }
        _hasActiveInventory = false;
        _lines = [];
      }
    } finally {
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
