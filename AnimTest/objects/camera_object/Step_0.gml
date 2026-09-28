// ============================================================
// CAMERA TEST CONTROLS
// ============================================================

// K — Save current camera state.
if (keyboard_check_pressed(ord("K")))
{
    saved_state = camera_copy_state();
}


// T — Transition back to the saved camera state.
if (keyboard_check_pressed(ord("T")))
{
    if (!is_undefined(saved_state))
    {
        camera_apply_state_transition(saved_state, 2, CameraEase.SMOOTH);
    }
}

if (keyboard_check_pressed(ord("B")))
{
    camera_letterbox(2.39);
}

if (keyboard_check_pressed(ord("N")))
{
    camera_letterbox_clear_timed(1, CameraEase.SMOOTH);
}


// A — Test multi-target fit.
if (keyboard_check_pressed(ord("A")))
{
    camera_fit_clear_targets();
    camera_fit_start();

    camera_fit_scale_limits(0.2, 2.0);

    camera_fit_shrink(true);
    camera_fit_expand(false);

    camera_fit_add(instance_find(target1, 0));

    camera_fit_add(instance_find(target2, 0));

    camera_fit_add(instance_find(oPlayer, 0));
}


// F — Test normal player follow.
// This is also the primary camera-zone test.
if (keyboard_check_pressed(ord("F")))
{
    camera_fit_clear();

    camera_follow(instance_find(oPlayer, 0), 0.02, 0.85);
}


// I — Test timed zoom.
if (keyboard_check_pressed(ord("I")))
{
    camera_zoom_timed(0.8, 1, CameraEase.SMOOTH);
}


// J — Test normal smooth zoom at 100% of base size.
if (keyboard_check_pressed(ord("J")))
{
    camera_zoom(1.0);
}


// L — Test normal smooth zoom at 300% of base size.
if (keyboard_check_pressed(ord("L")))
{
    camera_zoom(3.0);
}


// O — Test camera transition.
if (keyboard_check_pressed(ord("O")))
{
    camera_transition_to_point(800, 800, 2, 10, true, CameraEase.SMOOTH);
}

if (keyboard_check_pressed(ord("P")))
{
    camera_pause_transition();
}

if (keyboard_check_pressed(ord("R")))
{
    camera_resume_transition();
}

if (keyboard_check_pressed(ord("X")))
{
    camera_interrupt();
}
if (keyboard_check_pressed(ord("C")))
{
    camera_transition_cancel();
}

// ============================================================
// CAMERA BOUNDS
// ============================================================

var _bounds_enabled = true;

var _bounds_left = 0;

var _bounds_top = 0;

var _bounds_right = room_width;

var _bounds_bottom = room_height;


switch (bounds_mode)
{
    case CameraBoundsMode.NONE:
        _bounds_enabled = false;
    break;


    case CameraBoundsMode.ROOM:
        _bounds_left = 0;

        _bounds_top = 0;

        _bounds_right = room_width;

        _bounds_bottom = room_height;
    break;


    case CameraBoundsMode.CUSTOM:
        _bounds_left = bounds_left;

        _bounds_top = bounds_top;

        _bounds_right = bounds_right;

        _bounds_bottom = bounds_bottom;
    break;
}

// ============================================================
// CAMERA ZONE SELECTION
// ============================================================

// Normal follow determines the currently relevant camera zone.
if (follow_active && instance_exists(follow_target))
{
    camera_zone_update(follow_target);
}
else
{
    current_camera_zone = noone;
}


// ============================================================
// CAMERA ZONE HANDOFF STATE
// ============================================================

// These are recalculated every step.
//
// A handoff exists only while moving into a fully-clamped zone
// and the physical camera is not yet completely legal inside it.
//
// Direction is tracked per axis, not per crossed edge. This lets
// the camera handle one, two, three, or even four currently
// crossed edges without maintaining fragile edge-entry state.

var _zone_handoff_active = false;
var _zone_handoff_x_active = false;
var _zone_handoff_y_active = false;

var _zone_handoff_dir_x = 0;
var _zone_handoff_dir_y = 0;

// ============================================================
// KEYFRAME SCHEDULER
// ============================================================

if (keyframe_active && !hold_active)
{
    var _keyframe_dt = delta_time / 1000000;
    var _keyframe_count = array_length(keyframe_group);

	var _keyframe_entry_transition_active =
    position_transition_active ||
    zoom_transition_active ||
    transition_active ||
    transition_compat_active;

    // ========================================================
    // ACTIVE MASTER SEGMENT
    // ========================================================

	if (keyframe_waiting_for_transition)
	{
		if (!_keyframe_entry_transition_active)
		{
		    keyframe_waiting_for_transition = false;

		    keyframe_wait_elapsed = 0;

		    keyframe_segment_active = false;
		    keyframe_segment_elapsed = 0;

		    camera_keyframe_apply_actions(keyframe_group[keyframe_index]);
		}
	}

	else if (keyframe_segment_active)
	{
        var _current_keyframe = keyframe_group[keyframe_index];

        keyframe_segment_elapsed += _keyframe_dt;

        var _segment_duration = max(_current_keyframe.keyframe_time, 0.001);


        if (keyframe_segment_elapsed >= _segment_duration)
        {
            keyframe_segment_active = false;
            keyframe_segment_elapsed = 0;

            keyframe_index++;
            keyframe_wait_elapsed = 0;
			camera_keyframe_apply_actions(keyframe_group[keyframe_index]);


            // =================================================
            // PROPERTY TARGETS REACHED
            // =================================================

            if (keyframe_position_target_index == keyframe_index)
                keyframe_position_target_index = -1;

            if (keyframe_zoom_target_index == keyframe_index)
                keyframe_zoom_target_index = -1;


        }
    }


    // ========================================================
    // WAIT AT CURRENT KEYFRAME
    // ========================================================

    else
    {
        var _current_keyframe = keyframe_group[keyframe_index];

        keyframe_wait_elapsed += _keyframe_dt;


        if (keyframe_wait_elapsed >= max(_current_keyframe.wait, 0))
        {
            keyframe_wait_elapsed = 0;


            if (keyframe_index < _keyframe_count - 1)
            {
                // =============================================
                // FIND NEXT ZOOM KEY
                // =============================================

                if (keyframe_zoom_target_index < 0)
                {
                    var _next_zoom_index = camera_keyframe_next_zoom(keyframe_group, keyframe_index);

                    if (_next_zoom_index >= 0)
                    {
                        var _zoom_keyframe = keyframe_group[_next_zoom_index];

                        var _zoom_duration = camera_keyframe_duration_to(keyframe_group, keyframe_index, _next_zoom_index);

                        keyframe_zoom_target_index = _next_zoom_index;

                        camera_zoom_transition(_zoom_keyframe.zoom_scale, _zoom_duration, _current_keyframe.keyframe_ease);
                    }
                }


                // =============================================
                // FIND NEXT POSITION KEY
                // =============================================

                if (keyframe_position_target_index < 0)
                {
                    var _next_position_index = camera_keyframe_next_position(keyframe_group, keyframe_index);

                    if (_next_position_index >= 0)
                    {
                        var _position_keyframe = keyframe_group[_next_position_index];

                        var _position_duration = camera_keyframe_duration_to(keyframe_group, keyframe_index, _next_position_index);

                        keyframe_position_target_index = _next_position_index;

                        camera_position_transition_to_keyframe(keyframe_group, keyframe_index, _next_position_index, _position_duration, _current_keyframe.keyframe_ease);
                    }
                }


                // =============================================
                // BEGIN NEXT MASTER SEGMENT
                // =============================================

                keyframe_segment_elapsed = 0;
                keyframe_segment_active = true;
            }

            else
            {
                keyframe_active = false;

                keyframe_position_target_index = -1;
                keyframe_zoom_target_index = -1;
            }
        }
    }
}
// ============================================================
// CAMERA HOLD
// ============================================================

if (hold_active)
{
    hold_elapsed += delta_time / 1000000;

    if (hold_elapsed >= hold_duration)
    {
        hold_active = false;
        hold_elapsed = 0;
    }
}

// ============================================================
// POSITION TRANSITION
// ============================================================

	// ============================================================
	// INDEPENDENT TRANSITION TRACKS
	// ============================================================

	else if (position_transition_active || (zoom_transition_active && keyframe_active))
	{
	    var _dt = delta_time / 1000000;


	    // ========================================================
	    // CURRENT PHYSICAL CAMERA
	    // ========================================================

	    var _old_width = camera_get_view_width(camera_id);
	    var _old_height = camera_get_view_height(camera_id);

	    var _old_x = camera_get_view_x(camera_id);
	    var _old_y = camera_get_view_y(camera_id);

	    var _old_center_x = _old_x + _old_width / 2;
	    var _old_center_y = _old_y + _old_height / 2;


	    // ========================================================
	    // DESIRED POSITION
	    // ========================================================

	    var _center_x = _old_center_x;
	    var _center_y = _old_center_y;


	    if (position_transition_active)
	    {
	        if (!position_transition_paused)
	        {
	            position_transition_elapsed += _dt;
	        }


	        var _position_t = clamp(
	            position_transition_elapsed / position_transition_duration,
	            0,
	            1
	        );


	        var _position_ease = _position_t;


	        switch (position_transition_ease)
	        {
	            case CameraEase.SMOOTH:
	                _position_ease = ease_smooth(_position_t);
	            break;


	            case CameraEase.IN:
	                _position_ease = ease_in(_position_t);
	            break;


	            case CameraEase.OUT:
	                _position_ease = ease_out(_position_t);
	            break;


	            case CameraEase.IN_OUT:
	                _position_ease = ease_in_out(_position_t);
	            break;


	            case CameraEase.LINEAR:
	                _position_ease = _position_t;
	            break;
	        }


			if (position_transition_replanned)
			{
			    _center_x = camera_hermite_value(position_transition_start_center_x, position_transition_start_velocity_x, position_transition_effective_center_x, position_transition_end_velocity_x, _position_t, position_transition_duration);

			    _center_y = camera_hermite_value(position_transition_start_center_y, position_transition_start_velocity_y, position_transition_effective_center_y, position_transition_end_velocity_y, _position_t, position_transition_duration);
			}

			else if (position_transition_spline_active)
			{
			    _center_x = camera_catmull_rom(position_transition_spline_p0_x, position_transition_spline_p1_x, position_transition_spline_p2_x, position_transition_spline_p3_x, _position_ease);

			    _center_y = camera_catmull_rom(position_transition_spline_p0_y, position_transition_spline_p1_y, position_transition_spline_p2_y, position_transition_spline_p3_y, _position_ease);
			}

			else
			{
			    _center_x = lerp(position_transition_start_center_x, position_transition_effective_center_x, _position_ease);

			    _center_y = lerp(position_transition_start_center_y, position_transition_effective_center_y, _position_ease);
			}
	    }


	    // ========================================================
	    // DESIRED ZOOM
	    // ========================================================

	    var _width = _old_width;
	    var _height = _old_height;


	    if (zoom_transition_active)
	    {
	        if (!zoom_transition_paused)
	        {
	            zoom_transition_elapsed += _dt;
	        }


	        var _zoom_t = clamp(
	            zoom_transition_elapsed / zoom_transition_duration,
	            0,
	            1
	        );


	        var _zoom_ease = _zoom_t;


	        switch (zoom_transition_ease)
	        {
	            case CameraEase.SMOOTH:
	                _zoom_ease = ease_smooth(_zoom_t);
	            break;


	            case CameraEase.IN:
	                _zoom_ease = ease_in(_zoom_t);
	            break;


	            case CameraEase.OUT:
	                _zoom_ease = ease_out(_zoom_t);
	            break;


	            case CameraEase.IN_OUT:
	                _zoom_ease = ease_in_out(_zoom_t);
	            break;


	            case CameraEase.LINEAR:
	                _zoom_ease = _zoom_t;
	            break;
	        }


	        var _scale = lerp(
	            zoom_transition_start_scale,
	            zoom_transition_effective_scale,
	            _zoom_ease
	        );


	        _width = zoom_base_width * _scale;
	        _height = zoom_base_height * _scale;


	        // ====================================================
	        // ZOOM-ONLY ANCHOR
	        // ====================================================

	        // If position is actively controlling the center,
	        // position owns it.
	        //
	        // If zoom is operating alone, preserve the existing
	        // zoom-anchor behavior.

	        if (!position_transition_active)
	        {
	            var _new_x = _old_x;
	            var _new_y = _old_y;


	            if (zoom_anchor_x == 0)
	            {
	                _new_x += (_old_width - _width) / 2;
	            }

	            else if (zoom_anchor_x == 1)
	            {
	                _new_x += (_old_width - _width);
	            }


	            if (zoom_anchor_y == 0)
	            {
	                _new_y += (_old_height - _height) / 2;
	            }

	            else if (zoom_anchor_y == 1)
	            {
	                _new_y += (_old_height - _height);
	            }


	            _center_x = _new_x + _width / 2;
	            _center_y = _new_y + _height / 2;
	        }
	    }


	    // ========================================================
	    // SHARED RECTANGLE RESOLUTION
	    // ========================================================

	    var _resolved = camera_resolve_view_rect(
	        _center_x - _width / 2,
	        _center_y - _height / 2,
	        _width,
	        _height
	    );


	    // ========================================================
	    // PHYSICAL POSITION VELOCITY
	    // ========================================================

	    if (position_transition_active && _dt > 0)
	    {
	        position_transition_velocity_x =
	            (_resolved.center_x - position_transition_last_center_x) / _dt;

	        position_transition_velocity_y =
	            (_resolved.center_y - position_transition_last_center_y) / _dt;


	        position_transition_last_center_x = _resolved.center_x;
	        position_transition_last_center_y = _resolved.center_y;
	    }


	    // ========================================================
	    // PHYSICAL ZOOM VELOCITY
	    // ========================================================

	    if (zoom_transition_active && _dt > 0)
	    {
	        var _resolved_scale =
	            _resolved.width / max(zoom_base_width, 1);

	        zoom_transition_velocity =
	            (_resolved_scale - zoom_transition_last_scale) / _dt;

	        zoom_transition_last_scale = _resolved_scale;
	    }


	    // ========================================================
	    // APPLY CAMERA ONCE
	    // ========================================================

	    camera_set_view_size(
	        camera_id,
	        _resolved.width,
	        _resolved.height
	    );

	    camera_set_view_pos(
	        camera_id,
	        _resolved.x,
	        _resolved.y
	    );


	    // ========================================================
	    // POSITION FINISHED
	    // ========================================================

		if (position_transition_active)
		{
		    if (position_transition_elapsed >= position_transition_duration)
		    {
		        position_transition_active = false;

		        position_transition_elapsed =
		            position_transition_duration;

		        position_transition_replanned = false;
		        position_transition_spline_active = false;

		        position_transition_velocity_x = 0;
		        position_transition_velocity_y = 0;
		    }
		}

	    // ========================================================
	    // ZOOM FINISHED
	    // ========================================================

	    if (zoom_transition_active)
	    {
	        if (zoom_transition_elapsed >= zoom_transition_duration)
	        {
	            zoom_transition_active = false;

	            zoom_transition_elapsed =
	                zoom_transition_duration;


	            zoom_target_width =
	                zoom_base_width * zoom_transition_requested_scale;

	            zoom_target_height =
	                zoom_base_height * zoom_transition_requested_scale;
	        }
	    }
		
		// ========================================================
		// COMPATIBILITY TRANSITION FINISHED
		// ========================================================

		if (transition_compat_active &&
		    !position_transition_active &&
		    !zoom_transition_active)
		{
		    transition_compat_active = false;


		    // ====================================================
		    // KEEP FINAL STATE
		    // ====================================================

		    if (transition_compat_keep_end)
		    {
		        zoom_target_width =
		            zoom_base_width * transition_compat_end_scale;

		        zoom_target_height =
		            zoom_base_height * transition_compat_end_scale;


		        if (instance_exists(transition_compat_target))
		        {
		            camera_set_view_target(
		                camera_id,
		                transition_compat_target
		            );

		            camera_target_border_center(camera_id);
		        }
		        else
		        {
		            camera_set_view_target(camera_id, noone);
		        }
		    }


		    // ====================================================
		    // RESTORE PREVIOUS CONTROL STATE
		    // ====================================================

		    else
		    {
		        zoom_target_width =
		            transition_compat_previous_zoom_width;

		        zoom_target_height =
		            transition_compat_previous_zoom_height;

		        camera_set_view_target(
		            camera_id,
		            transition_compat_previous_target
		        );
		    }
		}
	}

// ============================================================
// CAMERA TRANSITION
// ============================================================

else if (transition_active)
{
    if (!transition_paused)
    {
        transition_progress += (delta_time / 1000000) / transition_duration;
    }

    var _t = clamp(transition_progress, 0, 1);


    // ========================================================
    // TRANSITION EASING
    // ========================================================

    var _ease = _t;


    switch (transition_ease)
    {
        case CameraEase.SMOOTH:
            _ease = ease_smooth(_t);
        break;


        case CameraEase.IN:
            _ease = ease_in(_t);
        break;


        case CameraEase.OUT:
            _ease = ease_out(_t);
        break;


        case CameraEase.IN_OUT:
            _ease = ease_in_out(_t);
        break;


        case CameraEase.LINEAR:
            _ease = _t;
        break;
    }


    // ========================================================
    // TRANSITION SIZE
    // ========================================================

    var _width = lerp(transition_start_width, transition_target_width, _ease);

    var _height = lerp(transition_start_height, transition_target_height, _ease);


    // ========================================================
    // TRANSITION CENTER
    // ========================================================

    var _center_x = lerp(transition_start_center_x, transition_target_center_x, _ease);

    var _center_y = lerp(transition_start_center_y, transition_target_center_y, _ease);


    var _x = _center_x - _width / 2;

    var _y = _center_y - _height / 2;


	// ========================================================
	// TRANSITION RECTANGLE RESOLUTION
	// ========================================================

	var _resolved = camera_resolve_view_rect(_x, _y, _width, _height);

	_x = _resolved.x;
	_y = _resolved.y;

	_width = _resolved.width;
	_height = _resolved.height;


    // ========================================================
    // APPLY TRANSITION
    // ========================================================

    camera_set_view_size(camera_id, _width, _height);

    camera_set_view_pos(camera_id, _x, _y);


    // ========================================================
    // TRANSITION FINISHED
    // ========================================================

    if (_t >= 1)
    {
        transition_active = false;


        if (!is_undefined(transition_target_state))
        {
            var _state = transition_target_state;

            transition_target_state = undefined;

            camera_apply_state(_state);

            // Keep the final transition position/size after applying
            // the state's behavioral settings.
            camera_set_view_size(camera_id, _width, _height);
            camera_set_view_pos(camera_id, _x, _y);
        }

        else if (transition_keep_end)
        {
            zoom_target_width = transition_target_width;

            zoom_target_height = transition_target_height;


            camera_set_view_target(camera_id, transition_target);

            camera_target_border_center(camera_id);
        }

        else
        {
            zoom_target_width = transition_previous_zoom_width;

            zoom_target_height = transition_previous_zoom_height;


            camera_set_view_target(camera_id, transition_previous_target);
        }
    }
}


else if (!keyframe_active)
{
    // ========================================================
    // CINEMATIC CAMERA FOLLOW
    // ========================================================

    if (follow_active && !fit_active)
    {
        if (instance_exists(follow_target))
        {

            // =================================================
            // LOOK-AHEAD TARGET MOVEMENT
            // =================================================

            var _lookahead_velocity_x = 0;
            var _lookahead_velocity_y = 0;

            if (lookahead_active)
            {
                if (!lookahead_initialized)
                {
                    lookahead_previous_x = follow_target.x;
                    lookahead_previous_y = follow_target.y;

                    lookahead_initialized = true;
                }
                else
                {
                    _lookahead_velocity_x = follow_target.x - lookahead_previous_x;

                    _lookahead_velocity_y = follow_target.y - lookahead_previous_y;

                    lookahead_previous_x = follow_target.x;
                    lookahead_previous_y = follow_target.y;
                }
            }
            else
            {
                lookahead_initialized = false;
            }

            // =================================================
            // LOOK-AHEAD TARGET
            // =================================================

            if (lookahead_active)
            {
                if (_lookahead_velocity_x > 0)
                    lookahead_target_x = lookahead_distance_x;
                else if (_lookahead_velocity_x < 0)
                    lookahead_target_x = -lookahead_distance_x;
                else
                    lookahead_target_x = 0;


                if (_lookahead_velocity_y > 0)
                    lookahead_target_y = lookahead_distance_y;
                else if (_lookahead_velocity_y < 0)
                    lookahead_target_y = -lookahead_distance_y;
                else
                    lookahead_target_y = 0;


                lookahead_x = lerp(lookahead_x, lookahead_target_x, lookahead_speed);

                lookahead_y = lerp(lookahead_y, lookahead_target_y, lookahead_speed);
            }
            else
            {
                lookahead_x = 0;
                lookahead_y = 0;

                lookahead_target_x = 0;
                lookahead_target_y = 0;
            }

            var _follow_view_width = camera_get_view_width(camera_id);

            var _follow_view_height = camera_get_view_height(camera_id);

            var _follow_half_width = _follow_view_width / 2;

            var _follow_half_height = _follow_view_height / 2;


            // =================================================
            // CURRENT CAMERA CENTER
            // =================================================

            var _follow_center_x = camera_get_view_x(camera_id) + _follow_half_width;

            var _follow_center_y = camera_get_view_y(camera_id) + _follow_half_height;


            // =================================================
            // SMOOTH FOLLOW OFFSET
            // =================================================

            follow_offset_x = lerp(follow_offset_x, follow_offset_target_x, follow_offset_speed);

            follow_offset_y = lerp(follow_offset_y, follow_offset_target_y, follow_offset_speed);


            // =================================================
            // FOLLOW POSITION
            // =================================================

            var _follow_x = follow_target.x + follow_offset_x + lookahead_x;

            var _follow_y = follow_target.y + follow_offset_y + lookahead_y;

            // =================================================
            // FOLLOW DEAD ZONE
            // =================================================

            var _follow_target_x = _follow_center_x;

            var _follow_target_y = _follow_center_y;


            if (follow_x_active)
            {
                if (_follow_x > _follow_center_x + border_x)
                {
                    _follow_target_x = _follow_x - border_x;
                }

                else if (_follow_x < _follow_center_x - border_x)
                {
                    _follow_target_x = _follow_x + border_x;
                }
            }


            if (follow_y_active)
            {
                if (_follow_y > _follow_center_y + border_y)
                {
                    _follow_target_y = _follow_y - border_y;
                }

                else if (_follow_y < _follow_center_y - border_y)
                {
                    _follow_target_y = _follow_y + border_y;
                }
            }


            // =================================================
            // FOLLOW TARGET ZONE
            // =================================================

            // The selected zone constrains the DESIRED camera
            // position. The physical camera is still allowed to
            // ease toward that destination over multiple frames.

            if (instance_exists(current_camera_zone))
            {
                var _follow_zone_position = camera_zone_apply_bounds(_follow_target_x - _follow_half_width, _follow_target_y - _follow_half_height, _follow_view_width, _follow_view_height);

                _follow_target_x = _follow_zone_position.x + _follow_half_width;

                _follow_target_y = _follow_zone_position.y + _follow_half_height;
            }


            // =================================================
            // FOLLOW TARGET GLOBAL BOUNDS
            // =================================================

            // Global ROOM / CUSTOM bounds remain the outer legal
            // area and therefore win over any local zone constraint.

            if (_bounds_enabled)
            {
                var _follow_min_x = _bounds_left + _follow_half_width;

                var _follow_max_x = _bounds_right - _follow_half_width;

                var _follow_min_y = _bounds_top + _follow_half_height;

                var _follow_max_y = _bounds_bottom - _follow_half_height;


                if (_follow_min_x > _follow_max_x)
                {
                    _follow_target_x = (_bounds_left + _bounds_right) / 2;
                }
                else
                {
                    _follow_target_x = clamp(_follow_target_x, _follow_min_x, _follow_max_x);
                }


                if (_follow_min_y > _follow_max_y)
                {
                    _follow_target_y = (_bounds_top + _bounds_bottom) / 2;
                }
                else
                {
                    _follow_target_y = clamp(_follow_target_y, _follow_min_y, _follow_max_y);
                }
            }


            // =================================================
            // CAMERA ZONE HANDOFF
            // =================================================

            // Horizontal and vertical containment are independent.
            //
            // A horizontal handoff only requires LEFT + RIGHT to
            // be clamped. A vertical handoff only requires TOP +
            // BOTTOM to be clamped.
            //
            // This is important for pass-through zones. A zone may
            // be open on one horizontal side while still remaining
            // fully contained vertically.

            var _follow_zone = noone;

            var _follow_cross_left = false;
            var _follow_cross_right = false;
            var _follow_cross_top = false;
            var _follow_cross_bottom = false;


            if (instance_exists(current_camera_zone))
            {
                _follow_zone = current_camera_zone;

                var _handoff_left = _follow_center_x - _follow_half_width;
                var _handoff_right = _follow_center_x + _follow_half_width;
                var _handoff_top = _follow_center_y - _follow_half_height;
                var _handoff_bottom = _follow_center_y + _follow_half_height;

                _follow_cross_left = _follow_zone.clamp_left && _handoff_left < _follow_zone.zone_left - 0.001;
                _follow_cross_right = _follow_zone.clamp_right && _handoff_right > _follow_zone.zone_right + 0.001;
                _follow_cross_top = _follow_zone.clamp_top && _handoff_top < _follow_zone.zone_top - 0.001;
                _follow_cross_bottom = _follow_zone.clamp_bottom && _handoff_bottom > _follow_zone.zone_bottom + 0.001;

                var _handoff_x_contained = _follow_zone.clamp_left && _follow_zone.clamp_right;
                var _handoff_y_contained = _follow_zone.clamp_top && _follow_zone.clamp_bottom;

                var _handoff_x_legal = !_handoff_x_contained || (!_follow_cross_left && !_follow_cross_right);
                var _handoff_y_legal = !_handoff_y_contained || (!_follow_cross_top && !_follow_cross_bottom);

                _zone_handoff_x_active = _handoff_x_contained && !_handoff_x_legal;
                _zone_handoff_y_active = _handoff_y_contained && !_handoff_y_legal;
                _zone_handoff_active = _zone_handoff_x_active || _zone_handoff_y_active;


                // =========================================
                // HORIZONTAL HANDOFF DIRECTION
                // =========================================

                if (_zone_handoff_x_active)
                {
                    if (abs(_handoff_right - _follow_zone.zone_right) <= 0.001)
                    {
                        _zone_handoff_dir_x = 1;
                    }
                    else if (abs(_handoff_left - _follow_zone.zone_left) <= 0.001)
                    {
                        _zone_handoff_dir_x = -1;
                    }
                    else
                    {
                        var _handoff_dx = _follow_target_x - _follow_center_x;

                        if (abs(_handoff_dx) > 0.001)
                        {
                            _zone_handoff_dir_x = sign(_handoff_dx);
                        }
                        else if (abs(follow_velocity_x) > 0.001)
                        {
                            _zone_handoff_dir_x = sign(follow_velocity_x);
                        }
                        else
                        {
                            var _handoff_zone_center_x = (_follow_zone.zone_left + _follow_zone.zone_right) / 2;

                            if (_follow_center_x < _handoff_zone_center_x)
                                _zone_handoff_dir_x = 1;
                            else if (_follow_center_x > _handoff_zone_center_x)
                                _zone_handoff_dir_x = -1;
                        }
                    }

                    if (_zone_handoff_dir_x > 0)
                        _follow_target_x = min(_follow_target_x, _follow_zone.zone_right - _follow_half_width);
                    else if (_zone_handoff_dir_x < 0)
                        _follow_target_x = max(_follow_target_x, _follow_zone.zone_left + _follow_half_width);
                }


                // =========================================
                // VERTICAL HANDOFF DIRECTION
                // =========================================

                if (_zone_handoff_y_active)
                {
                    if (abs(_handoff_bottom - _follow_zone.zone_bottom) <= 0.001)
                    {
                        _zone_handoff_dir_y = 1;
                    }
                    else if (abs(_handoff_top - _follow_zone.zone_top) <= 0.001)
                    {
                        _zone_handoff_dir_y = -1;
                    }
                    else
                    {
                        var _handoff_dy = _follow_target_y - _follow_center_y;

                        if (abs(_handoff_dy) > 0.001)
                        {
                            _zone_handoff_dir_y = sign(_handoff_dy);
                        }
                        else if (abs(follow_velocity_y) > 0.001)
                        {
                            _zone_handoff_dir_y = sign(follow_velocity_y);
                        }
                        else
                        {
                            var _handoff_zone_center_y = (_follow_zone.zone_top + _follow_zone.zone_bottom) / 2;

                            if (_follow_center_y < _handoff_zone_center_y)
                                _zone_handoff_dir_y = 1;
                            else if (_follow_center_y > _handoff_zone_center_y)
                                _zone_handoff_dir_y = -1;
                        }
                    }

                    if (_zone_handoff_dir_y > 0)
                        _follow_target_y = min(_follow_target_y, _follow_zone.zone_bottom - _follow_half_height);
                    else if (_zone_handoff_dir_y < 0)
                        _follow_target_y = max(_follow_target_y, _follow_zone.zone_top + _follow_half_height);
                }
            }


            // =================================================
            // FOLLOW VELOCITY
            // =================================================

            if (follow_x_active)
            {
                follow_velocity_x += (_follow_target_x - _follow_center_x) * follow_strength;

                follow_velocity_x *= follow_damping;
            }

            else
            {
                follow_velocity_x = 0;
            }


            if (follow_y_active)
            {
                follow_velocity_y += (_follow_target_y - _follow_center_y) * follow_strength;

                follow_velocity_y *= follow_damping;
            }

            else
            {
                follow_velocity_y = 0;
            }

            // =================================================
            // FOLLOW SPEED LIMIT
            // =================================================

            if (follow_max_speed > 0)
            {
                var _follow_speed = sqrt(sqr(follow_velocity_x) + sqr(follow_velocity_y));

                if (_follow_speed > follow_max_speed)
                {
                    var _follow_speed_scale = follow_max_speed / _follow_speed;

                    follow_velocity_x *= _follow_speed_scale;

                    follow_velocity_y *= _follow_speed_scale;
                }
            }

            // =================================================
            // FOLLOW OVERSHOOT CONTROL
            // =================================================

            // Zone handoff overshoot is controlled per axis.
            // A horizontal handoff must not change vertical spring
            // behavior, and a vertical handoff must not change
            // horizontal spring behavior.

            var _follow_prevent_overshoot_x = !follow_allow_overshoot || _zone_handoff_x_active;
            var _follow_prevent_overshoot_y = !follow_allow_overshoot || _zone_handoff_y_active;


            if (_follow_prevent_overshoot_x && follow_x_active)
            {
                var _follow_next_x = _follow_center_x + follow_velocity_x;

                if ((_follow_center_x < _follow_target_x && _follow_next_x > _follow_target_x) || (_follow_center_x > _follow_target_x && _follow_next_x < _follow_target_x))
                {
                    _follow_center_x = _follow_target_x;
                    follow_velocity_x = 0;
                }
            }


            if (_follow_prevent_overshoot_y && follow_y_active)
            {
                var _follow_next_y = _follow_center_y + follow_velocity_y;

                if ((_follow_center_y < _follow_target_y && _follow_next_y > _follow_target_y) || (_follow_center_y > _follow_target_y && _follow_next_y < _follow_target_y))
                {
                    _follow_center_y = _follow_target_y;
                    follow_velocity_y = 0;
                }
            }


            // =================================================
            // MOVE CAMERA CENTER
            // =================================================

            _follow_center_x += follow_velocity_x;

            _follow_center_y += follow_velocity_y;


            // =================================================
            // FINAL FOLLOW ZONE EDGES
            // =================================================

            // Every enabled edge is enforced independently.
            //
            // If an edge was already crossed before this frame,
            // do not snap the camera back across it. The camera
            // may recover naturally toward the zone target.
            //
            // Any enabled edge that was still legal before this
            // frame may not be newly crossed. This keeps TOP /
            // BOTTOM confinement active during a horizontal
            // handoff and LEFT / RIGHT confinement active during
            // a vertical handoff.

            if (instance_exists(_follow_zone))
            {
                if (_follow_zone.clamp_left && !_follow_cross_left)
                {
                    var _follow_zone_min_x = _follow_zone.zone_left + _follow_half_width;

                    if (_follow_center_x < _follow_zone_min_x)
                    {
                        _follow_center_x = _follow_zone_min_x;

                        if (follow_velocity_x < 0)
                            follow_velocity_x = 0;
                    }
                }

                if (_follow_zone.clamp_right && !_follow_cross_right)
                {
                    var _follow_zone_max_x = _follow_zone.zone_right - _follow_half_width;

                    if (_follow_center_x > _follow_zone_max_x)
                    {
                        _follow_center_x = _follow_zone_max_x;

                        if (follow_velocity_x > 0)
                            follow_velocity_x = 0;
                    }
                }

                if (_follow_zone.clamp_top && !_follow_cross_top)
                {
                    var _follow_zone_min_y = _follow_zone.zone_top + _follow_half_height;

                    if (_follow_center_y < _follow_zone_min_y)
                    {
                        _follow_center_y = _follow_zone_min_y;

                        if (follow_velocity_y < 0)
                            follow_velocity_y = 0;
                    }
                }

                if (_follow_zone.clamp_bottom && !_follow_cross_bottom)
                {
                    var _follow_zone_max_y = _follow_zone.zone_bottom - _follow_half_height;

                    if (_follow_center_y > _follow_zone_max_y)
                    {
                        _follow_center_y = _follow_zone_max_y;

                        if (follow_velocity_y > 0)
                            follow_velocity_y = 0;
                    }
                }
            }


            // =================================================
            // FINAL FOLLOW GLOBAL BOUNDS
            // =================================================

            // Zones are intentionally NOT reapplied here.
            // Reapplying them to the physical camera would snap
            // the camera into a newly selected zone instead of
            // allowing the follow spring to transition into it.

            if (_bounds_enabled)
            {
                var _final_follow_min_x = _bounds_left + _follow_half_width;

                var _final_follow_max_x = _bounds_right - _follow_half_width;

                var _final_follow_min_y = _bounds_top + _follow_half_height;

                var _final_follow_max_y = _bounds_bottom - _follow_half_height;


                if (_final_follow_min_x > _final_follow_max_x)
                {
                    _follow_center_x = (_bounds_left + _bounds_right) / 2;
                }
                else
                {
                    _follow_center_x = clamp(_follow_center_x, _final_follow_min_x, _final_follow_max_x);
                }


                if (_final_follow_min_y > _final_follow_max_y)
                {
                    _follow_center_y = (_bounds_top + _bounds_bottom) / 2;
                }
                else
                {
                    _follow_center_y = clamp(_follow_center_y, _final_follow_min_y, _final_follow_max_y);
                }
            }


            // =================================================
            // APPLY CINEMATIC FOLLOW
            // =================================================

            camera_set_view_pos(camera_id, _follow_center_x - _follow_half_width, _follow_center_y - _follow_half_height);
        }

        else
        {
            follow_active = false;

            follow_velocity_x = 0;

            follow_velocity_y = 0;
        }
    }

	// ============================================================
	// INDEPENDENT ZOOM DURING NORMAL CAMERA CONTROL
	// ============================================================

	if (zoom_transition_active)
	{
	    var _zoom_dt = delta_time / 1000000;


	    // ========================================================
	    // CURRENT PHYSICAL CAMERA
	    // ========================================================

	    var _zoom_old_width = camera_get_view_width(camera_id);
	    var _zoom_old_height = camera_get_view_height(camera_id);

	    var _zoom_old_x = camera_get_view_x(camera_id);
	    var _zoom_old_y = camera_get_view_y(camera_id);


	    // ========================================================
	    // UPDATE ZOOM TRACK
	    // ========================================================

	    if (!zoom_transition_paused)
	    {
	        zoom_transition_elapsed += _zoom_dt;
	    }


	    var _zoom_t = clamp(
	        zoom_transition_elapsed /
	        zoom_transition_duration,
	        0,
	        1
	    );


	    var _zoom_ease =
	        camera_ease_value(
	            _zoom_t,
	            zoom_transition_ease
	        );


	    var _zoom_scale = lerp(
	        zoom_transition_start_scale,
	        zoom_transition_effective_scale,
	        _zoom_ease
	    );


	    var _zoom_new_width =
	        zoom_base_width * _zoom_scale;

	    var _zoom_new_height =
	        zoom_base_height * _zoom_scale;


	    // ========================================================
	    // ZOOM ANCHOR
	    // ========================================================

	    var _zoom_new_x = _zoom_old_x;
	    var _zoom_new_y = _zoom_old_y;


	    if (zoom_anchor_x == 0)
	        _zoom_new_x += (_zoom_old_width - _zoom_new_width) / 2;
	    else if (zoom_anchor_x == 1)
	        _zoom_new_x += (_zoom_old_width - _zoom_new_width);


	    if (zoom_anchor_y == 0)
	        _zoom_new_y += (_zoom_old_height - _zoom_new_height) / 2;
	    else if (zoom_anchor_y == 1)
	        _zoom_new_y += (_zoom_old_height - _zoom_new_height);


	    // ========================================================
	    // GLOBAL EDGE ANCHORS
	    // ========================================================

	    if (_bounds_enabled)
	    {
	        var _zoom_touch_left =
	            _zoom_old_x <= _bounds_left + 0.001;

	        var _zoom_touch_right =
	            _zoom_old_x + _zoom_old_width >=
	            _bounds_right - 0.001;

	        var _zoom_touch_top =
	            _zoom_old_y <= _bounds_top + 0.001;

	        var _zoom_touch_bottom =
	            _zoom_old_y + _zoom_old_height >=
	            _bounds_bottom - 0.001;


	        if (_zoom_touch_left && !_zoom_touch_right)
	            _zoom_new_x = _bounds_left;
	        else if (_zoom_touch_right && !_zoom_touch_left)
	            _zoom_new_x = _bounds_right - _zoom_new_width;


	        if (_zoom_touch_top && !_zoom_touch_bottom)
	            _zoom_new_y = _bounds_top;
	        else if (_zoom_touch_bottom && !_zoom_touch_top)
	            _zoom_new_y = _bounds_bottom - _zoom_new_height;
	    }


	    // ========================================================
	    // FINAL RECTANGLE
	    // ========================================================

	    var _zoom_resolved =
	        camera_resolve_view_rect(
	            _zoom_new_x,
	            _zoom_new_y,
	            _zoom_new_width,
	            _zoom_new_height
	        );


	    camera_set_view_size(
	        camera_id,
	        _zoom_resolved.width,
	        _zoom_resolved.height
	    );

	    camera_set_view_pos(
	        camera_id,
	        _zoom_resolved.x,
	        _zoom_resolved.y
	    );


	    // ========================================================
	    // TRACK VELOCITY
	    // ========================================================

	    if (_zoom_dt > 0)
	    {
	        var _resolved_scale =
	            _zoom_resolved.width /
	            max(zoom_base_width, 1);

	        zoom_transition_velocity =
	            (_resolved_scale -
	            zoom_transition_last_scale) /
	            _zoom_dt;

	        zoom_transition_last_scale =
	            _resolved_scale;
	    }


	    // ========================================================
	    // FINISHED
	    // ========================================================

	    if (zoom_transition_elapsed >= zoom_transition_duration)
	    {
	        zoom_transition_active = false;

	        zoom_transition_elapsed =
	            zoom_transition_duration;

	        zoom_target_width =
	            zoom_base_width *
	            zoom_transition_requested_scale;

	        zoom_target_height =
	            zoom_base_height *
	            zoom_transition_requested_scale;
	    }


	    exit;
	}

    // ============================================================
    // MULTI-TARGET FIT ZOOM
    // ============================================================

    if (fit_active)
    {
        camera_fit_cleanup();

        var _fit_extents = camera_fit_get_extents();

        if (!is_undefined(_fit_extents))
        {
            var _fit_size = camera_fit_get_size(_fit_extents);

            if (!is_undefined(_fit_size))
            {
                // ========================================================
                // CURRENT CAMERA
                // ========================================================

                var _fit_old_x = camera_get_view_x(camera_id);
                var _fit_old_y = camera_get_view_y(camera_id);
                var _fit_old_width = camera_get_view_width(camera_id);
                var _fit_old_height = camera_get_view_height(camera_id);

                var _fit_center_x = _fit_old_x + _fit_old_width / 2;
                var _fit_center_y = _fit_old_y + _fit_old_height / 2;


                // ========================================================
                // CURRENT CAMERA ZONE
                // ========================================================

                // Fit does not select a zone. The normal follow target
                // remains the source of current_camera_zone.
                //
                // Each edge is tracked independently so being outside on
                // one axis never disables valid clamps on the other axis.

                var _fit_zone_active = instance_exists(current_camera_zone);
                var _fit_zone = noone;

                var _fit_cross_left = false;
                var _fit_cross_right = false;
                var _fit_cross_top = false;
                var _fit_cross_bottom = false;

                if (_fit_zone_active)
                {
                    _fit_zone = current_camera_zone;

                    _fit_cross_left = _fit_zone.clamp_left && _fit_old_x < _fit_zone.zone_left - 0.001;
                    _fit_cross_right = _fit_zone.clamp_right && _fit_old_x + _fit_old_width > _fit_zone.zone_right + 0.001;
                    _fit_cross_top = _fit_zone.clamp_top && _fit_old_y < _fit_zone.zone_top - 0.001;
                    _fit_cross_bottom = _fit_zone.clamp_bottom && _fit_old_y + _fit_old_height > _fit_zone.zone_bottom + 0.001;
                }


                // ========================================================
                // FIT SCALE LIMITS
                // ========================================================

                // Keep all fit sizing on one scale value so the camera's
                // original aspect ratio is always preserved.

                var _fit_base_width = max(fit_base_width, 1);
                var _fit_base_height = max(fit_base_height, 1);

                var _fit_target_scale = _fit_size.width / _fit_base_width;
                var _fit_min_allowed_scale = max(fit_min_scale, 0.01);

                // If shrinking is disabled, fit itself may not request a
                // scale below its starting size. Environmental constraints
                // such as zones may still require the physical camera to
                // become smaller.
                if (!fit_allow_shrink)
                    _fit_min_allowed_scale = max(_fit_min_allowed_scale, 1.0);

                var _fit_max_allowed_scale = max(fit_max_scale, _fit_min_allowed_scale);

                if (!fit_allow_expand)
                    _fit_max_allowed_scale = min(_fit_max_allowed_scale, 1);

                _fit_min_allowed_scale = min(_fit_min_allowed_scale, _fit_max_allowed_scale);


                // ========================================================
                // FIT REQUEST
                // ========================================================

                // This remains the size fit wants from the target group.
                // Zones do not rewrite it.

                var _fit_requested_scale = clamp(_fit_target_scale, _fit_min_allowed_scale, _fit_max_allowed_scale);


                // ========================================================
                // CURRENTLY OBTAINABLE FIT SCALE
                // ========================================================

                // This is the largest scale the current environment can
                // physically support.
                //
                // A zone constrains width only when BOTH horizontal edges
                // clamp, and constrains height only when BOTH vertical
                // edges clamp. One open edge leaves that axis unrestricted.

                var _fit_obtainable_scale = _fit_max_allowed_scale;

                if (_fit_zone_active && _fit_zone.clamp_left && _fit_zone.clamp_right)
                {
                    var _fit_zone_width = _fit_zone.zone_right - _fit_zone.zone_left;
                    _fit_obtainable_scale = min(_fit_obtainable_scale, _fit_zone_width / _fit_base_width);
                }

                if (_fit_zone_active && _fit_zone.clamp_top && _fit_zone.clamp_bottom)
                {
                    var _fit_zone_height = _fit_zone.zone_bottom - _fit_zone.zone_top;
                    _fit_obtainable_scale = min(_fit_obtainable_scale, _fit_zone_height / _fit_base_height);
                }

                if (_bounds_enabled)
                {
                    var _fit_bounds_width = _bounds_right - _bounds_left;
                    var _fit_bounds_height = _bounds_bottom - _bounds_top;
                    _fit_obtainable_scale = min(_fit_obtainable_scale, _fit_bounds_width / _fit_base_width, _fit_bounds_height / _fit_base_height);
                }

                _fit_obtainable_scale = max(_fit_obtainable_scale, 0.01);


                // ========================================================
                // FIT NEW SIZE
                // ========================================================

                // The requested fit scale remains untouched. The current
                // zone merely changes the legal destination.
                //
                // This means leaving a restrictive zone naturally allows
                // fit to pursue the original target-derived request again.

                var _fit_old_scale = _fit_old_width / _fit_base_width;
                var _fit_legal_target_scale = min(_fit_requested_scale, _fit_obtainable_scale);
                var _fit_new_scale = lerp(_fit_old_scale, _fit_legal_target_scale, fit_zoom_speed);

                if (abs(_fit_new_scale - _fit_legal_target_scale) < 0.0001)
                    _fit_new_scale = _fit_legal_target_scale;

                var _fit_new_width = _fit_base_width * _fit_new_scale;
                var _fit_new_height = _fit_base_height * _fit_new_scale;


                // ========================================================
                // HAS THE CAMERA REACHED A REAL LIMIT?
                // ========================================================

                // Escaped targets stop influencing camera position only
                // after the camera has actually reached its obtainable
                // environmental limit. This remains correct when entering
                // a smaller zone from an oversized camera because the
                // shrink transition is allowed to finish first.

                var _fit_limit_width = _fit_base_width * _fit_obtainable_scale;
                var _fit_limit_height = _fit_base_height * _fit_obtainable_scale;

                var _fit_reached_obtainable_scale = abs(_fit_new_scale - _fit_obtainable_scale) <= 0.001;
                var _fit_width_blocked = _fit_size.required_width > _fit_limit_width + 1 && _fit_reached_obtainable_scale;
                var _fit_height_blocked = _fit_size.required_height > _fit_limit_height + 1 && _fit_reached_obtainable_scale;
                var _fit_at_limit = _fit_width_blocked || _fit_height_blocked;


                // ========================================================
                // MOVEMENT EXTENTS
                // ========================================================

                var _fit_move_extents = _fit_extents;

                // Once the camera genuinely cannot become large enough,
                // escaped targets stop influencing camera POSITION.
                //
                // They remain in the full fit group and automatically
                // contribute again if the environment later allows them.
                if (_fit_at_limit)
                {
                    var _fit_visible_extents = camera_fit_get_visible_extents();

                    if (!is_undefined(_fit_visible_extents))
                        _fit_move_extents = _fit_visible_extents;
                    else
                        _fit_move_extents = undefined;
                }


                // ========================================================
                // FIT MOVEMENT PRESSURE
                // ========================================================

                var _fit_pressure_left_amount = 0;
                var _fit_pressure_right_amount = 0;
                var _fit_pressure_top_amount = 0;
                var _fit_pressure_bottom_amount = 0;

                var _fit_horizontal_pressure = 0;
                var _fit_vertical_pressure = 0;

                if (!is_undefined(_fit_move_extents))
                {
                    var _fit_half_width = _fit_new_width / 2;
                    var _fit_half_height = _fit_new_height / 2;


                    // ====================================================
                    // HORIZONTAL FIT PRESSURE
                    // ====================================================

                    var _fit_inner_left = _fit_center_x - _fit_half_width + border_x;
                    var _fit_inner_right = _fit_center_x + _fit_half_width - border_x;

                    _fit_pressure_left_amount = max(_fit_inner_left - _fit_move_extents.left, 0);
                    _fit_pressure_right_amount = max(_fit_move_extents.right - _fit_inner_right, 0);

                    _fit_horizontal_pressure = _fit_pressure_right_amount - _fit_pressure_left_amount;


                    // ====================================================
                    // VERTICAL FIT PRESSURE
                    // ====================================================

                    var _fit_inner_top = _fit_center_y - _fit_half_height + border_y;
                    var _fit_inner_bottom = _fit_center_y + _fit_half_height - border_y;

                    _fit_pressure_top_amount = max(_fit_inner_top - _fit_move_extents.top, 0);
                    _fit_pressure_bottom_amount = max(_fit_move_extents.bottom - _fit_inner_bottom, 0);

                    _fit_vertical_pressure = _fit_pressure_bottom_amount - _fit_pressure_top_amount;

                    if (abs(_fit_horizontal_pressure) < 0.001)
                        _fit_horizontal_pressure = 0;

                    if (abs(_fit_vertical_pressure) < 0.001)
                        _fit_vertical_pressure = 0;
                }


                // ========================================================
                // FIT MOVEMENT VELOCITY
                // ========================================================

                if (!is_undefined(_fit_move_extents))
                {
                    fit_velocity_x += _fit_horizontal_pressure * fit_strength;
                    fit_velocity_y += _fit_vertical_pressure * fit_strength;

                    fit_velocity_x *= fit_damping;
                    fit_velocity_y *= fit_damping;


                    // ====================================================
                    // FIT SPEED LIMIT
                    // ====================================================

                    if (fit_max_speed > 0)
                    {
                        var _fit_speed = sqrt(sqr(fit_velocity_x) + sqr(fit_velocity_y));

                        if (_fit_speed > fit_max_speed)
                        {
                            var _fit_speed_scale = fit_max_speed / _fit_speed;
                            fit_velocity_x *= _fit_speed_scale;
                            fit_velocity_y *= _fit_speed_scale;
                        }
                    }


                    // ====================================================
                    // FIT OVERSHOOT CONTROL
                    // ====================================================

                    if (!fit_allow_overshoot)
                    {
                        if (_fit_horizontal_pressure == 0)
                        {
                            fit_velocity_x = 0;
                        }
                        else
                        {
                            if ((fit_velocity_x > 0 && _fit_horizontal_pressure < 0) || (fit_velocity_x < 0 && _fit_horizontal_pressure > 0))
                                fit_velocity_x = 0;

                            if (abs(fit_velocity_x) > abs(_fit_horizontal_pressure))
                                fit_velocity_x = _fit_horizontal_pressure;
                        }

                        if (_fit_vertical_pressure == 0)
                        {
                            fit_velocity_y = 0;
                        }
                        else
                        {
                            if ((fit_velocity_y > 0 && _fit_vertical_pressure < 0) || (fit_velocity_y < 0 && _fit_vertical_pressure > 0))
                                fit_velocity_y = 0;

                            if (abs(fit_velocity_y) > abs(_fit_vertical_pressure))
                                fit_velocity_y = _fit_vertical_pressure;
                        }
                    }


                    // ====================================================
                    // MOVE CAMERA CENTER
                    // ====================================================

                    _fit_center_x += fit_velocity_x;
                    _fit_center_y += fit_velocity_y;
                }
                else
                {
                    fit_velocity_x = 0;
                    fit_velocity_y = 0;
                }


                // ========================================================
                // FIT POSITION
                // ========================================================

                var _fit_new_x = _fit_center_x - _fit_new_width / 2;
                var _fit_new_y = _fit_center_y - _fit_new_height / 2;


                // ========================================================
                // ZONE HANDOFF FIT ANCHOR
                // ========================================================

                // When an oversized camera is entering a contained axis,
                // the destination-side clamp becomes the temporary size
                // anchor just as it does for normal and timed zoom.
                //
                // X and Y remain completely independent.

                if (_fit_zone_active)
                {
                    if (_zone_handoff_x_active && _zone_handoff_dir_x > 0 && _fit_zone.clamp_right && _fit_old_x + _fit_old_width >= _fit_zone.zone_right - 0.001)
                        _fit_new_x = _fit_zone.zone_right - _fit_new_width;
                    else if (_zone_handoff_x_active && _zone_handoff_dir_x < 0 && _fit_zone.clamp_left && _fit_old_x <= _fit_zone.zone_left + 0.001)
                        _fit_new_x = _fit_zone.zone_left;

                    if (_zone_handoff_y_active && _zone_handoff_dir_y > 0 && _fit_zone.clamp_bottom && _fit_old_y + _fit_old_height >= _fit_zone.zone_bottom - 0.001)
                        _fit_new_y = _fit_zone.zone_bottom - _fit_new_height;
                    else if (_zone_handoff_y_active && _zone_handoff_dir_y < 0 && _fit_zone.clamp_top && _fit_old_y <= _fit_zone.zone_top + 0.001)
                        _fit_new_y = _fit_zone.zone_top;
                }


                // ========================================================
                // FINAL FIT ZONE EDGES
                // ========================================================

                // Every enabled edge is enforced independently.
                //
                // If an edge was already crossed before this fit update,
                // it may recover smoothly instead of snapping. Any other
                // enabled edge that was legal may not become newly crossed.

                if (_fit_zone_active)
                {
                    if (_fit_zone.clamp_left && !_fit_cross_left && _fit_new_x < _fit_zone.zone_left)
                    {
                        _fit_new_x = _fit_zone.zone_left;

                        if (fit_velocity_x < 0)
                            fit_velocity_x = 0;
                    }

                    if (_fit_zone.clamp_right && !_fit_cross_right && _fit_new_x + _fit_new_width > _fit_zone.zone_right)
                    {
                        _fit_new_x = _fit_zone.zone_right - _fit_new_width;

                        if (fit_velocity_x > 0)
                            fit_velocity_x = 0;
                    }

                    if (_fit_zone.clamp_top && !_fit_cross_top && _fit_new_y < _fit_zone.zone_top)
                    {
                        _fit_new_y = _fit_zone.zone_top;

                        if (fit_velocity_y < 0)
                            fit_velocity_y = 0;
                    }

                    if (_fit_zone.clamp_bottom && !_fit_cross_bottom && _fit_new_y + _fit_new_height > _fit_zone.zone_bottom)
                    {
                        _fit_new_y = _fit_zone.zone_bottom - _fit_new_height;

                        if (fit_velocity_y > 0)
                            fit_velocity_y = 0;
                    }
                }


                // ========================================================
                // FINAL GLOBAL CAMERA BOUNDS
                // ========================================================

                if (_bounds_enabled)
                {
                    if (_fit_new_width > _bounds_right - _bounds_left)
                        _fit_new_x = (_bounds_left + _bounds_right - _fit_new_width) / 2;
                    else
                        _fit_new_x = clamp(_fit_new_x, _bounds_left, _bounds_right - _fit_new_width);

                    if (_fit_new_height > _bounds_bottom - _bounds_top)
                        _fit_new_y = (_bounds_top + _bounds_bottom - _fit_new_height) / 2;
                    else
                        _fit_new_y = clamp(_fit_new_y, _bounds_top, _bounds_bottom - _fit_new_height);
                }


                // ========================================================
                // APPLY MULTI-TARGET FIT
                // ========================================================

                camera_set_view_size(camera_id, _fit_new_width, _fit_new_height);
                camera_set_view_pos(camera_id, _fit_new_x, _fit_new_y);
            }
        }
    }

    // ========================================================
    // TIMED CAMERA ZOOM
    // ========================================================

    if (!fit_active && zoom_timed_active)
    {
        // ====================================================
        // CURRENT CAMERA
        // ====================================================

        var _timed_old_width = camera_get_view_width(camera_id);

        var _timed_old_height = camera_get_view_height(camera_id);

        var _timed_old_x = camera_get_view_x(camera_id);

        var _timed_old_y = camera_get_view_y(camera_id);


        var _timed_current_scale = _timed_old_width / max(zoom_base_width, 1);


        // ====================================================
        // CURRENT CAMERA ZONE
        // ====================================================

        var _timed_zone_active = instance_exists(current_camera_zone);
        var _timed_zone = noone;

        var _timed_cross_left = false;
        var _timed_cross_right = false;
        var _timed_cross_top = false;
        var _timed_cross_bottom = false;


        if (_timed_zone_active)
        {
            _timed_zone = current_camera_zone;

            _timed_cross_left = _timed_zone.clamp_left && _timed_old_x < _timed_zone.zone_left - 0.001;
            _timed_cross_right = _timed_zone.clamp_right && _timed_old_x + _timed_old_width > _timed_zone.zone_right + 0.001;
            _timed_cross_top = _timed_zone.clamp_top && _timed_old_y < _timed_zone.zone_top - 0.001;
            _timed_cross_bottom = _timed_zone.clamp_bottom && _timed_old_y + _timed_old_height > _timed_zone.zone_bottom + 0.001;
        }


        // ====================================================
        // LEGAL TIMED-ZOOM DESTINATION
        // ====================================================

        // The requested scale remains absolute to the fixed
        // base camera size.
        //
        // Zone and global bounds only change the CURRENT legal
        // destination. They do not rewrite the requested scale.

        var _timed_legal_target_scale = zoom_timed_requested_scale;


        // ----------------------------------------------------
        // ZONE HORIZONTAL SIZE LIMIT
        // ----------------------------------------------------

        if (_timed_zone_active && _timed_zone.clamp_left && _timed_zone.clamp_right)
        {
            var _timed_zone_width = _timed_zone.zone_right - _timed_zone.zone_left;

            _timed_legal_target_scale = min(_timed_legal_target_scale, _timed_zone_width / max(zoom_base_width, 1));
        }


        // ----------------------------------------------------
        // ZONE VERTICAL SIZE LIMIT
        // ----------------------------------------------------

        if (_timed_zone_active && _timed_zone.clamp_top && _timed_zone.clamp_bottom)
        {
            var _timed_zone_height = _timed_zone.zone_bottom - _timed_zone.zone_top;

            _timed_legal_target_scale = min(_timed_legal_target_scale, _timed_zone_height / max(zoom_base_height, 1));
        }


        // ----------------------------------------------------
        // GLOBAL SIZE LIMIT
        // ----------------------------------------------------

        if (_bounds_enabled)
        {
            var _timed_bounds_width = _bounds_right - _bounds_left;

            var _timed_bounds_height = _bounds_bottom - _bounds_top;


            _timed_legal_target_scale = min(_timed_legal_target_scale, _timed_bounds_width / max(zoom_base_width, 1), _timed_bounds_height / max(zoom_base_height, 1));
        }


        _timed_legal_target_scale = max(_timed_legal_target_scale, 0.01);


        // ====================================================
        // DYNAMIC DESTINATION CHANGE
        // ====================================================

        // If the target enters a zone whose legal size differs
        // from the previous timed-zoom destination, begin a new
        // timed segment from the REAL camera size that exists
        // right now.
        //
        // This intentionally gives the new destination the full
        // requested duration. A zone change is a real change of
        // destination; preserving the old elapsed percentage
        // could otherwise cause a visible size jump.

        if (abs(_timed_legal_target_scale - zoom_timed_effective_target_scale) > 0.0001)
        {
            zoom_timed_start_scale = _timed_current_scale;

            zoom_timed_start_width = zoom_base_width * zoom_timed_start_scale;

            zoom_timed_start_height = zoom_base_height * zoom_timed_start_scale;

            zoom_timed_effective_target_scale = _timed_legal_target_scale;

            zoom_timed_progress = 0;
        }


        // ====================================================
        // TIMED ZOOM PROGRESS
        // ====================================================

        zoom_timed_progress += (delta_time / 1000000) / zoom_timed_duration;


        var _zoom_t = clamp(zoom_timed_progress, 0, 1);


        // ====================================================
        // TIMED ZOOM EASING
        // ====================================================

        var _zoom_ease = _zoom_t;


        switch (zoom_timed_ease)
        {
            case CameraEase.SMOOTH:
                _zoom_ease = ease_smooth(_zoom_t);
            break;


            case CameraEase.IN:
                _zoom_ease = ease_in(_zoom_t);
            break;


            case CameraEase.OUT:
                _zoom_ease = ease_out(_zoom_t);
            break;


            case CameraEase.IN_OUT:
                _zoom_ease = ease_in_out(_zoom_t);
            break;


            case CameraEase.LINEAR:
                _zoom_ease = _zoom_t;
            break;
        }


        // ====================================================
        // TIMED ZOOM SIZE
        // ====================================================

        // One scale drives both dimensions so timed zoom can
        // never deform the camera aspect ratio.

        var _timed_new_scale = lerp(zoom_timed_start_scale, zoom_timed_effective_target_scale, _zoom_ease);


        if (_zoom_t >= 1)
        {
            _timed_new_scale = zoom_timed_effective_target_scale;
        }


        var _timed_new_width = zoom_base_width * _timed_new_scale;

        var _timed_new_height = zoom_base_height * _timed_new_scale;


        // ====================================================
        // TIMED ZOOM ANCHOR
        // ====================================================

        var _timed_new_x = _timed_old_x;

        var _timed_new_y = _timed_old_y;


        if (zoom_anchor_x == 0)
        {
            _timed_new_x += (_timed_old_width - _timed_new_width) / 2;
        }

        else if (zoom_anchor_x == 1)
        {
            _timed_new_x += (_timed_old_width - _timed_new_width);
        }


        if (zoom_anchor_y == 0)
        {
            _timed_new_y += (_timed_old_height - _timed_new_height) / 2;
        }

        else if (zoom_anchor_y == 1)
        {
            _timed_new_y += (_timed_old_height - _timed_new_height);
        }


        // ====================================================
        // ZONE HANDOFF TIMED-ZOOM ANCHOR
        // ====================================================

        // During a fully-clamped handoff, once movement reaches
        // the destination-side clamp, that side becomes the
        // temporary zoom anchor.
        //
        // This keeps the sealed side of the destination room
        // visually sealed while the oversized remainder shrinks
        // out of the previous room.

        if (_timed_zone_active)
        {
            if (_zone_handoff_x_active && _zone_handoff_dir_x > 0 && _timed_zone.clamp_right && _timed_old_x + _timed_old_width >= _timed_zone.zone_right - 0.001)
            {
                _timed_new_x = _timed_zone.zone_right - _timed_new_width;
            }

            else if (_zone_handoff_x_active && _zone_handoff_dir_x < 0 && _timed_zone.clamp_left && _timed_old_x <= _timed_zone.zone_left + 0.001)
            {
                _timed_new_x = _timed_zone.zone_left;
            }


            if (_zone_handoff_y_active && _zone_handoff_dir_y > 0 && _timed_zone.clamp_bottom && _timed_old_y + _timed_old_height >= _timed_zone.zone_bottom - 0.001)
            {
                _timed_new_y = _timed_zone.zone_bottom - _timed_new_height;
            }

            else if (_zone_handoff_y_active && _zone_handoff_dir_y < 0 && _timed_zone.clamp_top && _timed_old_y <= _timed_zone.zone_top + 0.001)
            {
                _timed_new_y = _timed_zone.zone_top;
            }
        }


        // ====================================================
        // FINAL ZONE BOUNDS
        // ====================================================

        // Zone edges remain independent during timed zoom.
        // Horizontal illegality never disables vertical clamps,
        // and vertical illegality never disables horizontal clamps.

        if (_timed_zone_active)
        {
            if (_timed_zone.clamp_left && !_timed_cross_left)
                _timed_new_x = max(_timed_new_x, _timed_zone.zone_left);

            if (_timed_zone.clamp_right && !_timed_cross_right)
                _timed_new_x = min(_timed_new_x, _timed_zone.zone_right - _timed_new_width);

            if (_timed_zone.clamp_top && !_timed_cross_top)
                _timed_new_y = max(_timed_new_y, _timed_zone.zone_top);

            if (_timed_zone.clamp_bottom && !_timed_cross_bottom)
                _timed_new_y = min(_timed_new_y, _timed_zone.zone_bottom - _timed_new_height);
        }


        // ====================================================
        // FINAL GLOBAL CAMERA BOUNDS
        // ====================================================

        if (_bounds_enabled)
        {
            if (_timed_new_width > _bounds_right - _bounds_left)
            {
                _timed_new_x = (_bounds_left + _bounds_right - _timed_new_width) / 2;
            }
            else
            {
                _timed_new_x = clamp(_timed_new_x, _bounds_left, _bounds_right - _timed_new_width);
            }


            if (_timed_new_height > _bounds_bottom - _bounds_top)
            {
                _timed_new_y = (_bounds_top + _bounds_bottom - _timed_new_height) / 2;
            }
            else
            {
                _timed_new_y = clamp(_timed_new_y, _bounds_top, _bounds_bottom - _timed_new_height);
            }
        }


        // ====================================================
        // APPLY TIMED ZOOM
        // ====================================================

        camera_set_view_size(camera_id, _timed_new_width, _timed_new_height);

        camera_set_view_pos(camera_id, _timed_new_x, _timed_new_y);


        // ====================================================
        // TIMED ZOOM FINISHED
        // ====================================================

        if (_zoom_t >= 1)
        {
            zoom_timed_active = false;


            // Preserve the ORIGINAL requested scale.
            //
            // If the current zone limited it, the normal zoom
            // system will continue respecting that zone. If the
            // target later enters a less restrictive zone, the
            // camera can smoothly return toward the requested
            // absolute scale.

            zoom_target_width = zoom_base_width * zoom_timed_requested_scale;

            zoom_target_height = zoom_base_height * zoom_timed_requested_scale;
        }


        exit;
    }

    if (!fit_active)
    {
    // ========================================================
    // NORMAL CAMERA ZOOM
    // ========================================================

    var _old_width = camera_get_view_width(camera_id);

    var _old_height = camera_get_view_height(camera_id);

    var _old_x = camera_get_view_x(camera_id);

    var _old_y = camera_get_view_y(camera_id);


    // ========================================================
    // CURRENT CAMERA ZONE
    // ========================================================

    var _zoom_zone_active = instance_exists(current_camera_zone);
    var _zoom_zone = noone;

    var _zoom_cross_left = false;
    var _zoom_cross_right = false;
    var _zoom_cross_top = false;
    var _zoom_cross_bottom = false;


    if (_zoom_zone_active)
    {
        _zoom_zone = current_camera_zone;

        _zoom_cross_left = _zoom_zone.clamp_left && _old_x < _zoom_zone.zone_left - 0.001;
        _zoom_cross_right = _zoom_zone.clamp_right && _old_x + _old_width > _zoom_zone.zone_right + 0.001;
        _zoom_cross_top = _zoom_zone.clamp_top && _old_y < _zoom_zone.zone_top - 0.001;
        _zoom_cross_bottom = _zoom_zone.clamp_bottom && _old_y + _old_height > _zoom_zone.zone_bottom + 0.001;
    }


    // ========================================================
    // VIEWPORT EDGE BOUNDS
    // ========================================================

    // Global ROOM / CUSTOM edges are always the outer limit.
    //
    // Zone edges become physical zoom anchors only after the
    // camera is already legal inside that zone. This prevents
    // a newly selected zone from snapping the physical camera.

    var _edge_left_enabled = _bounds_enabled;

    var _edge_right_enabled = _bounds_enabled;

    var _edge_top_enabled = _bounds_enabled;

    var _edge_bottom_enabled = _bounds_enabled;


    var _edge_left = _bounds_left;

    var _edge_right = _bounds_right;

    var _edge_top = _bounds_top;

    var _edge_bottom = _bounds_bottom;


    if (_zoom_zone_active)
    {
        if (_zoom_zone.clamp_left && !_zoom_cross_left)
        {
            _edge_left_enabled = true;
            _edge_left = _zoom_zone.zone_left;
        }

        if (_zoom_zone.clamp_right && !_zoom_cross_right)
        {
            _edge_right_enabled = true;
            _edge_right = _zoom_zone.zone_right;
        }

        if (_zoom_zone.clamp_top && !_zoom_cross_top)
        {
            _edge_top_enabled = true;
            _edge_top = _zoom_zone.zone_top;
        }

        if (_zoom_zone.clamp_bottom && !_zoom_cross_bottom)
        {
            _edge_bottom_enabled = true;
            _edge_bottom = _zoom_zone.zone_bottom;
        }
    }


    // ========================================================
    // CHECK VIEWPORT EDGES
    // ========================================================

    var _touch_left = _edge_left_enabled && _old_x <= _edge_left;

    var _touch_right = _edge_right_enabled && _old_x + _old_width >= _edge_right;

    var _touch_top = _edge_top_enabled && _old_y <= _edge_top;

    var _touch_bottom = _edge_bottom_enabled && _old_y + _old_height >= _edge_bottom;


    // ========================================================
    // REQUESTED ZOOM SCALE
    // ========================================================

    // camera_zoom() stores an absolute target relative to the
    // fixed base camera size. Recover that single scale here so
    // width and height can never drift apart.

    var _requested_scale = zoom_target_width / max(zoom_base_width, 1);

    _requested_scale = max(_requested_scale, 0.01);


    // ========================================================
    // LEGAL TARGET SCALE
    // ========================================================

    // IMPORTANT:
    //
    // We constrain the DESTINATION, not the physical camera.
    //
    // If a target walks from an open zone at scale 3 into a
    // fully clamped zone that can only hold scale 1.5, the new
    // destination becomes 1.5. The physical camera then eases
    // from 3 -> 1.5 instead of snapping immediately to 1.5.

    var _legal_target_scale = _requested_scale;


    // --------------------------------------------------------
    // ZONE HORIZONTAL SIZE LIMIT
    // --------------------------------------------------------

    if (_zoom_zone_active && _zoom_zone.clamp_left && _zoom_zone.clamp_right)
    {
        var _zone_width = _zoom_zone.zone_right - _zoom_zone.zone_left;

        _legal_target_scale = min(_legal_target_scale, _zone_width / max(zoom_base_width, 1));
    }


    // --------------------------------------------------------
    // ZONE VERTICAL SIZE LIMIT
    // --------------------------------------------------------

    if (_zoom_zone_active && _zoom_zone.clamp_top && _zoom_zone.clamp_bottom)
    {
        var _zone_height = _zoom_zone.zone_bottom - _zoom_zone.zone_top;

        _legal_target_scale = min(_legal_target_scale, _zone_height / max(zoom_base_height, 1));
    }


    // --------------------------------------------------------
    // GLOBAL SIZE LIMIT
    // --------------------------------------------------------

    if (_bounds_enabled)
    {
        var _bounds_width = _bounds_right - _bounds_left;

        var _bounds_height = _bounds_bottom - _bounds_top;


        _legal_target_scale = min(_legal_target_scale, _bounds_width / max(zoom_base_width, 1), _bounds_height / max(zoom_base_height, 1));
    }


    _legal_target_scale = max(_legal_target_scale, 0.01);


    // ========================================================
    // SMOOTH PHYSICAL ZOOM
    // ========================================================

    // Smooth from the REAL current camera scale toward the
    // legal destination scale.
    //
    // One scale drives both dimensions, preserving aspect ratio.

    var _old_scale = _old_width / max(zoom_base_width, 1);

    var _new_scale = lerp(_old_scale, _legal_target_scale, zoom_speed);


    // Finish cleanly when extremely close to the destination.

    if (abs(_new_scale - _legal_target_scale) < 0.0001)
    {
        _new_scale = _legal_target_scale;
    }


    var _new_width = zoom_base_width * _new_scale;

    var _new_height = zoom_base_height * _new_scale;


    // ========================================================
    // ZOOM ANCHOR
    // ========================================================

    var _new_x = _old_x;

    var _new_y = _old_y;


    if (zoom_anchor_x == 0)
    {
        _new_x += (_old_width - _new_width) / 2;
    }

    else if (zoom_anchor_x == 1)
    {
        _new_x += (_old_width - _new_width);
    }


    if (zoom_anchor_y == 0)
    {
        _new_y += (_old_height - _new_height) / 2;
    }

    else if (zoom_anchor_y == 1)
    {
        _new_y += (_old_height - _new_height);
    }


    // ========================================================
    // ZONE HANDOFF ZOOM ANCHOR
    // ========================================================

    // Once movement reaches the destination-side clamp, use
    // that exact side as the temporary zoom anchor.
    //
    // Entering from the left while moving right:
    //     right edge remains fixed at zone_right
    //     left edge shrinks inward from the previous room
    //
    // The same rule is applied independently on Y, so diagonal
    // handoffs can naturally anchor to a corner.

    if (_zoom_zone_active)
    {
        if (_zone_handoff_x_active && _zone_handoff_dir_x > 0 && _zoom_zone.clamp_right && _old_x + _old_width >= _zoom_zone.zone_right - 0.001)
        {
            _new_x = _zoom_zone.zone_right - _new_width;
        }

        else if (_zone_handoff_x_active && _zone_handoff_dir_x < 0 && _zoom_zone.clamp_left && _old_x <= _zoom_zone.zone_left + 0.001)
        {
            _new_x = _zoom_zone.zone_left;
        }


        if (_zone_handoff_y_active && _zone_handoff_dir_y > 0 && _zoom_zone.clamp_bottom && _old_y + _old_height >= _zoom_zone.zone_bottom - 0.001)
        {
            _new_y = _zoom_zone.zone_bottom - _new_height;
        }

        else if (_zone_handoff_y_active && _zone_handoff_dir_y < 0 && _zoom_zone.clamp_top && _old_y <= _zoom_zone.zone_top + 0.001)
        {
            _new_y = _zoom_zone.zone_top;
        }
    }


    // ========================================================
    // VIEWPORT EDGE ANCHORS
    // ========================================================

    if (_touch_left && !_touch_right)
    {
        _new_x = _edge_left;
    }

    else if (_touch_right && !_touch_left)
    {
        _new_x = _edge_right - _new_width;
    }


    if (_touch_top && !_touch_bottom)
    {
        _new_y = _edge_top;
    }

    else if (_touch_bottom && !_touch_top)
    {
        _new_y = _edge_bottom - _new_height;
    }


    // ========================================================
    // FINAL ZONE BOUNDS
    // ========================================================

    // Each enabled zone edge is enforced independently.
    // An already-crossed edge is allowed to recover naturally,
    // but another legal edge may never be lost just because the
    // camera is outside somewhere else.

    if (_zoom_zone_active)
    {
        if (_zoom_zone.clamp_left && !_zoom_cross_left)
            _new_x = max(_new_x, _zoom_zone.zone_left);

        if (_zoom_zone.clamp_right && !_zoom_cross_right)
            _new_x = min(_new_x, _zoom_zone.zone_right - _new_width);

        if (_zoom_zone.clamp_top && !_zoom_cross_top)
            _new_y = max(_new_y, _zoom_zone.zone_top);

        if (_zoom_zone.clamp_bottom && !_zoom_cross_bottom)
            _new_y = min(_new_y, _zoom_zone.zone_bottom - _new_height);
    }


    // ========================================================
    // FINAL GLOBAL CAMERA BOUNDS
    // ========================================================

    // Global ROOM / CUSTOM bounds remain hard physical limits.

    if (_bounds_enabled)
    {
        if (_new_width > _bounds_right - _bounds_left)
        {
            _new_x = (_bounds_left + _bounds_right - _new_width) / 2;
        }
        else
        {
            _new_x = clamp(_new_x, _bounds_left, _bounds_right - _new_width);
        }


        if (_new_height > _bounds_bottom - _bounds_top)
        {
            _new_y = (_bounds_top + _bounds_bottom - _new_height) / 2;
        }
        else
        {
            _new_y = clamp(_new_y, _bounds_top, _bounds_bottom - _new_height);
        }
    }


    // ========================================================
    // APPLY ZOOM
    // ========================================================

    camera_set_view_size(camera_id, _new_width, _new_height);

    camera_set_view_pos(camera_id, _new_x, _new_y);
    }
}
