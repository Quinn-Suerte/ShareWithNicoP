function camera_zone_at_point(_x, _y)
{
    var _count = instance_number(camera_zone_object);

    for (var _i = 0; _i < _count; _i++)
    {
        var _zone = instance_find(camera_zone_object, _i);

        if (!_zone.active)
            continue;

        if (point_in_rectangle(
            _x,
            _y,
            _zone.zone_left,
            _zone.zone_top,
            _zone.zone_right,
            _zone.zone_bottom
        ))
        {
            return _zone;
        }
    }

    return noone;
}

// camera_zone_update(_target) — Determines the currently relevant zone from a target; needs a zone target and current-zone reference.
function camera_zone_update(_target)
{
    var _camera =
        instance_find(camera_object, 0);

    if (!instance_exists(_camera))
        return;


    if (!instance_exists(_target))
    {
        _camera.current_camera_zone =
            noone;

        return;
    }


    _camera.current_camera_zone =
        camera_zone_at_point(
            _target.x,
            _target.y
        );
}

// camera_zone_apply_bounds(_x, _y, _width, _height) — Constrains a desired camera position using the current zone's enabled edges.
function camera_zone_apply_bounds(_x, _y, _width, _height)
{
    var _camera =
        instance_find(camera_object, 0);

    if (!instance_exists(_camera))
    {
        return
        {
            x : _x,
            y : _y
        };
    }


    var _zone =
        _camera.current_camera_zone;

    if (!instance_exists(_zone))
    {
        return
        {
            x : _x,
            y : _y
        };
    }


    var _zone_width =
        _zone.zone_right - _zone.zone_left;

    var _zone_height =
        _zone.zone_bottom - _zone.zone_top;


    // ============================================================
    // HORIZONTAL CLAMPS
    // ============================================================

    if (_zone.clamp_left && _zone.clamp_right)
    {
        if (_width > _zone_width)
        {
            _x =
                (_zone.zone_left
                + _zone.zone_right
                - _width) / 2;
        }
        else
        {
            _x = clamp(
                _x,
                _zone.zone_left,
                _zone.zone_right - _width
            );
        }
    }

    else if (_zone.clamp_left)
    {
        _x =
            max(
                _x,
                _zone.zone_left
            );
    }

    else if (_zone.clamp_right)
    {
        _x =
            min(
                _x,
                _zone.zone_right - _width
            );
    }


    // ============================================================
    // VERTICAL CLAMPS
    // ============================================================

    if (_zone.clamp_top && _zone.clamp_bottom)
    {
        if (_height > _zone_height)
        {
            _y =
                (_zone.zone_top
                + _zone.zone_bottom
                - _height) / 2;
        }
        else
        {
            _y = clamp(
                _y,
                _zone.zone_top,
                _zone.zone_bottom - _height
            );
        }
    }

    else if (_zone.clamp_top)
    {
        _y =
            max(
                _y,
                _zone.zone_top
            );
    }

    else if (_zone.clamp_bottom)
    {
        _y =
            min(
                _y,
                _zone.zone_bottom - _height
            );
    }


    return
    {
        x : _x,
        y : _y
    };
}
