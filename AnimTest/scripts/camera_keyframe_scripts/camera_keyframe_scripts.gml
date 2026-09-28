function camera_keyframe_group(_group_name)
{
    // Find the persistent camera setup object.
    var _setup = instance_find(camera_setup_object, 0);

    if (_setup == noone)
    {
        return [];
    }

    // Search the stored keyframe groups.
    for (var i = 0; i < array_length(_setup.keyframe_groups); i++)
    {
        if (_setup.keyframe_groups[i][0] == _group_name)
        {
            return _setup.keyframe_groups[i][1];
        }
    }

    // Group was not found.
    return [];
}

function camera_keyframe_start(_group_name, _transition_time = 0)
{
    var _keyframes = camera_keyframe_group(_group_name);

    if (array_length(_keyframes) == 0)
        return false;

    var _camera = instance_find(camera_object, 0);

    if (_camera == noone)
        return false;

    _camera.keyframe_active = true;
    _camera.keyframe_group = _keyframes;
    _camera.keyframe_index = 0;

    _camera.keyframe_entry_time = max(0, _transition_time);

    _camera.keyframe_waiting_for_transition = false;
    _camera.keyframe_wait_elapsed = 0;

    _camera.keyframe_segment_active = false;
    _camera.keyframe_segment_elapsed = 0;

    _camera.keyframe_position_target_index = -1;
    _camera.keyframe_zoom_target_index = -1;

    var _keyframe = _keyframes[0];

    if (_keyframe.use_position)
    {
        if (_camera.keyframe_entry_time <= 0)
        {
            camera_cut_to_point(_keyframe.x, _keyframe.y);
        }
        else
        {
            _camera.keyframe_waiting_for_transition = true;

            camera_transition_to_point(_keyframe.x, _keyframe.y, 1, _camera.keyframe_entry_time, true);
        }
    }

    // If there is no entry transition, the first keyframe has
    // effectively already been reached, so fire its actions now.
    if (!_camera.keyframe_waiting_for_transition)
    {
        camera_keyframe_apply_actions(_keyframe);
    }

    return true;
}
/// @function camera_keyframe_next_position(_group, _from_index)
function camera_keyframe_next_position(_group, _from_index)
{
    var _count = array_length(_group);

    for (var _i = _from_index + 1; _i < _count; _i++)
    {
        if (_group[_i].use_position)
            return _i;
    }

    return -1;
}

/// @function camera_keyframe_next_zoom(_group, _from_index)
function camera_keyframe_next_zoom(_group, _from_index)
{
    var _count = array_length(_group);

    for (var _i = _from_index + 1; _i < _count; _i++)
    {
        if (_group[_i].use_zoom)
            return _i;
    }

    return -1;
}

/// @function camera_keyframe_duration_to(_group, _from_index, _to_index)
function camera_keyframe_duration_to(_group, _from_index, _to_index)
{
    if (_to_index <= _from_index)
        return 0.001;

    var _duration = 0;

    for (var _i = _from_index; _i < _to_index; _i++)
    {
        _duration += max(_group[_i].keyframe_time, 0);

        var _arrive_index = _i + 1;

        // Include waits at intermediate markers, but not the
        // destination keyframe's wait.
        if (_arrive_index < _to_index)
            _duration += max(_group[_arrive_index].wait, 0);
    }

    return max(_duration, 0.001);
}

function camera_keyframe_apply_actions(_keyframe)
{
    if (!instance_exists(_keyframe))
        return;

    if (_keyframe.use_shake)
    {
        camera_shake(_keyframe.shake_strength, _keyframe.shake_duration);
    }

    if (_keyframe.use_letterbox)
    {
        if (_keyframe.letterbox_ratio <= 0)
        {
            if (_keyframe.letterbox_duration <= 0)
                camera_letterbox_clear();
            else
                camera_letterbox_clear_timed(_keyframe.letterbox_duration, CameraEase.SMOOTH);
        }
        else
        {
            if (_keyframe.letterbox_duration <= 0)
                camera_letterbox(_keyframe.letterbox_ratio);
            else
                camera_letterbox_timed(_keyframe.letterbox_ratio, _keyframe.letterbox_duration, CameraEase.SMOOTH);
        }
    }

    if (_keyframe.use_follow && instance_exists(_keyframe.follow_target))
    {
        with (camera_object)
        {
            keyframe_active = false;
            keyframe_waiting_for_transition = false;

            keyframe_segment_active = false;
            keyframe_segment_elapsed = 0;
            keyframe_wait_elapsed = 0;

            keyframe_position_target_index = -1;
            keyframe_zoom_target_index = -1;

            position_transition_active = false;
            position_transition_paused = false;
            position_transition_spline_active = false;

            zoom_transition_active = false;
            zoom_transition_paused = false;
            zoom_timed_active = false;
        }

        camera_follow(_keyframe.follow_target, _keyframe.follow_strength, _keyframe.follow_damping, _keyframe.follow_lookahead_x, _keyframe.follow_lookahead_y);
    }
}