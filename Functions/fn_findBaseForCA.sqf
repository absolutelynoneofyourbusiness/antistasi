params ["_marker", ["_force", false],["_isReinf",false]];
private ["_position","_basesAAF","_bases","_base","_posBase","_busy","_radio"];

if (typeName _marker == "STRING") then {_position = getMarkerPos _marker} else {_position = _marker};

_basesAAF = bases - mrkFIA;
_bases = [];
_base = "";
{
	_base = _x;
	_posBase = getMarkerPos _base;
	_busy = [true, false] select (dateToNumber date >= server getVariable _base);
	_radio = [[_base] call AS_fnc_radioCheck, true] select (_force);

	diag_log format ["base: %1; busy: %2; radio: %3; contact: %4; distance: %5",_base,_busy,_radio,(count ((_position nearEntities ["Man", 1500]) select {side _x == side_blue}) < 1),_position distance _posBase];

	if ((!_busy) and (count ((_position nearEntities ["Man", 1500]) select {side _x == side_blue}) < 1)) then {
		if (_isReinf) then {
			if ((((_position distance _posBase < 7000) and (_radio)) or (_position distance _posBase < 2000)) AND (_position distance _posBase > 300)) then {
				if (worldName == "Tanoa") then {
					if ([_posBase, _position] call AS_fnc_IslandCheck) then {_bases pushBack _base};
				} else {
					_bases pushBack _base;
				};
			};
		} else {
			if (((_position distance _posBase < 5000) and (_radio)) or (_position distance _posBase < 2000)) then {
				if (worldName == "Tanoa") then {
					if ([_posBase, _position] call AS_fnc_IslandCheck) then {_bases pushBack _base};
				} else {
					_bases pushBack _base;
				};
			};
		};
	};
} forEach _basesAAF;

if (count _bases > 0) then {[_bases,_position] call BIS_fnc_nearestPosition} else {""}