shader_type canvas_item;

// 0 = screen fully visible, 1 = screen fully covered.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Keeps increasing through the whole transition so the lines always slide left.
uniform float scroll = 0.0;
// Distance between lines, in pixels.
uniform float spacing = 100.0;
// How much the lines lean (0 = straight up and down, 1 = 45 degrees).
uniform float lean = -0.2;
// How far the lines slide per unit of scroll, in line widths.
uniform float scroll_lines = 1.0;
// How much later the left side fills than the right (0 = all at once).
uniform float sweep = .5;
uniform vec4 line_color : source_color = vec4(0.00, 0.08, 0.23, 1.0);
// Set by the script: false while closing, true while opening.
// Either way the wave travels right-to-left: the right side fills first, then clears first.
uniform bool opening = false;

void fragment() {
	// Position across the slanted lines, measured in "lines". Adding scroll slides them left.
	float u = (FRAGCOORD.x + FRAGCOORD.y * lean) / spacing + scroll * scroll_lines;
	float stripe = fract(u);
	// The right side runs ahead: lines appear there first and spread left,
	// and on the way out they thin away from the right first too.
	float lag = opening ? UV.x : 1.0 - UV.x;
	float p = clamp(progress * (1.0 + sweep) - lag * sweep, 0.0, 1.0);
	// Each line thickens from its middle until it meets its neighbours.
	float covered = p > 0.0 ? step(abs(stripe - 0.5) * 2.0, p) : 0.0;
	COLOR = vec4(line_color.rgb, line_color.a * covered);
}
