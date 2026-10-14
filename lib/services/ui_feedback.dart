import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The kinds of feedback the UI gives. Each pairs a haptic with a short, quiet sound.
enum UiCue {
  /// Plain button press (pills, glass buttons, toggles, cards).
  tap,

  /// A meaningful selection: a building, a floor, an apartment, a tab.
  select,

  /// Closing / collapsing / going back.
  dismiss,

  /// Small repeated movement: rotating one frame, stepping one floor.
  step,

  /// A completed action (form submitted).
  success,

  /// Something was rejected (form validation failed).
  error,
}

/// Haptics + subtle interaction sounds for the whole app.
///
/// The sounds are synthesised once as tiny WAV buffers (soft sine blips with a
/// fast decay), so there are no audio assets to ship. Everything is
/// fire-and-forget and swallows failures: a missing audio plugin (tests,
/// desktop) or a muted device must never break a tap.
class UiFeedback {
  UiFeedback._();

  /// Master switches (e.g. a future settings toggle).
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  static const _sampleRate = 22050;
  static final Map<UiCue, AudioPlayer> _players = {};
  static Future<void>? _init;

  /// Pre-loads the sounds. Call once from `main()`; safe to skip or repeat.
  static Future<void> init() => _init ??= _load();

  static Future<void> _load() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
      for (final cue in UiCue.values) {
        final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        await player.setVolume(_volume[cue]!);
        await player.setSource(BytesSource(_wav(_notes[cue]!), mimeType: 'audio/wav'));
        _players[cue] = player;
      }
    } catch (e) {
      debugPrint('UiFeedback: sounds unavailable ($e)');
    }
  }

  /// Plays [cue]'s haptic and sound.
  static void play(UiCue cue) {
    if (hapticsEnabled) _haptic(cue);
    if (soundEnabled) _sound(cue);
  }

  static void tap() => play(UiCue.tap);
  static void select() => play(UiCue.select);
  static void dismiss() => play(UiCue.dismiss);
  static void step() => play(UiCue.step);
  static void success() => play(UiCue.success);
  static void error() => play(UiCue.error);

  static void _haptic(UiCue cue) {
    switch (cue) {
      case UiCue.tap:
      case UiCue.step:
        HapticFeedback.selectionClick();
      case UiCue.select:
      case UiCue.dismiss:
        HapticFeedback.lightImpact();
      case UiCue.success:
        HapticFeedback.mediumImpact();
      case UiCue.error:
        HapticFeedback.heavyImpact();
    }
  }

  static Future<void> _sound(UiCue cue) async {
    try {
      await init();
      final player = _players[cue];
      if (player == null) return;
      await player.stop();
      await player.resume();
    } catch (_) {
      // Sound is a nicety; ignore any playback failure.
    }
  }

  // --- Synthesis -----------------------------------------------------------

  /// Player volume per cue (0..1): taps are barely-there, success is the loudest.
  static const _volume = <UiCue, double>{
    UiCue.tap: 0.35,
    UiCue.select: 0.45,
    UiCue.dismiss: 0.35,
    UiCue.step: 0.2,
    UiCue.success: 0.5,
    UiCue.error: 0.4,
  };

  /// (frequency Hz, duration s) notes per cue, played back to back.
  static const _notes = <UiCue, List<(double, double)>>{
    UiCue.tap: [(1320, 0.05)],
    UiCue.select: [(880, 0.05), (1318, 0.09)],
    UiCue.dismiss: [(988, 0.04), (659, 0.07)],
    UiCue.step: [(740, 0.03)],
    UiCue.success: [(659, 0.08), (831, 0.08), (988, 0.08), (1319, 0.18)],
    UiCue.error: [(311, 0.07), (247, 0.12)],
  };

  /// Builds a 16-bit mono WAV of sine blips, each with a 4 ms attack and an
  /// exponential decay so there are no clicks.
  static Uint8List _wav(List<(double, double)> notes) {
    final samples = <int>[];
    for (final (freq, seconds) in notes) {
      final count = (seconds * _sampleRate).round();
      final attack = (0.004 * _sampleRate).round();
      for (var i = 0; i < count; i++) {
        final t = i / _sampleRate;
        final env = math.min(1.0, i / attack) * math.exp(-5 * i / count);
        final v = math.sin(2 * math.pi * freq * t) * env;
        samples.add((v * 0.8 * 32767).round());
      }
    }
    final data = ByteData(44 + samples.length * 2);
    void text(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    text(0, 'RIFF');
    data.setUint32(4, 36 + samples.length * 2, Endian.little);
    text(8, 'WAVEfmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, _sampleRate, Endian.little);
    data.setUint32(28, _sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    text(36, 'data');
    data.setUint32(40, samples.length * 2, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      data.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
