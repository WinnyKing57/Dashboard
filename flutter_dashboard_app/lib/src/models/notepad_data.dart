import 'package:hive/hive.dart';

part 'notepad_data.g.dart';

@HiveType(typeId: 1) // Unique typeId
class NotepadData extends HiveObject {
  @HiveField(0)
  String content;

  NotepadData({this.content = ''}); // Default content is empty string
}
