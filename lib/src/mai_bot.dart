import 'package:hive_ce/hive.dart';
import 'package:tg_reg_bot/src/commands/command.dart';
import 'package:teledart/teledart.dart';
import 'package:tg_reg_bot/tg_reg_bot.dart';

final class NoCommand implements Exception {}

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
  String? get state => _state;

  bool _initialized = false;
  bool _working = false;

  String? _state;

  void _init() {
    if (initialized) return;

    // Reg commands
    for (final command in _commands) {
      _teledart.onCommand(command.name).listen((event) {
        _state = command.name;
        command.call(event, _teledart, _db, () {
          _state = null;
        });
      });
    }

    _initialized = true;
    if (autostart) {
      _teledart.start();
      _working = true;
    }
  }

  void playCommand(TeleDartMessage event, {required String name}) {
    final command = _commands.firstWhere(
      (command) => command.name == name,
      orElse: () => throw NoCommand(),
    );
    _state = command.name;
    command.call(event, _teledart, _db, () {
      _state = null;
    });
  }
}
