import 'dart:io';

import 'completion.dart';

const String _pathScript =
    r"$dir = '@DIR@'; "
    r"$current = [Environment]::GetEnvironmentVariable('Path', 'User'); "
    r'$parts = @(); '
    r"if ($current) { $parts = @($current -split ';' | Where-Object { $_ }) }; "
    r'if ($parts -notcontains $dir) { '
    r"[Environment]::SetEnvironmentVariable('Path', (($parts + $dir) -join ';'), 'User'); "
    r"Write-Output 'added' } else { Write-Output 'present' }";

void _write(String path, String content) {
  final File file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void _installBinary(String source, String target) {
  final File dest = File(target);
  dest.parent.createSync(recursive: true);
  if (dest.existsSync() &&
      dest.resolveSymbolicLinksSync() ==
          File(source).resolveSymbolicLinksSync()) {
    return;
  }
  final String temp = '$target.new';
  File(source).copySync(temp);
  if (!Platform.isWindows) {
    Process.runSync('chmod', <String>['755', temp]);
  }
  File(temp).renameSync(target);
}

int _installPosix(String exe) {
  final String home = Platform.environment['HOME'] ?? '';
  if (home.isEmpty) {
    stderr.writeln('HOME is not set');
    return 1;
  }
  final String xdg = Platform.environment['XDG_DATA_HOME'] ?? '';
  final String dataDir = xdg.isEmpty ? '$home/.local/share' : xdg;
  final String binDir = '$home/.local/bin';
  final String bashFile = '$dataDir/bash-completion/completions/pcc';
  final String zshDir = '$dataDir/zsh/site-functions';

  _installBinary(exe, '$binDir/pcc');
  _write(bashFile, bashCompletion());
  _write('$zshDir/_pcc', zshCompletion());

  stdout.writeln('Installed: $binDir/pcc');
  stdout.writeln('Bash completion: $bashFile');
  stdout.writeln('Zsh completion: $zshDir/_pcc');
  final String path = Platform.environment['PATH'] ?? '';
  if (!path.split(':').contains(binDir)) {
    stdout.writeln('Add $binDir to your PATH.');
  }
  stdout.writeln('For zsh, add this to ~/.zshrc before compinit:');
  stdout.writeln('  fpath=($zshDir \$fpath)');
  return 0;
}

int _installWindows(String exe) {
  final String local = Platform.environment['LOCALAPPDATA'] ?? '';
  if (local.isEmpty) {
    stderr.writeln('LOCALAPPDATA is not set');
    return 1;
  }
  final String dir = '$local\\Programs\\pcc';

  _installBinary(exe, '$dir\\pcc.exe');
  _write('$dir\\completions\\pcc.bash', bashCompletion());
  _write('$dir\\completions\\_pcc', zshCompletion());

  stdout.writeln('Installed: $dir\\pcc.exe');
  stdout.writeln('Completions: $dir\\completions');

  final ProcessResult result = Process.runSync('powershell', <String>[
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    _pathScript.replaceAll('@DIR@', dir.replaceAll("'", "''")),
  ]);
  if (result.exitCode == 0) {
    if (result.stdout.toString().trim() == 'added') {
      stdout.writeln('Added $dir to your user PATH. Restart your terminal.');
    }
  } else {
    stdout.writeln('Could not update PATH. Add $dir to it manually.');
  }
  stdout.writeln('For bash on Windows (Git Bash, MSYS2), add to ~/.bashrc:');
  stdout.writeln(
    '  source ~/AppData/Local/Programs/pcc/completions/pcc.bash',
  );
  return 0;
}

int runInstall() {
  final String exe = Platform.resolvedExecutable;
  final String name = exe.split(Platform.pathSeparator).last.toLowerCase();
  if (name == 'dart' || name == 'dart.exe') {
    stderr.writeln('Run the compiled pcc binary, not dart run.');
    return 1;
  }
  try {
    return Platform.isWindows ? _installWindows(exe) : _installPosix(exe);
  } on FileSystemException catch (e) {
    stderr.writeln('Install failed: ${e.message} ${e.path ?? ''}');
    return 1;
  }
}
