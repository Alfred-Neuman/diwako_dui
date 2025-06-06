#include "script_component.hpp"

// loop
[FUNC(cacheLoop),[],0.5] call CBA_fnc_waitAndExecute;

private _player = [] call CBA_fnc_currentUnit;
private _group = units _player;
if (GVAR(syncGroup) && {isMultiplayer && {GVAR(sortType) isEqualTo "none" && {local (leader _player)}}}) then {
    if (_group isNotEqualTo ((group _player) getVariable [QGVAR(syncGroup), []])) then {
        (group _player) setVariable [QGVAR(syncGroup), _group, true];
    };
};

// if both compass and namelist are not enabled, just remove the controls if there are any
if !(diwako_dui_enable_compass || diwako_dui_namelist) exitWith {
    {
        ctrlDelete ctrlParentControlsGroup (GVAR(namebox_lists) deleteAt 0);
    } forEach GVAR(namebox_lists);
    "diwako_dui_namebox" cutRsc ["diwako_dui_RscNameBox","PLAIN", 0, true];
};

_group = (group _player) getVariable [QGVAR(syncGroup), _group];
private _isAloneInGroup = (count _group) <= 1;
if (diwako_dui_compass_hide_blip_alone_group && {_isAloneInGroup}) then {
    _group = [];
};

if (GVAR(group_by_vehicle)) then {
    private _newGrp = _group apply { [objectParent _x, parseNumber ((driver vehicle _x) isNotEqualTo _x), _x] };
    _newGrp sort true;
    _newGrp = _newGrp apply { _x select 2 };

    private _dummyList = [];
    private _filteredGrp = [];
    {
        if (_dummyList pushBackUnique (vehicle _x) isNotEqualTo -1) then {
            _filteredGrp pushBack _x;
        };
    } forEach _newGrp;
    GVAR(group) = _filteredGrp;
} else {
    GVAR(group) = + _group;
};

private _uiScale = diwako_dui_hudScaling;
private _uiPixels = GVAR(uiPixels);

private _iconNamespace = missionNamespace getVariable format[QEGVAR(main,icon_%1), diwako_dui_icon_style];

private _speakingArray = ["", EGVAR(main,speakingIcon), EGVAR(main,speakingRadioIcon)];

{
    if (alive _x) then {
        _x setVariable [QGVAR(compass_icon), [_x, _iconNamespace, _player, true] call FUNC(getIcon)];
        _x setVariable [QGVAR(icon), [_x, _iconNamespace, _player] call FUNC(getIcon)];
    };
} forEach _group;

private _specialTrack = missionNamespace getVariable ["diwako_dui_special_track", []];
if (_specialTrack isEqualType [] && {_specialTrack isNotEqualTo []}) then {
    private _toTrack = [];
    private _vehNamespace = GVAR(vehicleNamespace);
    {
        if !(isNull _x) then {
            private _index = _toTrack pushBackUnique _x;
            if (_index > -1) then {
                if (_x isKindOf "CAManBase") then {
                    _x setVariable [QGVAR(compass_icon), [_x, _iconNamespace, _player, true] call FUNC(getIcon)];
                };
                if (_x isKindOf "LandVehicle" || _x isKindOf "Air") then {
                    private _type = (typeOf _x);
                    private _picture = _vehNamespace getVariable _type;
                    if (isNil "_picture") then {
                        _picture = getText (configFile >> "CfgVehicles" >> _type >> "icon");
                        if (isText (configFile >> "CfgVehicleIcons" >> _picture)) then {
                            _picture = getText (configFile >> "CfgVehicleIcons" >> _picture);
                        } else {
                            private _found = (toLower _picture) find ".paa";
                            if (_found isEqualTo -1 || {((count _picture) - 4) isNotEqualTo _found}) then {
                                _picture = "a3\ui_f\data\Map\VehicleIcons\iconObject_ca.paa";
                            };
                        };
                        _vehNamespace setVariable [_type, _picture];
                    };
                    _x setVariable [QGVAR(icon_size), [2,1] select (_picture isEqualTo "a3\ui_f\data\Map\VehicleIcons\iconObject_ca.paa")];
                    _x setVariable [QGVAR(compass_icon), _picture];
                };
            };
        };
    } forEach _specialTrack;
    GVAR(group) = _toTrack + GVAR(group) - [objNull];
};

// start compass if enabeld but not running yet
if (diwako_dui_enable_compass) then {
    private _compassDisplay = uiNamespace getVariable ["diwako_dui_RscCompass", displayNull];
    if (GVAR(compass_pfHandle) <= -1 || {isNull _compassDisplay}) then {
        [GVAR(compass_pfHandle)] call CBA_fnc_removePerFrameHandler;
        "diwako_dui_compass" cutRsc ["diwako_dui_RscCompass","PLAIN", 0, false];
        [] call FUNC(compass);
    };

    private _compassCtrl = _compassDisplay displayCtrl IDC_COMPASS;
    private _compass = [_player] call EFUNC(main,getCompass);
    _compassCtrl ctrlSetText (diwako_dui_compass_style select (GVAR(show_cardinal_points) && {_compass isNotEqualTo ""}));

    if (_compass isNotEqualTo "") then {
        GVAR(maxDegrees) = GVAR(oddDirectionCompasses) getVariable [_compass, 360];
    };

    if (GVAR(setCompass)) then {
        GVAR(setCompass) = false;
        private _ctrlHeight = pixelH * _uiPixels;
        private _ctrlWidth = pixelW * _uiPixels;
        private _ctrlMiddleX = 0.5 - (pixelW * (_uiPixels / 2));
        private _compassY = safeZoneY + safeZoneH - (pixelH * (_uiPixels + 10));

        private _dirCtrl = _compassDisplay displayCtrl IDC_DIRECTION;
        private _grpCtrl = _compassDisplay displayCtrl IDC_COMPASS_CTRLGRP;

        if (diwako_dui_use_layout_editor) then {
            _ctrlMiddleX = profileNamespace getVariable ["igui_diwako_dui_compass_x", _ctrlMiddleX];
            _compassY = profileNamespace getVariable ["igui_diwako_dui_compass_y", _compassY];
            _ctrlWidth = profileNamespace getVariable ["igui_diwako_dui_compass_w", _ctrlWidth];
            _ctrlHeight = profileNamespace getVariable ["igui_diwako_dui_compass_h", _ctrlHeight];
        };

        GVAR(bearing_size_calc) = diwako_dui_dir_size * GVAR(a3UiScale) * _uiScale * GVAR(windowHeightMod);

        _compassCtrl ctrlSetPosition [
            _ctrlMiddleX,
            _compassY,
            _ctrlWidth,
            _ctrlHeight
        ];
        _compassCtrl ctrlSetTextColor [1 ,1 , 1, diwako_dui_compass_opacity];
        _compassCtrl ctrlCommit 0;
        _grpCtrl ctrlSetPosition [
           _ctrlMiddleX,
           _compassY,
           _ctrlWidth,
           _ctrlHeight
        ];
        _grpCtrl ctrlCommit 0;
        _dirCtrl ctrlSetPosition [
            _ctrlMiddleX,
            _compassY - (pixelH * GVAR(dir_padding) * _uiScale),
            // safeZoneY + safeZoneH - (pixelH * (_uiPixels + (55 * _uiScale))),
            _ctrlWidth,
            pixelH * 70 * _uiScale
        ];
        _dirCtrl ctrlSetTextColor [1, 1, 1, 1];
        _dirCtrl ctrlSetFont diwako_dui_font;
        _dirCtrl ctrlCommit 0;
    };
};

// built name list from here
private _display = uiNamespace getVariable ["diwako_dui_RscNameBox", displayNull];
if (isNull _display) exitWith {
    if (diwako_dui_namelist) then {
        "diwako_dui_RscNameBox" cutRsc ["diwako_dui_RscNameBox","PLAIN", 0, false];
        _display = uiNamespace getVariable ["diwako_dui_RscNameBox", displayNull];
    };
};

private _grpCtrl = _display displayCtrl IDC_NAMEBOX_CTRLGRP;
private _lists = GVAR(namebox_lists);

// delete all name list controls if not active
if (!diwako_dui_namelist || {GVAR(namelist_hideWhenLeader) && (leader _player) isEqualTo _player}) exitWith {
    if (_lists isNotEqualTo []) then {
        {
            ctrlDelete ctrlParentControlsGroup (_lists deleteAt _forEachIndex);
        } forEachReversed _lists;
        "diwako_dui_namebox" cutText ["","PLAIN"];
    };
};

if !([_player] call EFUNC(main,canHudBeShown)) exitWith {
    _grpCtrl ctrlShow false;
};

private _nameList = _display displayCtrl IDC_NAMEBOX;
if (GVAR(setNamelist)) then {
    GVAR(setNamelist) = false;
    private _xPos = 0.5 + (pixelW * (_uiPixels / 2 + 10));
    private _yPos = safeZoneY + safeZoneH - (pixelH * (_uiPixels + 10));
    private _wPos = 0.5 * safeZoneW - (pixelW * (_uiPixels / 2 + 10));
    private _hPos = pixelH * (_uiPixels + 10);
    if (diwako_dui_use_layout_editor) then {
        _xPos = profileNamespace getVariable ["igui_diwako_dui_namelist_x", _xPos];
        _yPos = profileNamespace getVariable ["igui_diwako_dui_namelist_y", _yPos];
        _hPos = profileNamespace getVariable ["igui_diwako_dui_namelist_h", _hPos];
        _wPos = profileNamespace getVariable ["igui_diwako_dui_namelist_w", _wPos];
    };
    private _nameListPos = [
        _xPos,
        _yPos,
        _wPos,
        _hPos
    ];
    _grpCtrl ctrlSetPosition _nameListPos;
    _grpCtrl ctrlCommit 0;
    _nameList ctrlSetPosition _nameListPos;
    _nameList ctrlCommit 0;
};
ctrlPosition _grpCtrl params ["", "", "", "_height"];
private _curNameListHeight = (_height / pixelH) - ((15 * _uiScale) max 15);

// no need to show any names if you are alone in the group
if (_isAloneInGroup) exitWith {
    {
        ctrlDelete ctrlParentControlsGroup (_lists deleteAt _forEachIndex);
    } forEachReversed _lists;
};
if !(ctrlShown _grpCtrl) then {
    _grpCtrl ctrlShow true;
};

_group = [_group, _player] call FUNC(sortNameList);

private _text = "";
private _curList = controlNull;

private _selectedUnits = groupSelectedUnits _player;
private _textSize = diwako_dui_namelist_size * GVAR(a3UiScale);
private _shadow = diwako_dui_namelist_text_shadow;
private _bgOpacity = diwako_dui_namelist_bg;
private _onlyBuddyIcon = diwako_dui_namelist_only_buddy_icon;
private _heightMod = GVAR(windowHeightMod);
private _listWidth = diwako_dui_namelist_width * pixelW * _uiScale;
private _itemHeight = (128 / 5) * diwako_dui_namelist_size * GVAR(namelist_vertical_spacing);
private _columnNo = 0;
private _curColumnHeight = 0;
private _ctrlPosList = [0, 0, _listWidth * 10, _itemHeight * pixelH];
private _showSpeaking = GVAR(showSpeaking);
private _replaceIconWhenSpeaking = GVAR(showSpeaking_replaceIcon);
private _circleRange = GVAR(compassRangeLimit) min diwako_dui_compassRange;
{
    if ((count _lists) < (_forEachIndex + 1)) then {
        private _curGrp = _display ctrlCreate["RscControlsGroupNoScrollbars", -1, _grpCtrl];
        _curGrp ctrlSetPosition [
            _listWidth * _columnNo,
            _curColumnHeight * pixelH,
            _listWidth,
            _itemHeight * pixelH
        ];
        _curGrp ctrlCommit 0;
        _curList = _display ctrlCreate ["RscStructuredText", -1, _curGrp];
        _curList ctrlSetFont diwako_dui_font;
        _curList ctrlSetBackgroundColor [0,0,0,_bgOpacity];
        _curList ctrlSetPosition _ctrlPosList;
        _lists pushBack _curList;
    } else {
        _curList = _lists select _forEachIndex;
    };
    _curColumnHeight = _curColumnHeight + _itemHeight;
    if (_curColumnHeight >= _curNameListHeight) then {
        _curColumnHeight = 0;
        _columnNo = _columnNo + 1;
    };

    private _unit = _x;
    private _selected = "";
    if ((GVAR(always_show_unit_numbers) || {_selectedUnits isNotEqualTo []}) && {_unit isNotEqualTo _player}) then {
        private _curName = vehicleVarName _unit;
        _unit setVehicleVarName "";
        private _defaultIdent = str _unit;
        _unit setVehicleVarName _curName;
        private _arr = [_defaultIdent, ":"] call CBA_fnc_split;
        private _num = if ((count _arr) > 1) then {
            (_arr select 1) select [0, 2]
        } else {
            ""
        };
        _selected = format ["%1%2", (["", ">> "] select (_selectedUnits findIf {_x isEqualTo _unit} > -1)), _num];
    };
    private _buddy = ["", _iconNamespace getVariable ["buddy", DUI_BUDDY]] select (_player isEqualTo (_unit getVariable [QEGVAR(buddy,buddy), objNull]));
    private _inrange = (_player distance2D _unit) < _circleRange;
    private _isSpeaking = _unit getVariable [QGVAR(isSpeaking), 0];
    private _speakingIcon = _speakingArray select _isSpeaking;
    private _icon = [
        [
            _unit getVariable [QGVAR(icon), DUI_RIFLEMAN],
            _speakingIcon
        ] select (_showSpeaking && { _replaceIconWhenSpeaking && {_isSpeaking > 0 && {_inrange}}}),
        ""
    ] select (_buddy isNotEqualTo "" && {_onlyBuddyIcon});
    private _speakingIcon = ["", _speakingIcon] select (_showSpeaking && { !_replaceIconWhenSpeaking && {_isSpeaking > 0 && {_inrange || {_isSpeaking isEqualTo 2}}}});
    _text = format ["<t color='%3' size='%5' shadow='%7' shadowColor='#000000' valign='middle' align='left'>%4<img image='%6'valign='bottom'/><img image='%1'valign='bottom'/> %2 <img image='%8'valign='bottom'/></t><br/>",
        _icon, // 1
        _unit getVariable [QEGVAR(main,customName), _unit getVariable ["ACE_Name", name _unit]], // 2
        _unit getVariable [QEGVAR(main,color),"#FFFFFF"], // 3
        _selected, // 4
        (_textSize * _heightMod), // 5
        _buddy, // 6
        _shadow, // 7
        _speakingIcon]; // 8
    _curList ctrlSetStructuredText parseText _text;
    _curList ctrlCommit 0;
} forEach _group;

for "_i" from (count _group) to (count _lists) do {
    ctrlDelete ctrlParentControlsGroup (_lists deleteAt (count _group));
};
