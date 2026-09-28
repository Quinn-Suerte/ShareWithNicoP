#region CAMERA DEFINITIONS

enum CameraEase
{
    SMOOTH,
    IN,
    OUT,
    IN_OUT,
    LINEAR
}

enum CameraBoundsMode
{
    NONE,
    ROOM,
    CUSTOM
}

enum CameraLetterbox
{
    NONE = 0,
    WIDE_185 = 1.85,
    WIDE_200 = 2.00,
    CINEMA_235 = 2.35,
    CINEMA_239 = 2.39,
    CINEMA_240 = 2.40,
    ULTRA_276 = 2.76
}

function CameraState() constructor
{
    // CAMERA
    target = noone;

    x = 0;
    y = 0;

    width = 0;
    height = 0;


    // ZOOM
    zoom_target_width = 0;
    zoom_target_height = 0;

    zoom_anchor_x = 0;
    zoom_anchor_y = 0;


    // FOLLOW
    follow_active = false;

    follow_x_active = true;
    follow_y_active = true;

    follow_strength = 0.12;
    follow_damping = 0.75;

    follow_max_speed = 0;
    follow_allow_overshoot = true;

    follow_offset_x = 0;
    follow_offset_y = 0;

    follow_offset_target_x = 0;
    follow_offset_target_y = 0;


    // FIT
    fit_active = false;


    // LETTERBOX
    letterbox_ratio = 0;
    letterbox_current_amount = 0;

    letterbox_timed_active = false;
    letterbox_start_amount = 0;
    letterbox_target_amount = 0;
    letterbox_timed_progress = 0;
    letterbox_timed_duration = 0;
    letterbox_timed_ease = CameraEase.SMOOTH;
}

/// @function cam(_number)
/// @description Returns the camera assigned to the requested viewport slot.
/// @param {Real} _number Viewport slot from 0 to 7.
function cam(_number)
{
    _number = round(_number);

    if (_number < 0 || _number > 7)
        return noone;

    var _camera = view_camera[_number];

    if (_camera == -1)
        return noone;

    return _camera;
}

#endregion

#region CAMERA LETTERBOX

function camera_letterbox(_ratio = undefined)
{
    with (camera_object)
    {
        if (!is_undefined(_ratio))
            letterbox_ratio = max(_ratio, 0);

        letterbox_timed_active = false;
        letterbox_timed_progress = 0;

        if (letterbox_ratio <= 0)
        {
            letterbox_current_amount = 0;
            letterbox_start_amount = 0;
            letterbox_target_amount = 0;
            exit;
        }

        var _gui_width = display_get_gui_width();
        var _gui_height = display_get_gui_height();
        var _visible_height = _gui_width / letterbox_ratio;
        var _bar_height = max((_gui_height - _visible_height) / 2, 0);
        var _amount = _bar_height / max(_gui_height, 1);

        letterbox_current_amount = _amount;
        letterbox_start_amount = _amount;
        letterbox_target_amount = _amount;
    }
}

function camera_letterbox_timed(_ratio, _seconds, _ease = CameraEase.SMOOTH)
{
    with (camera_object)
    {
        letterbox_ratio = max(_ratio, 0);

        var _gui_width = display_get_gui_width();
        var _gui_height = display_get_gui_height();

        var _visible_height = _gui_width / max(letterbox_ratio, 0.001);
        var _bar_height = max((_gui_height - _visible_height) / 2, 0);

        letterbox_start_amount = letterbox_current_amount;
        letterbox_target_amount = _bar_height / max(_gui_height, 1);

        letterbox_timed_progress = 0;
        letterbox_timed_duration = max(_seconds, 0.001);
        letterbox_timed_ease = _ease;
        letterbox_timed_active = true;
    }
}

function camera_letterbox_clear()
{
    with (camera_object)
    {
        letterbox_timed_active = false;
        letterbox_timed_progress = 0;

        letterbox_current_amount = 0;
        letterbox_start_amount = 0;
        letterbox_target_amount = 0;
    }
}

function camera_letterbox_clear_timed(_seconds, _ease = CameraEase.SMOOTH)
{
    with (camera_object)
    {
        letterbox_start_amount = letterbox_current_amount;
        letterbox_target_amount = 0;

        letterbox_timed_progress = 0;
        letterbox_timed_duration = max(_seconds, 0.001);
        letterbox_timed_ease = _ease;
        letterbox_timed_active = true;
    }
}

function camera_letterbox_color(_color)
{
    with (camera_object)
    {
        letterbox_color = _color;
    }
}

#endregion

#region CAMERA BASIC CONTROL

/// @function camera_speed(_camera, _x_speed, _y_speed)
/// @description Sets the camera follow speed using whole-pixel movement.
/// @param {Camera} _camera Camera ID.
/// @param {Real} _x_speed Horizontal follow speed.
/// @param {Real} _y_speed Vertical follow speed.
function camera_speed(_camera, _x_speed, _y_speed)
{
    camera_set_view_speed(_camera, round(_x_speed), round(_y_speed));
}

/// @function camera_zoom(_scale)
/// @description Smoothly changes the camera to an absolute scale of its base size.
/// @param {Real} _scale Fraction of the base camera size. 1.0 is the base size.
function camera_zoom(_scale)
{
    with (camera_object)
    {
        zoom_timed_active = false;
        _scale = max(_scale, 0.01);

        zoom_target_width = zoom_base_width * _scale;
        zoom_target_height = zoom_base_height * _scale;
    }
}

function camera_hold(_duration)
{
    hold_duration = max(_duration, 0);
    hold_elapsed = 0;
    hold_active = true;
}

function camera_transition_cancel()
{
    with (camera_object)
    {
        var _legacy_active = transition_active;
        var _compat_active = transition_compat_active;

        var _position_active = position_transition_active;
        var _zoom_active = zoom_transition_active || zoom_timed_active;


        if (!_legacy_active &&
            !_compat_active &&
            !_position_active &&
            !_zoom_active)
        {
            exit;
        }


        // ====================================================
        // SAVE RESTORE STATE
        // ====================================================

        var _restore_previous = false;

        var _restore_target = noone;

        var _restore_zoom_width = zoom_target_width;
        var _restore_zoom_height = zoom_target_height;


        // New compatibility transition.
        if (_compat_active)
        {
            _restore_previous = true;

            _restore_target =
                transition_compat_previous_target;

            _restore_zoom_width =
                transition_compat_previous_zoom_width;

            _restore_zoom_height =
                transition_compat_previous_zoom_height;
        }

        // Legacy combined transition.
        else if (_legacy_active)
        {
            _restore_previous = true;

            _restore_target =
                transition_previous_target;

            _restore_zoom_width =
                transition_previous_zoom_width;

            _restore_zoom_height =
                transition_previous_zoom_height;
        }


        var _state_transition_active =
            _legacy_active &&
            !is_undefined(transition_target_state);


        // ====================================================
        // STOP LEGACY TRANSITION
        // ====================================================

        transition_active = false;
        transition_paused = false;
        transition_progress = 0;

        transition_target_state = undefined;

        zoom_timed_active = false;


        // ====================================================
        // STOP POSITION TRACK
        // ====================================================

        position_transition_active = false;
        position_transition_paused = false;

        position_transition_elapsed = 0;

        position_transition_velocity_x = 0;
        position_transition_velocity_y = 0;

        position_transition_start_velocity_x = 0;
        position_transition_start_velocity_y = 0;

        position_transition_end_velocity_x = 0;
        position_transition_end_velocity_y = 0;

        position_transition_replanned = false;
        position_transition_spline_active = false;


        // ====================================================
        // STOP ZOOM TRACK
        // ====================================================

        zoom_transition_active = false;
        zoom_transition_paused = false;

        zoom_transition_elapsed = 0;
        zoom_transition_velocity = 0;


        // ====================================================
        // STOP COMPATIBILITY WRAPPER
        // ====================================================

        transition_compat_active = false;


        // ====================================================
        // CANCEL STATE LETTERBOX TRANSITION
        // ====================================================

        if (_state_transition_active)
        {
            letterbox_timed_active = false;

            letterbox_start_amount =
                letterbox_current_amount;

            letterbox_target_amount =
                letterbox_current_amount;

            letterbox_timed_progress = 0;
        }


        // ====================================================
        // RESTORE PREVIOUS CONTROL STATE
        // ====================================================

        if (_restore_previous)
        {
            zoom_target_width =
                _restore_zoom_width;

            zoom_target_height =
                _restore_zoom_height;

            camera_set_view_target(
                camera_id,
                _restore_target
            );
        }
    }
}

/// @function camera_zoom_timed(_scale, _seconds, _ease)
/// @description Changes the camera to an absolute scale over a specific duration.
function camera_zoom_timed(_scale, _seconds, _ease = CameraEase.SMOOTH)
{
    camera_zoom_transition(_scale, _seconds, _ease);
}

function camera_zoom_transition(_scale, _seconds, _ease = CameraEase.SMOOTH)
{
    with (camera_object)
    {
        _scale = max(_scale, 0.01);


        // ====================================================
        // OLD ZOOM OWNERSHIP
        // ====================================================

        zoom_timed_active = false;


        // ====================================================
        // FIT CANNOT OWN SIZE SIMULTANEOUSLY
        // ====================================================

        fit_active = false;
        fit_velocity_x = 0;
        fit_velocity_y = 0;


        // ====================================================
        // CURRENT PHYSICAL SCALE
        // ====================================================

        var _current_scale = camera_get_view_width(camera_id) / max(zoom_base_width, 1);


        // ====================================================
        // REQUESTED SCALE
        // ====================================================

        zoom_transition_requested_scale = _scale;


        // ====================================================
        // EFFECTIVE SCALE
        // ====================================================

        var _effective_scale = _scale;


        if (bounds_mode == CameraBoundsMode.ROOM)
        {
            _effective_scale = min(_effective_scale, room_width / max(zoom_base_width, 1), room_height / max(zoom_base_height, 1));
        }

        else if (bounds_mode == CameraBoundsMode.CUSTOM)
        {
            _effective_scale = min(_effective_scale, (bounds_right - bounds_left) / max(zoom_base_width, 1), (bounds_bottom - bounds_top) / max(zoom_base_height, 1));
        }


        zoom_transition_effective_scale = max(_effective_scale, 0.01);


        // ====================================================
        // START ZOOM TRAJECTORY
        // ====================================================

        zoom_transition_start_scale = _current_scale;
        zoom_transition_last_scale = _current_scale;

        zoom_transition_velocity = 0;

        zoom_transition_elapsed = 0;
        zoom_transition_duration = max(_seconds, 0.001);

        zoom_transition_ease = _ease;

        zoom_transition_paused = false;
        zoom_transition_active = true;


        // ====================================================
        // LEGACY COMBINED TRANSITION
        // ====================================================

        transition_active = false;
        transition_paused = false;
        transition_progress = 0;


		// ====================================================
		// POSITION DEPENDENCY REPLAN
		// ====================================================

		if (position_transition_active)
		{
		    var _remaining =
		        max(
		            position_transition_duration -
		            position_transition_elapsed,
		            0
		        );


		    // =================================================
		    // FIRST CONTACT WITH MOVING LEGAL BOUNDARY
		    // =================================================

		    var _contact_time =
		        camera_position_constraint_contact_time(
		            _remaining
		        );


		    // =================================================
		    // CONSTRAINT SHORTENS THE TRAJECTORY
		    // =================================================

		    if (_contact_time >= 0 &&
		        _contact_time < _remaining - 0.001)
		    {
		        var _contact_position =
		            camera_position_track_center_at(
		                _contact_time
		            );


		        var _contact_scale =
		            camera_transition_predict(
		                zoom_transition_start_scale,
		                zoom_transition_effective_scale,
		                zoom_transition_elapsed,
		                zoom_transition_duration,
		                zoom_transition_ease,
		                _contact_time
		            );


		        var _contact_width =
		            zoom_base_width * _contact_scale;

		        var _contact_height =
		            zoom_base_height * _contact_scale;


		        var _contact_resolved =
		            camera_resolve_view_rect(
		                _contact_position.x - _contact_width / 2,
		                _contact_position.y - _contact_height / 2,
		                _contact_width,
		                _contact_height
		            );


		        var _physical_width =
		            camera_get_view_width(camera_id);

		        var _physical_height =
		            camera_get_view_height(camera_id);

		        var _physical_center_x =
		            camera_get_view_x(camera_id) +
		            _physical_width / 2;

		        var _physical_center_y =
		            camera_get_view_y(camera_id) +
		            _physical_height / 2;


		        position_transition_effective_center_x =
		            _contact_resolved.center_x;

		        position_transition_effective_center_y =
		            _contact_resolved.center_y;


		        position_transition_start_velocity_x =
		            camera_hermite_safe_velocity(
		                _physical_center_x,
		                position_transition_velocity_x,
		                position_transition_effective_center_x,
		                max(_contact_time, 0.001)
		            );

		        position_transition_start_velocity_y =
		            camera_hermite_safe_velocity(
		                _physical_center_y,
		                position_transition_velocity_y,
		                position_transition_effective_center_y,
		                max(_contact_time, 0.001)
		            );


		        position_transition_end_velocity_x = 0;
		        position_transition_end_velocity_y = 0;


		        position_transition_start_center_x =
		            _physical_center_x;

		        position_transition_start_center_y =
		            _physical_center_y;

		        position_transition_last_center_x =
		            _physical_center_x;

		        position_transition_last_center_y =
		            _physical_center_y;


		        position_transition_elapsed = 0;

		        position_transition_duration =
		            max(_contact_time, 0.001);


		        position_transition_replanned = true;
		        position_transition_spline_active = false;
		    }


		    // =================================================
		    // NO EARLY CONTACT
		    // =================================================

		    else
		    {
		        var _future_scale =
		            camera_transition_predict(
		                zoom_transition_start_scale,
		                zoom_transition_effective_scale,
		                zoom_transition_elapsed,
		                zoom_transition_duration,
		                zoom_transition_ease,
		                _remaining
		            );


		        var _future_width =
		            zoom_base_width * _future_scale;

		        var _future_height =
		            zoom_base_height * _future_scale;


		        var _position_resolved =
		            camera_resolve_view_rect(
		                position_transition_requested_center_x - _future_width / 2,
		                position_transition_requested_center_y - _future_height / 2,
		                _future_width,
		                _future_height
		            );


		        var _new_effective_x =
		            _position_resolved.center_x;

		        var _new_effective_y =
		            _position_resolved.center_y;


		        // =============================================
		        // ENDPOINT CHANGED WITHOUT EARLY CONTACT
		        // =============================================

		        if (abs(_new_effective_x - position_transition_effective_center_x) > 0.0001 ||
		            abs(_new_effective_y - position_transition_effective_center_y) > 0.0001)
		        {
		            var _physical_width =
		                camera_get_view_width(camera_id);

		            var _physical_height =
		                camera_get_view_height(camera_id);

		            var _physical_center_x =
		                camera_get_view_x(camera_id) +
		                _physical_width / 2;

		            var _physical_center_y =
		                camera_get_view_y(camera_id) +
		                _physical_height / 2;


		            position_transition_effective_center_x =
		                _new_effective_x;

		            position_transition_effective_center_y =
		                _new_effective_y;


		            if (_remaining <= 0.001)
		            {
		                position_transition_start_center_x =
		                    _new_effective_x;

		                position_transition_start_center_y =
		                    _new_effective_y;

		                position_transition_last_center_x =
		                    _physical_center_x;

		                position_transition_last_center_y =
		                    _physical_center_y;

		                position_transition_start_velocity_x = 0;
		                position_transition_start_velocity_y = 0;

		                position_transition_end_velocity_x = 0;
		                position_transition_end_velocity_y = 0;

		                position_transition_velocity_x = 0;
		                position_transition_velocity_y = 0;

		                position_transition_elapsed = 0.001;
		                position_transition_duration = 0.001;

		                position_transition_replanned = false;
		                position_transition_spline_active = false;
		            }

		            else
		            {
		                position_transition_start_velocity_x =
		                    camera_hermite_safe_velocity(
		                        _physical_center_x,
		                        position_transition_velocity_x,
		                        _new_effective_x,
		                        _remaining
		                    );

		                position_transition_start_velocity_y =
		                    camera_hermite_safe_velocity(
		                        _physical_center_y,
		                        position_transition_velocity_y,
		                        _new_effective_y,
		                        _remaining
		                    );


		                position_transition_end_velocity_x = 0;
		                position_transition_end_velocity_y = 0;


		                position_transition_start_center_x =
		                    _physical_center_x;

		                position_transition_start_center_y =
		                    _physical_center_y;

		                position_transition_last_center_x =
		                    _physical_center_x;

		                position_transition_last_center_y =
		                    _physical_center_y;

		                position_transition_elapsed = 0;
		                position_transition_duration = _remaining;

		                position_transition_replanned = true;
		                position_transition_spline_active = false;
		            }
		        }
		    }
		}
    }
}

#endregion

#region CAMERA FIT

/// @function camera_fit_add(_target)
/// @description Adds an instance to the multi-target camera fit group.
/// @param {Instance} _target Instance to include in camera fitting.
function camera_fit_add(_target)
{
    with (camera_object)
    {
        if (instance_exists(_target))
        {
            var _already_added = false;

            for (var _i = 0; _i < array_length(fit_targets); _i++)
            {
                if (fit_targets[_i] == _target)
                {
                    _already_added = true;
                    break;
                }
            }

            if (!_already_added)
            {
                array_push(fit_targets, _target);
            }
        }
    }
}

/// @function camera_fit_remove(_target)
/// @description Removes an instance from the multi-target camera fit group.
function camera_fit_remove(_target)
{
    with (camera_object)
    {
        for (var _i = array_length(fit_targets) - 1; _i >= 0; _i--)
        {
            if (fit_targets[_i] == _target)
            {
                array_delete(fit_targets, _i, 1);
            }
        }


        if (array_length(fit_targets) == 0)
        {
            fit_velocity_x = 0;
            fit_velocity_y = 0;
        }
    }
}

/// @function camera_fit_clear_targets()
/// @description Removes all fit targets without disabling fit mode.
function camera_fit_clear_targets()
{
    with (camera_object)
    {
        fit_targets = [];

        fit_velocity_x = 0;
        fit_velocity_y = 0;
    }
}

/// @function camera_fit_clear()
/// @description Stops multi-target fitting and removes all fit targets.
function camera_fit_clear()
{
    with (camera_object)
    {
        if (fit_active)
        {
            zoom_target_width = fit_previous_zoom_width;

            zoom_target_height = fit_previous_zoom_height;
        }


        fit_active = false;
        fit_targets = [];

        fit_velocity_x = 0;
        fit_velocity_y = 0;
    }
}

/// @function camera_fit_start()
/// @description Enables multi-target camera fitting.
function camera_fit_start()
{
    with (camera_object)
    {
        fit_previous_zoom_width = zoom_target_width;

        fit_previous_zoom_height = zoom_target_height;


        fit_active = true;

        zoom_timed_active = false;


        fit_base_width = camera_get_view_width(camera_id);

        fit_base_height = camera_get_view_height(camera_id);


        fit_velocity_x = 0;
        fit_velocity_y = 0;


        follow_velocity_x = 0;
        follow_velocity_y = 0;


        lookahead_initialized = false;

        lookahead_x = 0;
        lookahead_y = 0;

        lookahead_target_x = 0;
        lookahead_target_y = 0;
    }
}

/// @function camera_fit_stop()
/// @description Stops multi-target fitting without removing fit targets.
function camera_fit_stop()
{
    with (camera_object)
    {
        if (fit_active)
        {
            zoom_target_width = fit_previous_zoom_width;

            zoom_target_height = fit_previous_zoom_height;
        }


        fit_active = false;

        fit_velocity_x = 0;
        fit_velocity_y = 0;
    }
}

/// @function camera_fit_cleanup()
/// @description Removes destroyed or invalid instances from the multi-target fit group.
function camera_fit_cleanup()
{
    with (camera_object)
    {
        for (var _i = array_length(fit_targets) - 1; _i >= 0; _i--)
        {
            if (!instance_exists(fit_targets[_i]))
            {
                array_delete(fit_targets, _i, 1);
            }
        }


        if (array_length(fit_targets) == 0)
        {
            fit_velocity_x = 0;
            fit_velocity_y = 0;
        }
    }
}

/// @function camera_fit_get_extents()
/// @description Returns the outermost positions of all valid multi-target fit targets.
function camera_fit_get_extents()
{
    var _camera_instance = instance_find(camera_object, 0);

    if (!instance_exists(_camera_instance))
        return undefined;


    var _targets = _camera_instance.fit_targets;

    var _count = array_length(_targets);


    var _found = false;

    var _left = 0;
    var _right = 0;
    var _top = 0;
    var _bottom = 0;


    for (var _i = 0; _i < _count; _i++)
    {
        var _target = _targets[_i];

        if (!instance_exists(_target))
            continue;


        if (!_found)
        {
            _left = _target.x;
            _right = _target.x;

            _top = _target.y;
            _bottom = _target.y;

            _found = true;
        }
        else
        {
            _left = min(_left, _target.x);

            _right = max(_right, _target.x);

            _top = min(_top, _target.y);

            _bottom = max(_bottom, _target.y);
        }
    }


    if (!_found)
        return undefined;


    return
    {
        left : _left,
        right : _right,
        top : _top,
        bottom : _bottom
    };
}

/// @function camera_fit_get_size(_extents)
/// @description Calculates the camera view size needed to fit the target extents and reports whether the group exceeds the allowed maximum size.
function camera_fit_get_size(_extents)
{
    var _camera_instance = instance_find(camera_object, 0);

    if (!instance_exists(_camera_instance))
        return undefined;


    var _group_width = _extents.right - _extents.left;

    var _group_height = _extents.bottom - _extents.top;


    _group_width += _camera_instance.border_x * 2;

    _group_height += _camera_instance.border_y * 2;


    var _base_width = _camera_instance.fit_base_width;

    var _base_height = _camera_instance.fit_base_height;


    // ========================================================
    // REQUIRED SCALE
    // ========================================================

    var _required_scale_x = max(_group_width, 1) / _base_width;

    var _required_scale_y = max(_group_height, 1) / _base_height;


    var _required_scale = max(_required_scale_x, _required_scale_y);


    // ========================================================
    // ALLOWED SCALE RANGE
    // ========================================================

    var _min_scale = max(_camera_instance.fit_min_scale, 0.01);

    var _max_scale = max(_camera_instance.fit_max_scale, _min_scale);


    // Expanding is a separate rule.
    //
    // If expansion is disabled, the camera cannot become
    // larger than the size it had when fit mode began.

    if (!_camera_instance.fit_allow_expand)
    {
        _max_scale = min(_max_scale, 1);
    }


    // Keep the range valid.
    _min_scale = min(_min_scale, _max_scale);


    // IMPORTANT:
    //
    // fit_allow_shrink is NOT handled here.
    //
    // fit_min_scale determines the smallest size fit mode
    // is allowed to reach relative to its starting size.
    //
    // fit_allow_shrink determines whether the current camera
    // is allowed to move downward toward that smaller size.


    // ========================================================
    // MAXIMUM LIMIT
    // ========================================================

    var _limited = _required_scale > _max_scale;


    var _final_scale = clamp(_required_scale, _min_scale, _max_scale);


    return
    {
        width :
            _base_width * _final_scale,

        height :
            _base_height * _final_scale,

        required_width :
            _base_width * _required_scale,

        required_height :
            _base_height * _required_scale,

        limited :
            _limited
    };
}

/// @function camera_fit_get_visible_extents()
/// @description Returns the outermost positions of fit targets currently inside the camera viewport.
function camera_fit_get_visible_extents()
{
    var _camera_instance = instance_find(camera_object, 0);

    if (!instance_exists(_camera_instance))
        return undefined;


    var _camera_x = camera_get_view_x(_camera_instance.camera_id);

    var _camera_y = camera_get_view_y(_camera_instance.camera_id);

    var _camera_width = camera_get_view_width(_camera_instance.camera_id);

    var _camera_height = camera_get_view_height(_camera_instance.camera_id);


    var _camera_right = _camera_x + _camera_width;

    var _camera_bottom = _camera_y + _camera_height;


    var _targets = _camera_instance.fit_targets;

    var _count = array_length(_targets);


    var _found = false;

    var _left = 0;
    var _right = 0;
    var _top = 0;
    var _bottom = 0;


    for (var _i = 0; _i < _count; _i++)
    {
        var _target = _targets[_i];

        if (!instance_exists(_target))
            continue;


        var _inside = _target.x >= _camera_x && _target.x <= _camera_right && _target.y >= _camera_y && _target.y <= _camera_bottom;


        if (!_inside)
            continue;


        if (!_found)
        {
            _left = _target.x;
            _right = _target.x;

            _top = _target.y;
            _bottom = _target.y;

            _found = true;
        }
        else
        {
            _left = min(_left, _target.x);

            _right = max(_right, _target.x);

            _top = min(_top, _target.y);

            _bottom = max(_bottom, _target.y);
        }
    }


    if (!_found)
        return undefined;


    return
    {
        left : _left,
        right : _right,
        top : _top,
        bottom : _bottom
    };
}

/// @function camera_fit_limits(_min_scale, _max_scale, _allow_shrink, _allow_expand)
/// @description Sets the size limits and shrink/expand permissions for multi-target fitting.
/// @param {Real} _min_scale Smallest allowed camera scale.
/// @param {Real} _max_scale Largest allowed camera scale.
/// @param {Bool} _allow_shrink Whether fit mode may zoom in smaller than its starting size.
/// @param {Bool} _allow_expand Whether fit mode may zoom out larger than its starting size.
function camera_fit_limits(_min_scale, _max_scale, _allow_shrink = true, _allow_expand = true)
{
    with (camera_object)
    {
        fit_min_scale = max(_min_scale, 0.01);

        fit_max_scale = max(_max_scale, fit_min_scale);

        fit_allow_shrink = _allow_shrink;

        fit_allow_expand = _allow_expand;
    }
}

/// @function camera_fit_scale_limits(_min_scale, _max_scale)
/// @description Sets the minimum and maximum multi-target fit scales.
function camera_fit_scale_limits(_min_scale, _max_scale)
{
    with (camera_object)
    {
        fit_min_scale = max(_min_scale, 0.01);

        fit_max_scale = max(_max_scale, fit_min_scale);
    }
}

/// @function camera_fit_shrink(_enabled)
/// @description Enables or disables reducing the current multi-target fit camera size.
function camera_fit_shrink(_enabled)
{
    with (camera_object)
    {
        fit_allow_shrink = _enabled;
    }
}

/// @function camera_fit_expand(_enabled)
/// @description Enables or disables multi-target fit camera expansion.
function camera_fit_expand(_enabled)
{
    with (camera_object)
    {
        fit_allow_expand = _enabled;
    }
}

/// @function camera_fit_zoom_speed(_speed)
/// @description Sets how quickly multi-target fitting changes camera size.
function camera_fit_zoom_speed(_speed)
{
    with (camera_object)
    {
        fit_zoom_speed = clamp(_speed, 0, 1);
    }
}

/// @function camera_fit_strength(_strength)
/// @description Sets the spring strength used by multi-target fit movement.
function camera_fit_strength(_strength)
{
    with (camera_object)
    {
        fit_strength = max(_strength, 0);
    }
}

/// @function camera_fit_damping(_damping)
/// @description Sets the damping used by multi-target fit movement.
function camera_fit_damping(_damping)
{
    with (camera_object)
    {
        fit_damping = clamp(_damping, 0, 1);
    }
}

/// @function camera_fit_max_speed(_speed)
/// @description Sets the maximum multi-target fit movement speed. Zero means unlimited.
function camera_fit_max_speed(_speed)
{
    with (camera_object)
    {
        fit_max_speed = max(_speed, 0);
    }
}

/// @function camera_fit_overshoot(_enabled)
/// @description Enables or disables overshoot for multi-target fit movement.
function camera_fit_overshoot(_enabled)
{
    with (camera_object)
    {
        fit_allow_overshoot = _enabled;
    }
}

#endregion

#region CAMERA MATH AND EASING

/// @function normalize(_value, _start, _end)
/// @description Converts a value within a range into a value from 0 to 1.
function normalize(_value, _start, _end)
{
    if (_start == _end)
        return 0;

    return (_value - _start) / (_end - _start);
}


/// @function remap(_value, _start_in, _end_in, _start_out, _end_out)
/// @description Converts a value from one range into another range.
function remap(_value, _start_in, _end_in, _start_out, _end_out)
{
    var _t = normalize(_value, _start_in, _end_in);

    return lerp(_start_out, _end_out, _t);
}


/// @function ease_smooth(_t)
function ease_smooth(_t)
{
    _t = clamp(_t, 0, 1);

    return _t * _t * (3 - 2 * _t);
}


/// @function ease_out(_t)
function ease_out(_t)
{
    _t = clamp(_t, 0, 1);

    return 1 - power(1 - _t, 2);
}


/// @function ease_in(_t)
function ease_in(_t)
{
    _t = clamp(_t, 0, 1);

    return _t * _t;
}


/// @function ease_in_out(_t)
function ease_in_out(_t)
{
    _t = clamp(_t, 0, 1);

    if (_t < 0.5)
        return 2 * _t * _t;

    return 1 - power(-2 * _t + 2, 2) / 2;
}

/// @function camera_ease_value(_t, _ease)
function camera_ease_value(_t, _ease)
{
    _t = clamp(_t, 0, 1);

    switch (_ease)
    {
        case CameraEase.SMOOTH:
            return ease_smooth(_t);

        case CameraEase.IN:
            return ease_in(_t);

        case CameraEase.OUT:
            return ease_out(_t);

        case CameraEase.IN_OUT:
            return ease_in_out(_t);

        case CameraEase.LINEAR:
            return _t;
    }

    return _t;
}


/// @function camera_transition_predict(_start, _target, _elapsed, _duration, _ease, _seconds_from_now)
function camera_transition_predict(_start, _target, _elapsed, _duration, _ease, _seconds_from_now)
{
    var _future_elapsed = _elapsed + max(_seconds_from_now, 0);
    var _t = clamp(_future_elapsed / max(_duration, 0.001), 0, 1);
    var _eased = camera_ease_value(_t, _ease);

    return lerp(_start, _target, _eased);
}


/// @function camera_hermite_value(_start, _start_velocity, _end, _end_velocity, _t, _duration)
function camera_hermite_value(_start, _start_velocity, _end, _end_velocity, _t, _duration)
{
    _t = clamp(_t, 0, 1);

    var _t2 = _t * _t;
    var _t3 = _t2 * _t;

    var _h00 = 2 * _t3 - 3 * _t2 + 1;
    var _h10 = _t3 - 2 * _t2 + _t;
    var _h01 = -2 * _t3 + 3 * _t2;
    var _h11 = _t3 - _t2;

    var _start_tangent = _start_velocity * _duration;
    var _end_tangent = _end_velocity * _duration;

    return _h00 * _start + _h10 * _start_tangent + _h01 * _end + _h11 * _end_tangent;
}

/// @function camera_hermite_safe_velocity(_start, _velocity, _end, _duration)
/// @description Limits an incoming Hermite velocity so the remaining segment does not reverse or overshoot.
function camera_hermite_safe_velocity(_start, _velocity, _end, _duration)
{
    var _delta = _end - _start;

    _duration = max(_duration, 0.001);


    // Already effectively at the destination.
    if (abs(_delta) <= 0.0001)
    {
        return 0;
    }


    // Current velocity is moving away from the new destination.
    // Preserving it would require the trajectory to reverse.
    if (_velocity * _delta <= 0)
    {
        return 0;
    }


    // With an ending velocity of zero, limiting the starting
    // tangent to 3x the interval distance keeps this Hermite
    // segment monotonic.
    var _max_velocity = (3 * abs(_delta)) / _duration;


    return clamp(
        _velocity,
        -_max_velocity,
        _max_velocity
    );
}

/// @function camera_catmull_rom(_p0, _p1, _p2, _p3, _t)
/// @description Evaluates one Catmull-Rom spline component from P1 to P2.
function camera_catmull_rom(_p0, _p1, _p2, _p3, _t)
{
    _t = clamp(_t, 0, 1);

    var _t2 = _t * _t;
    var _t3 = _t2 * _t;

    return 0.5 * (
        (2 * _p1) +
        (-_p0 + _p2) * _t +
        (2 * _p0 - 5 * _p1 + 4 * _p2 - _p3) * _t2 +
        (-_p0 + 3 * _p1 - 3 * _p2 + _p3) * _t3
    );
}

/// @function camera_position_track_center_at(_seconds_from_now)
/// @description Predicts the authored position track without modifying it.
function camera_position_track_center_at(_seconds_from_now)
{
    var _future_elapsed =
        position_transition_elapsed +
        max(_seconds_from_now, 0);

    var _t = clamp(
        _future_elapsed /
        max(position_transition_duration, 0.001),
        0,
        1
    );

    var _ease =
        camera_ease_value(
            _t,
            position_transition_ease
        );


    var _x;
    var _y;


    if (position_transition_replanned)
    {
        _x = camera_hermite_value(
            position_transition_start_center_x,
            position_transition_start_velocity_x,
            position_transition_effective_center_x,
            position_transition_end_velocity_x,
            _t,
            position_transition_duration
        );

        _y = camera_hermite_value(
            position_transition_start_center_y,
            position_transition_start_velocity_y,
            position_transition_effective_center_y,
            position_transition_end_velocity_y,
            _t,
            position_transition_duration
        );
    }

    else if (position_transition_spline_active)
    {
        _x = camera_catmull_rom(
            position_transition_spline_p0_x,
            position_transition_spline_p1_x,
            position_transition_spline_p2_x,
            position_transition_spline_p3_x,
            _ease
        );

        _y = camera_catmull_rom(
            position_transition_spline_p0_y,
            position_transition_spline_p1_y,
            position_transition_spline_p2_y,
            position_transition_spline_p3_y,
            _ease
        );
    }

    else
    {
        _x = lerp(
            position_transition_start_center_x,
            position_transition_effective_center_x,
            _ease
        );

        _y = lerp(
            position_transition_start_center_y,
            position_transition_effective_center_y,
            _ease
        );
    }


    return {
        x: _x,
        y: _y
    };
}

/// @function camera_position_constraint_contact_time(_max_seconds)
/// @description Finds the first future time the active position track contacts a moving camera bound.
function camera_position_constraint_contact_time(_max_seconds)
{
    if (!position_transition_active)
        return -1;


    _max_seconds = max(_max_seconds, 0);


    if (_max_seconds <= 0)
        return 0;


    var _samples = 32;
    var _iterations = 16;

    var _previous_time = 0;


    for (var _i = 1; _i <= _samples; _i++)
    {
        var _probe_time =
            _max_seconds * (_i / _samples);


        var _position =
            camera_position_track_center_at(
                _probe_time
            );


        var _scale =
            camera_transition_predict(
                zoom_transition_start_scale,
                zoom_transition_effective_scale,
                zoom_transition_elapsed,
                zoom_transition_duration,
                zoom_transition_ease,
                _probe_time
            );


        var _width =
            zoom_base_width * _scale;

        var _height =
            zoom_base_height * _scale;


        var _resolved =
            camera_resolve_view_rect(
                _position.x - _width / 2,
                _position.y - _height / 2,
                _width,
                _height
            );


        var _blocked =
            abs(_resolved.center_x - _position.x) > 0.0001 ||
            abs(_resolved.center_y - _position.y) > 0.0001;


        if (_blocked)
        {
            var _low = _previous_time;
            var _high = _probe_time;


            for (var _j = 0; _j < _iterations; _j++)
            {
                var _mid =
                    (_low + _high) * 0.5;


                var _mid_position =
                    camera_position_track_center_at(
                        _mid
                    );


                var _mid_scale =
                    camera_transition_predict(
                        zoom_transition_start_scale,
                        zoom_transition_effective_scale,
                        zoom_transition_elapsed,
                        zoom_transition_duration,
                        zoom_transition_ease,
                        _mid
                    );


                var _mid_width =
                    zoom_base_width * _mid_scale;

                var _mid_height =
                    zoom_base_height * _mid_scale;


                var _mid_resolved =
                    camera_resolve_view_rect(
                        _mid_position.x - _mid_width / 2,
                        _mid_position.y - _mid_height / 2,
                        _mid_width,
                        _mid_height
                    );


                var _mid_blocked =
                    abs(_mid_resolved.center_x - _mid_position.x) > 0.0001 ||
                    abs(_mid_resolved.center_y - _mid_position.y) > 0.0001;


                if (_mid_blocked)
                    _high = _mid;
                else
                    _low = _mid;
            }


            return _high;
        }


        _previous_time = _probe_time;
    }


    return -1;
}

#endregion

#region CAMERA ANCHOR AND TARGET

/// @function camera_anchor(_anchor_x, _anchor_y)
/// @description Sets the camera zoom anchor.
function camera_anchor(_anchor_x, _anchor_y)
{
    with (camera_object)
    {
        zoom_anchor_x = clamp(round(_anchor_x), -1, 1);

        zoom_anchor_y = clamp(round(_anchor_y), -1, 1);
    }
}


/// @function camera_anchor_zoom(_anchor_x, _anchor_y, _scale)
/// @description Sets the zoom anchor and smoothly zooms.
function camera_anchor_zoom(_anchor_x, _anchor_y, _scale)
{
    camera_anchor(_anchor_x, _anchor_y);
    camera_zoom(_scale);
}


/// @function camera_anchor_zoom_timed(_anchor_x, _anchor_y, _scale, _seconds, _ease)
/// @description Sets the zoom anchor and zooms over a specific duration.
function camera_anchor_zoom_timed(_anchor_x, _anchor_y, _scale, _seconds, _ease = CameraEase.SMOOTH)
{
    camera_anchor(_anchor_x, _anchor_y);
    camera_zoom_timed(_scale, _seconds, _ease);
}


/// @function camera_set_self_target(_camera)
function camera_set_self_target(_camera)
{
    camera_set_view_target(_camera, id);
}


#endregion

#region CAMERA FOLLOW

// ============================================================
// CAMERA FOLLOW
// ============================================================

/// @function camera_follow(_target, _strength, _damping, _lookahead_x, _lookahead_y)
/// @description Starts smooth cinematic following of a target instance.
/// @param {Instance} _target Instance for the camera to follow.
/// @param {Real} _strength How strongly the camera accelerates toward the target.
/// @param {Real} _damping How much existing camera velocity is retained each step.
/// @param {Real} _lookahead_x Horizontal automatic look-ahead distance.
/// @param {Real} _lookahead_y Vertical automatic look-ahead distance.
function camera_follow(_target, _strength = 0.12, _damping = 0.75, _lookahead_x = 120, _lookahead_y = 60)
{
    with (camera_object)
    {
        follow_target = _target;

        follow_strength = _strength;
        follow_damping = _damping;

        lookahead_distance_x = max(_lookahead_x, 0);
        lookahead_distance_y = max(_lookahead_y, 0);

        follow_velocity_x = 0;
        follow_velocity_y = 0;

        follow_active = true;

        // Custom cinematic follow will control position,
        // so disable GameMaker's built-in target following.
        camera_set_view_target(camera_id, noone);
    }
}

/// @function camera_follow_max_speed(_speed)
/// @description Sets the maximum cinematic follow speed. Use 0 for unlimited speed.
/// @param {Real} _speed Maximum follow speed in pixels per step.
function camera_follow_max_speed(_speed)
{
    with (camera_object)
    {
        follow_max_speed = max(_speed, 0);
    }
}

/// @function camera_follow_axes(_follow_x, _follow_y)
/// @description Enables or disables cinematic following on each axis.
function camera_follow_axes(_follow_x, _follow_y)
{
    with (camera_object)
    {
        follow_x_active = _follow_x;
        follow_y_active = _follow_y;

        if (!follow_x_active)
            follow_velocity_x = 0;

        if (!follow_y_active)
            follow_velocity_y = 0;
    }
}

/// @function camera_lookahead(_enabled)
/// @description Enables or disables automatic camera look-ahead.
/// @param {Bool} _enabled Whether automatic look-ahead is active.
function camera_lookahead(_enabled)
{
    with (camera_object)
    {
        lookahead_active = _enabled;

        if (!_enabled)
        {
            lookahead_initialized = false;

            lookahead_x = 0;
            lookahead_y = 0;

            lookahead_target_x = 0;
            lookahead_target_y = 0;
        }
    }
}

/// @function camera_lookahead_distance(_x, _y)
/// @description Sets the horizontal and vertical automatic look-ahead distances.
/// @param {Real} _x Horizontal look-ahead distance.
/// @param {Real} _y Vertical look-ahead distance.
function camera_lookahead_distance(_x, _y)
{
    with (camera_object)
    {
        lookahead_distance_x = max(_x, 0);
        lookahead_distance_y = max(_y, 0);
    }
}

/// @function camera_follow_offset(_x, _y)
/// @description Smoothly changes the cinematic follow offset target.
function camera_follow_offset(_x, _y)
{
    with (camera_object)
    {
        follow_offset_target_x = _x;
        follow_offset_target_y = _y;
    }
}


/// @function camera_follow_stop()
/// @description Stops cinematic camera following and leaves the camera in place.
function camera_follow_stop()
{
    with (camera_object)
    {
        follow_active = false;
        follow_target = noone;

        follow_velocity_x = 0;
        follow_velocity_y = 0;

        camera_set_view_target(camera_id, noone);
    }
}


#endregion

#region CAMERA INTERRUPT

// ============================================================
// CAMERA INTERRUPT
// ============================================================

function camera_interrupt()
{
    with (camera_object)
    {
        // ====================================================
        // STOP LEGACY TRANSITIONS
        // ====================================================

        transition_active = false;
        transition_paused = false;
        transition_progress = 0;

        zoom_timed_active = false;


        // ====================================================
        // STOP NEW TRANSITION TRACKS
        // ====================================================

        position_transition_active = false;
        position_transition_paused = false;

        position_transition_velocity_x = 0;
        position_transition_velocity_y = 0;

        position_transition_replanned = false;
        position_transition_spline_active = false;


        zoom_transition_active = false;
        zoom_transition_paused = false;

        zoom_transition_velocity = 0;


        transition_compat_active = false;


        // ====================================================
        // STOP CINEMATIC FOLLOW
        // ====================================================

        follow_active = false;
        follow_target = noone;

        follow_velocity_x = 0;
        follow_velocity_y = 0;


        // ====================================================
        // HOLD CURRENT ZOOM
        // ====================================================

        zoom_target_width =
            camera_get_view_width(camera_id);

        zoom_target_height =
            camera_get_view_height(camera_id);


        camera_set_view_target(camera_id, noone);
    }
}

function camera_pause_transition()
{
    with (camera_object)
    {
        if (transition_active)
            transition_paused = true;

        if (position_transition_active)
            position_transition_paused = true;

        if (zoom_transition_active)
            zoom_transition_paused = true;
    }
}


function camera_resume_transition()
{
    with (camera_object)
    {
        transition_paused = false;

        position_transition_paused = false;

        zoom_transition_paused = false;
    }
}

#endregion

#region CAMERA BOUNDS

// ============================================================
// CAMERA BOUNDS
// ============================================================

/// @function camera_set_bounds(_left, _top, _right, _bottom)
/// @description Sets custom camera bounds.
function camera_set_bounds(_left, _top, _right, _bottom)
{
    with (camera_object)
    {
        bounds_left = min(_left, _right);

        bounds_top = min(_top, _bottom);

        bounds_right = max(_left, _right);

        bounds_bottom = max(_top, _bottom);

        bounds_mode = CameraBoundsMode.CUSTOM;
    }
}

/// @function camera_bounds_room()
/// @description Uses the room as the camera bounds.
function camera_bounds_room()
{
    with (camera_object)
    {
        bounds_left = 0;
        bounds_top = 0;

        bounds_right = room_width;

        bounds_bottom = room_height;

        bounds_mode = CameraBoundsMode.ROOM;
    }
}

/// @function camera_clear_bounds()
/// @description Removes camera bounds.
function camera_clear_bounds()
{
    with (camera_object)
    {
        bounds_mode = CameraBoundsMode.NONE;
    }
}

/// @function camera_resolve_view_rect(_x, _y, _width, _height)
/// @description Resolves a requested camera rectangle against the active global camera bounds.
function camera_resolve_view_rect(_x, _y, _width, _height)
{
    var _left = 0;
    var _top = 0;
    var _right = 0;
    var _bottom = 0;

    var _bounds_active = true;


    switch (bounds_mode)
    {
        case CameraBoundsMode.NONE:
            _bounds_active = false;
        break;


        case CameraBoundsMode.ROOM:
            _left = 0;
            _top = 0;
            _right = room_width;
            _bottom = room_height;
        break;


        case CameraBoundsMode.CUSTOM:
            _left = bounds_left;
            _top = bounds_top;
            _right = bounds_right;
            _bottom = bounds_bottom;
        break;
    }


    if (_bounds_active)
    {
        var _bounds_width = _right - _left;
        var _bounds_height = _bottom - _top;


        if (_width > _bounds_width)
        {
            _x = (_left + _right - _width) / 2;
        }
        else
        {
            _x = clamp(_x, _left, _right - _width);
        }


        if (_height > _bounds_height)
        {
            _y = (_top + _bottom - _height) / 2;
        }
        else
        {
            _y = clamp(_y, _top, _bottom - _height);
        }
    }


    return
    {
        x: _x,
        y: _y,

        width: _width,
        height: _height,

        center_x: _x + _width / 2,
        center_y: _y + _height / 2
    };
}

#endregion

#region CAMERA TARGET BORDER

// ============================================================
// CAMERA TARGET BORDER
// ============================================================

/// @function camera_target_border_zero(_camera)
function camera_target_border_zero(_camera)
{
    camera_set_view_border(_camera, 0, 0);
}

/// @function camera_target_border_center(_camera)
function camera_target_border_center(_camera)
{
    var _half_width = round(camera_get_view_width(_camera) / 2);

    var _half_height = round(camera_get_view_height(_camera) / 2);

    camera_set_view_border(_camera, _half_width, _half_height);
}

#endregion

#region CAMERA TRANSITION

// ============================================================
// CAMERA TRANSITION
// ============================================================

/// @function camera_transition_to(_target, _zoom_scale, _seconds, _keep_end, _ease)
/// @description Moves and zooms the camera toward a target over a set duration.
function camera_transition_to(_target, _zoom_scale, _seconds, _keep_end, _ease = CameraEase.SMOOTH)
{
    if (!instance_exists(_target))
        return;


    _zoom_scale = max(_zoom_scale, 0.01);


    // ========================================================
    // SAVE COMPATIBILITY STATE
    // ========================================================

    with (camera_object)
    {
        transition_compat_active = true;

        transition_compat_keep_end = _keep_end;

        transition_compat_target = _target;

        transition_compat_previous_target =
            camera_get_view_target(camera_id);

        transition_compat_previous_zoom_width =
            zoom_target_width;

        transition_compat_previous_zoom_height =
            zoom_target_height;
    }


    // ========================================================
    // START INDEPENDENT TRACKS
    // ========================================================

    // Start zoom first so the position track can predict the
    // camera size that will exist at its destination.

    camera_zoom_transition(
        _zoom_scale,
        _seconds,
        _ease
    );


    camera_position_transition_to_point(
        _target.x,
        _target.y,
        _seconds,
        _ease
    );


    // ========================================================
    // STORE EFFECTIVE END SCALE
    // ========================================================

    with (camera_object)
    {
        transition_compat_end_scale =
            zoom_transition_effective_scale;
    }
}

/// @function camera_transition_to_point(_x, _y, _zoom_scale, _seconds, _keep_end, _ease)
/// @description Moves and zooms the camera toward a world position over a set duration.
function camera_transition_to_point(_x, _y, _zoom_scale, _seconds, _keep_end, _ease = CameraEase.SMOOTH)
{
    _zoom_scale = max(_zoom_scale, 0.01);


    // ========================================================
    // SAVE COMPATIBILITY STATE
    // ========================================================

    with (camera_object)
    {
        transition_compat_active = true;

        transition_compat_keep_end = _keep_end;

        // A point transition has no built-in follow target.
        transition_compat_target = noone;

        transition_compat_previous_target =
            camera_get_view_target(camera_id);

        transition_compat_previous_zoom_width =
            zoom_target_width;

        transition_compat_previous_zoom_height =
            zoom_target_height;
    }


    // ========================================================
    // START INDEPENDENT TRACKS
    // ========================================================

    camera_zoom_transition(
        _zoom_scale,
        _seconds,
        _ease
    );


    camera_position_transition_to_point(
        _x,
        _y,
        _seconds,
        _ease
    );


    // ========================================================
    // STORE EFFECTIVE END SCALE
    // ========================================================

    with (camera_object)
    {
        transition_compat_end_scale =
            zoom_transition_effective_scale;
    }
}

function camera_position_transition_to_point(_x, _y, _seconds, _ease = CameraEase.SMOOTH)
{
    with (camera_object)
    {
        transition_active = false;
        transition_paused = false;
        transition_progress = 0;


        // ====================================================
        // CURRENT PHYSICAL CAMERA
        // ====================================================

        var _width = camera_get_view_width(camera_id);
        var _height = camera_get_view_height(camera_id);

        var _center_x = camera_get_view_x(camera_id) + _width / 2;
        var _center_y = camera_get_view_y(camera_id) + _height / 2;


        // ====================================================
        // REQUESTED DESTINATION
        // ====================================================

        position_transition_requested_center_x = _x;
        position_transition_requested_center_y = _y;


        // ====================================================
        // DESTINATION CAMERA SIZE
        // ====================================================

        var _destination_width = _width;
        var _destination_height = _height;


        if (zoom_transition_active)
        {
            var _zoom_advance = zoom_transition_paused ? 0 : max(_seconds, 0);

            var _destination_scale = camera_transition_predict(zoom_transition_start_scale, zoom_transition_effective_scale, zoom_transition_elapsed, zoom_transition_duration, zoom_transition_ease, _zoom_advance);

            _destination_width = zoom_base_width * _destination_scale;
            _destination_height = zoom_base_height * _destination_scale;
        }


        // ====================================================
        // EFFECTIVE DESTINATION
        // ====================================================

        var _resolved = camera_resolve_view_rect(_x - _destination_width / 2, _y - _destination_height / 2, _destination_width, _destination_height);

        position_transition_effective_center_x = _resolved.center_x;
        position_transition_effective_center_y = _resolved.center_y;


        // ====================================================
        // START TRAJECTORY
        // ====================================================

        position_transition_start_center_x = _center_x;
        position_transition_start_center_y = _center_y;

        position_transition_last_center_x = _center_x;
        position_transition_last_center_y = _center_y;

        position_transition_velocity_x = 0;
        position_transition_velocity_y = 0;

        position_transition_start_velocity_x = 0;
        position_transition_start_velocity_y = 0;

        position_transition_end_velocity_x = 0;
        position_transition_end_velocity_y = 0;

		position_transition_spline_active = false;
        position_transition_replanned = false;

        position_transition_elapsed = 0;
        position_transition_duration = max(_seconds, 0.001);

        position_transition_ease = _ease;

        position_transition_paused = false;
        position_transition_active = true;

        camera_set_view_target(camera_id, noone);
    }
}

/// @function camera_position_transition_to_keyframe(_group, _from_index, _to_index, _seconds, _ease)
function camera_position_transition_to_keyframe(_group, _from_index, _to_index, _seconds, _ease = CameraEase.SMOOTH)
{
    var _count = array_length(_group);

    if (_to_index < 0 || _to_index >= _count)
        return;


    var _target_keyframe = _group[_to_index];


    // ========================================================
    // START NORMAL POSITION TRACK
    // ========================================================

    camera_position_transition_to_point(
        _target_keyframe.x,
        _target_keyframe.y,
        _seconds,
        _ease
    );


    // ========================================================
    // SPLINE SETUP
    // ========================================================

    with (camera_object)
    {
        position_transition_spline_active =
		    variable_instance_exists(_target_keyframe, "position_spline")
		    ? _target_keyframe.position_spline
		    : false;


        if (!position_transition_spline_active)
            exit;


        // ====================================================
        // P1 — REAL CURRENT START
        // ====================================================

        position_transition_spline_p1_x =
            position_transition_start_center_x;

        position_transition_spline_p1_y =
            position_transition_start_center_y;


        // ====================================================
        // P2 — EFFECTIVE DESTINATION
        // ====================================================

        position_transition_spline_p2_x =
            position_transition_effective_center_x;

        position_transition_spline_p2_y =
            position_transition_effective_center_y;


        // ====================================================
        // P0 — PREVIOUS POSITION KEY
        // ====================================================

        var _previous_position_index = -1;


        for (var _i = _from_index - 1; _i >= 0; _i--)
        {
            if (_group[_i].use_position)
            {
                _previous_position_index = _i;
                break;
            }
        }


        if (_previous_position_index >= 0)
        {
            var _previous_keyframe =
                _group[_previous_position_index];

            position_transition_spline_p0_x =
                _previous_keyframe.x;

            position_transition_spline_p0_y =
                _previous_keyframe.y;
        }
        else
        {
            position_transition_spline_p0_x =
                position_transition_spline_p1_x;

            position_transition_spline_p0_y =
                position_transition_spline_p1_y;
        }


        // ====================================================
        // P3 — NEXT POSITION KEY
        // ====================================================

        var _next_position_index =
            camera_keyframe_next_position(
                _group,
                _to_index
            );


        if (_next_position_index >= 0)
        {
            var _next_keyframe =
                _group[_next_position_index];

            position_transition_spline_p3_x =
                _next_keyframe.x;

            position_transition_spline_p3_y =
                _next_keyframe.y;
        }
        else
        {
            position_transition_spline_p3_x =
                position_transition_spline_p2_x;

            position_transition_spline_p3_y =
                position_transition_spline_p2_y;
        }
    }
}

#endregion

#region CAMERA CUT

// ============================================================
// CAMERA CUT
// ============================================================

/// @function camera_cut_to(_target, _zoom_scale)
/// @description Instantly moves and zooms the camera to a target.
/// @param {Real} _zoom_scale Fraction of the base camera size. 1.0 is the base size.
function camera_cut_to(_target, _zoom_scale = 1)
{
    with (camera_object)
    {
        transition_active = false;
        zoom_timed_active = false;
		
		position_transition_active = false;
		position_transition_paused = false;

		position_transition_velocity_x = 0;
		position_transition_velocity_y = 0;

		position_transition_replanned = false;
		position_transition_spline_active = false;


		zoom_transition_active = false;
		zoom_transition_paused = false;

		zoom_transition_velocity = 0;


		transition_compat_active = false;

        follow_active = false;
        follow_target = noone;

        follow_velocity_x = 0;
        follow_velocity_y = 0;

        _zoom_scale = max(_zoom_scale, 0.01);


        // ====================================================
        // CUT SIZE
        // ====================================================

        var _width = zoom_base_width * _zoom_scale;

        var _height = zoom_base_height * _zoom_scale;


        if (bounds_mode == CameraBoundsMode.ROOM)
        {
            _width = min(_width, room_width);

            _height = min(_height, room_height);
        }

        else if (bounds_mode == CameraBoundsMode.CUSTOM)
        {
            _width = min(_width, bounds_right - bounds_left);

            _height = min(_height, bounds_bottom - bounds_top);
        }


        zoom_target_width = _width;

        zoom_target_height = _height;


        // ====================================================
        // CUT CENTER
        // ====================================================

        var _half_width = _width / 2;

        var _half_height = _height / 2;

        var _center_x = _target.x;

        var _center_y = _target.y;


        if (bounds_mode == CameraBoundsMode.ROOM)
        {
            _center_x = clamp(_center_x, _half_width, room_width - _half_width);

            _center_y = clamp(_center_y, _half_height, room_height - _half_height);
        }

        else if (bounds_mode == CameraBoundsMode.CUSTOM)
        {
            _center_x = clamp(_center_x, bounds_left + _half_width, bounds_right - _half_width);

            _center_y = clamp(_center_y, bounds_top + _half_height, bounds_bottom - _half_height);
        }


        // ====================================================
        // APPLY CUT
        // ====================================================

        camera_set_view_size(camera_id, _width, _height);

        camera_set_view_pos(camera_id, _center_x - _half_width + shake_offset_x, _center_y - _half_height + shake_offset_y);

        camera_set_view_target(camera_id, _target);

        camera_target_border_center(camera_id);
    }
}

/// @function camera_cut_to_point(_x, _y, _zoom_scale)
/// @description Instantly moves and zooms the camera to a world position.
/// @param {Real} _zoom_scale Fraction of the base camera size. 1.0 is the base size.
function camera_cut_to_point(_x, _y, _zoom_scale = 1)
{
    with (camera_object)
    {
        transition_active = false;
        zoom_timed_active = false;
		
		position_transition_active = false;
		position_transition_paused = false;

		position_transition_velocity_x = 0;
		position_transition_velocity_y = 0;

		position_transition_replanned = false;
		position_transition_spline_active = false;


		zoom_transition_active = false;
		zoom_transition_paused = false;

		zoom_transition_velocity = 0;


		transition_compat_active = false;

        follow_active = false;
        follow_target = noone;

        follow_velocity_x = 0;
        follow_velocity_y = 0;

        _zoom_scale = max(_zoom_scale, 0.01);


        // ====================================================
        // CUT SIZE
        // ====================================================

        var _width = zoom_base_width * _zoom_scale;

        var _height = zoom_base_height * _zoom_scale;


        if (bounds_mode == CameraBoundsMode.ROOM)
        {
            _width = min(_width, room_width);

            _height = min(_height, room_height);
        }

        else if (bounds_mode == CameraBoundsMode.CUSTOM)
        {
            _width = min(_width, bounds_right - bounds_left);

            _height = min(_height, bounds_bottom - bounds_top);
        }


        zoom_target_width = _width;

        zoom_target_height = _height;


        // ====================================================
        // CUT CENTER
        // ====================================================

        var _half_width = _width / 2;

        var _half_height = _height / 2;

        var _center_x = _x;

        var _center_y = _y;


        if (bounds_mode == CameraBoundsMode.ROOM)
        {
            _center_x = clamp(_center_x, _half_width, room_width - _half_width);

            _center_y = clamp(_center_y, _half_height, room_height - _half_height);
        }

        else if (bounds_mode == CameraBoundsMode.CUSTOM)
        {
            _center_x = clamp(_center_x, bounds_left + _half_width, bounds_right - _half_width);

            _center_y = clamp(_center_y, bounds_top + _half_height, bounds_bottom - _half_height);
        }


        // ====================================================
        // APPLY CUT
        // ====================================================

        camera_set_view_size(camera_id, _width, _height);

        camera_set_view_pos(camera_id, _center_x - _half_width + shake_offset_x, _center_y - _half_height + shake_offset_y);

        camera_set_view_target(camera_id, noone);
    }
}

#endregion

#region CAMERA SHAKE

/// @function camera_shake_axes(_shake_x, _shake_y)
/// @description Enables or disables camera shake on each axis.
function camera_shake_axes(_shake_x, _shake_y)
{
    with (camera_object)
    {
        shake_x_active = _shake_x;
        shake_y_active = _shake_y;

        if (!shake_x_active)
            shake_offset_x = 0;

        if (!shake_y_active)
            shake_offset_y = 0;
    }
}

/// @function camera_shake_frequency(_frequency)
/// @description Sets how many times per second a new shake offset is chosen.
function camera_shake_frequency(_frequency)
{
    with (camera_object)
    {
        shake_frequency = max(_frequency, 0.001);

        shake_frequency_time = 0;
    }
}

/// @function camera_shake_direction(_direction)
/// @description Enables directional shake along an angle.
function camera_shake_direction(_direction)
{
    with (camera_object)
    {
        shake_direction = _direction;
        shake_directional = true;
    }
}

/// @function camera_shake_direction_stop()
/// @description Returns shake to normal random X/Y movement.
function camera_shake_direction_stop()
{
    with (camera_object)
    {
        shake_directional = false;
    }
}

/// @function camera_shake_ease(_ease)
/// @description Sets the shake falloff easing.
function camera_shake_ease(_ease)
{
    with (camera_object)
    {
        shake_ease = _ease;
    }
}

/// @function camera_shake_continuous(_strength)
/// @description Starts continuous camera shake.
function camera_shake_continuous(_strength)
{
    with (camera_object)
    {
        shake_trauma_active = false;
        shake_trauma = 0;

        shake_strength = max(_strength, 0);

        shake_time = 0;
        shake_frequency_time = 0;

        shake_continuous = true;

        shake_active = (shake_strength > 0);
    }
}

/// @function camera_shake_stop()
/// @description Immediately stops any active camera shake.
function camera_shake_stop()
{
    with (camera_object)
    {
        shake_active = false;
        shake_continuous = false;
        shake_trauma_active = false;

        shake_trauma = 0;

        shake_time = 0;
        shake_frequency_time = 0;

        shake_offset_x = 0;
        shake_offset_y = 0;
    }
}

/// @function camera_shake_trauma(_strength, _trauma, _decay)
/// @description Starts trauma-style camera shake.
function camera_shake_trauma(_strength, _trauma = 1, _decay = 1)
{
    with (camera_object)
    {
        shake_strength = max(_strength, 0);

        shake_trauma = clamp(_trauma, 0, 1);

        shake_trauma_decay = max(_decay, 0);

        shake_time = 0;
        shake_frequency_time = 0;

        shake_continuous = false;

        shake_trauma_active = (shake_strength > 0 && shake_trauma > 0);

        shake_active = shake_trauma_active;
    }
}

/// @function camera_shake(_strength, _seconds)
/// @description Starts a normal timed camera shake.
function camera_shake(_strength, _seconds)
{
    with (camera_object)
    {
        shake_continuous = false;

        shake_trauma_active = false;
        shake_trauma = 0;

        shake_strength = max(_strength, 0);

        shake_duration = max(_seconds, 0);

        shake_time = 0;
        shake_frequency_time = 0;

        shake_active = (shake_strength > 0 && shake_duration > 0);
    }
}

#endregion

#region CAMERA STATE FUNCTIONS

function camera_copy_state()
{
    var _state = new CameraState();

    // CAMERA
    _state.target = follow_target;

    _state.x = camera_get_view_x(camera_id);
    _state.y = camera_get_view_y(camera_id);

    _state.width = camera_get_view_width(camera_id);
    _state.height = camera_get_view_height(camera_id);


    // ZOOM
    _state.zoom_target_width = zoom_target_width;
    _state.zoom_target_height = zoom_target_height;

    _state.zoom_anchor_x = zoom_anchor_x;
    _state.zoom_anchor_y = zoom_anchor_y;


    // FOLLOW
    _state.follow_active = follow_active;

    _state.follow_x_active = follow_x_active;
    _state.follow_y_active = follow_y_active;

    _state.follow_strength = follow_strength;
    _state.follow_damping = follow_damping;

    _state.follow_max_speed = follow_max_speed;
    _state.follow_allow_overshoot = follow_allow_overshoot;

    _state.follow_offset_x = follow_offset_x;
    _state.follow_offset_y = follow_offset_y;

    _state.follow_offset_target_x = follow_offset_target_x;
    _state.follow_offset_target_y = follow_offset_target_y;


    // FIT
    _state.fit_active = fit_active;


    // LETTERBOX
    _state.letterbox_ratio = letterbox_ratio;
    _state.letterbox_current_amount = letterbox_current_amount;

    _state.letterbox_timed_active = letterbox_timed_active;
    _state.letterbox_start_amount = letterbox_start_amount;
    _state.letterbox_target_amount = letterbox_target_amount;
    _state.letterbox_timed_progress = letterbox_timed_progress;
    _state.letterbox_timed_duration = letterbox_timed_duration;
    _state.letterbox_timed_ease = letterbox_timed_ease;

    return _state;
}

function camera_apply_state(_state)
{
    if (is_undefined(_state))
        return;

    // CAMERA
    follow_target = _state.target;

    camera_set_view_pos(camera_id, _state.x, _state.y);
    camera_set_view_size(camera_id, _state.width, _state.height);


    // ZOOM
    zoom_target_width = _state.zoom_target_width;
    zoom_target_height = _state.zoom_target_height;

    zoom_anchor_x = _state.zoom_anchor_x;
    zoom_anchor_y = _state.zoom_anchor_y;


    // FOLLOW
    follow_active = _state.follow_active;

    follow_x_active = _state.follow_x_active;
    follow_y_active = _state.follow_y_active;

    follow_strength = _state.follow_strength;
    follow_damping = _state.follow_damping;

    follow_max_speed = _state.follow_max_speed;
    follow_allow_overshoot = _state.follow_allow_overshoot;

    follow_offset_x = _state.follow_offset_x;
    follow_offset_y = _state.follow_offset_y;

    follow_offset_target_x = _state.follow_offset_target_x;
    follow_offset_target_y = _state.follow_offset_target_y;


    // FIT
    fit_active = _state.fit_active;


    // LETTERBOX
    letterbox_ratio = _state.letterbox_ratio;
    letterbox_current_amount = _state.letterbox_current_amount;

    letterbox_timed_active = _state.letterbox_timed_active;
    letterbox_start_amount = _state.letterbox_start_amount;
    letterbox_target_amount = _state.letterbox_target_amount;
    letterbox_timed_progress = _state.letterbox_timed_progress;
    letterbox_timed_duration = _state.letterbox_timed_duration;
    letterbox_timed_ease = _state.letterbox_timed_ease;
}

function camera_apply_state_transition(_state, _duration = 1, _ease = CameraEase.SMOOTH)
{
    if (is_undefined(_state))
        return;

    with (camera_object)
    {
		
		position_transition_active = false;
		position_transition_paused = false;

		position_transition_velocity_x = 0;
		position_transition_velocity_y = 0;

		position_transition_replanned = false;
		position_transition_spline_active = false;


		zoom_transition_active = false;
		zoom_transition_paused = false;

		zoom_transition_velocity = 0;


		transition_compat_active = false;

		zoom_timed_active = false;

        // ====================================================
        // TRANSITION START
        // ====================================================

        transition_start_x = camera_get_view_x(camera_id);
        transition_start_y = camera_get_view_y(camera_id);

        transition_start_width = camera_get_view_width(camera_id);
        transition_start_height = camera_get_view_height(camera_id);

        transition_start_center_x = transition_start_x + transition_start_width / 2;
        transition_start_center_y = transition_start_y + transition_start_height / 2;


        // ====================================================
        // TRANSITION TARGET STATE
        // ====================================================

        transition_target_state = _state;

        transition_target = noone;

        transition_target_x = _state.x;
        transition_target_y = _state.y;

        transition_target_width = _state.width;
        transition_target_height = _state.height;

        transition_target_center_x = _state.x + _state.width / 2;
        transition_target_center_y = _state.y + _state.height / 2;


        // ====================================================
        // PREVIOUS TRANSITION STATE
        // ====================================================

        transition_previous_target = camera_get_view_target(camera_id);

        transition_previous_zoom_width = zoom_target_width;
        transition_previous_zoom_height = zoom_target_height;


        // ====================================================
        // LETTERBOX TRANSITION
        // ====================================================

        letterbox_ratio = _state.letterbox_ratio;

        letterbox_start_amount = letterbox_current_amount;
        letterbox_target_amount = _state.letterbox_current_amount;

        letterbox_timed_progress = 0;
        letterbox_timed_duration = max(_duration, 0.001);
        letterbox_timed_ease = _ease;
        letterbox_timed_active = true;


        // ====================================================
        // TRANSITION SETTINGS
        // ====================================================

        transition_progress = 0;
        transition_duration = max(_duration, 0.001);

        transition_ease = _ease;

        transition_keep_end = false;
        transition_paused = false;

        transition_active = true;
    }
}

#endregion
