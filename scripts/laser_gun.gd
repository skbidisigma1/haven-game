extends Node2D
class_name LaserGun

signal shooting_finished(laser_data: Dictionary)
signal target_struck(target: Node)
@export var max_bounces: int = 16
@export var max_distance: float = 5000.0
var is_animating := false
var elapsed := 0.0
var shoot_duration := 0.8
var full_laser_data: Dictionary = {}
var segments: Array[Dictionary] = []
var hit_events: Array[Dictionary] = []
var travel_length := 1.0
@onready var muzzle: Marker2D = $Muzzle

func clear_laser() -> void:
	is_animating = false
	segments.clear()
	hit_events.clear()
	queue_redraw()

func fire_laser(duration: float = 0.8) -> Dictionary:
	full_laser_data = cast_laser()
	segments = full_laser_data["segments"]
	hit_events = full_laser_data["hits_sequence"]
	travel_length = 1.0
	for segment in segments:
		travel_length = maxf(travel_length, segment["distance"] + segment["from"].distance_to(segment["to"]))
	elapsed = 0.0
	shoot_duration = maxf(duration, 0.01)
	is_animating = true
	queue_redraw()
	return full_laser_data

func _process(delta: float) -> void:
	if not is_animating: return
	elapsed += delta
	var distance := minf(elapsed / shoot_duration, 1.0) * travel_length
	for hit in hit_events:
		if not hit["triggered"] and distance >= hit["distance"]:
			hit["triggered"] = true
			var target: Target = hit["node"]
			if is_instance_valid(target):
				target.set_hit(true)
				target_struck.emit(target)
	queue_redraw()
	if elapsed >= shoot_duration:
		is_animating = false
		shooting_finished.emit(full_laser_data)

func _draw() -> void:
	var distance := minf(elapsed / shoot_duration, 1.0) * travel_length if is_animating else travel_length
	for segment in segments:
		var available: float = distance - segment["distance"]
		if available <= 0: continue
		var start: Vector2 = to_local(segment["from"])
		var end: Vector2 = to_local(segment["to"])
		end = start.move_toward(end, available)
		draw_line(start, end, Color(1, 0.35, 0.18, 0.12), 12)
		draw_line(start, end, Color("f1714d"), 4)
		draw_line(start, end, Color("fff2bc"), 1.5)
		draw_circle(end, 3, Color("fff2bc"))

func cast_laser() -> Dictionary:
	var space := get_world_2d().direct_space_state
	var rays: Array[Dictionary] = [{"pos": muzzle.global_position, "dir": Vector2.RIGHT.rotated(global_rotation), "distance": 0.0, "remaining": max_distance, "bounces": 0, "exclude": []}]
	var traced: Array[Dictionary] = []
	var zombies: Array[Node] = []
	var humans: Array[Node] = []
	var hits: Array[Dictionary] = []
	var bounce_count := 0
	var iterations := 0
	# Both per-path and global limits keep closed splitter circuits finite.
	while not rays.is_empty() and iterations < 256:
		var ray: Dictionary = rays.pop_front()
		var point: Vector2 = ray["pos"]
		var direction: Vector2 = ray["dir"]
		var remaining: float = ray["remaining"]
		var distance: float = ray["distance"]
		var excluded: Array[RID] = []
		for rid in ray["exclude"]: excluded.append(rid)
		while remaining > 0.1 and iterations < 256:
			iterations += 1
			var query := PhysicsRayQueryParameters2D.create(point, point + direction * remaining)
			query.collision_mask = 1
			query.collide_with_areas = true
			query.exclude = excluded
			var result := space.intersect_ray(query)
			var end: Vector2 = result["position"] if not result.is_empty() else point + direction * remaining
			var length := point.distance_to(end)
			traced.append({"from": point, "to": end, "distance": distance})
			distance += length
			remaining -= length
			if result.is_empty(): break
			var collider: Node = result["collider"]
			var rid: RID = result["rid"]
			if collider is Target:
				var list: Array[Node] = zombies if collider.target_type == Target.Type.ZOMBIE else humans
				if not list.has(collider):
					list.append(collider)
					hits.append({"node": collider, "distance": distance, "triggered": false})
				else:
					for hit in hits:
						if hit["node"] == collider:
							hit["distance"] = minf(hit["distance"], distance)
							break
				excluded.append(rid)
			elif collider is Platform:
				var normal := Vector2.UP.rotated(collider.global_rotation)
				# Stop at the final mirror; never invent an untraced outgoing beam.
				if ray["bounces"] >= max_bounces: break
				var reflected := direction.bounce(normal).normalized()
				if collider.kind == "splitter" and rays.size() < 32:
					rays.append({"pos": end + direction * 0.1, "dir": direction, "distance": distance + 0.1, "remaining": remaining - 0.1, "bounces": ray["bounces"] + 1, "exclude": [rid]})
				direction = reflected
				ray["bounces"] += 1
				bounce_count += 1
				excluded.clear()
				excluded.append(rid)
			else:
				break
			point = end + direction * 0.1
			distance += 0.1
			remaining -= 0.1
	# A target may be reached by several branches: play its first impact only.
	hits.sort_custom(func(a: Dictionary, b: Dictionary): return a["distance"] < b["distance"])
	return {"segments": traced, "hit_zombies": zombies, "hit_humanoids": humans, "hits_sequence": hits, "bounces": bounce_count}
