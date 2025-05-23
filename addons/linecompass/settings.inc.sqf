private _cat = format ["%1 - %2", localize "STR_dui_mod", localize "STR_dui_addon_linecompass"];

private _curCat = localize "STR_dui_cat_general";

[
    QGVAR(Enabled),
    "CHECKBOX",
    "STR_dui_linecompass_enabled",
    [_cat, _curCat],
    true,
    0,
    {
        params ["_value"];
        if (_value) then { call FUNC(showCompass); };
    }
] call CBA_fnc_addSetting;

[
    QGVAR(CompassAvailableShown),
    "CHECKBOX",
    "STR_dui_linecompass_compass_required",
    [_cat, _curCat],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(DrawBearing),
    "LIST",
    "STR_dui_linecompass_draw_directions",
    [_cat, _curCat],
    [[0, 1, 2], ["STR_dui_linecompass_draw_bearings_none", "STR_dui_linecompass_draw_bearings_bearings", "STR_dui_linecompass_draw_bearings_all"], 2],
    0,
    {
        params ["_value"];
        GVAR(ResolvedDrawBearing) = if (!isNil QGVAR(AllowNumericDrawBearing) && {!GVAR(AllowNumericDrawBearing)}) then {
            _value min 1
        } else {
            _value
        };
    }
] call CBA_fnc_addSetting;

[
    QGVAR(AllowNumericDrawBearing),
    "CHECKBOX",
    ["STR_dui_linecompass_allowed_draw_directions", "STR_dui_linecompass_allowed_draw_directions_desc"],
    [_cat, _curCat],
    true,
    1,
    {
        params ["_value"];
        GVAR(ResolvedDrawBearing) = if (!isNil QGVAR(DrawBearing) && !_value) then {
            GVAR(DrawBearing) min 1
        };
    }
] call CBA_fnc_addSetting;

[
    QGVAR(IconOutline),
    "LIST",
    "STR_dui_linecompass_icon_outline",
    [_cat, _curCat],
    [[0, 1, 2], ["STR_dui_namelist_text_shadow_0", "STR_dui_namelist_text_shadow_1", "STR_dui_namelist_text_shadow_2"], 0]
] call CBA_fnc_addSetting;

[
    QGVAR(DefaultIconColor),
    "COLOR",
    ["STR_dui_linecompass_default_icon_color", "STR_dui_linecompass_default_icon_color_desc"],
    [_cat, _curCat],
    [0.5, 0.87, 0.5, 1]
] call CBA_fnc_addSetting;

[
    QGVAR(WaypointColor),
    "COLOR",
    ["STR_dui_linecompass_default_waypoint_color", "STR_dui_linecompass_default_waypoint_color_desc"],
    [_cat, _curCat],
    [0, 0, 0.87, 1]
] call CBA_fnc_addSetting;

[
    QGVAR(CustomWaypointColor),
    "COLOR",
    ["STR_dui_linecompass_custom_waypoint_color", "STR_dui_linecompass_custom_waypoint_color_desc"],
    [_cat, _curCat],
    [0, 0, 0.87, 1]
] call CBA_fnc_addSetting;

if (isClass(configFile >> "CfgPatches" >> "ace_finger")) then {
    [
        QGVAR(ACEFingeringColor),
        "COLOR",
        "STR_dui_linecompass_ace_fingering_color",
        [_cat, _curCat],
        [1, 0.66, 0, 1]
    ] call CBA_fnc_addSetting;
};

[
    QGVAR(SwapOrder),
    "CHECKBOX",
    ["STR_dui_linecompass_swap_order", "STR_dui_linecompass_swap_order_desc"],
    [_cat, _curCat],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(compassRange),
    "SLIDER",
    [localize "STR_dui_compass_range", localize "STR_dui_compass_range_desc"],
    [_cat, _curCat],
    [DUI_MIN_RANGE, DUI_MAX_RANGE, 35, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(compassRangeLimit),
    "SLIDER",
    [localize "STR_dui_compass_range_limit", localize "STR_dui_compass_range_limit_desc"],
    [_cat, _curCat],
    [DUI_MIN_RANGE, DUI_MAX_RANGE, DUI_DEFAULT_MAX_RANGE, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(enableOcclusion),
    "CHECKBOX",
    ["STR_dui_occlusion", "STR_dui_occlusion_desc"],
    [_cat, _curCat],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(occlusionFadeSpeed),
    "SLIDER",
    ["STR_dui_occlusion_fade_time", "STR_dui_occlusion_fade_time_desc"],
    [_cat, _curCat],
    [0, 10, 3.5, 1],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(enableShowCustomWP),
    "CHECKBOX",
    ["STR_dui_linecompass_show_custom_waypoint", "STR_dui_linecompass_show_custom_waypoint_desc"],
    [_cat, _curCat],
    true,
    0,
    {
        params ["_value"];
        if (_value && customWaypointPosition isNotEqualTo []) then {
            ["CUSTOM_WAYPOINT_POSITION", customWaypointPosition, GVAR(CustomWaypointColor)] call FUNC(addLineMarker);
            GVAR(customWaypointPosition) = customWaypointPosition;
        } else {
            "CUSTOM_WAYPOINT_POSITION" call FUNC(removeLineMarker);
        };
    }
] call CBA_fnc_addSetting;

private _tfar = isClass (configFile >> "CfgPatches" >> "task_force_radio");
private _acre = isClass (configFile >> "CfgPatches" >> "acre_main");

if (_acre || _tfar) then {
    [
        QGVAR(showSpeaking),
        "CHECKBOX",
        [localize "STR_dui_linecompass_show_speaking", localize "STR_dui_linecompass_show_speaking_desc"],
        [_cat, _curCat],
        true,
        false
    ] call CBA_fnc_addSetting;
} else {
    GVAR(showSpeaking) = false;
};
