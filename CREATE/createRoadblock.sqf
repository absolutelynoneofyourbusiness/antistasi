if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_allVehicles","_allGroups","_allSoldiers","_markerPos","_size","_distance","_roads","_connectedRoads","_position","_bunker","_static","_group","_unit","_groupType","_tempGroup","_dog","_normalPos","_spawnPos","_hidden","_hidden","_initialGroupSetup","_localIDs"];

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];

_initialGroupSetup = [];
_localIDs = [];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;

_tempGroup = createGroup side_green;

_distance = 20;
while {true} do {
	_roads = _markerPos nearRoads _distance;
	if (count _roads > 1) exitWith {};
	_distance = _distance + 5;
};
_connectedRoads = roadsConnectedto (_roads select 0);

_direction = [_roads select 0, _connectedRoads select 0] call BIS_fnc_DirTo;
if ((isNull (_roads select 0)) OR (isNull (_connectedRoads select 0))) exitWith {diag_log format ["Error in createRoadblock: no suitable roads found near %1",_marker]};

_fnc_createBunker = {
	params ["_dist","_dir"];

	_position = [(_roads select 0), _dist, _dir] call BIS_Fnc_relPos;
	_bunker = bld_smallBunker createVehicle _position;
	_allVehicles pushBack _bunker;
	_bunker setDir (_dir + 90);
	_normalPos = surfaceNormal (position _bunker);
	_bunker setVectorUp _normalPos;
	_position = getPosATL _bunker;
	_static = statMG createVehicle _markerPos;
	_allVehicles pushBack _static;
	_static setPosATL _position;
	_static setDir (_dir - 90);
	_normalPos = surfaceNormal (position _static);
	_static setVectorUp _normalPos;
	_static enableDynamicSimulation true;
	_allVehicles pushBack _static;
	[_static] spawn genVEHinit;
	sleep 1;

	_unit = ([_markerPos, 0, infGunner, _tempGroup] call bis_fnc_spawnvehicle) select 0;
	_unit moveInGunner _static;
};

[9, _direction + 270] call _fnc_createBunker;
[7, _direction + 90] call _fnc_createBunker;

_position = [getPos _bunker, 6, getDir _bunker] call BIS_fnc_relPos;
_static = createVehicle [cFlag, _position, [],0, "CAN_COLLIDE"];
_allVehicles pushBack _static;
[_static] spawn genVEHinit;

{
	_x enableDynamicSimulation true;
} forEach _allVehicles;

while {true} do {
	_spawnPos = [_markerPos, 10 + (random _size), random 360] call BIS_fnc_relPos;
	if (!surfaceIsWater _spawnPos) exitWith {};
};
_groupType = [infAT, side_green] call AS_fnc_pickGroup;
_groupPatrol = [_spawnPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
if (random 5 < 2.5) then {
	_dog = _groupPatrol createUnit ["Fin_random_F",_spawnPos,[],0,"FORM"];
	[_dog] spawn guardDog;
};
{[_x] join _groupPatrol} forEach units _tempGroup;
_soldier = ([_spawnPos, 0, sol_MED, _groupPatrol] call bis_fnc_spawnvehicle) select 0;
_soldier = ([_spawnPos, 0, sol_LAT, _groupPatrol] call bis_fnc_spawnvehicle) select 0;
_initialGroupSetup pushBack [_groupType, "patrol", _spawnPos];
[_groupPatrol, _markerPos, 50, 3, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
_localIDs pushBack (_groupPatrol call BIS_fnc_netId);
grps_VCOM pushBackUnique (_groupPatrol call BIS_fnc_netId);
_groupPatrol allowFleeing 0;
[_groupPatrol, 400, true, _markerPos] spawn AS_fnc_monitorGroup;
deleteGroup _tempGroup;
_allGroups pushBack _groupPatrol;

{[_x] spawn genInitBASES; _allSoldiers pushBack _x} forEach units _groupPatrol;

publicVariable "grps_VCOM";
([_marker,count _allSoldiers] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];

// Dynamic Simulation
sleep 10;
{
	_x enableDynamicSimulation true;
} forEach _allGroups;

{
	_x hideObjectGlobal true;
} forEach _allSoldiers + _allVehicles;
_hidden = true;

while {(count (_allSoldiers select {alive _x AND !captive _x}) > _reinfStrength) AND {(spawner getVariable _marker)}} do {
	while {
		(count ((_markerPos nearEntities ["LandVehicle",2000]) select {_x getVariable ["BLUFORSpawn",false]}) < 1) AND
		{(count ((_markerPos nearEntities ["AirVehicle",2000]) select {_x getVariable ["BLUFORSpawn",false]}) < 1)} AND
		{(count ((_markerPos nearEntities [solCat,2000]) select {_x getVariable ["BLUFORSpawn",false]}) < 1)} AND
		{(spawner getVariable _marker)}
	} do {
		if !(_hidden) then {
			{
				_x hideObjectGlobal true;
			} forEach _allSoldiers + _allVehicles;
			_hidden = true;
		};
		sleep 1;
	};

	if (_hidden) then {
		{
			_x hideObjectGlobal false;
		} forEach _allSoldiers + _allVehicles;
		_hidden = false;
	};

	sleep 5;
};

sleep 5;

diag_log format ["Reduced garrison at %1", _marker];
if (spawner getVariable _marker) then {
	garrison setVariable [format ["%1_reduced", _marker],true,true];
	reducedGarrisons pushBackUnique _marker;
};

waitUntil {sleep 3;
	!(spawner getVariable _marker) OR
	{((count ((_markerPos nearEntities [solCat, (_size max 200)]) select {_x getVariable ["BLUFORSpawn",false]})) > (3*count (_allSoldiers select {alive _x AND !captive _x})))} OR
	{!(garrison getVariable [format ["%1_reduced", _marker],false])}
};

call {
	// Garrison was overwhelmed
	if (count (_allSoldiers select {alive _x AND !captive _x}) < 1) exitWith {
		[-5,0,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		[["TaskSucceeded", ["", localize "STR_TSK_RB_DESTROYED"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
		[_markerPos] remoteExec ["patrolCA",HCattack];
		mrkAAF = mrkAAF - [_marker];
		mrkFIA = mrkFIA + [_marker];
		publicVariable "mrkAAF";
		publicVariable "mrkFIA";
		if (activeBE) then {["cl_loc"] remoteExec ["fnc_BE_XP", 2]};
		[_marker] spawn AS_fnc_respawnRoadblock;
		reducedGarrisons = reducedGarrisons - [_marker];
		publicVariable "reducedGarrisons";
	};

	// Zone was despawned
	if !(spawner getVariable _marker) exitWith {

	};

	// Garrison was replenished
	if !(garrison getVariable [format ["%1_reduced", _marker],false]) exitWith {
		spawner setVariable [format ["%1_respawning", _marker],true,true];
		reducedGarrisons = reducedGarrisons - [_marker];
		publicVariable "reducedGarrisons";
	};
};

spawner setVariable [_marker,false,true];
waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

[_allGroups, _allSoldiers, _allVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)])] spawn AS_fnc_despawnUnits;
grps_VCOM = grps_VCOM - _localIDs; publicVariable "grps_VCOM";

if (spawner getVariable [format ["%1_respawning", _marker],false]) then {
	sleep 15;
	waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

	[_marker] call AS_fnc_respawnZone;
};