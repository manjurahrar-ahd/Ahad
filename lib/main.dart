import 'package:flutter/material.dart';
import 'storage.dart';
import 'sound.dart';
import 'screens.dart';
import 'training.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  try {
    await Sfx.init();
    Sfx.playMusic('menu');
  } catch (_) {}
  runApp(const ArenaApp());
}

class ArenaApp extends StatelessWidget {
  const ArenaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arena Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF10131C),
      ),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _go(BuildContext c, Widget w) {
    Sfx.play('click');
    Navigator.push(c, MaterialPageRoute(builder: (_) => w));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Text(
                  'ARENA DASH',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Color(0xFF4CFFA0),
                  ),
                ),
                const SizedBox(height: 32),
                _btn(context, 'PLAY', Icons.play_arrow,
                    () => _go(context, const ComingSoonScreen(
                        title: 'PLAY', info: 'LAN Host / Join Phase 4 mein aayega.'))),
                _btn(context, 'CHARACTERS', Icons.person,
                    () => _go(context, const ComingSoonScreen(
                        title: 'CHARACTERS', info: 'Characters Phase 7 mein aayenge.'))),
                _btn(context, 'PROFILE', Icons.badge,
                    () => _go(context, const ProfileScreen())),
                _btn(context, 'TRAINING', Icons.fitness_center,
                    () => _go(context, const TrainingScreen())),
                _btn(context, 'SETTINGS', Icons.settings,
                    () => _go(context, const SettingsScreen())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(BuildContext c, String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: 280,
        height: 56,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
