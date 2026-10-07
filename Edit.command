#!/bin/zsh
cd "${0:A:h}" || exit 1
for cinder_engine in "$PWD/.tools/Godot.app/Contents/MacOS/Godot" /Applications/Godot.app/Contents/MacOS/Godot "$HOME/Applications/Godot.app/Contents/MacOS/Godot"; do
  if [[ -x "$cinder_engine" ]]; then
    exec "$cinder_engine" --editor --path . "$@"
  fi
done
if command -v godot >/dev/null 2>&1; then
  exec godot --editor --path . "$@"
fi
printf '%s\n' 'Download Godot 4.7.2 from godotengine.org, then open project.godot in the editor.'
exit 1
