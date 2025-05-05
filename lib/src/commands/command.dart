import 'package:hive_ce/hive.dart';
import 'package:meta/meta.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';

final class NoRights implements Exception {}

abstract base class MaiCommand {
  String get name;

  /// Если == null, то команда доступна всем пользователям.
  /// Если значение != null, то команда доступна только тем юзенеймам, которые
  /// указано в массиве.
  List<String>? get allowedUsers;

  /// Если возвращает [true], значит команда будет работать. Если [false], то
  /// команда никак не отреагирует на вызов.
  bool Function(TeleDartMessage event, TeleDart teledart, BoxCollection db)?
      get allowCondition;

  @mustCallSuper
  Future<void> call(
    TeleDartMessage event,
    TeleDart teledart,
    BoxCollection db,
  ) async {
    if (allowCondition?.call(event, teledart, db) == false) throw NoRights();
    if (allowedUsers != null) {
      if (!allowedUsers!.contains(event.chat.username)) {
        throw NoRights();
      }
    }
  }
}

sealed class Output {}

class TextOutput extends Output {
  final String text;

  TextOutput(this.text);
}

class FileOutput extends Output {
  final File file;

  FileOutput(this.file);
}

final class OutputCommand extends MaiCommand {
  @override
  final String name;

  final Output output;

  @override
  final List<String>? allowedUsers;

  @override
  final bool Function(
          TeleDartMessage event, TeleDart teledart, BoxCollection db)?
      allowCondition;

  OutputCommand({
    required this.name,
    required this.output,
    this.allowedUsers,
    this.allowCondition,
  });

  @override
  Future<void> call(TeleDartMessage event, TeleDart teledart, _) async {
    super.call(event, teledart, _);
    switch (output) {
      case TextOutput():
        await teledart.sendMessage(event.chat.id, (output as TextOutput).text);
      case FileOutput():
        await teledart.sendDocument(event.chat.id, (output as FileOutput).file);
    }
  }
}

final class CustomCommand extends MaiCommand {
  @override
  final String name;

  @override
  final List<String>? allowedUsers;

  @override
  final bool Function(
          TeleDartMessage event, TeleDart teledart, BoxCollection db)?
      allowCondition;

  final Future<void> Function(
      TeleDartMessage event, TeleDart teledart, BoxCollection db) callback;

  CustomCommand({
    required this.name,
    required this.callback,
    this.allowCondition,
    this.allowedUsers,
  });

  @override
  Future<void> call(
      TeleDartMessage event, TeleDart teledart, BoxCollection db) async {
    super.call(event, teledart, db);
    return callback(event, teledart, db);
  }
}
