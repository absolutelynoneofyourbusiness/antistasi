params ["_markerPos", "_roads","_staticType"];
private ["_roads","_distance","_road","_connectedRoads","_connectedRoad","_direction","_position","_bunker","_bunkertype","_static"];

_distance = 0;
_road = objNull;
{
	if ((position _x) distance _markerPos > _distance) then {
		_road = _x;
		_distance = position _x distance _markerPos;
	};
} forEach _roads;
_connectedRoads = roadsConnectedto _road;
_connectedRoad = objNull;
{
	if ((position _x) distance _markerPos > _distance) then {
		_connectedRoad = _x;
	};
} forEach _connectedRoads;
_direction = [_connectedRoad, _road] call BIS_fnc_DirTo;
_position = [getPos _road, 7, _direction + 270] call BIS_Fnc_relPos;
_bunkertype = ["Land_BagBunker_Small_F","Land_BagBunker_01_small_green_F"] select (worldName == "Tanoa");
_bunker = _bunkertype createVehicle _position;
_bunker setDir _direction;
_position = getPosATL _bunker;
_static = _staticType createVehicle _markerPos;
_static setPos _position;
_static setDir _dirVeh + 180;
_unit = ([_markerPos, 0, infGunner, _groupGunners] call bis_fnc_spawnvehicle) select 0;
[_unit] spawn genInitBASES;
[_static] spawn genVEHinit;
_unit moveInGunner _static;

[_bunker, _static]