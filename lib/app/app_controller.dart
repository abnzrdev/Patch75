import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/storage/app_state.dart';
import '../features/problems/problem.dart';

class AppController extends ChangeNotifier {
  AppController({required this.problem, required this._state, this.onSave}) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_timerPaused) {
        final timers = {..._state.timerSeconds};
        timers[problem.slug] = elapsedSeconds + 1;
        _state = _state.copyWith(timerSeconds: timers);
        notifyListeners();
      }
    });
  }

  final Problem problem;
  final Future<void> Function(AppState state)? onSave;
  late final Timer _timer;
  AppState _state;
  bool _timerPaused = false;
  int compactIndex = 0;

  AppState get state => _state;
  int get elapsedSeconds => _state.timerSeconds[problem.slug] ?? 0;
  bool get timerPaused => _timerPaused;
  String get draft =>
      _state.drafts['${problem.slug}:python'] ??
      problem.starterCodeByLanguage['python'] ??
      '';
  String get notes => _state.notes[problem.slug] ?? '';

  void toggleFocus() {
    _state = _state.copyWith(focusMode: !_state.focusMode);
    _changed();
  }

  void toggleTimer() {
    _timerPaused = !_timerPaused;
    notifyListeners();
  }

  void setCompactIndex(int value) {
    compactIndex = value;
    notifyListeners();
  }

  void updateDraft(String value) {
    _state = _state.copyWith(
      drafts: {..._state.drafts, '${problem.slug}:python': value},
    );
    _save();
  }

  void updateNotes(String value) {
    _state = _state.copyWith(notes: {..._state.notes, problem.slug: value});
    _save();
  }

  void markSolved() {
    _state = _state.copyWith(
      progress: {..._state.progress, problem.slug: 'solved'},
    );
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void _save() {
    onSave?.call(_state);
  }

  @override
  void dispose() {
    _timer.cancel();
    _save();
    super.dispose();
  }
}
