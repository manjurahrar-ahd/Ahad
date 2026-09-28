import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'storage.dart';

/// Sab awaaz code se banti hai (koi audio file nahi).
class Sfx {
  static const int rate = 22050;
  static final Map<String, Uint8List> _cache = {};
  static final List<AudioPlayer> _pool = [];
  static int _next = 0;
  static AudioPlayer? _music;
  static String? _musicName;

  static Future<void> init() async {
    for (int i = 0; i < 8; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      _pool.add(p);
    }
    _cache['step'] = _wav(_tone(0.08, 90, 60, decay: 8, vol: 0.6, noise: 0.8));
    _cache['jump'] = _wav(_tone(0.16, 300, 650, decay: 5, vol: 0.4));
    _cache['land'] = _wav(_tone(0.09, 70, 40, decay: 9, vol: 0.6, noise: 0.5));
    _cache['shoot'] = _wav(_tone(0.25, 220, 50, decay: 9, vol: 0.8, noise: 0.6));
    _cache['explosion'] =
        _wav(_tone(0.7, 90, 30, decay: 4, vol: 0.9, noise: 0.85));
    _cache['click'] = _wav(_tone(0.05, 900, 700, decay: 10, vol: 0.3));
    _cache['hit'] = _wav(_tone(0.1, 180, 120, decay: 8, vol: 0.6, noise: 0.6));
    _cache['death'] = _wav(_tone(0.5, 300, 60, decay: 4, vol: 0.5, noise: 0.1));
    _cache['pickup'] = _wav([
      ..._tone(0.07, 600, 600, decay: 3, vol: 0.35),
      ..._tone(0.12, 900, 900, decay: 5, vol: 0.35),
    ]);
    final click = _tone(0.03, 1200, 800, decay: 8, vol: 0.4, noise: 0.5);
    _cache['reload'] = _wav([
      ...click,
      ...List<double>.filled((0.12 * rate).round(), 0.0),
      ...click,
    ]);
    WidgetsBinding.instance.addObserver(_Lifecycle());
  }

  static Future<void> play(String name) async {
    if (!Store.sound || _pool.isEmpty) return;
    final b = _cache[name];
    if (b == null) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await p.play(BytesSource(b), volume: Store.sfxVolume);
    } catch (_) {}
  }

  static Future<void> playMusic(String track) async {
    if (!Store.music) {
      await stopMusic();
      return;
    }
    if (_musicName == track) return;
    _musicName = track;
    try {
      _music ??= AudioPlayer();
      await _music!.setReleaseMode(ReleaseMode.loop);
      final bytes = _cache.putIfAbsent(
        'music_$track',
        () => track == 'game'
            ? _musicTrack(140, [98, 98, 116.5, 110])
            : _musicTrack(96, [110, 130.8, 98, 123.5]),
      );
      await _music!.play(BytesSource(bytes), volume: 0.35);
    } catch (_) {}
  }

  static Future<void> stopMusic() async {
    _musicName = null;
    try {
      await _music?.stop();
    } catch (_) {}
  }

  // ---- awaaz banane ke helpers ----

  static List<double> _tone(double dur, double f0, double f1,
      {double decay = 6, double vol = 0.5, double noise = 0}) {
    final n = (dur * rate).round();
    final rnd = Random(7);
    final out = List<double>.filled(n, 0);
    double phase = 0;
    double lp = 0;
    for (int i = 0; i < n; i++) {
      final t = i / n;
      final f = f0 + (f1 - f0) * t;
      phase += 2 * pi * f / rate;
      final env = exp(-decay * t);
      final nz = rnd.nextDouble() * 2 - 1;
      lp += (nz - lp) * 0.3;
      out[i] = (sin(phase) * (1 - noise) + lp * noise) * env * vol;
    }
    return out;
  }

  static Uint8List _musicTrack(int bpm, List<double> bass) {
    final beat = 60.0 / bpm;
    const beats = 16;
    final total = (beats * beat * rate).round();
    final out = List<double>.filled(total, 0);
    void add(List<double> s, int start) {
      for (int i = 0; i < s.length && start + i < total; i++) {
        out[start + i] += s[i];
      }
    }

    final kick = _tone(0.15, 120, 45, decay: 9, vol: 0.6);
    final hat = _tone(0.05, 0, 0, decay: 12, vol: 0.2, noise: 1);
    for (int b = 0; b < beats; b++) {
      final start = (b * beat * rate).round();
      if (b % 2 == 0) add(kick, start);
      add(hat, start + (beat * rate / 2).round());
      final f = bass[(b ~/ 4) % bass.length];
      add(_tone(beat * 0.9, f, f, decay: 2.5, vol: 0.25), start);
    }
    return _wav(out);
  }

  static Uint8List _wav(List<double> s) {
    final n = s.length;
    final data = ByteData(44 + n * 2);
    void str(int o, String t) {
      for (int i = 0; i < t.length; i++) {
        data.setUint8(o + i, t.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (int i = 0; i < n; i++) {
      data.setInt16(44 + i * 2, (s[i].clamp(-1.0, 1.0) * 32000).round(),
          Endian.little);
    }
    return data.buffer.asUint8List();
  }
}

class _Lifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      Sfx._music?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (Sfx._musicName != null && Store.music) Sfx._music?.resume();
    }
  }
}
