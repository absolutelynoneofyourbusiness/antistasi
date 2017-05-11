/*
 	Description:
		Find a base for a specific purpose

	Parameters:
		0: STRING/ARRAY - Marker name or position of the target zone
		1: STRING - Mission type

 	Returns:
		0: STRING - Marker name of the base, or "" if none found

 	Example:
		_baseForAttack = ["Neri", "attack"] call AS_fnc_findBase;
*/

params [
	["_marker", [], ["", []]],
	["_missionType", "replacement", []],
	["_bases", []],
	["_base", ""]
];

private ["_markerPos", "_options", "_fn_check", "_basePos"];

if (_marker isEqualTo []) exitWith {diag_log "Error in findBase, no position/marker provided."};

if (typeName _marker isEqualTo "STRING") then {
	_markerPos = getMarkerPos _marker;
} else {
	_markerPos = _marker;
};

call {
	// distance 2000 < x < 10000, radio contact
	if (toLower _missionType isEqualTo "replacement") exitWith {
		_fn_check = {
			params ["_markerPos", "_base", "_basePos"];
			((_markerPos distance _basePos < 10000) AND {([_basePos] call AS_fnc_radioCheck)} AND {(_markerPos distance _basePos > 2000)})
		};
	};

	// not busy, distance 300 < x < 2000 and radio contact, < 7000 if no radio contact
	if (toLower _missionType isEqualTo "attack") exitWith {
		_fn_check = {
			params ["_markerPos", "_base", "_basePos"];
			(([true, false] select (dateToNumber date >= server getVariable _base)) AND {({(_markerPos distance _basePos < 7000)} AND {([_basePos] call AS_fnc_radioCheck)}) OR {(_markerPos distance _basePos < 2000)}} AND {(_markerPos distance _basePos > 300)})
		};
	};

	// distance 1000 < x < 6000, radio contact
	if (toLower _missionType isEqualTo "reinforcement") exitWith {
		_fn_check = {
			params ["_markerPos", "_base", "_basePos"];
			((_markerPos distance _basePos < 6000) AND {([_basePos] call AS_fnc_radioCheck)} AND {(_markerPos distance _basePos > 1000)})
		};
	};

	// default
	_fn_check = {
		params ["_markerPos", "_base", "_basePos"];
		((_markerPos distance _basePos < 10000) AND {([_basePos] call AS_fnc_radioCheck)} AND {(_markerPos distance _basePos > 2000)})
	};
};

_options = bases - mrkFIA;
{
	_base = _x;
	_basePos = getMarkerPos _base;

	if (count ((_markerPos nearEntities [solCat, 2000]) select {_x getVariable ["BLUFORSpawn", false]}) < 1) then {
		if (_fn_check) then {
			if (worldName == "Tanoa") then {
				if ([_basePos, _markerPos] call AS_fnc_IslandCheck) then {_bases pushBack _base};
			} else {
				_bases pushBack _base;
			};
		};
	};
} forEach _options;

if (count _bases > 0) then {[_bases,_markerPos] call BIS_fnc_nearestPosition} else {""}