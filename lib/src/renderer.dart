import 'dart:math' as math;

import 'color.dart';
import 'font.dart';
import 'palette.dart';
import 'settings.dart';

const List<String> _weekdays = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class ClockRenderer {
  ClockRenderer({required this.settings, required this.trueColor});

  final Settings settings;
  final bool trueColor;

  Palette get _palette => settings.palette;

  late final String base = _computeBase();

  String get clearSequence => '$base\x1b[2J';

  String _computeBase() {
    final Rgb? bg = settings.paintBackground ? _palette.background : null;
    if (bg == null) {
      return '\x1b[0m';
    }
    return background(bg, trueColor: trueColor);
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String format(
    DateTime now, {
    required bool withSeconds,
    required bool colon,
  }) {
    int hour = now.hour;
    if (settings.twelveHour) {
      hour = hour % 12 == 0 ? 12 : hour % 12;
    }
    final String sep = colon ? ':' : ' ';
    final String head = '${_two(hour)}$sep${_two(now.minute)}';
    return withSeconds ? '$head$sep${_two(now.second)}' : head;
  }

  String _date(DateTime now) {
    final String day = _weekdays[now.weekday - 1];
    final String month = _months[now.month - 1];
    return '$day, ${now.day} $month ${now.year}';
  }

  double _position(int c, Bitmap bitmap, double rowFrac) {
    return switch (settings.direction) {
      Direction.horizontal => c / bitmap.width * 0.5,
      Direction.vertical => rowFrac * 0.5,
      Direction.diagonal => c / bitmap.width * 0.35 + rowFrac * 0.25,
      Direction.digit => bitmap.columnGlyph[c] / bitmap.glyphCount,
    };
  }

  String _colored(String text, double phase) {
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final double t = i / math.max(1, text.length) * 0.5 + phase;
      out.write(foreground(_palette.at(t), trueColor: trueColor));
      out.write(text[i]);
    }
    out.write(base);
    return out.toString();
  }

  String frame(DateTime now, int cols, int rows) {
    final double phase = settings.animate
        ? ((now.millisecondsSinceEpoch ~/ 1000) % 30) / 30.0
        : 0.0;
    final bool colonOn = !settings.blink || now.second.isEven;
    final Bitmap bitmap = buildBitmap(
      settings.font,
      format(now, withSeconds: settings.showSeconds, colon: colonOn),
    );
    final int h = settings.font.height;
    final int extra = settings.showDate ? 2 : 0;
    int sx = cols ~/ bitmap.width;
    int sy = (rows - extra) ~/ h;
    final int k = math.min(sx ~/ 2, sy);
    if (k >= 1) {
      sx = 2 * k;
      sy = k;
    }
    if (sx < 1 || sy < 1) {
      return _plain(now, cols, rows, phase, colonOn);
    }
    final int top = (rows - (h * sy + extra)) ~/ 2 + 1;
    final int left = (cols - bitmap.width * sx) ~/ 2 + 1;
    final bool led = settings.pixel == PixelStyle.led;
    final String blank = ' ' * sx;
    final StringBuffer out = StringBuffer();
    for (int r = 0; r < h; r++) {
      for (int v = 0; v < sy; v++) {
        final double rowFrac = (r + v / sy) / h;
        final bool gapRow = led && sy >= 2 && v == sy - 1;
        final StringBuffer line = StringBuffer();
        for (int c = 0; c < bitmap.width; c++) {
          if (bitmap.rows[r][c] == '#' && !gapRow) {
            final Rgb color = _palette.at(
              _position(c, bitmap, rowFrac) + phase,
            );
            line.write(background(color, trueColor: trueColor));
            if (led && sx >= 2) {
              line.write(' ' * (sx - 1));
              line.write(base);
              line.write(' ');
            } else {
              line.write(blank);
            }
          } else {
            line.write(base);
            line.write(blank);
          }
        }
        line.write(base);
        out.write('\x1b[${top + r * sy + v};${left}H');
        out.write(line);
      }
    }
    if (settings.showDate) {
      String text = _date(now);
      if (text.length > cols) {
        text = text.substring(0, cols);
      }
      final int dateRow = top + h * sy + 1;
      final int dateLeft = math.max(1, (cols - text.length) ~/ 2 + 1);
      out.write('\x1b[$dateRow;1H$base\x1b[2K\x1b[$dateRow;${dateLeft}H');
      out.write(_colored(text, phase));
    }
    return out.toString();
  }

  String _plain(DateTime now, int cols, int rows, double phase, bool colonOn) {
    String text = format(
      now,
      withSeconds: settings.showSeconds,
      colon: colonOn,
    );
    if (text.length > cols) {
      text = format(now, withSeconds: false, colon: colonOn);
    }
    if (text.length > cols) {
      text = text.substring(0, math.max(0, cols));
    }
    final int top = rows ~/ 2 + 1;
    final int left = math.max(1, (cols - text.length) ~/ 2 + 1);
    return '\x1b[$top;1H$base\x1b[2K\x1b[$top;${left}H${_colored(text, phase)}';
  }
}
