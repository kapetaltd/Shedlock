/// Player preferences.
class GameSettings {
  const GameSettings({this.sound = true, this.haptics = true, this.screenShake = true});

  final bool sound;
  final bool haptics;

  /// Off for players sensitive to motion.
  final bool screenShake;

  GameSettings copyWith({bool? sound, bool? haptics, bool? screenShake}) => GameSettings(
        sound: sound ?? this.sound,
        haptics: haptics ?? this.haptics,
        screenShake: screenShake ?? this.screenShake,
      );

  Map<String, bool> toJson() => {'sound': sound, 'haptics': haptics, 'shake': screenShake};

  factory GameSettings.fromJson(Map<String, Object?> j) => GameSettings(
        sound: j['sound'] as bool? ?? true,
        haptics: j['haptics'] as bool? ?? true,
        screenShake: j['shake'] as bool? ?? true,
      );
}
