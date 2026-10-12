extends Node2D

## Opening / Main Menu AKSARA (Godot 4.7)
## Alur: Splash Studio ("CHILL CHAMBER") -> Intro Kamera -> Title Glow -> Menu Interaktif

enum State { SPLASH, INTRO, TITLE, MENU, MODAL, LEAVING }

const NEXT_SCENE := "res://scenes/prolog/ruang_kapsul.tscn"
const FALLBACK_SCENE := "res://Scene/aksara.tscn"

const CAM_START_Y := -130.0
const CAM_END_Y := 0.0

const COLOR_TEXT_DIM := Color("4E9AA8")
const COLOR_TEXT_FOCUS := Color("4FF0F5")
const COLOR_TEXT_DISABLED := Color(0.18, 0.32, 0.36, 0.7)
const COLOR_MOON_BASE := Color(1.3, 1.8, 2.0, 1.0)

var state: State = State.SPLASH
var tween: Tween
var ambient_time: float = 0.0
var is_transitioning: bool = false
var last_focused_btn: Button

# Node References
@onready var cam: Camera2D = $Camera2D
@onready var moon_sprite: Sprite2D = $Parallax2D_Bulan/SpriteBulan
@onready var mist_glow: Sprite2D = $MistGlow
@onready var parallax_langit: Parallax2D = $Parallax2D_Langit
@onready var parallax_awan_tengah: Parallax2D = $Parallax2D_AwanTengah
@onready var parallax_awan_depan: Parallax2D = $Parallax2D_AwanDepan
@onready var particles_bintang: GPUParticles2D = $GPUParticles2D_Bintang

# UI References
@onready var splash: Control = $UI/Splash
@onready var splash_studio: Label = $UI/Splash/CenterContainer/VBoxContainer/StudioLabel
@onready var splash_subtitle: Label = $UI/Splash/CenterContainer/VBoxContainer/SubtitleLabel

@onready var title_container: Control = $UI/TitleContainer
@onready var logo_label: Label = $UI/TitleContainer/LogoLabel
@onready var logo_shadow: Label = $UI/TitleContainer/LogoShadow

@onready var menu: VBoxContainer = $UI/Menu
@onready var btn_mulai: Button = $UI/Menu/BtnMulai
@onready var btn_lanjutkan: Button = $UI/Menu/BtnLanjutkan
@onready var btn_jurnal: Button = $UI/Menu/BtnJurnal
@onready var btn_pengaturan: Button = $UI/Menu/BtnPengaturan
@onready var btn_keluar: Button = $UI/Menu/BtnKeluar

@onready var modal_popup: Control = $UI/ModalPopup
@onready var modal_title: Label = $UI/ModalPopup/Panel/VBoxContainer/ModalTitle
@onready var modal_body: Label = $UI/ModalPopup/Panel/VBoxContainer/ModalBody
@onready var btn_modal_tutup: Button = $UI/ModalPopup/Panel/VBoxContainer/BtnModalTutup

@onready var fade: ColorRect = $UI/Fade


func _ready() -> void:
	# Inisialisasi posisi awal kamera di atas langit
	cam.position.y = CAM_START_Y
	cam.position.x = 0.0

	# Set transparansi awal elemen visual UI
	fade.modulate.a = 0.0
	title_container.modulate.a = 0.0
	title_container.visible = false
	menu.modulate.a = 0.0
	menu.visible = false
	modal_popup.visible = false

	# Setup tombol menu
	_setup_buttons()

	# Jalankan sekuens splash studio
	_play_splash()


func _process(delta: float) -> void:
	ambient_time += delta

	# Animasi ambient hanya aktif saat di menu / title
	if state == State.MENU or state == State.TITLE or state == State.MODAL:
		# Denyut glow lembut bulan (periode ~4 detik)
		var moon_sine := sin(ambient_time * (PI * 0.5))
		if moon_sprite:
			moon_sprite.modulate = COLOR_MOON_BASE * (1.0 + 0.15 * moon_sine)

		# Kamera "bernapas" (subtle floating offset 1-1.5 px)
		if cam:
			cam.offset.x = sin(ambient_time * 0.8) * 1.5
			cam.offset.y = cos(ambient_time * 0.6) * 1.0

		# Efek kabut berdenyut halus
		if mist_glow:
			mist_glow.modulate.a = 0.8 + 0.2 * sin(ambient_time * 0.7)


func _unhandled_input(event: InputEvent) -> void:
	# Skip Intro / Splash jika ada input tombol ditekan
	if (state == State.SPLASH or state == State.INTRO) and event.is_pressed() and not event.is_echo():
		_skip_to_menu()
		get_viewport().set_input_as_handled()
		return

	# Tutup modal jika tombol cancel ditekan saat di modal
	if state == State.MODAL and event.is_action_pressed("ui_cancel"):
		_on_modal_tutup_pressed()
		get_viewport().set_input_as_handled()
		return

	# Shortcut Layar Penuh (F11)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# ==========================================
# ALUR OPENING (STATE MACHINE)
# ==========================================

func _play_splash() -> void:
	state = State.SPLASH
	splash.visible = true
	splash.modulate.a = 0.0

	tween = create_tween()
	# 1. Fade in teks studio (0.6 dtk)
	tween.tween_property(splash, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 2. Tahan di layar (1.3 dtk)
	tween.tween_interval(1.3)
	# 3. Fade out teks studio (0.6 dtk)
	tween.tween_property(splash, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_play_intro)


func _play_intro() -> void:
	state = State.INTRO
	splash.visible = false
	cam.position.y = CAM_START_Y

	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Kamera turun dari CAM_START_Y ke posisi akhir (0.0) selama 4.8 detik
	tween.tween_property(cam, "position:y", CAM_END_Y, 4.8)
	tween.tween_callback(_play_title)


func _play_title() -> void:
	state = State.TITLE

	# 1. Bulan berdenyut sekali (modulate HDR naik lalu turun)
	var moon_tween := create_tween().set_trans(Tween.TRANS_QUAD)
	moon_tween.tween_property(moon_sprite, "modulate", COLOR_MOON_BASE * 1.9, 0.45).set_ease(Tween.EASE_OUT)
	moon_tween.tween_property(moon_sprite, "modulate", COLOR_MOON_BASE, 0.65).set_ease(Tween.EASE_IN)

	# 2. Logo AKSARA fade in lembut di bawah bulan
	title_container.visible = true
	title_container.modulate.a = 0.0

	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_container, "modulate:a", 1.0, 1.2)
	tween.tween_interval(0.3)
	tween.tween_callback(_show_menu)


func _show_menu() -> void:
	state = State.MENU

	if tween and tween.is_valid():
		tween.kill()

	splash.visible = false
	cam.position.y = CAM_END_Y
	title_container.visible = true
	title_container.modulate.a = 1.0

	menu.visible = true
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu, "modulate:a", 1.0, 0.5)

	# Fokus otomatis ke tombol MULAI
	btn_mulai.grab_focus()


func _skip_to_menu() -> void:
	if tween and tween.is_valid():
		tween.kill()
	_show_menu()


# ==========================================
# SETUP & EVENT HANDLER TOMBOL
# ==========================================

func _setup_buttons() -> void:
	var buttons: Array[Button] = [
		btn_mulai,
		btn_lanjutkan,
		btn_jurnal,
		btn_pengaturan,
		btn_keluar,
		btn_modal_tutup
	]

	for btn in buttons:
		if not btn:
			continue
		btn.focus_entered.connect(_on_btn_focus_entered.bind(btn))
		btn.focus_exited.connect(_on_btn_focus_exited.bind(btn))
		btn.mouse_entered.connect(_on_btn_mouse_entered.bind(btn))

	# Cek apakah ada file save
	var has_save := FileAccess.file_exists("user://savegame.save") or FileAccess.file_exists("user://save.dat")
	if not has_save:
		btn_lanjutkan.disabled = true
		btn_lanjutkan.focus_mode = Control.FOCUS_NONE
		btn_lanjutkan.text = "   LANJUTKAN"
		btn_lanjutkan.add_theme_color_override("font_color", COLOR_TEXT_DISABLED)
		btn_lanjutkan.add_theme_color_override("font_disabled_color", COLOR_TEXT_DISABLED)

	# Koneksi event klik
	btn_mulai.pressed.connect(_on_btn_mulai_pressed)
	btn_lanjutkan.pressed.connect(_on_btn_lanjutkan_pressed)
	btn_jurnal.pressed.connect(_on_btn_jurnal_pressed)
	btn_pengaturan.pressed.connect(_on_btn_pengaturan_pressed)
	btn_keluar.pressed.connect(_on_btn_keluar_pressed)
	btn_modal_tutup.pressed.connect(_on_modal_tutup_pressed)


func _clean_btn_title(text: String) -> String:
	return text.replace("◆", "").strip_edges()


func _on_btn_focus_entered(btn: Button) -> void:
	if btn.disabled:
		return
	var raw_title := _clean_btn_title(btn.text)
	btn.text = "◆ " + raw_title
	btn.add_theme_color_override("font_color", COLOR_TEXT_FOCUS)
	btn.add_theme_color_override("font_focus_color", COLOR_TEXT_FOCUS)


func _on_btn_focus_exited(btn: Button) -> void:
	if btn.disabled:
		return
	var raw_title := _clean_btn_title(btn.text)
	btn.text = "   " + raw_title
	btn.add_theme_color_override("font_color", COLOR_TEXT_DIM)


func _on_btn_mouse_entered(btn: Button) -> void:
	if not btn.disabled and state == State.MENU:
		btn.grab_focus()


func _on_btn_mulai_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	state = State.LEAVING

	# Kamera turun menembus awan dan fade to black
	tween = create_tween().set_parallel(true)
	tween.tween_property(cam, "position:y", 110.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(fade, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_pindah_ke_gameplay)


func _pindah_ke_gameplay() -> void:
	if ResourceLoader.exists(NEXT_SCENE):
		get_tree().change_scene_to_file(NEXT_SCENE)
	elif ResourceLoader.exists(FALLBACK_SCENE):
		print("Scene Prolog '%s' belum ada. Membuka scene fallback: %s" % [NEXT_SCENE, FALLBACK_SCENE])
		get_tree().change_scene_to_file(FALLBACK_SCENE)
	else:
		push_warning("Scene Prolog tidak ditemukan di: " + NEXT_SCENE)
		is_transitioning = false
		state = State.MENU
		fade.modulate.a = 0.0
		cam.position.y = CAM_END_Y


func _on_btn_lanjutkan_pressed() -> void:
	if btn_lanjutkan.disabled:
		return
	print("Memuat data simpanan...")
	_on_btn_mulai_pressed()


func _on_btn_jurnal_pressed() -> void:
	last_focused_btn = btn_jurnal
	_show_modal("JURNAL AKSARA", "Belum ada rekaman ekspedisi yang tersimpan.\nJelajahi reruntuhan Nusantara untuk membuka fragmen arsip kapsul.")


func _on_btn_pengaturan_pressed() -> void:
	last_focused_btn = btn_pengaturan
	_show_modal(
		"PENGATURAN",
		"Resolusi Dasar: 576 x 324 (16:9 Pixel Art)\nFilter Tekstur: Nearest Sharp Pixel\nMode Layar Penuh: Tekan F11"
	)


func _show_modal(title_text: String, body_text: String) -> void:
	state = State.MODAL
	modal_title.text = title_text
	modal_body.text = body_text
	modal_popup.visible = true
	modal_popup.modulate.a = 0.0

	var modal_tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	modal_tween.tween_property(modal_popup, "modulate:a", 1.0, 0.25)
	btn_modal_tutup.grab_focus()


func _on_modal_tutup_pressed() -> void:
	var modal_tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	modal_tween.tween_property(modal_popup, "modulate:a", 0.0, 0.2)
	modal_tween.tween_callback(func():
		modal_popup.visible = false
		state = State.MENU
		if last_focused_btn and is_instance_valid(last_focused_btn):
			last_focused_btn.grab_focus()
		else:
			btn_mulai.grab_focus()
	)


func _on_btn_keluar_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	state = State.LEAVING

	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): get_tree().quit())
