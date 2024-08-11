package hpb


import "base:builtin"
import "core:fmt"
import "core:mem"

import rl "vendor:raylib"


VerletObj :: struct {
	position_current: rl.Vector2,
	position_prev:    rl.Vector2,
	acceleration:     rl.Vector2,
	radius:           f32,
}

update_object_position :: proc(vo: ^VerletObj, dt_sec: f32) {
	velocity := vo.position_current - vo.position_prev
	vo.position_prev = vo.position_current
	vo.position_current += velocity + vo.acceleration * dt_sec * dt_sec
	vo.acceleration = rl.Vector2(0)
}

accelerate_object :: proc(vo: ^VerletObj, acc: rl.Vector2) {
	vo.acceleration += acc
}

constraint_object_circle :: proc(vo: ^VerletObj, center: rl.Vector2, radius: f32) {
	to_obj_axis := vo.position_current - center
	dist := rl.Vector2Length(to_obj_axis)
	if dist == 0 {return}
	if dist > radius - vo.radius {
		dir := to_obj_axis / dist
		vo.position_current = center + dir * (radius - vo.radius)
	}
}

constraint_object_rectangle :: proc(vo: ^VerletObj, rect: rl.Rectangle) {
}

Solver :: struct {
	sub_steps:         int,
	frame_dt_sec:      f32,
	//
	constraint_center: rl.Vector2,
	constraint_radius: f32,
	//
	gravity:           rl.Vector2,
	objs:              [dynamic]VerletObj,
}

solver_update :: proc(s: ^Solver) {
	sub_frame_dt_sec := s.frame_dt_sec / f32(s.sub_steps)

	for i := uint(s.sub_steps); i > 0; i -= 1 {
		solver_check_collisions(s)

		for &o in s.objs {
			accelerate_object(&o, s.gravity) // apply_gravity
			update_object_position(&o, sub_frame_dt_sec)
			constraint_object_circle(&o, s.constraint_center, s.constraint_radius) // apply_constraint
		}
	}
}
solver_check_collisions :: proc(s: ^Solver) {
	for &o_i in s.objs {
		for &o_j in s.objs {
			collision_axis := o_i.position_current - o_j.position_current
			dist := rl.Vector2Length(collision_axis)
			min_dist := o_i.radius + o_j.radius
			if dist == 0 {continue}
			if dist < min_dist {
				dir := collision_axis / dist
				delta := min_dist - dist
				offset := 0.5 * delta * dir
				o_i.position_current += offset
				o_j.position_current -= offset
			}
		}
	}
}

solver_delete :: proc(s: ^Solver) {
	builtin.delete(s.objs)
}

SCREEN_WIDTH_PX :: 800
SCREEN_HEIGHT_PX :: 600
FRAME_RATE :: 60
SUB_STEPS :: 4

MAX_OBJ_COUNT :: 100
SPAWN_DELAY_SEC :: 0.075

_main :: proc() {
	rl.SetConfigFlags({.WINDOW_HIGHDPI})
	rl.SetTargetFPS(FRAME_RATE)

	rl.InitWindow(SCREEN_WIDTH_PX, SCREEN_HEIGHT_PX, "Physic Sim")
	defer rl.CloseWindow()

	solver := Solver {
		gravity           = rl.Vector2{0, 1000},
		sub_steps         = SUB_STEPS,
		frame_dt_sec      = 1 / f32(FRAME_RATE),
		constraint_center = rl.Vector2{SCREEN_WIDTH_PX / 2, SCREEN_HEIGHT_PX / 2},
		constraint_radius = SCREEN_HEIGHT_PX / 2,
	}
	defer solver_delete(&solver)

	elapsed_from_last_spawn_sec := f32(rl.GetTime())

	for !rl.WindowShouldClose() {
		if len(solver.objs) < MAX_OBJ_COUNT && elapsed_from_last_spawn_sec >= SPAWN_DELAY_SEC {
			elapsed_from_last_spawn_sec = 0

			vo := VerletObj {
				position_current = rl.Vector2{600, 250},
				position_prev    = rl.Vector2{600, 248},
				radius           = 15,
			}
			append(&solver.objs, vo)
		} else {
			elapsed_from_last_spawn_sec += rl.GetFrameTime() // `GetFrameTime`: Get time in seconds for last frame drawn (delta time)
		}

		solver_update(&solver)


		rl.BeginDrawing()

		rl.ClearBackground({0x18, 0x18, 0x18, 0xFF})

		rl.DrawCircleV(solver.constraint_center, solver.constraint_radius, rl.GRAY)

		for i in 0 ..< len(solver.objs) {
			rl.DrawCircleV(
				solver.objs[i].position_current,
				solver.objs[i].radius,
				rl.ColorFromHSV(210, 0.5, 0.5),
			)
		}

		rl.DrawText(rl.TextFormat("Elapsed: %f", rl.GetTime()), 50, 50, 20, rl.MAROON)
		rl.DrawText(rl.TextFormat("FPS: %i", rl.GetFPS()), 50, 80, 20, rl.MAROON)

		rl.EndDrawing()
	}
}

main :: proc() {
	tracker: mem.Tracking_Allocator

	mem.tracking_allocator_init(&tracker, context.allocator)
	defer mem.tracking_allocator_destroy(&tracker)

	context.allocator = mem.tracking_allocator(&tracker)
	defer {
		fmt.println("=== evaluating mem leak... ===")
		if len(tracker.allocation_map) > 0 {
			fmt.eprintf("=== %v allocations not freed: ===\n", len(tracker.allocation_map))
			for _, entry in tracker.allocation_map {
				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
			}
		}
		if len(tracker.bad_free_array) > 0 {
			fmt.eprintf("=== %v incorrect frees: ===\n", len(tracker.bad_free_array))
			for entry in tracker.bad_free_array {
				fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
			}
		}
		fmt.println("=== evaluate mem leak done ===")
	}

	_main()
}
