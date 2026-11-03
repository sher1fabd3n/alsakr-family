import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../models/parent_family_models.dart';
import '../services/parent_family_service.dart';

/// Global state for the active child across all parent screens.
class ParentChildContext extends ChangeNotifier {
  ParentChildContext(this._service, this._apiClient);

  final ParentFamilyService _service;
  final ApiClient _apiClient;

  static const _storageKey = 'parent_active_student_id';

  FamilyDashboardSummary? _family;
  ChildDashboardSummary? _activeChild;
  int? _activeStudentId;
  bool _loading = false;
  String? _error;
  int _photoRevision = 0;
  final Map<int, Uint8List> _localPhotoPreviews = {};

  final Map<int, ChildDashboardSummary> _summaryCache = {};

  bool get isLoading => _loading;
  String? get error => _error;
  FamilyDashboardSummary? get family => _family;
  List<ChildDashboardSummary> get children => _family?.children ?? [];
  int get childCount => children.length;
  ChildDashboardSummary? get activeChild => _activeChild;
  int? get activeStudentId => _activeStudentId;
  int get photoRevision => _photoRevision;

  Uint8List? localPhotoPreview(int studentId) => _localPhotoPreviews[studentId];

  ChildDashboardSummary? childById(int id) =>
      _summaryCache[id] ?? children.cast<ChildDashboardSummary?>().firstWhere(
            (c) => c?.studentId == id,
            orElse: () => null,
          );

  Future<void> bootstrap({bool force = false}) async {
    if (_loading) return;
    if (!force && _family != null && children.isNotEmpty && _activeChild != null) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _family = await _service.getFamilyDashboard();
      _family = FamilyDashboardSummary(
        totalChildren: _family!.totalChildren,
        activeStudentId: _family!.activeStudentId,
        children: _family!.children.where((c) => c.studentId > 0).toList(),
      );
      for (final c in _family!.children) {
        _summaryCache[c.studentId] = c;
      }

      final storedId = await _readStoredStudentId();
      final serverActive = _family!.activeStudentId;
      final candidate = _pickValidId(storedId ?? serverActive) ??
          (_family!.children.isNotEmpty ? _family!.children.first.studentId : null);

      if (candidate != null) {
        await _activateChild(candidate, syncServer: storedId == null);
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFamily() async {
    try {
      _family = await _service.getFamilyDashboard();
      for (final c in _family!.children) {
        _summaryCache[c.studentId] = c;
      }
      if (_activeStudentId != null) {
        _activeChild = childById(_activeStudentId!);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> selectChild(int studentId) async {
    if (_activeStudentId == studentId) return;
    await _activateChild(studentId, syncServer: true);
    unawaited(_service.refreshChildData(studentId));
  }

  Future<void> refreshActiveChildData() async {
    if (_activeStudentId == null) return;
    _loading = true;
    notifyListeners();
    try {
      final summary = await _service.getChildSummary(_activeStudentId!);
      _summaryCache[_activeStudentId!] = summary;
      _activeChild = summary;
      _family = _family == null
          ? null
          : FamilyDashboardSummary(
              totalChildren: _family!.totalChildren,
              activeStudentId: _activeStudentId,
              children: _family!.children
                  .map((c) => c.studentId == _activeStudentId ? summary : c)
                  .toList(),
            );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateChildPhoto(int studentId, Uint8List bytes) async {
    final previousUrl = childById(studentId)?.profilePhotoUrl;
    final photoUrl = await _service.uploadChildPhoto(studentId, bytes);
    if (photoUrl.isEmpty) {
      throw Exception('تعذر تحديث الصورة. حاول مرة أخرى.');
    }

    await _evictPhotoCache(previousUrl);
    await _evictPhotoCache(photoUrl);

    _localPhotoPreviews[studentId] = bytes;
    _applyPhotoUrl(studentId, photoUrl);
    _photoRevision++;
    notifyListeners();

    try {
      await refreshFamily();
      final refreshed = childById(studentId)?.profilePhotoUrl;
      if (refreshed == null || refreshed.isEmpty) {
        _applyPhotoUrl(studentId, photoUrl);
        notifyListeners();
      } else {
        await _evictPhotoCache(refreshed);
      }
    } catch (_) {}
  }

  void _applyPhotoUrl(int studentId, String photoUrl) {
    ChildDashboardSummary apply(ChildDashboardSummary child) =>
        child.copyWith(profilePhotoUrl: photoUrl);

    if (_activeChild?.studentId == studentId) {
      _activeChild = apply(_activeChild!);
    }
    if (_summaryCache.containsKey(studentId)) {
      _summaryCache[studentId] = apply(_summaryCache[studentId]!);
    }
    if (_family != null) {
      _family = FamilyDashboardSummary(
        totalChildren: _family!.totalChildren,
        activeStudentId: _family!.activeStudentId,
        children: _family!.children
            .map((c) => c.studentId == studentId ? apply(c) : c)
            .toList(),
      );
    }
  }

  Future<void> _evictPhotoCache(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await CachedNetworkImage.evictFromCache(url);
      final bare = url.split('?').first;
      if (bare != url) {
        await CachedNetworkImage.evictFromCache(bare);
      }
    } catch (_) {}
  }

  Future<void> _activateChild(int studentId, {required bool syncServer}) async {
    final cached = childById(studentId);
    _activeStudentId = studentId;
    if (cached != null) {
      _activeChild = cached;
    }
    notifyListeners();
    try {
      final summary = syncServer
          ? await _service.switchActiveChild(studentId)
          : cached ?? await _service.getChildSummary(studentId);
      _activeStudentId = studentId;
      _activeChild = summary;
      _summaryCache[studentId] = summary;
      await _apiClient.writeSecure(_storageKey, studentId.toString());
    } catch (e) {
      if (_activeChild == null && cached != null) {
        _activeChild = cached;
      }
      if (_activeChild == null) {
        _error = e.toString().replaceFirst('Exception: ', '');
      }
    }
  }

  int? _pickValidId(int? id) {
    if (id == null) return null;
    if (_family?.children.any((c) => c.studentId == id) == true) return id;
    return null;
  }

  Future<int?> _readStoredStudentId() async {
    final raw = await _apiClient.readSecure(_storageKey);
    return int.tryParse(raw ?? '');
  }

  void clear() {
    _family = null;
    _activeChild = null;
    _activeStudentId = null;
    _summaryCache.clear();
    _localPhotoPreviews.clear();
    _apiClient.deleteSecure(_storageKey);
    notifyListeners();
  }
}
