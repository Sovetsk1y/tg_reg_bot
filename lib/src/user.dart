import 'package:hive_ce/hive.dart';

class MaiUser extends HiveObject {
  final int id;
  final String? username;
  String? name;

  MaiUser({
    required this.id,
    required this.username,
    this.name,
  });
}
