extends Node

# ThemeManager v1.0 (Berdasarkan Panduan desain.md)
# Mengelola palet warna, icon vector flat, dan helper StyleBox untuk seluruh game Climb the Sky

# --- PALET WARNA UTAMA (desain.md) ---
const COLOR_BG_MAIN: Color = Color("#EAF6FF")       # Biru langit muda
const COLOR_CARD_WHITE: Color = Color("#FFFFFF")    # Putih (Kartu / Panel)
const COLOR_TEXT_NAVY: Color = Color("#1E2A4A")     # Teks utama (Kontras tinggi)
const COLOR_BTN_PRIMARY: Color = Color("#1F6FEB")   # Tombol utama (Biru)

# Warna Aksen Per Level
const COLOR_LVL1_ORANGE: Color = Color("#FF8A3D")   # Level 1: Cokelat (Oranye)
const COLOR_LVL2_PINK: Color = Color("#FF6FAE")     # Level 2: Permen (Pink)
const COLOR_LVL3_YELLOW: Color = Color("#FFC93C")   # Level 3: Mi Instan (Kuning)

# Warna Umpan Balik
const COLOR_CORRECT_GREEN: Color = Color("#3DDC97") # Jawaban Benar (+100)
const COLOR_WRONG_RED: Color = Color("#FF7A7A")     # Jawaban Salah (-25)
const COLOR_LOCKED_GRAY: Color = Color("#D5DDE8")   # Status Terkunci

# Cache ikon vector SVG
var _icon_cache: Dictionary = {}

func _ready() -> void:
	print("ThemeManager: Palet warna dan sistem tema desain.md siap.")

# Mengambil warna aksen berdasarkan level
func get_level_color(level: int) -> Color:
	match level:
		1:
			return COLOR_LVL1_ORANGE
		2:
			return COLOR_LVL2_PINK
		3:
			return COLOR_LVL3_YELLOW
		_:
			return COLOR_BTN_PRIMARY

# Mengambil tekstur icon vector SVG (dengan caching)
func get_icon(icon_name: String) -> Texture2D:
	if _icon_cache.has(icon_name):
		return _icon_cache[icon_name]
		
	var path = "res://assets/icons/%s.svg" % icon_name
	if FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img:
			var tex = ImageTexture.create_from_image(img)
			_icon_cache[icon_name] = tex
			return tex
			
	return null

# Helper membuat StyleBox kartu putih dengan rounded corners & shadow
func create_card_style(bg_color: Color = COLOR_CARD_WHITE, corner_radius: int = 18, border_color: Color = Color(0.85, 0.90, 0.96)) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(corner_radius)
	sb.border_color = border_color
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.shadow_color = Color(0.12, 0.16, 0.29, 0.08)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	return sb

# Helper membuat StyleBox tombol
func create_button_style(bg_color: Color = COLOR_BTN_PRIMARY, corner_radius: int = 14) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(corner_radius)
	sb.set_content_margin_all(12)
	return sb

# Helper membuat StyleBox socket matching (Bulatan 48px)
func create_socket_style(is_connected: bool, accent_color: Color = COLOR_BTN_PRIMARY) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(24) # Radius 24 = diameter 48px
	if is_connected:
		sb.bg_color = accent_color
		sb.border_color = COLOR_CARD_WHITE
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
	else:
		sb.bg_color = COLOR_CARD_WHITE
		sb.border_color = accent_color
		sb.border_width_left = 4
		sb.border_width_top = 4
		sb.border_width_right = 4
		sb.border_width_bottom = 4
	return sb

# Helper membuat pill badge tema
func create_pill_style(bg_color: Color, corner_radius: int = 10) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(corner_radius)
	sb.set_content_margin_all(8)
	return sb
