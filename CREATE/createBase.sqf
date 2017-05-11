if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_markerPos","_size","_isFrontline","_allVehicles","_allGroups","_allSoldiers","_patrolMarker","_currentStrength","_spawnPos","_groupType","_group","_dog","_flag","_currentCount","_patrolParams","_crate","_unit","_busy","_buildings","_building","_buildingType","_vehicle","_vehicleCount","_groupGunners","_roads","_data","_vehicleType","_spawnpool","_observer","_hidden","_initialGroupSetup","_localIDs"];

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];

_initialGroupSetup = [];
_localIDs = [];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;
_isFrontline = [_marker] call AS_fnc_isFrontline;
_patrolMarker = [_marker] call AS_fnc_createPatrolMarker;
_busy = if (dateToNumber date > server getVariable _marker) then {false} else {true};

_buildings = nearestObjects [_markerPos, listMilBld, _size*1.5];
_groupGunners = createGroup side_green;

// statics in buildings
for "_i" from 0 to (count _buildings) - 1 do {
	_building = _buildings select _i;
	_buildingType = typeOf _building;

	call {
		if 	((_buildingType == "Land_Cargo_HQ_V1_F") OR (_buildingType == "Land_Cargo_HQ_V2_F") OR (_buildingType == "Land_Cargo_HQ_V3_F")) exitWith {
			_vehicle = createVehicle [statAA, (_building buildingPos 8), [],0, "CAN_COLLIDE"];
			_vehicle setPosATL [(getPos _building select 0),(getPos _building select 1),(getPosATL _vehicle select 2)];
			_vehicle setDir (getDir _building);
			_vehicle enableDynamicSimulation true;
			_unit = ([_markerPos, 0, infGunner, _groupGunners] call bis_fnc_spawnvehicle) select 0;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
			sleep 1;
		};

		if 	((_buildingType == "Land_Cargo_Patrol_V1_F") OR (_buildingType == "Land_Cargo_Patrol_V2_F") OR (_buildingType == "Land_Cargo_Patrol_V3_F")) exitWith {
			_vehicle = createVehicle [statMGtower, (_building buildingPos 1), [], 0, "CAN_COLLIDE"];
			_position = [getPosATL _vehicle, 2.5, (getDir _building) - 180] call BIS_Fnc_relPos;
			_vehicle setPosATL _position;
			_vehicle setDir (getDir _building) - 180;
			_vehicle enableDynamicSimulation true;
			_unit = ([_markerPos, 0, infGunner, _groupGunners] call bis_fnc_spawnvehicle) select 0;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
			sleep 1;
		};

		if ((_buildingType == "Land_HelipadSquare_F") AND (!_isFrontline)) exitWith {
			_vehicle = createVehicle [selectRandom heli_unarmed, position _building, [],0, "CAN_COLLIDE"];
			_vehicle setDir (getDir _building);
			_vehicle enableDynamicSimulation true;
			_allVehicles pushBack _vehicle;
			sleep 1;
		};

		if 	(_buildingType in listbld) exitWith {
			_vehicle = createVehicle [statMGtower, (_building buildingPos 13), [], 0, "CAN_COLLIDE"];
			_vehicle enableDynamicSimulation true;
			_unit = ([_markerPos, 0, infGunner, _groupGunners] call bis_fnc_spawnvehicle) select 0;
			_unit moveInGunner _vehicle;
			_allSoldiers = _allSoldiers + [_unit];
			sleep 1;
			_allVehicles = _allVehicles + [_vehicle];
			_vehicle = createVehicle [statMGtower, (_building buildingPos 17), [], 0, "CAN_COLLIDE"];
			_vehicle enableDynamicSimulation true;
			_unit = ([_markerPos, 0, infGunner, _groupGunners] call bis_fnc_spawnvehicle) select 0;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
			sleep 1;
		};
	};
};

// flag and crate
_flag = createVehicle [cFlag, _markerPos, [],0, "CAN_COLLIDE"];
_flag allowDamage false;
[_flag,"take"] remoteExec ["AS_fnc_addActionMP",[0,-2] select isDedicated,_flag];
_allVehicles pushBack _flag;
_crate = "I_supplyCrate_F" createVehicle _markerPos;
_allVehicles pushBack _crate;

// mortars
_vehicleCount = 4 min (round (_size / 30));
if ( _vehicleCount > 0 ) then {
	_spawnPos = [_markerPos, random (_size / 2),random 360] call BIS_fnc_relPos;
	_currentCount = 0;
	while {(spawner getVariable _marker) AND (_currentCount < _vehicleCount)} do {
		_spawnPos = [_markerPos] call mortarPos;
		_vehicle = statMortar createVehicle _spawnPos;
		_vehicle enableDynamicSimulation true;
		_unit = ([_markerPos, 0, infGunner, _groupGunners] call bis_fnc_spawnvehicle) select 0;
		_unit moveInGunner _vehicle;
		_allVehicles pushBack _vehicle;
		sleep 1;
		_currentCount = _currentCount + 1;
	};
};

// bunker on access road
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

// vehicles
if (!_busy) then {
	_spawnpool = vehAPC + vehPatrol + enemyMotorpool - [heli_default];
	_vehicleCount = 1 max (round (_size/50));
	_spawnPos = _markerPos;
	_currentCount = 0;
	while {(spawner getVariable _marker) AND (_currentCount < _vehicleCount)} do {
		if (diag_fps > minimoFPS) then {
			_vehicleType = selectRandom _spawnpool;
			_spawnPos = [_spawnPos findEmptyPosition [10,60,_vehicleType], [_markerPos, 10, _size/2, 10, 0, 0.3, 0] call BIS_Fnc_findSafePos] select (_size > 40);
			_vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, "NONE"];
			_vehicle setDir random 360;
			_allVehicles pushBack _vehicle;
		};
		sleep 1;
		_currentCount = _currentCount + 1;
	};
};

{
	_x enableDynamicSimulation true;
	[_x] spawn genVEHinit;
} forEach _allVehicles;

// patrols
for "_i" from 1 to 2 do {
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

// spawn garrison squads
_groupType = [infSquad, side_green] call AS_fnc_pickGroup;
_groupGarrisonOne = [_markerPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
_initialGroupSetup pushBack [_groupType, "garrison", _markerPos];
_allGroups pushBack _groupGarrisonOne;

_groupType = [infSquad, side_green] call AS_fnc_pickGroup;
_groupGarrisonTwo = [_markerPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
_initialGroupSetup pushBack [_groupType, "garrison", _markerPos];
_allGroups pushBack _groupGarrisonTwo;

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
[_groupGarrisonOne, _size min 100] spawn AS_fnc_forceGarrison;
[_groupGarrisonTwo, _size min 100] spawn AS_fnc_forceGarrison;

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

deleteMarker _patrolMarker;
[_allGroups, _allSoldiers, _allVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)])] spawn AS_fnc_despawnUnits;
if (!isNull _observer) then {deleteVehicle _observer};
grps_VCOM = grps_VCOM - _localIDs; publicVariable "grps_VCOM";

if (spawner getVariable [format ["%1_respawning", _marker],false]) then {
	sleep 15;
	waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

	[_marker] call AS_fnc_respawnZone;
};