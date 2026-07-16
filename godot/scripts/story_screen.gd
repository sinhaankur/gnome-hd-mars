extends RefCounted
class_name StoryScreen
## The game's story / mission briefing. Reusable panel builder.

const STORY := """[b]G-NOME — OPERATION RED WALL[/b]

[i]Mars. 2049. The Red Planet has an owner — it says so in the fine print.[/i]

[b]AREX[/b], the launch corporation that put the first boots on Mars, filed
claim to the entire planet under its colonial charter. Its autonomous factories
have been building landing pads, refineries and walker plants in every
strategic basin ever since — and its security fleet enforces the claim.
The nations of Earth answered with one voice: Mars belongs to everyone.
The Union sent its Martian Corps to make that true.

You pilot a [b]HAWC[/b] — a Heavily Armored Walker Chassis — for the Union's
Martian Corps. Your war is not to conquer but to [b]set up bases[/b]:
territory by territory, from orbit to regolith, planting installations where
AREX says nothing may stand. Your posting: [b]Red Wall[/b], the Union's first
foothold, on the northern plains of Arabia Terra — command dome, comms array,
fuel reserves, and the only water-processing plant for 400 kilometers.

AREX wants it gone. Its security HAWCs are already moving across the regolith,
wave after wave, to erase the base before Union reinforcements arrive.

[b]Your orders:[/b] establish the installation and hold it. Break every wave.
If Red Wall falls, the Union loses its foothold in the northern hemisphere —
and Mars stays a company town.

[color=#ffb060]Walk tall. Hold the line.[/color]"""

static func build(on_back: Callable) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.06, 0.05, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	root.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	margin.add_child(col)

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.text = STORY
	body.fit_content = true
	body.scroll_active = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 18)
	body.add_theme_font_size_override("bold_font_size", 22)
	col.add_child(body)

	var back := Button.new()
	back.text = "◀ BACK"
	back.custom_minimum_size = Vector2(160, 44)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(on_back)
	col.add_child(back)
	return root
