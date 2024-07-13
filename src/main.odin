package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

GAME_SIZE :: 300

PADDLE_HEIGHT :: 5
PADDLE_WIDTH :: 40
PADDLE_Y_POS :: 260
PADDLE_SPEED :: 200

BALL_SPEED :: 260
BALL_RADIUS :: 3
BALL_START_Y :: 160

paddle_x_pos: f32

ball_pos: rl.Vector2
ball_dir: rl.Vector2

started: bool

restart :: proc() {
	paddle_x_pos = GAME_SIZE / 2 - PADDLE_WIDTH / 2
	ball_pos = {GAME_SIZE / 2, BALL_START_Y}
	started = false
}

reflect :: proc(dir: rl.Vector2, normal: rl.Vector2) -> rl.Vector2 {
	new_dir := linalg.reflect(dir, linalg.normalize(normal))
	return linalg.normalize(new_dir)
}

handle_wall_collisions :: proc() {
	// Ball is about to hit right side of the screen
	if ball_pos.x + BALL_RADIUS > GAME_SIZE {
		ball_pos.x = GAME_SIZE - BALL_RADIUS
		ball_dir = reflect(ball_dir, {-1, 0})
	}

	// Ball is about to hit the left side of the screen
	if ball_pos.x - BALL_RADIUS < 0 {
		ball_pos.x = BALL_RADIUS
		ball_dir = reflect(ball_dir, {1, 0})
	}

	// Ball is about to hit the top of the screen
	if ball_pos.y - BALL_RADIUS < 0 {
		ball_pos.y = BALL_RADIUS
		ball_dir = reflect(ball_dir, {0, -1})
	}

	// Ball has hit the bottom of the screen (game over)
	if ball_pos.y + BALL_RADIUS > GAME_SIZE {
		restart()
	}
}

handle_paddle_collisions :: proc(prev: rl.Vector2, rect: rl.Rectangle) -> rl.Vector2 {
	collision_normal: rl.Vector2

	// Ball is above the paddle
	if prev.y < rect.y + rect.height {
		collision_normal += {0, -1}
		ball_pos.y = rect.y - BALL_RADIUS
	}

	// Ball is below the paddle
	if prev.y > rect.y + rect.height {
		collision_normal += {0, 1}
		ball_pos.y = rect.y + rect.height + BALL_RADIUS
	}

	// Ball is to the left of the paddle
	if prev.x < rect.x {
		collision_normal += {-1, 0}
	}

	// Ball is to the right of the paddle
	if prev.x > rect.x + rect.width {
		collision_normal += {1, 0}
	}

	return reflect(ball_dir, collision_normal)
}

render :: proc() {

}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(900, 900, "Brick Breaker")
	rl.SetTargetFPS(500)

	restart()

	for !rl.WindowShouldClose() {
		dt: f32
		paddle_move_velocity: f32

		if !started {
			ball_pos = {GAME_SIZE / 2 + f32(math.cos(rl.GetTime()) * GAME_SIZE / 2.5), BALL_START_Y}

			if rl.IsKeyPressed(.SPACE) {
				paddle_middle := rl.Vector2{paddle_x_pos + PADDLE_WIDTH / 2, PADDLE_Y_POS}
				ball_to_paddle := paddle_middle - ball_pos

				ball_dir = linalg.normalize0(ball_to_paddle)
				started = true
			}
		} else {
			dt = rl.GetFrameTime()
		}

		previous_ball_pos := ball_pos
		ball_pos += ball_dir * BALL_SPEED * dt

		handle_wall_collisions()

		if rl.IsKeyDown(.A) {
			paddle_move_velocity -= PADDLE_SPEED
		}

		if rl.IsKeyDown(.D) {
			paddle_move_velocity += PADDLE_SPEED
		}

		paddle_x_pos += paddle_move_velocity * dt
		paddle_x_pos = clamp(paddle_x_pos, 0, GAME_SIZE - PADDLE_WIDTH)

		paddle_rect := rl.Rectangle{paddle_x_pos, PADDLE_Y_POS, PADDLE_WIDTH, PADDLE_HEIGHT}

		if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, paddle_rect) {
			ball_dir = handle_paddle_collisions(previous_ball_pos, paddle_rect)
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		camera := rl.Camera2D {
			zoom = f32(rl.GetScreenHeight() / GAME_SIZE),
		}

		rl.BeginMode2D(camera)
		defer rl.EndMode2D()

		rl.DrawRectangleRec(paddle_rect, rl.WHITE)
		rl.DrawCircleV(ball_pos, BALL_RADIUS, rl.RED)
	}

	rl.CloseWindow()
}

