/// Purchasable packs. Store product IDs for each live in
/// `config/monetization_config.dart`.
enum Pack {
  /// Removes interstitials only. Rewarded ads stay available.
  removeAds,
  skins,
  trails,
  themes,
}

/// Snake looks. Purely cosmetic.
enum SnakeSkin {
  classic(null, 'Classic'),
  striped(Pack.skins, 'Striped'),
  dotted(Pack.skins, 'Spotted'),
  hollow(Pack.skins, 'Outline');

  const SnakeSkin(this.pack, this.label);
  final Pack? pack;
  final String label;
}

/// What the tail leaves behind as the snake moves. Purely cosmetic.
enum Trail {
  none(null, 'None'),
  ghost(Pack.trails, 'Ghost'),
  dust(Pack.trails, 'Sparkle');

  const Trail(this.pack, this.label);
  final Pack? pack;
  final String label;
}

/// The look of the whole app. Purely cosmetic.
///
/// [auto] follows the device: [paper] in light mode, [dusk] in dark mode.
/// The [retro] themes switch everything to the monochrome LCD style.
enum BoardTheme {
  auto(null, 'Auto'),
  paper(null, 'Paper'),
  dusk(null, 'Dusk'),
  sage(Pack.themes, 'Sage'),
  sand(Pack.themes, 'Sand'),
  ink(Pack.themes, 'Ink'),
  lime(Pack.themes, 'Lime', retro: true),
  amber(Pack.themes, 'Amber', retro: true),
  ice(Pack.themes, 'Ice', retro: true),
  mono(Pack.themes, 'Mono', retro: true),
  night(Pack.themes, 'Night', retro: true);

  const BoardTheme(this.pack, this.label, {this.retro = false});
  final Pack? pack;
  final String label;
  final bool retro;

  /// The concrete theme to show: [auto] picks by the device's dark mode.
  BoardTheme resolve({required bool systemDark}) =>
      this == auto ? (systemDark ? dusk : paper) : this;
}

/// The player's selected cosmetics.
class Loadout {
  const Loadout({
    this.skin = SnakeSkin.classic,
    this.trail = Trail.none,
    this.theme = BoardTheme.auto,
  });

  final SnakeSkin skin;
  final Trail trail;
  final BoardTheme theme;

  Loadout copyWith({SnakeSkin? skin, Trail? trail, BoardTheme? theme}) => Loadout(
        skin: skin ?? this.skin,
        trail: trail ?? this.trail,
        theme: theme ?? this.theme,
      );

  /// Falls back to the free item for anything the player no longer owns
  /// (e.g. after a refund).
  Loadout restrictTo(Set<Pack> owned) => Loadout(
        skin: skin.pack == null || owned.contains(skin.pack) ? skin : SnakeSkin.classic,
        trail: trail.pack == null || owned.contains(trail.pack) ? trail : Trail.none,
        theme: theme.pack == null || owned.contains(theme.pack) ? theme : BoardTheme.auto,
      );

  Map<String, String> toJson() => {'skin': skin.name, 'trail': trail.name, 'theme': theme.name};

  factory Loadout.fromJson(Map<String, Object?> j) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return Loadout(
      skin: pick(SnakeSkin.values, j['skin'], SnakeSkin.classic),
      trail: pick(Trail.values, j['trail'], Trail.none),
      theme: pick(BoardTheme.values, j['theme'], BoardTheme.auto),
    );
  }
}
