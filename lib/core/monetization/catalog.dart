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
  classic(null, 'CLASSIC'),
  striped(Pack.skins, 'STRIPED'),
  dotted(Pack.skins, 'DOTTED'),
  hollow(Pack.skins, 'HOLLOW');

  const SnakeSkin(this.pack, this.label);
  final Pack? pack;
  final String label;
}

/// What the tail leaves behind as the snake moves. Purely cosmetic.
enum Trail {
  none(null, 'NONE'),
  ghost(Pack.trails, 'GHOST'),
  dust(Pack.trails, 'PIXEL DUST');

  const Trail(this.pack, this.label);
  final Pack? pack;
  final String label;
}

/// Screen colours. Purely cosmetic.
enum BoardTheme {
  lime(null, 'LIME LCD'),
  amber(Pack.themes, 'AMBER'),
  ice(Pack.themes, 'ICE'),
  mono(Pack.themes, 'MONO'),
  night(Pack.themes, 'NIGHT');

  const BoardTheme(this.pack, this.label);
  final Pack? pack;
  final String label;
}

/// The player's selected cosmetics.
class Loadout {
  const Loadout({
    this.skin = SnakeSkin.classic,
    this.trail = Trail.none,
    this.theme = BoardTheme.lime,
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
        theme: theme.pack == null || owned.contains(theme.pack) ? theme : BoardTheme.lime,
      );

  Map<String, String> toJson() => {'skin': skin.name, 'trail': trail.name, 'theme': theme.name};

  factory Loadout.fromJson(Map<String, Object?> j) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return Loadout(
      skin: pick(SnakeSkin.values, j['skin'], SnakeSkin.classic),
      trail: pick(Trail.values, j['trail'], Trail.none),
      theme: pick(BoardTheme.values, j['theme'], BoardTheme.lime),
    );
  }
}
