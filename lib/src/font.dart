class Font {
  const Font(this.name, this.height, this.glyphs);

  final String name;
  final int height;
  final Map<String, List<String>> glyphs;

  List<String> glyph(String ch) {
    if (ch == ' ') {
      return List<String>.filled(height, ' ' * glyphs[':']![0].length);
    }
    return glyphs[ch] ?? List<String>.filled(height, ' ');
  }
}

class Bitmap {
  const Bitmap(this.rows, this.columnGlyph);

  final List<String> rows;
  final List<int> columnGlyph;

  int get width => rows[0].length;

  int get glyphCount => columnGlyph.last + 1;
}

Bitmap buildBitmap(Font font, String text) {
  final List<StringBuffer> lines = List<StringBuffer>.generate(
    font.height,
    (int _) => StringBuffer(),
  );
  final List<int> columns = <int>[];
  for (int i = 0; i < text.length; i++) {
    if (i > 0) {
      for (final StringBuffer line in lines) {
        line.write(' ');
      }
      columns.add(i);
    }
    final List<String> glyph = font.glyph(text[i]);
    for (int row = 0; row < font.height; row++) {
      lines[row].write(glyph[row]);
    }
    for (int k = 0; k < glyph[0].length; k++) {
      columns.add(i);
    }
  }
  return Bitmap(
    <String>[for (final StringBuffer line in lines) line.toString()],
    columns,
  );
}

Map<String, List<String>> _build(Map<String, List<String>> raw) {
  return <String, List<String>>{
    for (final MapEntry<String, List<String>> e in raw.entries)
      e.key: <String>[for (final String r in e.value) r.replaceAll('.', ' ')],
  };
}

Map<String, List<String>> _stretchCols(Map<String, List<String>> source) {
  return <String, List<String>>{
    for (final MapEntry<String, List<String>> e in source.entries)
      e.key: <String>[
        for (final String row in e.value)
          row.split('').map((String ch) => ch * 2).join(),
      ],
  };
}

Map<String, List<String>> _stretchRows(Map<String, List<String>> source) {
  return <String, List<String>>{
    for (final MapEntry<String, List<String>> e in source.entries)
      e.key: <String>[
        for (final String row in e.value) ...<String>[row, row],
      ],
  };
}

Map<String, List<String>> _segmentGlyphs() {
  const Map<String, String> segmentsFor = <String, String>{
    '0': 'abcdef',
    '1': 'bc',
    '2': 'abged',
    '3': 'abgcd',
    '4': 'fgbc',
    '5': 'afgcd',
    '6': 'afgedc',
    '7': 'abc',
    '8': 'abcdefg',
    '9': 'abcdfg',
  };
  final Map<String, List<String>> out = <String, List<String>>{};
  for (final MapEntry<String, String> e in segmentsFor.entries) {
    final String s = e.value;
    String bar(String k) => s.contains(k) ? ' ### ' : '     ';
    String side(String l, String r) {
      return '${s.contains(l) ? '#' : ' '}   ${s.contains(r) ? '#' : ' '}';
    }

    out[e.key] = <String>[
      bar('a'),
      side('f', 'b'),
      side('f', 'b'),
      bar('g'),
      side('e', 'c'),
      side('e', 'c'),
      bar('d'),
    ];
  }
  out[':'] = <String>[' ', ' ', '#', ' ', '#', ' ', ' '];
  return out;
}

final Map<String, List<String>> _block = _build(<String, List<String>>{
  '0': <String>['###', '#.#', '#.#', '#.#', '###'],
  '1': <String>['.#.', '##.', '.#.', '.#.', '###'],
  '2': <String>['###', '..#', '###', '#..', '###'],
  '3': <String>['###', '..#', '###', '..#', '###'],
  '4': <String>['#.#', '#.#', '###', '..#', '..#'],
  '5': <String>['###', '#..', '###', '..#', '###'],
  '6': <String>['###', '#..', '###', '#.#', '###'],
  '7': <String>['###', '..#', '..#', '..#', '..#'],
  '8': <String>['###', '#.#', '###', '#.#', '###'],
  '9': <String>['###', '#.#', '###', '..#', '###'],
  ':': <String>['.', '#', '.', '#', '.'],
});

final Map<String, List<String>> _classic = _build(<String, List<String>>{
  '0': <String>['.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'],
  '1': <String>['..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'],
  '2': <String>['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
  '3': <String>['.###.', '#...#', '....#', '..##.', '....#', '#...#', '.###.'],
  '4': <String>['...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.'],
  '5': <String>['#####', '#....', '####.', '....#', '....#', '#...#', '.###.'],
  '6': <String>['..##.', '.#...', '#....', '####.', '#...#', '#...#', '.###.'],
  '7': <String>['#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...'],
  '8': <String>['.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.'],
  '9': <String>['.###.', '#...#', '#...#', '.####', '....#', '...#.', '.##..'],
  ':': <String>['.', '.', '#', '.', '#', '.', '.'],
});

final Map<String, Font> fonts = <String, Font>{
  'block': Font('block', 5, _block),
  'classic': Font('classic', 7, _classic),
  'segment': Font('segment', 7, _segmentGlyphs()),
  'wide': Font('wide', 5, _stretchCols(_block)),
  'tall': Font('tall', 10, _stretchRows(_block)),
};
