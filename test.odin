package hpb

import "core:testing"
import rl "vendor:raylib"

@(test)
test_span :: proc(t: ^testing.T) {
	solver := Solver {
		gravity = rl.Vector2{0, 100},
		frame_dt_sec = 1,
		objs    = make([dynamic]VerletObj, 1),
	}
	defer solver_delete(&solver)

	solver_update(&solver)
	solver_update(&solver)


	testing.expectf(
		t,
		solver.objs[0].position_prev == rl.Vector2{0, 100},
		"Prev: expected %v, got %v",
		rl.Vector2{0, 100},
		solver.objs[0].position_prev,
	)
	testing.expectf(
		t,
		solver.objs[0].position_current == rl.Vector2{0, 300},
		"Curr: expected %v, got %v",
		rl.Vector2{0, 300},
		solver.objs[0].position_current,
	)
}
