import 'dart:math' as math;

class Rgb {
  const Rgb(this.r, this.g, this.b);

  const Rgb.hex(int value)
      : r = (value >> 16) & 0xff,
        g = (value >> 8) & 0xff,
        b = value & 0xff;

  final int r;
  final int g;
  final int b;
}

Rgb hsvToRgb(double h, double s, double v) {
  final double hh = (h % 1.0) * 6.0;
  final int i = hh.floor();
  final double f = hh - i;
  final double p = v * (1 - s);
  final double q = v * (1 - s * f);
  final double t = v * (1 - s * (1 - f));
  final List<double> c;
  switch (i % 6) {
    case 0:
      c = <double>[v, t, p];
    case 1:
      c = <double>[q, v, p];
    case 2:
      c = <double>[p, v, t];
    case 3:
      c = <double>[p, q, v];
    case 4:
      c = <double>[t, p, v];
    default:
      c = <double>[v, p, q];
  }
  return Rgb(
    (c[0] * 255).round(),
    (c[1] * 255).round(),
    (c[2] * 255).round(),
  );
}

int _cube(int value) => math.min(5, (value / 51).round());

int toAnsi256(Rgb color) {
  return 16 + 36 * _cube(color.r) + 6 * _cube(color.g) + _cube(color.b);
}

String background(Rgb color, {required bool trueColor}) {
  if (trueColor) {
    return '\x1b[48;2;${color.r};${color.g};${color.b}m';
  }
  return '\x1b[48;5;${toAnsi256(color)}m';
}

String foreground(Rgb color, {required bool trueColor}) {
  if (trueColor) {
    return '\x1b[38;2;${color.r};${color.g};${color.b}m';
  }
  return '\x1b[38;5;${toAnsi256(color)}m';
}
