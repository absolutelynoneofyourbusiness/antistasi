/*
 	Description:
		Find an aiport for a specific purpose

	Parameters:
		0: STRING/ARRAY - Marker name or position of the target zone
		1: STRING - Mission type

 	Returns:
		0: STRING - Marker name of the aiport, or "" if none found

 	Example:
		_aiportForReinforcement = ["Kavala", "reinforcement"] call AS_fnc_findAirport;
*/

params [
	["_marker", [], ["", []]],
	["_missionType", "replacement", []],

	["_bases", []],
	["_base", ""]
];

private ["_markerPos", "_options", "_fnc_check", "_basePos"];

if (_marker isEqualTo []) exitWith {diag_log "Error in findAirport, no position/marker provided."};

if (typeName _marker isEqualTo "STRING") then {
	_markerPos = getMarkerPos _marker;
} else {
	_markerPos = _marker;
};

call {
	// distance 5000 < x < 20000, radio contact
	if (toLower _missionType isEqualTo "replacement") exitWith {
		_fnc_check = {
			params ["_markerPos", "_base", "_basePos"];
			((_markerPos distance _basePos < 20000) AND
			 {[_basePos] call AS_fnc_radioCheck} AND
			 {_markerPos distance _basePos > 5000})
		};
	};

	// not busy, distance 2000 < x < 10000 and radio contact, < 6000 if no radio contact
	if (toLower _missionType isEqualTo "attack") exitWith {
		_fnc_check = {
			params ["_markerPos", "_base", "_basePos"];
			((dateToNumber date >= server getVariable _base) AND
			 {((_markerPos distance _basePos < 10000) AND {[_basePos] call AS_fnc_radioCheck}) OR {_markerPos distance _basePos < 6000}} AND
			 {_markerPos distance _basePos > 2000})
		};
	};

	// distance 2000 < x < 10000, radio contact
	if (toLower _missionType isEqualTo "reinforcement") exitWith {
		_fnc_check = {
			params ["_markerPos", "_base", "_basePos"];
			((_markerPos distance _basePos < 10000) AND
			 {[_basePos] call AS_fnc_radioCheck} AND
			 {_markerPos distance _basePos > 2000})
		};
	};

	// default
	_fnc_check = {
		params ["_markerPos", "_base", "_basePos"];
		((_markerPos distance _basePos < 10000) AND
		 {[_basePos] call AS_fnc_radioCheck} AND
		 {_markerPos distance _basePos > 2000})
	};
};

_options = aeropuertos - mrkFIA;
{
	_base = _x;
	_basePos = getMarkerPos _base;

	if ([_markerPos, _base, _basePos] call _fnc_check) then {
		if ([_basePos, side_blue] call AS_fnc_proximityCheck) then {
			_bases pushBack _base;
		};
	};
} forEach _options;

if (count _bases > 0) then {[_bases,_markerPos] call BIS_fnc_nearestPosition} else {""}