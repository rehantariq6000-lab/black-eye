/// A saved settings preset.
///
/// A shortcut remembers which detection categories are on and which masking
/// style to use, under a name the user chooses — so a whole configuration can
/// be applied in one tap instead of setting each option every time.
class Shortcut {
  final String name;
  final List<String> categoryKeys;
  final int maskStyleIndex;

  const Shortcut({
    required this.name,
    required this.categoryKeys,
    required this.maskStyleIndex,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'keys': categoryKeys,
        'style': maskStyleIndex,
      };

  factory Shortcut.fromJson(Map<String, dynamic> json) => Shortcut(
        name: json['name'] as String,
        categoryKeys:
            (json['keys'] as List).map((e) => e as String).toList(),
        maskStyleIndex: json['style'] as int,
      );
}
