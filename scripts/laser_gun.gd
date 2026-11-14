extends Node2D
class_name LaserGun

signal laser_cast_completed(laser_data: Dictionary)
signal shooting_finished(laser_data: Dictionary)
signal target_struck(target: Node)

@export var max_bounces: int = 16
@export var max_distance: float = 4000.0
@export var shoot_duration: float = 0.25

var is_animating: bool = false
var anim_time: float = 0.0
var full_points: PackedVector2Array = []
var full_laser_data: Dictionary = {}
var target_hits_sequence: Array[Dictionary] = []
var total_beam_length: float = 0.0

@onready var muzzle: Marker2D = $Muzzle
@onready var laser_line: Line2D = $LaserLine

func _ready() -> void:
	if laser_line:
		laser_line.top_level = true
		laser_line.default_color = Color(1.0, 0.15, 0.15, 1.0)
		laser_line.width = 3.0
		laser_line.visible = false

func _process(delta: float) -> void:
	if not is_animating:
		return
	
	anim_time += delta
	var progress := clampf(anim_time / shoot_duration, 0.0, 1.0)
	var current_dist := progress * total_beam_length
	
	if laser_line:
		laser_line.visible = true
		laser_line.points = _get_partial_polyline(full_points, current_dist)
	
	# Trigger hit on targets as the beam reaches their distance
	for hit_info in target_hits_sequence:
		if current_dist >= hit_info.get("distance", 0.0):
			if not hit_info.get("triggered", false):
				hit_info["triggered"] = true
				var target_node: Node = hit_info.get("node")
				if is_instance_valid(target_node):
					target_struck.emit(target_node)
					if target_node.has_method("set_hit"):
						target_node.set_hit(true)
	
	if progress >= 1.0:
		is_animating = false
		if laser_line:
			laser_line.points = full_points
		shooting_finished.emit(full_laser_data)

func fire_laser(duration: float = 0.25) -> Dictionary:
	shoot_duration = duration
	full_laser_data = cast_laser()
	full_points = full_laser_data.get("points", PackedVector2Array())
	target_hits_sequence = full_laser_data.get("hits_sequence", [])
	total_beam_length = _calculate_total_length(full_points)
	
	anim_time = 0.0
	is_animating = true
	
	if laser_line:
		laser_line.visible = true
		laser_line.points = PackedVector2Array([muzzle.global_position])
	
	laser_cast_completed.emit(full_laser_data)
	return full_laser_data

func clear_laser() -> void:
	is_animating = false
	anim_time = 0.0
	if laser_line:
		laser_line.visible = false
		laser_line.points = PackedVector2Array()

func _calculate_total_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return maxf(total, 1.0)

func _get_partial_polyline(points: PackedVector2Array, current_dist: float) -> PackedVector2Array:
	if points.size() <= 1:
		return points
	if current_dist <= 0.0:
		return PackedVector2Array([points[0]])
	
	var result: PackedVector2Array = [points[0]]
	var dist_accum: float = 0.0
	
	for i in range(points.size() - 1):
		var p_start: Vector2 = points[i]
		var p_end: Vector2 = points[i + 1]
		var seg_len: float = p_start.distance_to(p_end)
		
		if dist_accum + seg_len <= current_dist:
			result.append(p_end)
			dist_accum += seg_len
			if is_equal_approx(dist_accum, current_dist):
				break
		else:
			var remain: float = current_dist - dist_accum
			var t: float = clampf(remain / seg_len, 0.0, 1.0)
			var tip: Vector2 = p_start.lerp(p_end, t)
			result.append(tip)
			break
	return result

func cast_laser() -> Dictionary:
	var space_state := get_world_2d().direct_space_state
	if not space_state or not muzzle:
		return {
			"points": PackedVector2Array(),
			"hit_zombies": [],
			"hit_humanoids": [],
			"hits_sequence": [],
			"bounces": 0
		}
	
	var current_pos: Vector2 = muzzle.global_position
	var points: PackedVector2Array = [current_pos]
	var current_dir: Vector2 = Vector2.RIGHT.rotated(global_rotation).normalized()
	var remaining_dist: float = max_distance
	var hit_zombies: Array[Node] = []
	var hit_humanoids: Array[Node] = []
	var hits_sequence: Array[Dictionary] = []
	var bounces: int = 0
	var exclude_rids: Array[RID] = []
	var accumulated_distance: float = 0.0
	
	var max_iterations := max_bounces + 35
	for _i in range(max_iterations):
		if remaining_dist <= 2.0 or bounces >= max_bounces:
			var end_pos := current_pos + current_dir * remaining_dist
			points.append(end_pos)
			break
		
		var target_pos := current_pos + current_dir * remaining_dist
		var query := PhysicsRayQueryParameters2D.create(current_pos, target_pos)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.exclude = exclude_rids
		
		var result := space_state.intersect_ray(query)
		if result.is_empty():
			points.append(target_pos)
			break
		
		var hit_pos: Vector2 = result.position
		var hit_normal: Vector2 = result.normal
		var collider: Object = result.collider
		var rid: RID = result.rid
		
		var step_len := current_pos.distance_to(hit_pos)
		accumulated_distance += step_len
		remaining_dist -= step_len
		
		if collider.is_in_group("zombies") or (collider.get_parent() and collider.get_parent().is_in_group("zombies")):
			var node: Node = collider if collider.is_in_group("zombies") else collider.get_parent()
			if not hit_zombies.has(node):
				hit_zombies.append(node)
			hits_sequence.append({
				"node": node,
				"distance": accumulated_distance,
				"type": "zombie",
				"triggered": false
			})
			exclude_rids.append(rid)
			current_pos = hit_pos + current_dir * 3.0
			continue
		
		elif collider.is_in_group("humanoids") or (collider.get_parent() and collider.get_parent().is_in_group("humanoids")):
			var node: Node = collider if collider.is_in_group("humanoids") else collider.get_parent()
			if not hit_humanoids.has(node):
				hit_humanoids.append(node)
			hits_sequence.append({
				"node": node,
				"distance": accumulated_distance,
				"type": "humanoid",
				"triggered": false
			})
			exclude_rids.append(rid)
			current_pos = hit_pos + current_dir * 3.0
			continue
		
		elif collider.is_in_group("reflectors") or (collider.get_parent() and collider.get_parent().is_in_group("reflectors")):
			points.append(hit_pos)
			bounces += 1
			var bounce_dir := current_dir.bounce(hit_normal).normalized()
			if bounce_dir == Vector2.ZERO or is_nan(bounce_dir.x):
				bounce_dir = -current_dir
			current_dir = bounce_dir
			current_pos = hit_pos + hit_normal * 1.5
			exclude_rids = [rid]
		
		else:
			# Wall or obstacle barrier
			points.append(hit_pos)
			break
	
	return {
		"points": points,
		"hit_zombies": hit_zombies,
		"hit_humanoids": hit_humanoids,
		"hits_sequence": hits_sequence,
		"bounces": bounces
	}
