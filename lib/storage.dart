import 'package:shared_preferences/shared_preferences.dart';

/// Local storage: guest profile + settings. No internet, no login.
class Store {
  static late SharedPreferences _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    if (!_p.containsKey('name')) {
      final id = 1000 + DateTime.now().millisecondsSinceEpoch % 9000;
      await _p.setString('name', 'Guest$id');
    }
  }

  // Profile
  static String get name => _p.getString('name') ?? 'Guest';
  static set name(String v) => _p.setString('name', v);
  static int get coins => _p.getInt('coins') ?? 0;
  static set coins(int v) => _p.setInt('coins', v);
  static int get kills => _p.getInt('kills') ?? 0;
  static set kills(int v) => _p.setInt('kills', v);
  static int get deaths => _p.getInt('deaths') ?? 0;
  static set deaths(int v) => _p.setInt('deaths', v);
  static String get character => _p.getString('character') ?? 'BASE';
  static set character(String v) => _p.setString('character', v);

  // Settings
  static bool get music => _p.getBool('music') ?? true;
  static set music(bool v) => _p.setBool('music', v);
  static bool get sound => _p.getBool('sound') ?? true;
  static set sound(bool v) => _p.setBool('sound', v);
  static double get sfxVolume => _p.getDouble('sfx') ?? 0.8;
  static set sfxVolume(double v) => _p.setDouble('sfx', v);
  static double get moveSens => _p.getDouble('moveSens') ?? 1.0;
  static set moveSens(double v) => _p.setDouble('moveSens', v);
  static double get aimSens => _p.getDouble('aimSens') ?? 1.0;
  static set aimSens(double v) => _p.setDouble('aimSens', v);
  static int get graphics => _p.getInt('gfx') ?? 1; // 0 low, 1 medium, 2 high
  static set graphics(int v) => _p.setInt('gfx', v);

  static Future<void> resetAll() async {
    await _p.clear();
    await init();
  }
}
