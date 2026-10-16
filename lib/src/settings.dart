import 'font.dart';
import 'palette.dart';

enum Direction { horizontal, vertical, diagonal, digit }

enum PixelStyle { solid, led }

class Settings {
  const Settings({
    required this.palette,
    required this.font,
    required this.direction,
    required this.pixel,
    required this.twelveHour,
    required this.showSeconds,
    required this.showDate,
    required this.blink,
    required this.animate,
    required this.paintBackground,
    required this.help,
    required this.list,
    required this.install,
    required this.completion,
  });

  final Palette palette;
  final Font font;
  final Direction direction;
  final PixelStyle pixel;
  final bool twelveHour;
  final bool showSeconds;
  final bool showDate;
  final bool blink;
  final bool animate;
  final bool paintBackground;
  final bool help;
  final bool list;
  final bool install;
  final String? completion;
}

T? _enumByName<T extends Enum>(List<T> values, String name) {
  final String lower = name.toLowerCase();
  for (final T value in values) {
    if (value.name == lower) {
      return value;
    }
  }
  return null;
}

Settings parseArgs(List<String> args) {
  Palette palette = palettes['rainbow']!;
  Font font = fonts['block']!;
  Direction direction = Direction.horizontal;
  PixelStyle pixel = PixelStyle.solid;
  bool twelveHour = false;
  bool showSeconds = true;
  bool showDate = false;
  bool blink = false;
  bool animate = true;
  bool paintBackground = false;
  bool help = false;
  bool list = false;
  bool install = false;
  String? completion;

  int i = 0;
  while (i < args.length) {
    final String raw = args[i];
    final int eq = raw.startsWith('--') ? raw.indexOf('=') : -1;
    final String flag = eq == -1 ? raw : raw.substring(0, eq);
    final String? inline = eq == -1 ? null : raw.substring(eq + 1);

    String value() {
      if (inline != null) {
        return inline;
      }
      if (i + 1 >= args.length) {
        throw FormatException('Missing value for $flag');
      }
      i++;
      return args[i];
    }

    switch (flag) {
      case '-h':
      case '--help':
        help = true;
      case '-l':
      case '--list':
        list = true;
      case '-t':
      case '--12h':
        twelveHour = true;
      case '-n':
      case '--no-seconds':
        showSeconds = false;
      case '-D':
      case '--date':
        showDate = true;
      case '-b':
      case '--blink':
        blink = true;
      case '-s':
      case '--static':
        animate = false;
      case '-B':
      case '--bg':
        paintBackground = true;
      case '-c':
      case '--color':
      case '--theme':
        final String colorName = value();
        final Palette? foundPalette = resolvePalette(colorName);
        if (foundPalette == null) {
          throw FormatException('Unknown color or theme: $colorName');
        }
        palette = foundPalette;
      case '-f':
      case '--font':
        final String fontName = value();
        final Font? foundFont = fonts[fontName.toLowerCase()];
        if (foundFont == null) {
          throw FormatException('Unknown font: $fontName');
        }
        font = foundFont;
      case '-d':
      case '--direction':
        final String directionName = value();
        final Direction? foundDirection = _enumByName(
          Direction.values,
          directionName,
        );
        if (foundDirection == null) {
          throw FormatException('Unknown direction: $directionName');
        }
        direction = foundDirection;
      case '-p':
      case '--pixel':
        final String pixelName = value();
        final PixelStyle? foundPixel = _enumByName(
          PixelStyle.values,
          pixelName,
        );
        if (foundPixel == null) {
          throw FormatException('Unknown pixel style: $pixelName');
        }
        pixel = foundPixel;
      case '--install':
        install = true;
      case '--completion':
        final String shellName = value().toLowerCase();
        if (shellName != 'bash' && shellName != 'zsh') {
          throw FormatException('Unknown shell: $shellName (use bash or zsh)');
        }
        completion = shellName;
      default:
        throw FormatException('Unknown option: $raw');
    }
    i++;
  }

  return Settings(
    palette: palette,
    font: font,
    direction: direction,
    pixel: pixel,
    twelveHour: twelveHour,
    showSeconds: showSeconds,
    showDate: showDate,
    blink: blink,
    animate: animate,
    paintBackground: paintBackground,
    help: help,
    list: list,
    install: install,
    completion: completion,
  );
}

String describeChoices() {
  final StringBuffer out = StringBuffer();
  out.writeln('Colors and themes (-c):');
  out.writeln('  ${palettes.keys.join(', ')}');
  out.writeln('  or any hex color such as #ff8800 or f80');
  out.writeln('  aliases: catppuccin, catppuccin-latte, tokyo-night, ...');
  out.writeln();
  out.writeln('Fonts (-f):');
  out.writeln('  ${fonts.keys.join(', ')}');
  out.writeln();
  out.writeln('Directions (-d):');
  out.writeln('  ${Direction.values.map((Direction d) => d.name).join(', ')}');
  out.writeln();
  out.writeln('Pixel styles (-p):');
  out.write('  ${PixelStyle.values.map((PixelStyle p) => p.name).join(', ')}');
  return out.toString();
}
