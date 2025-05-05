import 'package:hive_ce/hive.dart';
import 'package:tg_reg_bot/src/commands/command.dart';
import 'package:teledart/teledart.dart';

final class MaiBot {
  final bool autostart;
  final List<MaiCommand> _commands;
  final TeleDart _teledart;
  final BoxCollection _db;

  MaiBot(
    this._teledart,
    this._db,
    this._commands, {
    this.autostart = true,
  }) {
    _init();
  }

  bool get working => _working;
  bool get initialized => _initialized;

  bool _initialized = false;
  bool _working = false;

  void _init() {
    if (initialized) return;

    // Reg commands
    for (final command in _commands) {
      _teledart.onCommand(command.name).listen((event) {
        command.call(event, _teledart, _db);
      });
    }

    _initialized = true;
    if (autostart) {
      _teledart.start();
      _working = true;
    }
  }
}
