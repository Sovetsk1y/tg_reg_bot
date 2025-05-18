import 'dart:async';

import 'package:hive_ce/hive.dart' show BoxCollection;
import 'package:tg_reg_bot/src/commands/command.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';

class InputCommandState {
  final String msg;
  // Name of field in db model
  final String fieldName;
  final String? Function(TeleDartMessage event) validate;
  final bool Function(Map<String, dynamic> model)? skip;

  InputCommandState({
    required this.msg,
    required this.fieldName,
    required this.validate,
    this.skip,
  });
}

base class StateCommand extends MaiCommand {
  late final List<InputCommandState> _states;

  final _userModels = <String, Map<String, dynamic>>{};

  final void Function(
    String chatId,
    Map<String, dynamic> model,
    TeleDart teledart,
  ) stateCompleter;
  @override
  final String name;
  final String? initialText;
  final String? finalText;

  @override
  final bool Function(
          TeleDartMessage event, TeleDart teledart, BoxCollection db)?
      allowCondition;

  @override
  final List<String>? allowedUsers;

  StateCommand(
    this._states, {
    required this.name,
    required this.stateCompleter,
    this.allowCondition,
    this.allowedUsers,
    this.initialText,
    this.finalText,
  }) : assert(
          _states.isNotEmpty,
          'Initialize states array with non-empty array',
        );

  final Map<int, InputCommandState> _current = {};
  StreamSubscription? _userOnMessageSubscription;
  StreamSubscription? _userOnPhoneNumberSubscription;
  StreamSubscription? _userOnEmailSubscription;

  @override
  Future<void> call(
    TeleDartMessage event,
    TeleDart teledart,
    BoxCollection db,
    void Function() onFinish,
  ) async {
    try {
      await super.call(event, teledart, db, onFinish);
      final chatId = event.chat.id;
      if (_userOnMessageSubscription == null &&
          _userOnEmailSubscription == null &&
          _userOnPhoneNumberSubscription == null) {
        _userOnMessageSubscription = teledart
            .onMessage()
            .listen((event) => _eventHandler(event, teledart, onFinish));
        _userOnPhoneNumberSubscription = teledart
            .onPhoneNumber()
            .listen((event) => _eventHandler(event, teledart, onFinish));
        _userOnEmailSubscription = teledart
            .onEmail()
            .listen((event) => _eventHandler(event, teledart, onFinish));
      }

      // Send initial text if exists
      if (initialText != null) {
        teledart.sendMessage(event.chat.id, initialText ?? '');
      }

      _current[chatId] = _states.first;
      teledart.sendMessage(event.chat.id, _states.first.msg);
    } on NoRights {
      return;
    }
  }

  Future<void> _eventHandler(
    TeleDartMessage event,
    TeleDart teledart,
    void Function() onFinish,
  ) async {
    final chatId = event.chat.id;
    if (_current[chatId] == null) return;
    final errMsg = _current[chatId]!.validate(event);
    if (errMsg == null) {
      if (_userModels[chatId.toString()] == null) {
        _userModels[chatId.toString()] = {};
      }
      _userModels[chatId.toString()]?[_current[chatId]!.fieldName] = event.text;
      _nextState(teledart, event, onFinish);
    } else {
      teledart.sendMessage(chatId, errMsg);
    }
  }

  void _nextState(
    TeleDart teledart,
    TeleDartMessage event,
    void Function() onFinish,
  ) {
    final chatId = event.chat.id;
    if (_current[chatId] == null) return;
    final currState = _current[chatId]!;
    final currIndex = _states.indexOf(currState);
    if (currIndex + 1 < _states.length) {
      _current[chatId] = _states[currIndex + 1];
      if (_current[chatId]?.skip != null &&
          _current[chatId]!.skip!(_userModels[chatId.toString()] ?? {})) {
        return _nextState(teledart, event, onFinish);
      }
      teledart.sendMessage(chatId, _current[chatId]!.msg);
    } else {
      _current.remove(chatId);
      stateCompleter(
        chatId.toString(),
        _userModels[chatId.toString()] ?? {},
        teledart,
      );
      onFinish();
      _userModels[chatId.toString()] = {};
      if (finalText != null) teledart.sendMessage(chatId, finalText!);
    }
  }
}
