# dmgbuild settings for the macOS installer DMG. build.sh passes the
# paths with -D app=... -D background=... (dmgbuild provides `defines`).
import os.path

app = defines["app"]  # noqa: F821 (injected by dmgbuild)
background = defines["background"]  # noqa: F821

format = "UDZO"
filesystem = "HFS+"
files = [app]
symlinks = {}
hide_extensions = [os.path.basename(app)]
icon_locations = {os.path.basename(app): (330, 170)}
window_rect = ((200, 120), (660, 420))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
icon_size = 128
text_size = 13
