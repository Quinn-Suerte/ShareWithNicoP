#region CAMERA DEBUG

function camera_debug_draw()
{
    if (!debug)
        return;
        
    var _old_font = draw_get_font();
    

    // ========================================================
    // DEBUG COLORS
    // ========================================================

    var _color_room = c_white;
    var _color_bounds = c_gray;

    var _color_zone = c_green;
    var _color_zone_selected = c_lime;

    var _color_camera = c_fuchsia;
    var _color_zoom_target = c_yellow;
    var _color_transition = c_fuchsia;
    var _color_position_requested = c_aqua;
    var _color_position_effective = c_fuchsia;
    var _color_keyframe_active = c_white;

    var _color_target = c_aqua;
    var _color_fit_area = c_green;

    var _color_border = c_yellow;
    var _color_border_active = c_red;
    var _color_disabled = c_gray;

    var _color_follow_offset = c_silver;
    var _color_lookahead = c_blue;

    var _color_velocity = c_white;
    var _color_velocity_limited = c_red;

    var _color_anchor = _color_camera;
    var _color_shake = c_red;
    var _color_letterbox = c_silver;

    var _color_text = c_white;

    // ========================================================
    // DEBUG SETTINGS
    // ========================================================

    var _padding = 32;
    var _info_padding = 6;

    var _border_corner_size = 8;
    var _target_point_size = 2;
    var _anchor_size = 4;
    var _indicator_point_size = 2;

    var _velocity_draw_scale = 8;

    // ========================================================
    // SAVE DRAW STATE
    // ========================================================

    var _old_color = draw_get_color();
    var _old_alpha = draw_get_alpha();
    var _old_halign = draw_get_halign();
    var _old_valign = draw_get_valign();

    draw_set_alpha(1);

    // ========================================================
    // GUI / ROOM SCALE
    // ========================================================

    var _gui_width = display_get_gui_width();
    var _gui_height = display_get_gui_height();

    var _available_width = max(_gui_width - _padding * 2, 1);
    var _available_height = max(_gui_height - _padding * 2, 1);

    var _scale_x = _available_width / max(room_width, 1);
    var _scale_y = _available_height / max(room_height, 1);
    var _scale = min(_scale_x, _scale_y);

    var _room_draw_width = room_width * _scale;
    var _room_draw_height = room_height * _scale;

    var _origin_x = (_gui_width - _room_draw_width) / 2;
    var _origin_y = (_gui_height - _room_draw_height) / 2;

    // ========================================================
    // CAMERA INFORMATION
    // ========================================================

    var _view_x = camera_get_view_x(camera_id);
    var _view_y = camera_get_view_y(camera_id);
    var _view_width = camera_get_view_width(camera_id);
    var _view_height = camera_get_view_height(camera_id);

    var _view_right = _view_x + _view_width;
    var _view_bottom = _view_y + _view_height;

    var _view_center_x = _view_x + _view_width / 2;
    var _view_center_y = _view_y + _view_height / 2;

    var _camera_left = _origin_x + _view_x * _scale;
    var _camera_top = _origin_y + _view_y * _scale;
    var _camera_right = _origin_x + _view_right * _scale;
    var _camera_bottom = _origin_y + _view_bottom * _scale;

    var _camera_center_x = _origin_x + _view_center_x * _scale;
    var _camera_center_y = _origin_y + _view_center_y * _scale;

    // ========================================================
    // FOLLOW TARGET DUPLICATION
    // ========================================================

    var _follow_is_fit_target = false;

    if (instance_exists(follow_target))
    {
        for (var _i = 0; _i < array_length(fit_targets); _i++)
        {
            if (fit_targets[_i] == follow_target)
            {
                _follow_is_fit_target = true;
                break;
            }
        }
    }

    // ========================================================
    // TARGETS
    // Lowest object layer
    // ========================================================

    draw_set_color(_color_target);

    for (var _i = 0; _i < array_length(fit_targets); _i++)
    {
        var _target = fit_targets[_i];

        if (!instance_exists(_target))
            continue;

        var _target_left = _origin_x + _target.bbox_left * _scale;
        var _target_top = _origin_y + _target.bbox_top * _scale;
        var _target_right = _origin_x + _target.bbox_right * _scale;
        var _target_bottom = _origin_y + _target.bbox_bottom * _scale;

        var _target_x = _origin_x + _target.x * _scale;
        var _target_y = _origin_y + _target.y * _scale;

        draw_rectangle(_target_left, _target_top, _target_right, _target_bottom, true);
        draw_circle(_target_x, _target_y, _target_point_size, false);
    }

    if (instance_exists(follow_target) && !_follow_is_fit_target)
    {
        var _target_left = _origin_x + follow_target.bbox_left * _scale;
        var _target_top = _origin_y + follow_target.bbox_top * _scale;
        var _target_right = _origin_x + follow_target.bbox_right * _scale;
        var _target_bottom = _origin_y + follow_target.bbox_bottom * _scale;

        var _target_x = _origin_x + follow_target.x * _scale;
        var _target_y = _origin_y + follow_target.y * _scale;

        draw_rectangle(_target_left, _target_top, _target_right, _target_bottom, true);
        draw_circle(_target_x, _target_y, _target_point_size, false);
    }

    // ========================================================
    // FIT AREA
    // Uses the same positional extents and border padding
    // used by the fit system.
    // ========================================================

    if (fit_active)
    {
        var _fit_found = false;
        var _fit_left = 0;
        var _fit_right = 0;
        var _fit_top = 0;
        var _fit_bottom = 0;

        for (var _i = 0; _i < array_length(fit_targets); _i++)
        {
            var _target = fit_targets[_i];

            if (!instance_exists(_target))
                continue;

            if (!_fit_found)
            {
                _fit_left = _target.x;
                _fit_right = _target.x;
                _fit_top = _target.y;
                _fit_bottom = _target.y;
                _fit_found = true;
            }
            else
            {
                _fit_left = min(_fit_left, _target.x);
                _fit_right = max(_fit_right, _target.x);
                _fit_top = min(_fit_top, _target.y);
                _fit_bottom = max(_fit_bottom, _target.y);
            }
        }

        if (_fit_found)
        {
            _fit_left -= border_x;
            _fit_right += border_x;
            _fit_top -= border_y;
            _fit_bottom += border_y;

            var _fit_draw_left = _origin_x + _fit_left * _scale;
            var _fit_draw_right = _origin_x + _fit_right * _scale;
            var _fit_draw_top = _origin_y + _fit_top * _scale;
            var _fit_draw_bottom = _origin_y + _fit_bottom * _scale;

            draw_set_color(_color_fit_area);
            draw_rectangle(_fit_draw_left, _fit_draw_top, _fit_draw_right, _fit_draw_bottom, true);
        }
    }

    // ========================================================
    // FOLLOW OFFSET + LOOKAHEAD
    // ========================================================

    if (follow_active && instance_exists(follow_target))
    {
        var _target_x = _origin_x + follow_target.x * _scale;
        var _target_y = _origin_y + follow_target.y * _scale;

        var _offset_world_x = follow_target.x + follow_offset_x;
        var _offset_world_y = follow_target.y + follow_offset_y;

        var _offset_x = _origin_x + _offset_world_x * _scale;
        var _offset_y = _origin_y + _offset_world_y * _scale;

        var _offset_target_world_x = follow_target.x + follow_offset_target_x;
        var _offset_target_world_y = follow_target.y + follow_offset_target_y;

        var _offset_target_x = _origin_x + _offset_target_world_x * _scale;
        var _offset_target_y = _origin_y + _offset_target_world_y * _scale;

        draw_set_color(_color_follow_offset);

        draw_line(_target_x, _target_y, _offset_x, _offset_y);
        draw_circle(_offset_x, _offset_y, _indicator_point_size, false);

        draw_line(_offset_target_x - 2, _offset_target_y, _offset_target_x + 2, _offset_target_y);
        draw_line(_offset_target_x, _offset_target_y - 2, _offset_target_x, _offset_target_y + 2);

        var _lookahead_world_x = _offset_world_x + lookahead_x;
        var _lookahead_world_y = _offset_world_y + lookahead_y;

        var _lookahead_draw_x = _origin_x + _lookahead_world_x * _scale;
        var _lookahead_draw_y = _origin_y + _lookahead_world_y * _scale;

        draw_set_color(_color_lookahead);

        draw_line(_offset_x, _offset_y, _lookahead_draw_x, _lookahead_draw_y);
        draw_circle(_lookahead_draw_x, _lookahead_draw_y, _indicator_point_size, false);

        var _debug_lookahead_target_x =
		    variable_instance_exists(id, "lookahead_target_x")
		    ? lookahead_target_x
		    : 0;

		var _debug_lookahead_target_y =
		    variable_instance_exists(id, "lookahead_target_y")
		    ? lookahead_target_y
		    : 0;

		var _lookahead_target_world_x =
		    _offset_world_x + _debug_lookahead_target_x;

		var _lookahead_target_world_y =
		    _offset_world_y + _debug_lookahead_target_y;

        var _lookahead_target_x = _origin_x + _lookahead_target_world_x * _scale;
        var _lookahead_target_y = _origin_y + _lookahead_target_world_y * _scale;

        draw_line(_lookahead_target_x - 2, _lookahead_target_y, _lookahead_target_x + 2, _lookahead_target_y);
        draw_line(_lookahead_target_x, _lookahead_target_y - 2, _lookahead_target_x, _lookahead_target_y + 2);
    }

    // ========================================================
    // ZOOM TARGET
    // Supports the new independent zoom track first, then the
    // legacy timed-zoom path as a fallback.
    // ========================================================

    var _zoom_debug_width = zoom_target_width;
    var _zoom_debug_height = zoom_target_height;

    if (zoom_transition_active)
    {
        _zoom_debug_width = zoom_base_width * zoom_transition_effective_scale;
        _zoom_debug_height = zoom_base_height * zoom_transition_effective_scale;
    }
    else if (zoom_timed_active)
    {
        _zoom_debug_width = zoom_base_width * zoom_timed_effective_target_scale;
        _zoom_debug_height = zoom_base_height * zoom_timed_effective_target_scale;
    }

    if (!transition_active && _zoom_debug_width > 0 && _zoom_debug_height > 0)
    {
        if (abs(_zoom_debug_width - _view_width) > 0.01 || abs(_zoom_debug_height - _view_height) > 0.01)
        {
            var _zoom_debug_x = _view_x;
            var _zoom_debug_y = _view_y;

            // Position owns center while both independent tracks run.
            if (position_transition_active)
            {
                _zoom_debug_x = position_transition_effective_center_x - _zoom_debug_width / 2;
                _zoom_debug_y = position_transition_effective_center_y - _zoom_debug_height / 2;
            }
            else
            {
                if (zoom_anchor_x == 0)
                    _zoom_debug_x = _view_center_x - _zoom_debug_width / 2;
                else if (zoom_anchor_x == 1)
                    _zoom_debug_x = _view_right - _zoom_debug_width;

                if (zoom_anchor_y == 0)
                    _zoom_debug_y = _view_center_y - _zoom_debug_height / 2;
                else if (zoom_anchor_y == 1)
                    _zoom_debug_y = _view_bottom - _zoom_debug_height;
            }

            var _zoom_left = _origin_x + _zoom_debug_x * _scale;
            var _zoom_top = _origin_y + _zoom_debug_y * _scale;
            var _zoom_right = _origin_x + (_zoom_debug_x + _zoom_debug_width) * _scale;
            var _zoom_bottom = _origin_y + (_zoom_debug_y + _zoom_debug_height) * _scale;

            draw_set_color(_color_zoom_target);
            draw_set_alpha(0.7);
            draw_rectangle(_zoom_left, _zoom_top, _zoom_right, _zoom_bottom, true);
            draw_set_alpha(1);
        }
    }

    // ========================================================
    // INDEPENDENT POSITION TARGET
    // Requested point = aqua cross.
    // Effective legal point = fuchsia circle.
    // ========================================================

    if (position_transition_active)
    {
        var _requested_x = _origin_x + position_transition_requested_center_x * _scale;
        var _requested_y = _origin_y + position_transition_requested_center_y * _scale;

        var _effective_x = _origin_x + position_transition_effective_center_x * _scale;
        var _effective_y = _origin_y + position_transition_effective_center_y * _scale;

        draw_set_color(_color_position_effective);
        draw_line(_camera_center_x, _camera_center_y, _effective_x, _effective_y);
        draw_circle(_effective_x, _effective_y, 4, true);

        draw_set_color(_color_position_requested);
        draw_line(_requested_x - 4, _requested_y, _requested_x + 4, _requested_y);
        draw_line(_requested_x, _requested_y - 4, _requested_x, _requested_y + 4);

        if (abs(position_transition_requested_center_x - position_transition_effective_center_x) > 0.001 ||
            abs(position_transition_requested_center_y - position_transition_effective_center_y) > 0.001)
        {
            draw_set_alpha(0.6);
            draw_line(_requested_x, _requested_y, _effective_x, _effective_y);
            draw_set_alpha(1);
        }
    }

    // ========================================================
    // LEGACY COMBINED TRANSITION TARGET
    // ========================================================

    if (transition_active)
    {
        var _transition_left_world = transition_target_center_x - transition_target_width / 2;
        var _transition_top_world = transition_target_center_y - transition_target_height / 2;

        var _transition_left = _origin_x + _transition_left_world * _scale;
        var _transition_top = _origin_y + _transition_top_world * _scale;
        var _transition_right = _origin_x + (_transition_left_world + transition_target_width) * _scale;
        var _transition_bottom = _origin_y + (_transition_top_world + transition_target_height) * _scale;

        draw_set_color(_color_transition);
        draw_rectangle(_transition_left, _transition_top, _transition_right, _transition_bottom, true);
    }

    // ========================================================
    // CAMERA
    // ========================================================

    draw_set_color(_color_camera);
    draw_rectangle(_camera_left, _camera_top, _camera_right, _camera_bottom, true);

    // ========================================================
    // FOLLOW BORDER
    // Disabled axes = gray
    // Enabled axes = yellow
    // Active pressure = red
    // ========================================================

    if (follow_active && instance_exists(follow_target))
    {
        var _border_left_world = _view_center_x - border_x;
        var _border_right_world = _view_center_x + border_x;
        var _border_top_world = _view_center_y - border_y;
        var _border_bottom_world = _view_center_y + border_y;

        var _border_left = _origin_x + _border_left_world * _scale;
        var _border_right = _origin_x + _border_right_world * _scale;
        var _border_top = _origin_y + _border_top_world * _scale;
        var _border_bottom = _origin_y + _border_bottom_world * _scale;

        var _follow_x = follow_target.x + follow_offset_x + lookahead_x;
        var _follow_y = follow_target.y + follow_offset_y + lookahead_y;

        var _pressure_left = follow_x_active && _follow_x < _border_left_world;
        var _pressure_right = follow_x_active && _follow_x > _border_right_world;
        var _pressure_top = follow_y_active && _follow_y < _border_top_world;
        var _pressure_bottom = follow_y_active && _follow_y > _border_bottom_world;

        // Top.

        if (!follow_y_active)
            draw_set_color(_color_disabled);
        else if (_pressure_top)
            draw_set_color(_color_border_active);
        else
            draw_set_color(_color_border);

        draw_line(_border_left, _border_top, _border_left + _border_corner_size, _border_top);
        draw_line(_border_right, _border_top, _border_right - _border_corner_size, _border_top);

        // Bottom.

        if (!follow_y_active)
            draw_set_color(_color_disabled);
        else if (_pressure_bottom)
            draw_set_color(_color_border_active);
        else
            draw_set_color(_color_border);

        draw_line(_border_left, _border_bottom, _border_left + _border_corner_size, _border_bottom);
        draw_line(_border_right, _border_bottom, _border_right - _border_corner_size, _border_bottom);

        // Left.

        if (!follow_x_active)
            draw_set_color(_color_disabled);
        else if (_pressure_left)
            draw_set_color(_color_border_active);
        else
            draw_set_color(_color_border);

        draw_line(_border_left, _border_top, _border_left, _border_top + _border_corner_size);
        draw_line(_border_left, _border_bottom, _border_left, _border_bottom - _border_corner_size);

        // Right.

        if (!follow_x_active)
            draw_set_color(_color_disabled);
        else if (_pressure_right)
            draw_set_color(_color_border_active);
        else
            draw_set_color(_color_border);

        draw_line(_border_right, _border_top, _border_right, _border_top + _border_corner_size);
        draw_line(_border_right, _border_bottom, _border_right, _border_bottom - _border_corner_size);
    }

    // ========================================================
    // CAMERA VELOCITY
    // ========================================================

    var _debug_velocity_x = 0;
    var _debug_velocity_y = 0;
    var _velocity_limit = 0;

    if (position_transition_active)
    {
        _debug_velocity_x = position_transition_velocity_x;
        _debug_velocity_y = position_transition_velocity_y;
    }
    else if (fit_active)
    {
        _debug_velocity_x = fit_velocity_x;
        _debug_velocity_y = fit_velocity_y;
        _velocity_limit = fit_max_speed;
    }
    else if (follow_active)
    {
        _debug_velocity_x = follow_velocity_x;
        _debug_velocity_y = follow_velocity_y;
        _velocity_limit = follow_max_speed;
    }

    var _debug_speed = point_distance(0, 0, _debug_velocity_x, _debug_velocity_y);

    if (_debug_speed > 0.001)
    {
        var _velocity_world_x = _view_center_x + _debug_velocity_x * _velocity_draw_scale;
        var _velocity_world_y = _view_center_y + _debug_velocity_y * _velocity_draw_scale;

        var _velocity_x = _origin_x + _velocity_world_x * _scale;
        var _velocity_y = _origin_y + _velocity_world_y * _scale;

        var _velocity_limited = _velocity_limit > 0 && _debug_speed >= _velocity_limit - 0.001;

        draw_set_color(_velocity_limited ? _color_velocity_limited : _color_velocity);
        draw_line(_camera_center_x, _camera_center_y, _velocity_x, _velocity_y);
        draw_circle(_velocity_x, _velocity_y, _indicator_point_size, false);
    }

    // ========================================================
    // ZOOM ANCHOR
    // ========================================================

    var _anchor_world_x = _view_center_x;
    var _anchor_world_y = _view_center_y;

    if (zoom_anchor_x < 0)
        _anchor_world_x = _view_x;
    else if (zoom_anchor_x > 0)
        _anchor_world_x = _view_right;

    if (zoom_anchor_y < 0)
        _anchor_world_y = _view_y;
    else if (zoom_anchor_y > 0)
        _anchor_world_y = _view_bottom;

    var _anchor_x = _origin_x + _anchor_world_x * _scale;
    var _anchor_y = _origin_y + _anchor_world_y * _scale;

    draw_set_color(_color_anchor);

    draw_circle(_anchor_x, _anchor_y, _anchor_size, true);
    draw_line(_anchor_x - _anchor_size, _anchor_y, _anchor_x + _anchor_size, _anchor_y);
    draw_line(_anchor_x, _anchor_y - _anchor_size, _anchor_x, _anchor_y + _anchor_size);

    // ========================================================
    // SHAKE OFFSET
    // ========================================================

    if (shake_active)
    {
        var _shake_base_world_x = _view_center_x - shake_offset_x;
        var _shake_base_world_y = _view_center_y - shake_offset_y;

        var _shake_base_x = _origin_x + _shake_base_world_x * _scale;
        var _shake_base_y = _origin_y + _shake_base_world_y * _scale;

        draw_set_color(_color_shake);
        draw_line(_shake_base_x, _shake_base_y, _camera_center_x, _camera_center_y);
        draw_circle(_shake_base_x, _shake_base_y, _indicator_point_size, true);
    }

    // ========================================================
    // LETTERBOX
    // ========================================================

    var _letterbox_amount = 0;

    if (variable_instance_exists(id, "letterbox_current_amount"))
    {
        _letterbox_amount = variable_instance_get(id, "letterbox_current_amount");
    }
    else if (letterbox_ratio > 0)
    {
        var _visible_height = _gui_width / letterbox_ratio;
        var _bar_height = max((_gui_height - _visible_height) / 2, 0);
        _letterbox_amount = _bar_height / max(_gui_height, 1);
    }

    if (_letterbox_amount > 0)
    {
        var _letterbox_world_height = _view_height * _letterbox_amount;

        var _letterbox_top_world = _view_y + _letterbox_world_height;
        var _letterbox_bottom_world = _view_bottom - _letterbox_world_height;

        var _letterbox_top = _origin_y + _letterbox_top_world * _scale;
        var _letterbox_bottom = _origin_y + _letterbox_bottom_world * _scale;

        draw_set_color(_color_letterbox);

        draw_line(_camera_left, _letterbox_top, _camera_right, _letterbox_top);
        draw_line(_camera_left, _letterbox_bottom, _camera_right, _letterbox_bottom);
    }

    // ========================================================
    // NONSELECTED CAMERA ZONES
    // Above camera
    // ========================================================

    var _zone_count = instance_number(camera_zone_object);

    draw_set_color(_color_zone);

    for (var _i = 0; _i < _zone_count; _i++)
    {
        var _zone = instance_find(camera_zone_object, _i);

        if (!instance_exists(_zone))
            continue;

        if (_zone == current_camera_zone)
            continue;

        var _zone_left = _origin_x + _zone.zone_left * _scale;
        var _zone_top = _origin_y + _zone.zone_top * _scale;
        var _zone_right = _origin_x + _zone.zone_right * _scale;
        var _zone_bottom = _origin_y + _zone.zone_bottom * _scale;

        draw_rectangle(_zone_left, _zone_top, _zone_right, _zone_bottom, true);
    }

    // ========================================================
    // SELECTED CAMERA ZONE
    // Draw after every nonselected zone
    // ========================================================

    if (instance_exists(current_camera_zone))
    {
        var _zone = current_camera_zone;

        var _zone_left = _origin_x + _zone.zone_left * _scale;
        var _zone_top = _origin_y + _zone.zone_top * _scale;
        var _zone_right = _origin_x + _zone.zone_right * _scale;
        var _zone_bottom = _origin_y + _zone.zone_bottom * _scale;

        draw_set_color(_color_zone_selected);
        draw_rectangle(_zone_left, _zone_top, _zone_right, _zone_bottom, true);
    }

    // ========================================================
    // CUSTOM GLOBAL BOUNDS
    // ========================================================

    if (bounds_mode == CameraBoundsMode.CUSTOM)
    {
        var _bounds_draw_left = _origin_x + bounds_left * _scale;
        var _bounds_draw_top = _origin_y + bounds_top * _scale;
        var _bounds_draw_right = _origin_x + bounds_right * _scale;
        var _bounds_draw_bottom = _origin_y + bounds_bottom * _scale;

        draw_set_color(_color_bounds);
        draw_rectangle(_bounds_draw_left, _bounds_draw_top, _bounds_draw_right, _bounds_draw_bottom, true);
    }

    // ========================================================
    // CAMERA KEYFRAMES
    // Position paths skip zoom-only markers and render authored
    // spline segments when the destination position key requests one.
    // ========================================================

    var _keyframe_setup = instance_find(camera_setup_object, 0);
    var _active_keyframe = noone;

    if (keyframe_active && keyframe_index >= 0 && keyframe_index < array_length(keyframe_group))
        _active_keyframe = keyframe_group[keyframe_index];

    if (_keyframe_setup != noone)
    {
        for (var _group_index = 0; _group_index < array_length(_keyframe_setup.keyframe_groups); _group_index++)
        {
            var _group_name = _keyframe_setup.keyframe_groups[_group_index][0];
            var _keyframes = _keyframe_setup.keyframe_groups[_group_index][1];

            var _group_hash = 17;

            for (var _char_index = 1; _char_index <= string_length(_group_name); _char_index++)
                _group_hash = (_group_hash * 31 + ord(string_char_at(_group_name, _char_index))) mod 2147483647;

            var _group_hue = abs(_group_hash) mod 256;
            var _group_color = make_color_hsv(_group_hue, 220, 255);

            draw_set_color(_group_color);
            draw_set_alpha(1);

            // ----------------------------------------------------
            // POSITION PATH
            // ----------------------------------------------------

            var _last_position_index = -1;

            for (var _key_index = 0; _key_index < array_length(_keyframes); _key_index++)
            {
                var _keyframe_b = _keyframes[_key_index];

                if (!instance_exists(_keyframe_b) || !_keyframe_b.use_position)
                    continue;

                if (_last_position_index >= 0)
                {
                    var _keyframe_a = _keyframes[_last_position_index];
                    var _use_spline = variable_instance_exists(_keyframe_b, "position_spline") && _keyframe_b.position_spline;

                    if (_use_spline)
                    {
                        var _p0 = _keyframe_a;
                        var _p3 = _keyframe_b;

                        for (var _search = _last_position_index - 1; _search >= 0; _search--)
                        {
                            if (_keyframes[_search].use_position)
                            {
                                _p0 = _keyframes[_search];
                                break;
                            }
                        }

                        for (var _search = _key_index + 1; _search < array_length(_keyframes); _search++)
                        {
                            if (_keyframes[_search].use_position)
                            {
                                _p3 = _keyframes[_search];
                                break;
                            }
                        }

                        var _previous_draw_x = _origin_x + _keyframe_a.x * _scale;
                        var _previous_draw_y = _origin_y + _keyframe_a.y * _scale;
                        var _spline_steps = 24;

                        for (var _step = 1; _step <= _spline_steps; _step++)
                        {
                            var _t = _step / _spline_steps;
                            var _world_x = camera_catmull_rom(_p0.x, _keyframe_a.x, _keyframe_b.x, _p3.x, _t);
                            var _world_y = camera_catmull_rom(_p0.y, _keyframe_a.y, _keyframe_b.y, _p3.y, _t);

                            var _draw_x = _origin_x + _world_x * _scale;
                            var _draw_y = _origin_y + _world_y * _scale;

                            draw_line_width(_previous_draw_x, _previous_draw_y, _draw_x, _draw_y, 2);

                            _previous_draw_x = _draw_x;
                            _previous_draw_y = _draw_y;
                        }
                    }
                    else
                    {
                        draw_line_width(_origin_x + _keyframe_a.x * _scale, _origin_y + _keyframe_a.y * _scale, _origin_x + _keyframe_b.x * _scale, _origin_y + _keyframe_b.y * _scale, 2);
                    }
                }

                _last_position_index = _key_index;
            }

            // ----------------------------------------------------
            // KEYFRAME MARKERS
            // ----------------------------------------------------

            for (var _key_index = 0; _key_index < array_length(_keyframes); _key_index++)
            {
                var _keyframe = _keyframes[_key_index];

                if (!instance_exists(_keyframe))
                    continue;

                var _keyframe_x = _origin_x + _keyframe.x * _scale;
                var _keyframe_y = _origin_y + _keyframe.y * _scale;
                var _diamond_size = _keyframe.use_position ? 6 : 4;

                draw_set_color(_group_color);
                draw_primitive_begin(pr_trianglefan);
                draw_vertex(_keyframe_x, _keyframe_y - _diamond_size);
                draw_vertex(_keyframe_x + _diamond_size, _keyframe_y);
                draw_vertex(_keyframe_x, _keyframe_y + _diamond_size);
                draw_vertex(_keyframe_x - _diamond_size, _keyframe_y);
                draw_primitive_end();

                if (_keyframe == _active_keyframe)
                {
                    var _active_size = _diamond_size + 3;

                    draw_set_color(_color_keyframe_active);
                    draw_line(_keyframe_x, _keyframe_y - _active_size, _keyframe_x + _active_size, _keyframe_y);
                    draw_line(_keyframe_x + _active_size, _keyframe_y, _keyframe_x, _keyframe_y + _active_size);
                    draw_line(_keyframe_x, _keyframe_y + _active_size, _keyframe_x - _active_size, _keyframe_y);
                    draw_line(_keyframe_x - _active_size, _keyframe_y, _keyframe_x, _keyframe_y - _active_size);
                }
            }
        }
    }

    // ========================================================
    // ROOM OUTLINE
    // Highest geometry layer
    // ========================================================

    draw_set_color(_color_room);
    draw_rectangle(_origin_x, _origin_y, _origin_x + _room_draw_width, _origin_y + _room_draw_height, true);

    // ========================================================
    // LABELS
    // Always drawn after geometry
    // ========================================================

    draw_set_font(-1);
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_bottom);

    // Fit targets.

    draw_set_color(_color_target);

    for (var _i = 0; _i < array_length(fit_targets); _i++)
    {
        var _target = fit_targets[_i];

        if (!instance_exists(_target))
            continue;

        var _target_left = _origin_x + _target.bbox_left * _scale;
        var _target_top = _origin_y + _target.bbox_top * _scale;

        var _target_name = object_get_name(_target.object_index);
        var _target_name_y = max(_target_top - 2, _origin_y + string_height(_target_name));

        draw_text(_target_left, _target_name_y, _target_name);
    }

    // Follow target.

    if (instance_exists(follow_target) && !_follow_is_fit_target)
    {
        var _target_left = _origin_x + follow_target.bbox_left * _scale;
        var _target_top = _origin_y + follow_target.bbox_top * _scale;

        var _target_name = object_get_name(follow_target.object_index);
        var _target_name_y = max(_target_top - 2, _origin_y + string_height(_target_name));

        draw_set_color(_color_target);
        draw_text(_target_left, _target_name_y, _target_name);
    }

    // Keyframes.

    if (_keyframe_setup != noone)
    {
        draw_set_halign(fa_left);
        draw_set_valign(fa_bottom);

        for (var _group_index = 0; _group_index < array_length(_keyframe_setup.keyframe_groups); _group_index++)
        {
            var _group_name = _keyframe_setup.keyframe_groups[_group_index][0];
            var _keyframes = _keyframe_setup.keyframe_groups[_group_index][1];

            var _group_hash = 17;

            for (var _char_index = 1; _char_index <= string_length(_group_name); _char_index++)
                _group_hash = (_group_hash * 31 + ord(string_char_at(_group_name, _char_index))) mod 2147483647;

            var _group_hue = abs(_group_hash) mod 256;
            var _group_color = make_color_hsv(_group_hue, 220, 255);

            for (var _key_index = 0; _key_index < array_length(_keyframes); _key_index++)
            {
                var _keyframe = _keyframes[_key_index];

                if (!instance_exists(_keyframe))
                    continue;

                var _keyframe_x = _origin_x + _keyframe.x * _scale;
                var _keyframe_y = _origin_y + _keyframe.y * _scale;
                var _flags = "";

                if (_keyframe.use_position)
                    _flags += "P";

                if (_keyframe.use_zoom)
                    _flags += "Z";

                if (variable_instance_exists(_keyframe, "position_spline") && _keyframe.position_spline)
                    _flags += "S";

                if (_flags == "")
                    _flags = "-";

                var _keyframe_label = _group_name + " " + string(_keyframe.keyframe_sequence_number) + " [" + _flags + "]";

                draw_set_color(_keyframe == _active_keyframe ? _color_keyframe_active : _group_color);
                draw_text(_keyframe_x + 9, _keyframe_y - 2, _keyframe_label);
            }
        }
    }

    // Camera.

    var _camera_name = object_get_name(object_index);
    var _camera_name_y = max(_camera_top - 2, _origin_y + string_height(_camera_name));

    draw_set_color(_color_camera);
    draw_text(_camera_left, _camera_name_y, _camera_name);

    // Nonselected zones.

    draw_set_color(_color_zone);

    for (var _i = 0; _i < _zone_count; _i++)
    {
        var _zone = instance_find(camera_zone_object, _i);

        if (!instance_exists(_zone))
            continue;

        if (_zone == current_camera_zone)
            continue;

        var _zone_left = _origin_x + _zone.zone_left * _scale;
        var _zone_top = _origin_y + _zone.zone_top * _scale;

        var _zone_name = _zone.name;
        var _zone_name_y = max(_zone_top - 2, _origin_y + string_height(_zone_name));

        draw_text(_zone_left, _zone_name_y, _zone_name);
    }

    // Selected zone.

    if (instance_exists(current_camera_zone))
    {
        var _zone = current_camera_zone;

        var _zone_left = _origin_x + _zone.zone_left * _scale;
        var _zone_top = _origin_y + _zone.zone_top * _scale;

        var _zone_name = _zone.name;
        var _zone_name_y = max(_zone_top - 2, _origin_y + string_height(_zone_name));

        draw_set_color(_color_zone_selected);
        draw_text(_zone_left, _zone_name_y, _zone_name);
    }

    // Custom bounds.

    if (bounds_mode == CameraBoundsMode.CUSTOM)
    {
        var _bounds_draw_left = _origin_x + bounds_left * _scale;
        var _bounds_draw_top = _origin_y + bounds_top * _scale;

        draw_set_color(_color_bounds);
        draw_text(_bounds_draw_left, max(_bounds_draw_top - 2, _origin_y + string_height("Custom Bounds")), "Custom Bounds");
    }

    // Transition target.

    if (transition_active)
    {
        var _transition_left_world = transition_target_center_x - transition_target_width / 2;
        var _transition_top_world = transition_target_center_y - transition_target_height / 2;

        var _transition_left = _origin_x + _transition_left_world * _scale;
        var _transition_top = _origin_y + _transition_top_world * _scale;

        draw_set_color(_color_transition);
        draw_text(_transition_left, max(_transition_top - 2, _origin_y + string_height("Transition Target")), "Transition Target");
    }

    // ========================================================
    // CAMERA ACTIVITY
    // ========================================================

    var _moving = false;
    var _zooming = false;

    if (position_transition_active && !position_transition_paused)
        _moving = true;

    if (follow_active && (abs(follow_velocity_x) > 0.001 || abs(follow_velocity_y) > 0.001))
        _moving = true;

    if (fit_active && (abs(fit_velocity_x) > 0.001 || abs(fit_velocity_y) > 0.001))
        _moving = true;

    if (transition_active && !transition_paused)
    {
        if (abs(_view_center_x - transition_target_center_x) > 0.01 || abs(_view_center_y - transition_target_center_y) > 0.01)
            _moving = true;

        if (abs(_view_width - transition_target_width) > 0.01 || abs(_view_height - transition_target_height) > 0.01)
            _zooming = true;
    }

    if (zoom_transition_active && !zoom_transition_paused)
        _zooming = true;

    if (zoom_timed_active)
        _zooming = true;

    if (!fit_active && !transition_active && !zoom_transition_active && !zoom_timed_active)
    {
        if (abs(_view_width - zoom_target_width) > 0.01 || abs(_view_height - zoom_target_height) > 0.01)
            _zooming = true;
    }

    // ========================================================
    // TOP RIGHT INFORMATION
    // ========================================================

    draw_set_color(_color_text);
    draw_set_halign(fa_right);
    draw_set_valign(fa_top);

    var _text_x = _origin_x + _room_draw_width - _info_padding;
    var _text_y = _origin_y + _info_padding;
    var _line_height = 16;

    draw_text(_text_x, _text_y, "X: " + string_format(_view_x, 1, 2));
    _text_y += _line_height;

    draw_text(_text_x, _text_y, "Y: " + string_format(_view_y, 1, 2));
    _text_y += _line_height;

    var _current_scale = _view_width / max(zoom_base_width, 1);
    draw_text(_text_x, _text_y, "SCALE: " + string_format(_current_scale, 1, 3));
    _text_y += _line_height * 2;

    var _has_activity = false;

    if (keyframe_active)
    {
        var _keyframe_count = array_length(keyframe_group);
        var _safe_keyframe_index = clamp(keyframe_index, 0, max(_keyframe_count - 1, 0));

        if (_keyframe_count > 0)
        {
            var _current_keyframe = keyframe_group[_safe_keyframe_index];
            var _debug_group_name = variable_instance_exists(_current_keyframe, "keyframe_group_name") ? _current_keyframe.keyframe_group_name : "keyframe";

            draw_set_color(_color_keyframe_active);
            draw_text(_text_x, _text_y, "KEYFRAME: " + _debug_group_name + " " + string(_safe_keyframe_index + 1) + "/" + string(_keyframe_count));
            _text_y += _line_height;

            if (keyframe_waiting_for_transition)
            {
                draw_text(_text_x, _text_y, "ENTRY TRANSITION");
                _text_y += _line_height;
            }
            else if (keyframe_segment_active)
            {
                var _segment_duration = max(_current_keyframe.keyframe_time, 0.001);
                draw_text(_text_x, _text_y, "SEGMENT: " + string_format(keyframe_segment_elapsed, 1, 2) + " / " + string_format(_segment_duration, 1, 2));
                _text_y += _line_height;
            }
            else
            {
                var _wait_duration = max(_current_keyframe.wait, 0);
                draw_text(_text_x, _text_y, "WAIT: " + string_format(keyframe_wait_elapsed, 1, 2) + " / " + string_format(_wait_duration, 1, 2));
                _text_y += _line_height;
            }

            if (keyframe_position_target_index >= 0)
            {
                draw_text(_text_x, _text_y, "POS KEY -> " + string(keyframe_position_target_index + 1));
                _text_y += _line_height;
            }

            if (keyframe_zoom_target_index >= 0)
            {
                draw_text(_text_x, _text_y, "ZOOM KEY -> " + string(keyframe_zoom_target_index + 1));
                _text_y += _line_height;
            }

            _has_activity = true;
            draw_set_color(_color_text);
        }
    }

    if (position_transition_active)
    {
        var _position_state = position_transition_paused ? "POSITION PAUSED" : "POSITION TRANSITION";
        draw_text(_text_x, _text_y, _position_state);
        _text_y += _line_height;

        draw_text(_text_x, _text_y, "POS TIME: " + string_format(position_transition_elapsed, 1, 2) + " / " + string_format(position_transition_duration, 1, 2));
        _text_y += _line_height;

        if (position_transition_spline_active)
        {
            draw_text(_text_x, _text_y, "SPLINE");
            _text_y += _line_height;
        }

        if (position_transition_replanned)
        {
            draw_text(_text_x, _text_y, "REPLANNED");
            _text_y += _line_height;
        }

        _has_activity = true;
    }

    if (zoom_transition_active)
    {
        var _zoom_state = zoom_transition_paused ? "ZOOM PAUSED" : "ZOOM TRANSITION";
        draw_text(_text_x, _text_y, _zoom_state);
        _text_y += _line_height;

        draw_text(_text_x, _text_y, "ZOOM TIME: " + string_format(zoom_transition_elapsed, 1, 2) + " / " + string_format(zoom_transition_duration, 1, 2));
        _text_y += _line_height;

        draw_text(_text_x, _text_y, "ZOOM REQ/EFF: " + string_format(zoom_transition_requested_scale, 1, 2) + " / " + string_format(zoom_transition_effective_scale, 1, 2));
        _text_y += _line_height;

        _has_activity = true;
    }

    if (transition_active)
    {
        draw_text(_text_x, _text_y, transition_paused ? "LEGACY TRANSITION PAUSED" : "LEGACY TRANSITION");
        _text_y += _line_height;
        _has_activity = true;
    }

    if (follow_active)
    {
        draw_text(_text_x, _text_y, "FOLLOWING");
        _text_y += _line_height;
        _has_activity = true;
    }

    if (fit_active)
    {
        draw_text(_text_x, _text_y, "FITTING");
        _text_y += _line_height;
        _has_activity = true;
    }

    if (_moving)
    {
        draw_text(_text_x, _text_y, "MOVING");
        _text_y += _line_height;
        _has_activity = true;
    }

    if (_zooming)
    {
        draw_text(_text_x, _text_y, "ZOOMING");
        _text_y += _line_height;
        _has_activity = true;
    }

    if (shake_active)
    {
        var _shake_text = "SHAKING";

        if (shake_x_active && shake_y_active)
            _shake_text = "SHAKING XY";
        else if (shake_x_active)
            _shake_text = "SHAKING X";
        else if (shake_y_active)
            _shake_text = "SHAKING Y";

        draw_text(_text_x, _text_y, _shake_text);
        _text_y += _line_height;
        _has_activity = true;
    }

    if (hold_active)
    {
        draw_text(_text_x, _text_y, "HOLDING: " + string_format(hold_elapsed, 1, 2) + " / " + string_format(hold_duration, 1, 2));
        _text_y += _line_height;
        _has_activity = true;
    }

    if (_letterbox_amount > 0)
    {
        draw_text(_text_x, _text_y, "LETTERBOX");
        _text_y += _line_height;
        _has_activity = true;
    }

    if (!_has_activity)
    {
        draw_text(_text_x, _text_y, "IDLE");
        _text_y += _line_height;
    }

    // ========================================================
    // FIT INFORMATION
    // ========================================================

    if (fit_active)
    {
        _text_y += _line_height;

        var _fit_current_scale = _view_width / max(fit_base_width, 1);

        draw_text(_text_x, _text_y, "FIT SCALE: " + string_format(_fit_current_scale, 1, 2));
        _text_y += _line_height;

        draw_text(_text_x, _text_y, "FIT RANGE: " + string_format(fit_min_scale, 1, 2) + " - " + string_format(fit_max_scale, 1, 2));
        _text_y += _line_height;

        var _fit_permissions = "";

        if (fit_allow_shrink)
            _fit_permissions += "SHRINK ";

        if (fit_allow_expand)
            _fit_permissions += "EXPAND";

        if (_fit_permissions == "")
            _fit_permissions = "LOCKED";

        draw_text(_text_x, _text_y, _fit_permissions);
    }

    // ========================================================
    // RESTORE DRAW STATE
    // ========================================================

    draw_set_color(_old_color);
    draw_set_alpha(_old_alpha);
    draw_set_halign(_old_halign);
    draw_set_valign(_old_valign);
    
    draw_set_font(_old_font);
}

#endregion

#region LETTERBOX

if (letterbox_timed_active)
{
    letterbox_timed_progress += (delta_time / 1000000) / letterbox_timed_duration;

    var _t = clamp(letterbox_timed_progress, 0, 1);
    var _ease = _t;

    switch (letterbox_timed_ease)
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

    letterbox_current_amount = lerp(letterbox_start_amount, letterbox_target_amount, _ease);

    if (_t >= 1)
    {
        letterbox_current_amount = letterbox_target_amount;
        letterbox_timed_progress = 0;
        letterbox_timed_active = false;
    }
}

if (letterbox_current_amount > 0)
{
    var _gui_width = display_get_gui_width();
    var _gui_height = display_get_gui_height();
    var _bar_height = _gui_height * letterbox_current_amount;

    var _old_color = draw_get_color();
    var _old_alpha = draw_get_alpha();

    draw_set_color(letterbox_color);
    draw_set_alpha(1);

    draw_rectangle(0, 0, _gui_width, _bar_height, false);
    draw_rectangle(0, _gui_height - _bar_height, _gui_width, _gui_height, false);

    draw_set_color(_old_color);
    draw_set_alpha(_old_alpha);
}

#endregion

if (debug){
    camera_debug_draw();
}
