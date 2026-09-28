import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'storage.dart';
import 'sound.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with SingleTickerProviderStateMixin {
  static const double worldW = 1800;
  static const double worldH = 500;
  static const double pw = 26;
  static const double ph = 44;

  final List<Rect> platforms = [
    const Rect.fromLTWH(0, 460, worldW, 40), // ground
    const Rect.fromLTWH(250, 370, 160, 16),
    const Rect.fromLTWH(480, 290, 160, 16),
    const Rect.fromLTWH(760, 370, 200, 16),
    const Rect.fromLTWH(1040, 300, 160, 16),
    const Rect.fromLTWH(1300, 220, 180, 16),
    const Rect.fromLTWH(1480, 380, 120, 16),
  ];

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  Offset pos = const Offset(60, 400);
  double vx = 0, vy = 0;
  bool onGround = false;
  bool wasOnGround = false;
  bool left = false, right = false, jump = false, fire = false;
  double stepTimer = 0, fireTimer = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    Sfx.playMusic('game');
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    Sfx.playMusic('menu');
    super.dispose();
  }

  void _tick(Duration elapsed) {
    double dt = (elapsed - _last).inMicroseconds / 1000000.0;
    _last = elapsed;
    if (dt > 0.05) dt = 0.05;
    if (dt <= 0) return;

    final dir = (right ? 1 : 0) - (left ? 1 : 0);
    vx = dir * 230 * Store.moveSens;
    if (jump && onGround) {
      vy = -560;
      onGround = false;
      Sfx.play('jump');
    }
    vy = min(vy + 1400 * dt, 900);
    final impact = vy;

    // Horizontal move + collision
    double nx = pos.dx + vx * dt;
    Rect r = Rect.fromLTWH(nx, pos.dy, pw, ph);
    for (final p in platforms) {
      if (r.overlaps(p)) {
        if (vx > 0) nx = p.left - pw;
        if (vx < 0) nx = p.right;
        r = Rect.fromLTWH(nx, pos.dy, pw, ph);
      }
    }
    nx = nx.clamp(0.0, worldW - pw);

    // Vertical move + collision
    double ny = pos.dy + vy * dt;
    onGround = false;
    r = Rect.fromLTWH(nx, ny, pw, ph);
    for (final p in platforms) {
      if (r.overlaps(p)) {
        if (vy > 0) {
          ny = p.top - ph;
          onGround = true;
        } else if (vy < 0) {
          ny = p.bottom;
        }
        vy = 0;
        r = Rect.fromLTWH(nx, ny, pw, ph);
      }
    }

    pos = Offset(nx, ny);
    if (pos.dy > worldH + 200) {
      pos = const Offset(60, 400);
      vy = 0;
    }

    // Sounds
    if (onGround && !wasOnGround && impact > 250) Sfx.play('land');
    wasOnGround = onGround;
    stepTimer += dt;
    if (dir != 0 && onGround && stepTimer > 0.28) {
      Sfx.play('step');
      stepTimer = 0;
    }
    fireTimer += dt;
    if (fire && fireTimer > 0.15) {
      Sfx.play('shoot');
      fireTimer = 0;
    }

    setState(() {});
  }

  Widget _btn(IconData icon, void Function(bool) onChange) {
    return Listener(
      onPointerDown: (_) => onChange(true),
      onPointerUp: (_) => onChange(false),
      onPointerCancel: (_) => onChange(false),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0x55FFFFFF),
          borderRadius: BorderRadius.circular(38),
        ),
        child: Icon(icon, size: 36, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TrainingPainter(pos, platforms, worldW, worldH, pw, ph),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          const Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: Center(
              child: Text('TRAINING - chalo, kudo, FIRE aur GRENADE dabao',
                  style: TextStyle(color: Colors.white70)),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: Row(children: [
              _btn(Icons.arrow_left, (v) => left = v),
              const SizedBox(width: 16),
              _btn(Icons.arrow_right, (v) => right = v),
            ]),
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: Row(children: [
              _btn(Icons.local_fire_department, (v) => fire = v),
              const SizedBox(width: 12),
              _btn(Icons.circle, (v) {
                if (v) Sfx.play('explosion');
              }),
              const SizedBox(width: 12),
              _btn(Icons.keyboard_arrow_up, (v) => jump = v),
            ]),
          ),
        ],
      ),
    );
  }
}

class _TrainingPainter extends CustomPainter {
  final Offset pos;
  final List<Rect> platforms;
  final double worldW, worldH, pw, ph;
  _TrainingPainter(this.pos, this.platforms, this.worldW, this.worldH, this.pw, this.ph);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / worldH;
    final viewW = size.width / scale;
    final camX = (pos.dx + pw / 2 - viewW / 2).clamp(0.0, max(0.0, worldW - viewW));

    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF16203A));
    canvas.save();
    canvas.scale(scale);
    canvas.translate(-camX.toDouble(), 0.0);

    final p = Paint()..color = const Color(0xFF3C4A6B);
    for (final r in platforms) {
      canvas.drawRect(r, p);
    }
    // Player
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx, pos.dy, pw, ph), const Radius.circular(6)),
      Paint()..color = const Color(0xFF4CFFA0),
    );
    canvas.drawCircle(Offset(pos.dx + pw / 2, pos.dy + 12), 4, Paint()..color = Colors.black);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrainingPainter old) => true;
}
