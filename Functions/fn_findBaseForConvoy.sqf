params ["_marker"];
private ["_position","_basesAAF","_bases","_base","_posBase","_busy"];

if (typeName _marker == "STRING") then {_position = getMarkerPos _marker} else {_position = _marker};

_basesAAF = bases - mrkFIA;
_bases = [];
_base = "";

{
	_base = _x;
	_posBase = getMarkerPos _base;
	_busy = [true, false] select (dateToNumber date >= server getVariable _base);
	if ((_position distance _posBase < 7500) and (_position distance _posBase > 1500) and (count ((_position nearEntities ["Man", 1500]) select {side _x == side_blue}) < 1) and !(_busy)) then {
		if (worldName == "Tanoa") then {
			if ([_posBase, _position] call AS_fnc_IslandCheck) then {_bases pushBack _base};
		} else {
			_bases pushBack _base;
		};
	};
} forEach _basesAAF;

if (count _bases > 0) then {[_bases,_position] call BIS_fnc_nearestPosition} else {""}