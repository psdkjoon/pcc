import 'font.dart';
import 'palette.dart';
import 'settings.dart';

const String _options =
    '-c --color --theme -f --font -d --direction -p --pixel -t --12h '
    '-n --no-seconds -D --date -b --blink -s --static -B --bg -l --list '
    '-h --help --install --completion';

const String _bashTemplate = r'''
_pcc() {
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}

  if [[ $cur == '=' ]]; then
    cur=''
  elif [[ $prev == '=' ]]; then
    prev=${COMP_WORDS[COMP_CWORD-2]}
  fi

  case $prev in
    -c|--color|--theme)
      mapfile -t COMPREPLY < <(compgen -W '@COLORS@' -- "$cur")
      ;;
    -f|--font)
      mapfile -t COMPREPLY < <(compgen -W '@FONTS@' -- "$cur")
      ;;
    -d|--direction)
      mapfile -t COMPREPLY < <(compgen -W '@DIRECTIONS@' -- "$cur")
      ;;
    -p|--pixel)
      mapfile -t COMPREPLY < <(compgen -W '@PIXELS@' -- "$cur")
      ;;
    --completion)
      mapfile -t COMPREPLY < <(compgen -W 'bash zsh' -- "$cur")
      ;;
    *)
      mapfile -t COMPREPLY < <(compgen -W '@OPTIONS@' -- "$cur")
      ;;
  esac
}

complete -F _pcc pcc
''';

const String _zshTemplate = r'''
#compdef pcc

_arguments \
  '(-c --color --theme)'{-c,--color,--theme}'[color, theme or hex]:color:(@COLORS@)' \
  '(-f --font)'{-f,--font}'[font]:font:(@FONTS@)' \
  '(-d --direction)'{-d,--direction}'[gradient direction]:direction:(@DIRECTIONS@)' \
  '(-p --pixel)'{-p,--pixel}'[pixel style]:pixel:(@PIXELS@)' \
  '(-t --12h)'{-t,--12h}'[use 12-hour format]' \
  '(-n --no-seconds)'{-n,--no-seconds}'[hide seconds]' \
  '(-D --date)'{-D,--date}'[show the date]' \
  '(-b --blink)'{-b,--blink}'[blink the colons]' \
  '(-s --static)'{-s,--static}'[do not animate the colors]' \
  '(-B --bg)'{-B,--bg}'[paint the theme background]' \
  '(-l --list)'{-l,--list}'[list colors, fonts and styles]' \
  '(-h --help)'{-h,--help}'[show help]' \
  '--install[install pcc and its completions]' \
  '--completion[print a completion script]:shell:(bash zsh)'
''';

String _fill(String template) {
  return template
      .replaceAll('@OPTIONS@', _options)
      .replaceAll('@COLORS@', colorNames.join(' '))
      .replaceAll('@FONTS@', fonts.keys.join(' '))
      .replaceAll(
        '@DIRECTIONS@',
        Direction.values.map((Direction d) => d.name).join(' '),
      )
      .replaceAll(
        '@PIXELS@',
        PixelStyle.values.map((PixelStyle p) => p.name).join(' '),
      );
}

String bashCompletion() => _fill(_bashTemplate);

String zshCompletion() => _fill(_zshTemplate);

String? completionFor(String shell) {
  return switch (shell) {
    'bash' => bashCompletion(),
    'zsh' => zshCompletion(),
    _ => null,
  };
}
