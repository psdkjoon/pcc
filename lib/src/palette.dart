import 'color.dart';

class Palette {
  const Palette(
    this.name,
    this.stops, {
    this.background,
    this.rainbow = false,
  });

  final String name;
  final List<Rgb> stops;
  final Rgb? background;
  final bool rainbow;

  Rgb at(double t) {
    final double wrapped = t % 1.0;
    if (rainbow) {
      return hsvToRgb(wrapped, 0.85, 1.0);
    }
    if (stops.length == 1) {
      return stops.first;
    }
    final double pos = wrapped * stops.length;
    final int i = pos.floor() % stops.length;
    final double f = pos - pos.floor();
    final Rgb a = stops[i];
    final Rgb b = stops[(i + 1) % stops.length];
    return Rgb(_mix(a.r, b.r, f), _mix(a.g, b.g, f), _mix(a.b, b.b, f));
  }
}

int _mix(int a, int b, double f) => (a + (b - a) * f).round();

Palette _solid(String name, int hex) => Palette(name, <Rgb>[Rgb.hex(hex)]);

Palette _gradient(String name, List<int> hexes, {int? background}) {
  return Palette(
    name,
    <Rgb>[for (final int h in hexes) Rgb.hex(h)],
    background: background == null ? null : Rgb.hex(background),
  );
}

final List<Palette> _all = <Palette>[
  const Palette('rainbow', <Rgb>[Rgb(255, 0, 0)], rainbow: true),
  _gradient(
    'mocha',
    <int>[
      0xf38ba8,
      0xfab387,
      0xf9e2af,
      0xa6e3a1,
      0x94e2d5,
      0x89dceb,
      0x89b4fa,
      0xb4befe,
      0xcba6f7,
      0xf5c2e7,
    ],
    background: 0x1e1e2e,
  ),
  _gradient(
    'macchiato',
    <int>[
      0xed8796,
      0xf5a97f,
      0xeed49f,
      0xa6da95,
      0x8bd5ca,
      0x91d7e3,
      0x8aadf4,
      0xb7bdf8,
      0xc6a0f6,
      0xf5bde6,
    ],
    background: 0x24273a,
  ),
  _gradient(
    'frappe',
    <int>[
      0xe78284,
      0xef9f76,
      0xe5c890,
      0xa6d189,
      0x81c8be,
      0x99d1db,
      0x8caaee,
      0xbabbf1,
      0xca9ee6,
      0xf4b8e4,
    ],
    background: 0x303446,
  ),
  _gradient(
    'latte',
    <int>[
      0xd20f39,
      0xfe640b,
      0xdf8e1d,
      0x40a02b,
      0x179299,
      0x04a5e5,
      0x1e66f5,
      0x7287fd,
      0x8839ef,
      0xea76cb,
    ],
    background: 0xeff1f5,
  ),
  _gradient(
    'nord',
    <int>[
      0xbf616a,
      0xd08770,
      0xebcb8b,
      0xa3be8c,
      0x8fbcbb,
      0x88c0d0,
      0x81a1c1,
      0x5e81ac,
      0xb48ead,
    ],
    background: 0x2e3440,
  ),
  _gradient(
    'dracula',
    <int>[0xff5555, 0xffb86c, 0xf1fa8c, 0x50fa7b, 0x8be9fd, 0xbd93f9, 0xff79c6],
    background: 0x282a36,
  ),
  _gradient(
    'gruvbox',
    <int>[0xfb4934, 0xfe8019, 0xfabd2f, 0xb8bb26, 0x8ec07c, 0x83a598, 0xd3869b],
    background: 0x282828,
  ),
  _gradient(
    'tokyonight',
    <int>[
      0xf7768e,
      0xff9e64,
      0xe0af68,
      0x9ece6a,
      0x73daca,
      0x7dcfff,
      0x7aa2f7,
      0xbb9af7,
    ],
    background: 0x1a1b26,
  ),
  _gradient('fire', <int>[0xff2d00, 0xff6a00, 0xffb300, 0xff6a00]),
  _gradient('ocean', <int>[0x0077b6, 0x00b4d8, 0x90e0ef, 0x00b4d8]),
  _gradient(
    'sunset',
    <int>[0xff5e5b, 0xff9966, 0xffcc70, 0xc779d0, 0x4e54c8],
  ),
  _gradient('forest', <int>[0x2d6a4f, 0x52b788, 0xb7e4c7, 0x52b788]),
  _gradient('neon', <int>[0xff2bd6, 0x00f0ff, 0x39ff14]),
  _solid('red', 0xff3b30),
  _solid('orange', 0xff9500),
  _solid('yellow', 0xffd60a),
  _solid('green', 0x34c759),
  _solid('cyan', 0x64d2ff),
  _solid('blue', 0x0a84ff),
  _solid('purple', 0xbf5af2),
  _solid('pink', 0xff375f),
  _solid('white', 0xffffff),
];

final Map<String, Palette> palettes = <String, Palette>{
  for (final Palette p in _all) p.name: p,
};

const Map<String, String> _aliases = <String, String>{
  'catppuccin': 'mocha',
  'catppuccin-mocha': 'mocha',
  'catppuccin-macchiato': 'macchiato',
  'catppuccin-frappe': 'frappe',
  'catppuccin-latte': 'latte',
  'tokyo-night': 'tokyonight',
  'violet': 'purple',
};

final List<String> colorNames = <String>[
  ...palettes.keys,
  ..._aliases.keys,
];

Rgb? parseHex(String text) {
  String s = text.startsWith('#') ? text.substring(1) : text;
  if (s.length == 3) {
    s = s.split('').map((String ch) => ch + ch).join();
  }
  if (s.length != 6) {
    return null;
  }
  final int? value = int.tryParse(s, radix: 16);
  return value == null ? null : Rgb.hex(value);
}

Palette? resolvePalette(String input) {
  final String key = input.trim().toLowerCase().replaceAll('_', '-');
  final Palette? found = palettes[_aliases[key] ?? key];
  if (found != null) {
    return found;
  }
  final Rgb? rgb = parseHex(key);
  if (rgb == null) {
    return null;
  }
  return Palette('custom', <Rgb>[rgb]);
}
