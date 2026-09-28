// ============================================================
// CAMERA SHAKE
// ============================================================

// Remove last frame's shake first.
var _base_x = camera_get_view_x(camera_id) - shake_offset_x;
var _base_y = camera_get_view_y(camera_id) - shake_offset_y;


if (shake_active)
{
    var _dt = delta_time / 1000000;

    shake_time += _dt;
    shake_frequency_time += _dt;


    // ========================================================
    // SHAKE STRENGTH
    // ========================================================

    var _progress = 0;
    var _strength = shake_strength;


    // ========================================================
    // TRAUMA SHAKE
    // ========================================================

    if (shake_trauma_active)
    {
        shake_trauma = max(
            shake_trauma - shake_trauma_decay * _dt,
            0
        );

        // Squaring trauma makes low trauma subtle
        // while high trauma becomes much stronger.
        _strength =
            shake_strength * sqr(shake_trauma);

        if (shake_trauma <= 0)
        {
            shake_trauma = 0;
            shake_trauma_active = false;
            shake_active = false;

            shake_offset_x = 0;
            shake_offset_y = 0;
        }
    }


    // ========================================================
    // NORMAL TIMED SHAKE
    // ========================================================

    else if (!shake_continuous)
    {
        _progress = clamp(
            shake_time / shake_duration,
            0,
            1
        );


        // ====================================================
        // SHAKE FALLOFF
        // ====================================================

        var _falloff_progress = _progress;

        switch (shake_ease)
        {
            case CameraEase.SMOOTH:
                _falloff_progress =
                    ease_smooth(_progress);
            break;

            case CameraEase.IN:
                _falloff_progress =
                    ease_in(_progress);
            break;

            case CameraEase.OUT:
                _falloff_progress =
                    ease_out(_progress);
            break;

            case CameraEase.IN_OUT:
                _falloff_progress =
                    ease_in_out(_progress);
            break;

            case CameraEase.LINEAR:
                _falloff_progress =
                    _progress;
            break;
        }


        _strength =
            shake_strength
            * (1 - _falloff_progress);
    }


    // ========================================================
    // SHAKE FREQUENCY
    // ========================================================

    var _frequency_interval =
        1 / max(shake_frequency, 0.001);

    if (shake_frequency_time >= _frequency_interval)
    {
        shake_frequency_time = 0;


        // ====================================================
        // DIRECTIONAL SHAKE
        // ====================================================

        if (shake_directional)
        {
            var _shake_distance =
                random_range(-_strength, _strength);

            if (shake_x_active)
            {
                shake_offset_x = round(
                    lengthdir_x(
                        _shake_distance,
                        shake_direction
                    )
                );
            }
            else
            {
                shake_offset_x = 0;
            }

            if (shake_y_active)
            {
                shake_offset_y = round(
                    lengthdir_y(
                        _shake_distance,
                        shake_direction
                    )
                );
            }
            else
            {
                shake_offset_y = 0;
            }
        }


        // ====================================================
        // RANDOM SHAKE
        // ====================================================

        else
        {
            if (shake_x_active)
            {
                shake_offset_x = round(
                    random_range(
                        -_strength,
                        _strength
                    )
                );
            }
            else
            {
                shake_offset_x = 0;
            }

            if (shake_y_active)
            {
                shake_offset_y = round(
                    random_range(
                        -_strength,
                        _strength
                    )
                );
            }
            else
            {
                shake_offset_y = 0;
            }
        }
    }


    // ========================================================
    // TIMED SHAKE FINISHED
    // ========================================================

    if (!shake_continuous
        && !shake_trauma_active
        && _progress >= 1)
    {
        shake_active = false;

        shake_offset_x = 0;
        shake_offset_y = 0;
    }
}

else
{
    shake_offset_x = 0;
    shake_offset_y = 0;
}


// ============================================================
// APPLY SHAKE
// ============================================================

camera_set_view_pos(
    camera_id,
    _base_x + shake_offset_x,
    _base_y + shake_offset_y
);