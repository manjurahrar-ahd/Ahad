import 'package:flutter/material.dart';
import 'storage.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String info;
  const ComingSoonScreen({super.key, required this.title, required this.info});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(info,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _rename() async {
    final ctrl = TextEditingController(text: Store.name);
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Player name'),
        content: TextField(
          controller: ctrl,
          maxLength: 12,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      Store.name = result;
      setState(() {});
    }
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 16, color: Colors.white70)),
            Text(v,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFF4CFFA0),
              child: Text(
                Store.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    fontSize: 38, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _rename,
              icon: const Icon(Icons.edit),
              label: Text(Store.name, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const Divider(height: 32),
          _row('Character', Store.character),
          _row('Coins', '${Store.coins}'),
          _row('Total kills', '${Store.kills}'),
          _row('Total deaths', '${Store.deaths}'),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset local data?'),
        content: const Text('Coins, kills, deaths aur settings sab mit jayenge.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) {
      await Store.resetAll();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Music'),
            value: Store.music,
            onChanged: (v) => setState(() => Store.music = v),
          ),
          SwitchListTile(
            title: const Text('Sound'),
            value: Store.sound,
            onChanged: (v) => setState(() => Store.sound = v),
          ),
          _slider('SFX volume', Store.sfxVolume, 0, 1, (v) => Store.sfxVolume = v),
          _slider('Control sensitivity', Store.moveSens, 0.5, 1.5, (v) => Store.moveSens = v),
          _slider('Aim sensitivity', Store.aimSens, 0.5, 1.5, (v) => Store.aimSens = v),
          ListTile(
            title: const Text('Graphics quality'),
            trailing: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Low')),
                ButtonSegment(value: 1, label: Text('Med')),
                ButtonSegment(value: 2, label: Text('High')),
              ],
              selected: {Store.graphics},
              onSelectionChanged: (s) => setState(() => Store.graphics = s.first),
            ),
          ),
          const ListTile(
            title: Text('Character skills'),
            subtitle: Text(
                'Skill 15 second chalti hai, phir 30 second recharge. Host match se pehle Skills ON/OFF karta hai.'),
          ),
          ListTile(
            title: const Text('Reset local data'),
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onTap: _reset,
          ),
          const ListTile(
            title: Text('About'),
            subtitle: Text('Arena Dash v1.0.0 - original 2D arena shooter'),
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max,
      void Function(double) onSave) {
    return ListTile(
      title: Text(label),
      subtitle: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: (v) => setState(() => onSave(v)),
      ),
    );
  }
}
