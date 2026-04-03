#!/usr/bin/env bash
# Genera PNGs en entregables_capturas/ a partir de la salida de los comandos del taller.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CAP="$ROOT/entregables_capturas"
FONT="${FONT:-/usr/share/fonts/liberation-mono-fonts/LiberationMono-Regular.ttf}"
mkdir -p "$CAP"
cd "$ROOT"

filter_django() {
  grep -v "System check identified" \
    | grep -v "^WARNINGS:" \
    | grep -v "^movie\.Movie:" \
    | grep -v "^[[:space:]]*HINT:" \
    | grep -v "^[[:space:]]*Configure the DEFAULT" \
    || true
}
export -f filter_django

to_png() {
  local name="$1"
  shift
  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  "$@" >"$tmp" 2>&1 || true
  magick -size 2600x3600 xc:'#f8f8f8' \
    -font "$FONT" -pointsize 13 -fill '#111' \
    -gravity NorthWest -annotate +28+28 "@$tmp" \
    "$CAP/$name.png"
}

echo "01: link GitHub (texto)…"
printf '%s\n\n(Reemplaza por el enlace de TU fork en GitHub)\nhttps://github.com/jdmartinev/TallerIA_PI\n' \
  "Repositorio de referencia del taller:" >"$CAP/01_repositorio_github.txt"
magick -size 2000x400 xc:white -font "$FONT" -pointsize 20 -fill '#111' \
  -gravity Center -annotate +0+0 "@$CAP/01_repositorio_github.txt" \
  "$CAP/01_repositorio_github.png"

echo "02: update_descriptions…"
to_png "02_update_descriptions" bash -c "python manage.py update_descriptions 2>&1 | filter_django"

echo "03: update_movies_from_csv (muestra inicio y final)…"
tmp_csv_out="$(mktemp)"
python manage.py update_movies_from_csv 2>&1 | filter_django >"$tmp_csv_out"
tmp_combined="$(mktemp)"
{
  echo "=== Inicio de la salida ==="
  head -25 "$tmp_csv_out"
  echo ""
  echo "=== … (líneas omitidas) … ==="
  echo ""
  echo "=== Final de la salida ==="
  tail -8 "$tmp_csv_out"
} >"$tmp_combined"
rm -f "$tmp_csv_out"
magick -size 2600x3600 xc:'#f8f8f8' -font "$FONT" -pointsize 12 -fill '#111' \
  -gravity NorthWest -annotate +28+28 "@$tmp_combined" \
  "$CAP/03_update_movies_from_csv.png"
rm -f "$tmp_combined"

echo "04: update_images…"
to_png "04_update_images" bash -c "python manage.py update_images 2>&1 | filter_django"

echo "05: update_images_from_folder (últimas líneas)…"
to_png "05_update_images_from_folder" bash -c "python manage.py update_images_from_folder 2>&1 | filter_django | tail -40"

echo "06: movie_similarities (embeddings + similitud coseno)…"
to_png "06_movie_similarities" bash -c "python manage.py movie_similarities 2>&1 | filter_django"

echo "07a: movie_embeddings (muestra de generación y almacenamiento)…"
tmp_me="$(mktemp)"
python manage.py movie_embeddings --limit 12 2>&1 | filter_django >"$tmp_me"
tmp_me_head="$(mktemp)"
head -22 "$tmp_me" >"$tmp_me_head"
magick -size 2600x3600 xc:'#f8f8f8' -font "$FONT" -pointsize 13 -fill '#111' \
  -gravity NorthWest -annotate +28+28 "@$tmp_me_head" \
  "$CAP/07a_movie_embeddings.png"
rm -f "$tmp_me" "$tmp_me_head"

echo "07b: show_random_embedding (vector de una película al azar)…"
to_png "07b_show_random_embedding" bash -c "python manage.py show_random_embedding --preview 40 2>&1 | filter_django"

echo "Listo: $CAP"
