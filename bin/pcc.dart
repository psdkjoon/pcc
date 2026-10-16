import 'dart:async';
import 'dart:io';

import 'package:pcc/src/completion.dart';
import 'package:pcc/src/installer.dart';
import 'package:pcc/src/renderer.dart';
import 'package:pcc/src/settings.dart';

const String usage = '''
pcc - colorful terminal clock

Usage: pcc [options]

Options:
  -c, --color <name|#hex>   Color or theme (default: rainbow)
  -f, --font <name>         Font (default: block)
  -d, --direction <name>    Gradient direction (default: horizontal)
  -p, --pixel <name>        Pixel style: solid or led
  -t, --12h                 Use 12-hour format
  -n, --no-seconds          Hide seconds
  -D, --date                Show the date under the clock
  -b, --blink               Blink the colons
  -s, --static              Do not animate the colors
  -B, --bg                  Paint the theme background color
  -l, --list                List colors, themes, fonts and styles
      --install             Install pcc and its shell completions for you
      --completion <shell>  Print a completion script (bash or zsh)
  -h, --help                Show this help

Examples:
  pcc -c mocha -B -f classic
  pcc -c latte -B -f segment -p led -D
  pcc -c orange -f tall -n
  pcc --completion zsh > ~/.zfunc/_pcc

Press q or Ctrl+C to quit.''';

void watchSignal(ProcessSignal signal, void Function() action) {
  try {
    signal.watch().listen(
      (ProcessSignal _) => action(),
      onError: (Object _) {},
    );
  } on SignalException {
    stdout.write('');
  }
}

Future<void> main(List<String> args) async {
  final Settings settings;
  try {
    settings = parseArgs(args);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln('Run pcc --help for usage.');
    exit(64);
  }

  if (settings.help) {
    stdout.writeln(usage);
    return;
  }

  if (settings.list) {
    stdout.writeln(describeChoices());
    return;
  }

  final String? shell = settings.completion;
  if (shell != null) {
    stdout.write(completionFor(shell) ?? '');
    return;
  }

  if (settings.install) {
    exit(runInstall());
  }

  if (!stdout.hasTerminal) {
    stderr.writeln('pcc must be run in a terminal');
    exit(1);
  }

  final String colorTerm = Platform.environment['COLORTERM'] ?? '';
  final bool trueColor =
      colorTerm.contains('truecolor') || colorTerm.contains('24bit');

  final ClockRenderer renderer = ClockRenderer(
    settings: settings,
    trueColor: trueColor,
  );

  int lastCols = -1;
  int lastRows = -1;

  void draw() {
    final int cols = stdout.terminalColumns;
    final int rows = stdout.terminalLines;
    final StringBuffer buffer = StringBuffer();
    if (cols != lastCols || rows != lastRows) {
      buffer.write(renderer.clearSequence);
      lastCols = cols;
      lastRows = rows;
    }
    buffer.write(renderer.frame(DateTime.now(), cols, rows));
    stdout.write(buffer);
  }

  final Completer<void> done = Completer<void>();

  void finish() {
    if (!done.isCompleted) {
      done.complete();
    }
  }

  stdout.write('\x1b[?1049h\x1b[?25l');

  watchSignal(ProcessSignal.sigint, finish);
  watchSignal(ProcessSignal.sigterm, finish);
  watchSignal(ProcessSignal.sigwinch, draw);

  final bool interactive = stdin.hasTerminal;
  if (interactive) {
    try {
      stdin.echoMode = false;
      stdin.lineMode = false;
      stdin.listen((List<int> data) {
        if (data.contains(113) || data.contains(81) || data.contains(3)) {
          finish();
        }
      });
    } on StdinException {
      stdout.write('');
    }
  }

  while (!done.isCompleted) {
    draw();
    final int wait = 1000 - DateTime.now().millisecond;
    await Future.any<void>(<Future<void>>[
      Future<void>.delayed(Duration(milliseconds: wait)),
      done.future,
    ]);
  }

  if (interactive) {
    try {
      stdin.lineMode = true;
      stdin.echoMode = true;
    } on StdinException {
      stdout.write('');
    }
  }
  stdout.write('\x1b[0m\x1b[?25h\x1b[?1049l');
  exit(0);
}
