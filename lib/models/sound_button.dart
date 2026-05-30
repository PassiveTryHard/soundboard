import 'package:hive_flutter/hive_flutter.dart';

part 'sound_button.g.dart'; // Hive generates this file automatically

@HiveType(typeId: 0) // Tells Hive this is a storable object
class SoundButton extends HiveObject {
  @HiveField(0)
  late String id; // Unique identifier for each button

  @HiveField(1)
  late String label; // The name shown on the button

  @HiveField(2)
  late String audioFilePath; // Where the audio file lives on the device

  @HiveField(3)
  late int color; // Stored as an integer (Flutter colors are just numbers)

  @HiveField(4)
  late DateTime createdAt; // When the button was created, used for sorting

  @HiveField(5)
  String? categoryId; // Null for now — used later when we add categories

  @HiveField(6)
  bool isFavorite; // For a favorites feature later

  SoundButton({
    required this.id,
    required this.label,
    required this.audioFilePath,
    required this.color,
    required this.createdAt,
    this.categoryId,
    this.isFavorite = false,
  });
}