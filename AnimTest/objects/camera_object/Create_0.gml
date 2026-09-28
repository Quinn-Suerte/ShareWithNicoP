// ============================================================
// CAMERA
// ============================================================

camera_id = view_camera[0];

target = noone;

saved_state = undefined;

zoom_base_width =
    camera_get_view_width(camera_id);

zoom_base_height =
    camera_get_view_height(camera_id);
	

keyframe_active = false;
keyframe_group = [];
keyframe_index = 0;

keyframe_entry_time = 0;
keyframe_wait_elapsed = 0;

keyframe_segment_active = false;
keyframe_segment_elapsed = 0;

keyframe_position_target_index = -1;
keyframe_zoom_target_index = -1;

function camera_keyframe_start(_group_name, _transition_time = 0)
{
    var _keyframes = camera_keyframe_group(_group_name);

    if (array_length(_keyframes) == 0)
    {
        return false;
    }

    var _camera = instance_find(camera_object, 0);

    if (_camera == noone)
    {
        return false;
    }

    // ============================================================
    // INITIALIZE KEYFRAME PLAYBACK
    // ============================================================

    _camera.keyframe_active = true;
    _camera.keyframe_group = _keyframes;
    _camera.keyframe_index = 0;
    _camera.keyframe_entry_time = max(0, _transition_time);
    _camera.keyframe_waiting_for_transition = false;

    var _keyframe = _keyframes[0];

    // ============================================================
    // APPLY ENTRY POSITION
    // ============================================================

    if (_keyframe.use_position)
    {
        if (_camera.keyframe_entry_time <= 0)
        {
            camera_cut_to_point(_keyframe.x, _keyframe.y);
        }
        else
        {
            camera_transition_to_point(_keyframe.x, _keyframe.y, 1, _camera.keyframe_entry_time, true);
            _camera.keyframe_waiting_for_transition = true;
        }
    }

    return true;
}

// ============================================================
// CAMERA BOUNDS
// ============================================================

// Variable Definitions:
// bounds_left = 0;
// bounds_top = 0;
// bounds_right = 0;
// bounds_bottom = 0;
// bounds_mode = "ROOM";


// 0 means use the full room edge.
if (bounds_right == 0)
{
    bounds_right = room_width;
}

if (bounds_bottom == 0)
{
    bounds_bottom = room_height;
}


// Convert Variable Definition list option to CameraBoundsMode enum.
switch (bounds_mode)
{
    case "NONE":
        bounds_mode = CameraBoundsMode.NONE;
    break;

    case "ROOM":
        bounds_mode = CameraBoundsMode.ROOM;
    break;

    case "CUSTOM":
        bounds_mode = CameraBoundsMode.CUSTOM;
    break;

    default:
        bounds_mode = CameraBoundsMode.ROOM;
    break;
}

// ============================================================
// CAMERA LETTERBOX
// ============================================================

//letterbox_ratio = 0;

letterbox_current_amount = 0;
letterbox_start_amount = 0;
letterbox_target_amount = 0;

letterbox_timed_active = false;
letterbox_timed_progress = 0;
letterbox_timed_duration = 0;
letterbox_timed_ease = CameraEase.SMOOTH;

// ============================================================
// CAMERA ZONE
// ============================================================

// Zone currently selected by the camera target.
current_camera_zone = noone;

// ============================================================
// CAMERA ZOOM
// ============================================================

zoom_target_width = camera_get_view_width(camera_id);

zoom_target_height = camera_get_view_height(camera_id);


// Variable Definition:
// zoom_speed = 0.02;

zoom_speed = clamp(zoom_speed, 0, 1);


// ============================================================
// TIMED CAMERA ZOOM
// ============================================================

zoom_timed_active = false;

zoom_timed_start_width = 0;
zoom_timed_start_height = 0;

zoom_timed_target_width = 0;
zoom_timed_target_height = 0;

zoom_timed_progress = 0;
zoom_timed_duration = 1;

zoom_timed_ease = CameraEase.SMOOTH;


// ============================================================
// CAMERA ZOOM ANCHOR
// ============================================================

// Variable Definitions:
//
// zoom_anchor_x = 0;
// -1 = left
//  0 = center
//  1 = right
//
// zoom_anchor_y = 0;
// -1 = top
//  0 = center
//  1 = bottom

zoom_anchor_x = clamp(zoom_anchor_x, -1, 1);
zoom_anchor_y = clamp(zoom_anchor_y, -1, 1);

// ============================================================
// POSITION TRANSITION
// ============================================================

position_transition_active = false;
position_transition_paused = false;

position_transition_start_center_x =
    camera_get_view_x(camera_id) + camera_get_view_width(camera_id) / 2;

position_transition_start_center_y =
    camera_get_view_y(camera_id) + camera_get_view_height(camera_id) / 2;

position_transition_requested_center_x = position_transition_start_center_x;
position_transition_requested_center_y = position_transition_start_center_y;

position_transition_effective_center_x = position_transition_start_center_x;
position_transition_effective_center_y = position_transition_start_center_y;

position_transition_elapsed = 0;
position_transition_duration = 1;

position_transition_ease = CameraEase.SMOOTH;

position_transition_velocity_x = 0;
position_transition_velocity_y = 0;

position_transition_last_center_x = position_transition_start_center_x;
position_transition_last_center_y = position_transition_start_center_y;

position_transition_replanned = false;

position_transition_start_velocity_x = 0;
position_transition_start_velocity_y = 0;

position_transition_end_velocity_x = 0;
position_transition_end_velocity_y = 0;

position_transition_spline_active = false;

position_transition_spline_p0_x = 0;
position_transition_spline_p0_y = 0;

position_transition_spline_p1_x = 0;
position_transition_spline_p1_y = 0;

position_transition_spline_p2_x = 0;
position_transition_spline_p2_y = 0;

position_transition_spline_p3_x = 0;
position_transition_spline_p3_y = 0;

// ============================================================
// ZOOM TRANSITION
// ============================================================

zoom_transition_active = false;
zoom_transition_paused = false;

zoom_transition_start_scale =
    camera_get_view_width(camera_id) / max(zoom_base_width, 1);

zoom_transition_requested_scale = zoom_transition_start_scale;
zoom_transition_effective_scale = zoom_transition_start_scale;

zoom_transition_elapsed = 0;
zoom_transition_duration = 1;

zoom_transition_ease = CameraEase.SMOOTH;

zoom_transition_velocity = 0;
zoom_transition_last_scale = zoom_transition_start_scale;

// ============================================================
// TRANSITION COMPATIBILITY
// ============================================================

transition_compat_active = false;

transition_compat_keep_end = false;

transition_compat_target = noone;

transition_compat_previous_target =
    camera_get_view_target(camera_id);

transition_compat_previous_zoom_width =
    zoom_target_width;

transition_compat_previous_zoom_height =
    zoom_target_height;

transition_compat_end_scale = 1;

// ============================================================
// CAMERA TRANSITION
// ============================================================

transition_active = false;
transition_paused = false;


// ============================================================
// TRANSITION START
// ============================================================

transition_start_x = 0;
transition_start_y = 0;

transition_start_width = camera_get_view_width(camera_id);

transition_start_height = camera_get_view_height(camera_id);

transition_start_center_x = camera_get_view_x(camera_id) + transition_start_width / 2;

transition_start_center_y = camera_get_view_y(camera_id) + transition_start_height / 2;


// ============================================================
// TRANSITION TARGET
// ============================================================

transition_target = noone;

transition_target_state = undefined;

transition_target_x = 0;
transition_target_y = 0;

transition_target_width = transition_start_width;

transition_target_height = transition_start_height;

transition_target_center_x = transition_start_center_x;

transition_target_center_y = transition_start_center_y;


// ============================================================
// TRANSITION PREVIOUS STATE
// ============================================================

transition_previous_target = camera_get_view_target(camera_id);


// ============================================================
// TRANSITION SETTINGS
// ============================================================

transition_progress = 0;
transition_duration = 1;

transition_keep_end = false;

transition_ease = CameraEase.SMOOTH;


// ============================================================
// CAMERA HOLD
// ============================================================

hold_active = false;

hold_duration = 0;
hold_elapsed = 0;


// ============================================================
// CAMERA FOLLOW
// ============================================================

follow_active = false;


// Variable Definitions:
// follow_max_speed = 0;
// follow_allow_overshoot = true;
// follow_x_active = true;
// follow_y_active = true;

follow_max_speed = max(follow_max_speed, 0);


follow_target = noone;


// ============================================================
// FOLLOW OFFSET
// ============================================================

follow_offset_x = 0;
follow_offset_y = 0;


// Variable Definitions:
// follow_offset_target_x = 0;
// follow_offset_target_y = 0;
// follow_offset_speed = 0.08;

follow_offset_speed = clamp(follow_offset_speed, 0, 1);


// ============================================================
// MULTI-TARGET FIT
// ============================================================

fit_active = false;

fit_targets = [];


// Variable Definitions:
// fit_allow_shrink = true;
// fit_allow_expand = true;
//
// fit_min_scale = 0.75;
// fit_max_scale = 2.00;

fit_min_scale = max(fit_min_scale, 0.01);

fit_max_scale = max(
    fit_max_scale,
    fit_min_scale
);


fit_base_width = camera_get_view_width(camera_id);

fit_base_height = camera_get_view_height(camera_id);

fit_previous_zoom_width = zoom_target_width;

fit_previous_zoom_height = zoom_target_height;


// Variable Definition:
// fit_zoom_speed = 0.08;

fit_zoom_speed = clamp(fit_zoom_speed, 0, 1);


fit_velocity_x = 0;
fit_velocity_y = 0;


// Variable Definitions:
// fit_strength = 0.08;
// fit_damping = 0.65;

fit_strength = clamp(fit_strength, 0, 1);
fit_damping = clamp(fit_damping, 0, 1);


// Variable Definition:
// fit_allow_overshoot = false;


// Variable Definition:
// fit_max_speed = 0;

fit_max_speed = max(fit_max_speed, 0);


// ============================================================
// LOOK AHEAD
// ============================================================

lookahead_active = false;

lookahead_x = 0;
lookahead_y = 0;

lookahead_target_x = 0;
lookahead_target_y = 0;

lookahead_previous_x = 0;
lookahead_previous_y = 0;

lookahead_initialized = false;


// Variable Definitions:
// lookahead_distance_x = 120;
// lookahead_distance_y = 60;

lookahead_distance_x = max(lookahead_distance_x, 0);
lookahead_distance_y = max(lookahead_distance_y, 0);


// Variable Definition:
// lookahead_speed = 0.08;

lookahead_speed = clamp(lookahead_speed, 0, 1);


// ============================================================
// FOLLOW VELOCITY
// ============================================================

follow_velocity_x = 0;
follow_velocity_y = 0;


// Variable Definitions:
// follow_strength = 0.12;
// follow_damping = 0.75;

follow_strength = clamp(follow_strength, 0, 1);
follow_damping = clamp(follow_damping, 0, 1);


// ============================================================
// FOLLOW BORDER
// ============================================================

// Variable Definitions:
// border_x
// border_y

border_x = max(border_x, 0);
border_y = max(border_y, 0);


// Native follow-speed configuration intentionally omitted.
// Custom camera follow controls movement itself.

camera_set_view_border(
    camera_id,
    border_x,
    border_y
);


// ============================================================
// CAMERA SHAKE
// ============================================================

shake_active = false;


// Variable Definitions:
// shake_x_active = true;
// shake_y_active = true;


shake_strength = 0;
shake_duration = 0;
shake_time = 0;


// ============================================================
// SHAKE FREQUENCY
// ============================================================

// Variable Definition:
// shake_frequency = 60;

shake_frequency = max(shake_frequency, 0.01);


shake_frequency_time = 0;


// ============================================================
// DIRECTIONAL SHAKE
// ============================================================

shake_directional = false;
shake_direction = 0;


// ============================================================
// SHAKE FALLOFF
// ============================================================

shake_ease = CameraEase.LINEAR;


// ============================================================
// CONTINUOUS SHAKE
// ============================================================

shake_continuous = false;


// ============================================================
// TRAUMA SHAKE
// ============================================================

shake_trauma_active = false;

shake_trauma = 0;


// Variable Definition:
// shake_trauma_decay = 1;

shake_trauma_decay = max(shake_trauma_decay, 0);


// ============================================================
// SHAKE OFFSET
// ============================================================

shake_offset_x = 0;
shake_offset_y = 0;