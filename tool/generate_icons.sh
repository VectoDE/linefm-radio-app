#!/usr/bin/env bash
# Erzeugt alle App-Icons und Markenassets aus assets/branding/source/main_600.png.
# Quelle: https://cdn.linefm.de/images/icons/main.png (vom Inhaber freigegeben, 600x600, opak).
# Optisch unveraendert: nur Hochskalierung (Lanczos), Ebenen-Trennung fuer Android und
# plattformspezifische Zuschnitte. Voraussetzung: ImageMagick 7 (`magick`).
# Aufruf aus dem Repo-Root: bash tool/generate_icons.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SRC="assets/branding/source/main_600.png"
W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT

# Markenfarben der Quelle: Flaeche links/rechts der Diagonale.
C_LEFT="rgb(71,71,118)"   # #474776
C_RIGHT="rgb(75,75,125)"  # #4B4B7D
# Diagonale in Quellkoordinaten (600 px): x(y) = X0 + SLOPE * y
X0=264.69
X600=338.31

# 1. Flaeche (Hintergrund-Ebene) als exakter Nachbau der Quelle bei 600 px.
magick -size 600x600 "xc:$C_RIGHT" -fill "$C_LEFT" \
  -draw "polygon 0,0 $X0,0 $X600,600 0,600" "$W/bg600.png"

# 2. Wortmarke als Alpha-Maske: Quelle = Flaeche + weiss * alpha.
magick "$SRC" -alpha off -channel R -separate "$W/oR.png"
magick "$W/bg600.png" -channel R -separate "$W/bR.png"
magick "$W/oR.png" "$W/bR.png" -fx "clamp((u-v)/(1-v))" -level 4%,100% \
  -depth 16 "$W/alpha600.png"

# Hilfsfunktionen -----------------------------------------------------------

# fg N SCALE OUT : weisse Wortmarke auf transparentem NxN-Canvas, Quellmitte = Canvasmitte,
# Massstab SCALE = Pixel pro Quellpixel.
fg() {
  local n="$1" scale="$2" out="$3" side
  side="$(awk -v s="$scale" 'BEGIN{printf "%d", 600*s+0.5}')"
  magick "$W/alpha600.png" -filter Lanczos -resize "${side}x${side}!" \
    -background black -gravity center -extent "${n}x${n}" "$W/fgmask.png"
  magick -size "${n}x${n}" xc:white "$W/fgmask.png" -alpha off \
    -compose CopyOpacity -composite -strip "$out"
}

# rs SIZE OUT : Quadrat aus der 1024er Vollflaeche, Lanczos.
rs() { magick assets/branding/icon_1024.png -filter Lanczos -resize "${1}x${1}" -strip -define png:color-type=2 "$2"; }

# sm SIZE OUT : Kleinstufe (<= 32 px). Reiner Ausschnitt der Quelle (360x360 px um die
# Wortmarke) statt Gesamtbild, Lanczos plus leichtes Unsharp. Bei 16 bis 32 px waere die
# Wortmarke im Gesamtbild nur 8 bis 16 px breit und nicht mehr lesbar; der Ausschnitt
# aendert weder Farben noch Form, nur den Bildausschnitt.
sm() { magick "$SRC" -crop 360x360+118+109 +repage -filter Lanczos -resize "${1}x${1}"   -unsharp 0x0.5+0.5+0 -alpha off -strip -define png:color-type=2 "$2"; }

# 3. Vollflaeche 1024 (reine Hochskalierung der Quelle).
mkdir -p assets/branding
magick "$SRC" -filter Lanczos -resize 1024x1024 -alpha off -strip -define png:color-type=2 assets/branding/icon_1024.png

# Ebenen 1024 fuer Weiterverwendung (Wortmarke 1:1, Flaeche).
fg 1024 "$(awk 'BEGIN{printf "%.6f", 1024/600}')" assets/branding/icon_foreground_1024.png
magick -size 1024x1024 "xc:$C_RIGHT" -fill "$C_LEFT" \
  -draw "polygon 0,0 $(awk -v a=$X0 'BEGIN{printf "%.3f", a*1024/600}'),0 $(awk -v a=$X600 'BEGIN{printf "%.3f", a*1024/600}'),1024 0,1024" \
  -strip assets/branding/icon_background_1024.png

# Play-Store-Icon (512, opak).
rs 512 assets/branding/play_store_512.png

# 4. Android -----------------------------------------------------------------
RES=android/app/src/main/res
declare -A LEG=([mdpi]=48 [hdpi]=72 [xhdpi]=96 [xxhdpi]=144 [xxxhdpi]=192)
declare -A DENS=([mdpi]=1 [hdpi]=1.5 [xhdpi]=2 [xxhdpi]=3 [xxxhdpi]=4)
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  mkdir -p "$RES/mipmap-$d" "$RES/drawable-$d"
  s="${LEG[$d]}"
  rs "$s" "$RES/mipmap-$d/ic_launcher.png"
  # Runde Variante (Kreismaske, Aussenseite transparent)
  magick -size "${s}x${s}" xc:black -fill white \
    -draw "circle $(awk -v s=$s 'BEGIN{printf "%.2f,%.2f %.2f,%.2f", s/2,s/2,s/2,0}')" "$W/rmask.png"
  magick "$RES/mipmap-$d/ic_launcher.png" "$W/rmask.png" -alpha off \
    -compose CopyOpacity -composite -strip "$RES/mipmap-$d/ic_launcher_round.png"
  # Adaptive Vordergrund: 108dp-Canvas, Wortmarke 1:1 zur Quelle (Radius 30,8dp < 33dp Safe-Zone)
  px="$(awk -v k="${DENS[$d]}" 'BEGIN{printf "%d", 108*k}')"
  fg "$px" "$(awk -v p="$px" 'BEGIN{printf "%.6f", p/600}')" "$RES/drawable-$d/ic_launcher_foreground.png"
  # Benachrichtigungs-Icon: weiss, transparent, 24dp
  np="$(awk -v k="${DENS[$d]}" 'BEGIN{printf "%d", 24*k}')"
  magick "$W/alpha600.png" -trim +repage -filter Lanczos \
    -resize "$(awk -v n=$np 'BEGIN{printf "%dx", n-2*int(n/12)}')" \
    -background black -gravity center -extent "${np}x${np}" "$W/nmask.png"
  magick -size "${np}x${np}" xc:white "$W/nmask.png" -alpha off \
    -compose CopyOpacity -composite -strip "$RES/drawable-$d/ic_stat_linefm.png"
done

mkdir -p "$RES/mipmap-anydpi-v26" "$RES/drawable"
# Adaptive Hintergrund-Ebene als Vektor: Flaeche aus der Quelle, 108dp-Viewport (Faktor 0,18).
X0_DP="$(awk -v a=$X0 'BEGIN{printf "%.2f", a*0.18}')"
X1_DP="$(awk -v a=$X600 'BEGIN{printf "%.2f", a*0.18}')"
cat > "$RES/drawable/ic_launcher_background.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#4B4B7D"
        android:pathData="M0,0h108v108h-108z" />
    <path
        android:fillColor="#474776"
        android:pathData="M0,0L$X0_DP,0L$X1_DP,108L0,108z" />
</vector>
EOF
for n in ic_launcher ic_launcher_round; do
cat > "$RES/mipmap-anydpi-v26/$n.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
EOF
done

# 5. iOS (ohne Alpha) --------------------------------------------------------
IOS=ios/Runner/Assets.xcassets/AppIcon.appiconset
for f in "$IOS"/Icon-App-*.png; do
  b="$(basename "$f" .png)"; spec="${b#Icon-App-}"
  size="${spec%%@*}"; scale="${spec##*@}"; scale="${scale%x}"
  px="$(awk -v s="${size%%x*}" -v k="$scale" 'BEGIN{printf "%d", s*k+0.5}')"
  magick assets/branding/icon_1024.png -filter Lanczos -resize "${px}x${px}" \
    -background "$C_RIGHT" -alpha remove -alpha off -strip -define png:color-type=2 "$f"
done

# 5b. iOS-Startbild: Icon als Kreis (wie Android-Splash), 112 pt, transparent auf #0F1221
# (Hintergrund setzt LaunchScreen.storyboard).
LI=ios/Runner/Assets.xcassets/LaunchImage.imageset
for k in 1 2 3; do
  px=$((112*k))
  magick -size "${px}x${px}" xc:black -fill white     -draw "circle $(awk -v s=$px 'BEGIN{printf "%.2f,%.2f %.2f,%.2f", s/2,s/2,s/2,0}')" "$W/lmask.png"
  magick assets/branding/icon_1024.png -filter Lanczos -resize "${px}x${px}" "$W/lmask.png" -alpha off     -compose CopyOpacity -composite -strip "$W/li.png"
  if [ "$k" = 1 ]; then out="$LI/LaunchImage.png"; else out="$LI/LaunchImage@${k}x.png"; fi
  cp "$W/li.png" "$out"
done

# 6. macOS: Rundrechteck-Zuschnitt (824 px im 1024er Raster, Radius 185) -----
MAC=macos/Runner/Assets.xcassets/AppIcon.appiconset
magick -size 824x824 xc:black -fill white -draw "roundrectangle 0,0 823,823 185,185" "$W/mmask.png"
magick assets/branding/icon_1024.png -filter Lanczos -resize 824x824 "$W/mmask.png" -alpha off \
  -compose CopyOpacity -composite "$W/mac824.png"
magick "$W/mac824.png" -background none -gravity center -extent 1024x1024 "$W/mac1024.png"
for n in 16 32 64 128 256 512 1024; do
  magick "$W/mac1024.png" -filter Lanczos -resize "${n}x${n}" -strip "$MAC/app_icon_$n.png"
done

# 7. Windows: Stufen 16 bis 256; <= 32 px als Ausschnitt (sm), darueber Gesamtbild (rs).
ICO_LIST=()
for n in 16 20 24 32 40 48 64 128 256; do
  if [ "$n" -le 32 ]; then sm "$n" "$W/ico_$n.png"; else rs "$n" "$W/ico_$n.png"; fi
  ICO_LIST+=("$W/ico_$n.png")
done
magick "${ICO_LIST[@]}" windows/runner/resources/app_icon.ico

# 8. Linux (hicolor-Struktur, APPLICATION_ID de.linefm.app) ------------------
for n in 16 24 32 48 64 128 256 512; do
  d="linux/assets/icons/hicolor/${n}x${n}/apps"; mkdir -p "$d"
  if [ "$n" -le 32 ]; then sm "$n" "$d/de.linefm.app.png"; else rs "$n" "$d/de.linefm.app.png"; fi
done

# 9. Web ---------------------------------------------------------------------
mkdir -p web/icons
rs 48 web/favicon.png
sm 16 web/icons/favicon-16.png
sm 32 web/icons/favicon-32.png
rs 192 web/icons/Icon-192.png
rs 512 web/icons/Icon-512.png
rs 192 web/icons/Icon-maskable-192.png   # Wortmarkenradius 28,5 % < 40 % Safe-Zone
rs 512 web/icons/Icon-maskable-512.png
rs 180 web/icons/apple-touch-icon.png

# OG-Bild 1200x630: gleiche Flaeche + Diagonale, Wortmarke mittig (Hoehe ca. 40 %).
magick -size 1200x630 "xc:$C_RIGHT" -fill "$C_LEFT" \
  -draw "polygon 0,0 $(awk 'BEGIN{printf "%.2f", 573}'),0 $(awk 'BEGIN{printf "%.2f", 573+0.1227*630}'),630 0,630" "$W/og_bg.png"
magick "$W/alpha600.png" -crop 326x142+135+218 +repage -filter Lanczos -resize 640x \
  -background black -gravity center -extent 1200x630 "$W/og_mask.png"
magick -size 1200x630 xc:white "$W/og_mask.png" -alpha off -compose CopyOpacity -composite "$W/og_fg.png"
magick "$W/og_bg.png" "$W/og_fg.png" -compose Over -composite -strip web/icons/og-image.png

# 10. Social-Preview 1280x640 (GitHub, Hochladen nur im Browser durch den Inhaber).
# Nur vorhandene Bestandteile: Logo-Kachel, Markenfarben, Schriften aus assets/fonts.
F=assets/fonts
mkdir -p docs/assets
magick -size 420x420 xc:black -fill white -draw "roundrectangle 0,0 419,419 94,94" "$W/pm.png"
magick "$SRC" -filter Lanczos -resize 420x420 "$W/pm.png" -alpha off -compose CopyOpacity -composite "$W/tile.png"
magick -size 1280x640 "xc:#0F1221" "$W/tile.png" -geometry +90+110 -composite   -font $F/Syncopate-Bold.ttf -fill white -pointsize 58 -annotate +560+270 'LINEFM'   -font $F/Syncopate-Bold.ttf -fill '#A4A7B6' -pointsize 58 -annotate +560+350 'RADIO'   -font $F/Poppins-Regular.ttf -fill '#A4A7B6' -pointsize 26 -annotate +562+430 'LineFM +MAIN, +RAP, +GAMING, +LOFI live hören'   -font $F/Poppins-SemiBold.ttf -fill white -pointsize 22 -annotate +562+480 'Android · iOS · Windows · macOS · Linux · Web'   -depth 8 -strip -define png:color-type=2 docs/assets/social-preview.png

echo "Icons erzeugt."
