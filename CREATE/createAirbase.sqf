if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_markerPos","_size","_isFrontline","_allVehicles","_allGroups","_allSoldiers","_currentStrength","_spawnPos","_groupType","_group","_dog","_flag","_currentCount","_patrolParams","_crate","_unit","_busy","_buildings","_positionOne","_positionTwo","_vehicle","_vehicleCount","_groupGunners","_roads","_data","_vehicleType","_spawnpool","_observer","_direction","_position","_hidden","_initialGroupSetup","_localIDs"];

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];

_initialGroupSetup = [];
_localIDs = [];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;
_isFrontline = [_marker] call AS_fnc_isFrontline;
_busy = if (dateToNumber date > server getVariable _marker) then {false} else {true};

// bunker on road
_groupGunners = createGroup side_green;
if ((spawner getVariable _marker) AND (_isFrontline)) then {
	_roads = _markerPos nearRoads _size;
	if (count _roads != 0) then {
		_data = [_markerPos, _roads, statAT] call AS_fnc_spawnBunker;
		_allVehicles pushBack (_data select 0);
		_vehicle = (_data select 1);
		_vehicle enableDynamicSimulation true;
		_allVehicles pushBack _vehicle;
		_unit = ([_markerPos, 0, infGunner, _groupGunners] call bis_fnc_spawnvehicle) select 0;
		_unit moveInGunner _vehicle;
	};
};

_allGroups pushBack _groupGunners;

// small patrols
for "_i" from 1 to 3 do {
	while {true} do {
		_spawnPos = [_markerPos, 50 + (random 100), random 360] call BIS_fnc_relPos;
		if (!surfaceIsWater _spawnPos) exitWith {};
	};
	_groupType = [infTeam, side_green] call AS_fnc_pickGroup;
	_groupPatrol = [_spawnPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
	if (random 10 < 2.5) then {
		_dog = _groupPatrol createUnit ["Fin_random_F",_spawnPos,[],0,"FORM"];
		[_dog] spawn guardDog;
	};
	_initialGroupSetup pushBack [_groupType, "patrol", _spawnPos];
	[_groupPatrol, _markerPos, 300, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
	[_groupPatrol, _marker, (units _groupPatrol), 400, true] spawn AS_fnc_monitorGroup;
	_localIDs pushBack (_groupPatrol call BIS_fnc_netId);
	grps_VCOM pushBackUnique (_groupPatrol call BIS_fnc_netId);
	_allGroups pushBack _groupPatrol;
};

// planes/helicopters and pilots
if !(_busy) then {
	_buildings = nearestObjects [_markerPos, ["Land_LandMark_F"], _size / 2];
	if (count _buildings > 1) then {
		_positionOne = getPos (_buildings select 0);
		_positionTwo = getPos (_buildings select 1);
		_direction = [_positionOne, _positionTwo] call BIS_fnc_DirTo;
		_position = [_positionOne, 5,_direction] call BIS_fnc_relPos;
		_group = createGroup side_green;

		_currentCount = 0;
		while {(spawner getVariable _marker) AND (_currentCount < 5)} do {
			_vehicleType = indAirForce call BIS_fnc_selectRandom;
			_vehicle = createVehicle [_vehicleType, _position, [],3, "NONE"];
			_vehicle setDir (_direction + 90);
			sleep 1;
			_allVehicles pushBack _vehicle;
			_position = [_position, 20,_direction] call BIS_fnc_relPos;
			_unit = ([_markerPos, 0, infPilot, _group] call bis_fnc_spawnvehicle) select 0;
			_currentCount = _currentCount + 1;
		};
	};
	_allGroups pushBack _group;
};

// flag and crate
_flag = createVehicle [cFlag, _markerPos, [],0, "CAN_COLLIDE"];
_flag allowDamage false;
[_flag,"take"] remoteExec ["AS_fnc_addActionMP",[0,-2] select isDedicated,_flag];
_allVehicles pushBack _flag;
_crate = "I_supplyCrate_F" createVehicle _markerPos;
_allVehicles pushBack _crate;

// vehicles
_arrayVeh = vehPatrol + vehSupply + enemyMotorpool - [heli_default];
_vehicleCount = round (_size/60);
_currentCount = 0;
while {(spawner getVariable _marker) AND (_currentCount < _vehicleCount)} do {
	if (diag_fps > minimoFPS) then {
		_vehicleType = _arrayVeh call BIS_fnc_selectRandom;
		_position = [_markerPos, 10, _size/2, 10, 0, 0.3, 0] call BIS_Fnc_findSafePos;
		_vehicle = createVehicle [_vehicleType, _position, [], 0, "NONE"];
		_vehicle setDir random 360;
		_allVehicles pushBack _vehicle;
	};
	sleep 1;
	_currentCount = _currentCount + 1;
};

// garrison squad
_groupType = [infSquad, side_green] call AS_fnc_pickGroup;
_groupGarrison = [_markerPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
_initialGroupSetup pushBack [_groupType, "garrison", _markerPos];
_allGroups pushBack _groupGarrison;

{
	_x enableDynamicSimulation true;
	[_x] spawn genVEHinit;
} forEach _allVehicles;

sleep 3;

{
	_group = _x;
	{
		if (alive _x) then {
			[_x] spawn genInitBASES;
			_allSoldiers pushBackUnique _x;
		};
	} forEach units _group;
} forEach _allGroups;

publicVariable "grps_VCOM";
([_marker,count _allSoldiers] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];
[_groupGarrison,_size min 50] spawn AS_fnc_forceGarrison;

_group = createGroup civilian;
_allGroups pushBack _group;
_dog = _group createUnit ["Fin_random_F",_markerPos,[],0,"FORM"];
[_dog] spawn guardDog;
_allSoldiers pushBack _dog;

_observer = objNull;
if ((random 100 < (((server getVariable "prestigeNATO") + (server getVariable "prestigeCSAT"))/10)) AND (spawner getVariable _marker)) then {
	_spawnPos = [];
	_group = createGroup civilian;
	while {true} do {
		_spawnPos = [_markerPos, round (random _size), random 360] call BIS_Fnc_relPos;
		if !(surfaceIsWater _spawnPos) exitWith {};
	};
	_observer = _group createUnit [selectRandom CIV_journalists, _spawnPos, [],0, "NONE"];
	[_observer] spawn CIVinit;
	_allGroups pushBack _group;
	[_group, _markerPos, 150, 5, "MOVE", "SAFE", "BLUE", "LIMITED", "STAG COLUMN", "", [2,6,10]] call CBA_fnc_taskPatrol;
};

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
	publicVariable "reducedGarrisons";
};

waitUntil {sleep 3;
	!(spawner getVariable _marker) OR
	{((count ((_markerPos nearEntities [solCat, (_size max 200)]) select {_x getVariable ["BLUFORSpawn",false]})) > (3*count (_allSoldiers select {alive _x AND !captive _x})))} OR
	{!(garrison getVariable [format ["%1_reduced", _marker],false])}
};

call {
	// Garrison was overwhelmed
	if ((spawner getVariable _marker) AND !(_marker in mrkFIA)) exitWith {
		[_flag] remoteExec ["mrkWIN",2];
	};

	// Zone was despawned
	if !(spawner getVariable _marker) exitWith {

	};

	// Garrison was replenished
	if !(garrison getVariable [format ["%1_reduced", _marker],false]) exitWith {
		spawer setVariable [format ["%1_respawning", _marker],true,true];
		reducedGarrisons = reducedGarrisons - [_marker];
		publicVariable "reducedGarrisons";
	};
};

spawner setVariable [_marker,false,true];
waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

[_allGroups, _allSoldiers, _allVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)])] spawn AS_fnc_despawnUnits;
if (!isNull _observer) then {deleteVehicle _observer};
grps_VCOM = grps_VCOM - _localIDs; publicVariable "grps_VCOM";

if (spawner getVariable [format ["%1_respawning", _marker],false]) then {
	sleep 15;
	waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

	[_marker] call AS_fnc_respawnZone;
};