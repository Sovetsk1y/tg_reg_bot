import 'package:hive_ce/hive.dart';
import 'package:tg_reg_bot/src/commands/command.dart';
import 'package:tg_reg_bot/src/user.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';

/// Registers user to a [User] model and outputs a msg.
final class DefaultStartCommand extends MaiCommand {
  final String msg;

  DefaultStartCommand({required this.msg});

  @override
  Future<void> call(
    TeleDartMessage event,
    TeleDart teledart,
    BoxCollection db,
  ) async {
    super.call(event, teledart, db);
    final box = Hive.box<MaiUser>('users');
    final userId = event.chat.id;
    final user = box.get(userId);
    if (user == null) {
      box.put(
        userId.toString(),
        MaiUser(
          id: userId,
          username: event.chat.username,
          name: _name(event.chat),
        ),
      );
      teledart.sendMessage(event.chat.id, msg);
    } else {
      teledart.sendMessage(event.chat.id, msg);
    }
  }

  @override
  String get name => 'start';

  String _name(Chat chat) {
    String name = '';
    if (chat.firstName?.isNotEmpty ?? false) {
      name += chat.firstName!;
    }
    if ((chat.lastName?.isNotEmpty ?? false)) {
      if (name.isNotEmpty) {
        name += ' ${chat.lastName}';
      } else {
        name += chat.lastName!;
      }
    }
    return name;
  }

  @override
  List<String>? get allowedUsers => null;

  @override
  bool Function(TeleDartMessage event, TeleDart teledart, BoxCollection db)?
      get allowCondition => null;
}
