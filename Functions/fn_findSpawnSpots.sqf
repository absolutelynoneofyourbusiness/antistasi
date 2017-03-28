params ["_origin", ["_dest", "base_4"], ["_spot", false]];
private ["_roads", "_startRoad"];
_startRoad = _origin;
_roads = [];

if ((_spot) && (worldName == "Altis")) exitWith {
	[_origin, "none"] call fnc_getpresetSpawnPos;
};

private _tam = 10;

if !(typeName _origin == "ARRAY") then {
	_startRoad = getMarkerPos _origin;
};
if (worldName == "Altis") then {
	_startRoad = [_origin, "road"] call fnc_getpresetSpawnPos;
};
if !(typeName _dest == "ARRAY") then {
	_dest = getMarkerPos _dest;
};

while {true} do {
	_roads = _startRoad nearRoads _tam;
	if (count _roads > 0) exitWith {};
	_tam = _tam + 10;
};

private _road = _roads select 0;
private _conRoads = roadsConnectedto _road;
private _posRoad = position _road;
private _dist = _posRoad distance2D _dest;
if (count _conRoads > 0) then {
	{
		if ((position _x distance2D _dest) < _dist) then {
			_posRoad = position _x;
			_dist = _posRoad distance2D _dest;
		};
	} forEach _conRoads;
};
private _dir = [position _road, _posRoad] call BIS_fnc_dirTo;

[position _road, _dir]