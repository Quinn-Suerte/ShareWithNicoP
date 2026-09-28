keyframe_groups = [];

// ============================================================
// COLLECT KEYFRAMES
// ============================================================

var _keyframe_count = instance_number(camera_keyframe_object);

for (var i = 0; i < _keyframe_count; i++)
{
    var _keyframe = instance_find(camera_keyframe_object, i);
    var _group_name = _keyframe.keyframe_group_name;

    var _group_index = -1;

    // Find an existing group with this name.
    for (var g = 0; g < array_length(keyframe_groups); g++)
    {
        if (keyframe_groups[g][0] == _group_name)
        {
            _group_index = g;
            break;
        }
    }

    // If the group doesn't exist yet, create it.
    if (_group_index == -1)
    {
        _group_index = array_length(keyframe_groups);
        keyframe_groups[_group_index] = [_group_name, []];
    }

    // Add this keyframe to its group.
    array_push(keyframe_groups[_group_index][1], _keyframe);
}


// ============================================================
// SORT KEYFRAMES
// ============================================================

for (var g = 0; g < array_length(keyframe_groups); g++)
{
    array_sort(keyframe_groups[g][1], function(_a, _b)
    {
        return _a.keyframe_sequence_number - _b.keyframe_sequence_number;
    });
}

// ============================================================
// NORMALIZE KEYFRAME SEQUENCES
// ============================================================

for (var g = 0; g < array_length(keyframe_groups); g++)
{
    var _keys = keyframe_groups[g][1];

    for (var i = 0; i < array_length(_keys); i++)
    {
        _keys[i].keyframe_sequence_number = i + 1;
    }
}

// ============================================================
// CREATE CAMERA
// ============================================================

if (!instance_exists(camera_object))
{
    instance_create_layer(0, 0, layer, camera_object);
	
}