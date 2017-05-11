if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_allVehicles","_allGroups","_allSoldiers","_markerPos","_position","_size","_buildings","_building","_type","_vehicle","_unit","_flag","_crate","_isFrontline","_vehicleData","_vehCrew","_base","_roads","_data","_strength","_currentStrength","_groupType","_group","_patrolParams","_observer","_radioTower","_hidden","_initialGroupSetup","_tempGroup","_spawnPos"];

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];

_initialGroupSetup = [];
_localIDs = [];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;
_isFrontline = [_marker] call AS_fnc_isFrontline;

_buildings = nearestObjects [_markerPos, listMilBld, _size*1.5];
_tempGroup = createGroup side_green;

for "_i" from 0 to (count _buildings) - 1 do {
	_building = _buildings select _i;
	_type = typeOf _building;

	call {
		if 	((_type == "Land_Cargo_HQ_V1_F") OR (_type == "Land_Cargo_HQ_V2_F") OR (_type == "Land_Cargo_HQ_V3_F")) exitWith {
			_vehicle = createVehicle [statAA, (_building buildingPos 8), [],0, "CAN_COLLIDE"];
			_vehicle setPosATL [(getPos _building select 0),(getPos _building select 1),(getPosATL _vehicle select 2)];
			_vehicle setDir (getDir _building);
			_vehicle enableDynamicSimulation true;
			_unit = ([_markerPos, 0, infGunner, _tempGroup] call bis_fnc_spawnvehicle) select 0;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
		};

		if 	((_type == "Land_Cargo_Patrol_V1_F") OR (_type == "Land_Cargo_Patrol_V2_F") OR (_type == "Land_Cargo_Patrol_V3_F")) exitWith {
			_vehicle = createVehicle [statMGtower, (_building buildingPos 1), [], 0, "CAN_COLLIDE"];
			_ang = (getDir _building) - 180;
			_position = [getPosATL _vehicle, 2.5, _ang] call BIS_Fnc_relPos;
			_vehicle setPosATL _position;
			_vehicle setDir (getDir _building) - 180;
			_vehicle enableDynamicSimulation true;
			_unit = ([_markerPos, 0, infGunner, _tempGroup] call bis_fnc_spawnvehicle) select 0;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
		};

		if 	(_type in listbld) exitWith {
			_vehicle = createVehicle [statMGtower, (_building buildingPos 13), [], 0, "CAN_COLLIDE"];
			_vehicle enableDynamicSimulation true;
			_unit = ([_markerPos, 0, infGunner, _tempGroup] call bis_fnc_spawnvehicle) select 0;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
			sleep 1;
			_allVehicles = _allVehicles + [_vehicle];
			_vehicle = createVehicle [statMGtower, (_building buildingPos 17), [], 0, "CAN_COLLIDE"];
			_vehicle enableDynamicSimulation true;
			_unit = ([_markerPos, 0, infGunner, _tempGroup] call bis_fnc_spawnvehicle) select 0;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
		};
	};
};

_flag = createVehicle [cFlag, _markerPos, [],0, "CAN_COLLIDE"];
_flag allowDamage false;
[_flag,"take"] remoteExec ["AS_fnc_addActionMP",[0,-2] select isDedicated,_flag];
_allVehicles pushBack _flag;
sleep 0.5;

_crate = "I_supplyCrate_F" createVehicle _markerPos;
_allVehicles pushBack _crate;
sleep 0.5;

if (_marker in puertos) then {
	_position = [_markerPos,_size,_size*3,25,2,0,0] call BIS_Fnc_findSafePos;
	_vehicleData = [_position, 0, (selectRandom vehPatrolBoat), side_green] call bis_fnc_spawnvehicle;
	_vehicle = _vehicleData select 0;
	_vehicle enableDynamicSimulation true;
	_vehCrew = _vehicleData select 1;
	_groupVehicle = _vehicleData select 2;

	_beach = [_vehicle,0,200,0,0,90,1] call BIS_Fnc_findSafePos;
	_vehicle setdir ((_vehicle getRelDir _beach) + 180);

	_PP1 = [_position, 100, 200, 25, 2, 45, 0] call BIS_fnc_findSafePos;
	_pWP1 = _groupVehicle addWaypoint [_PP1, 5];
	_pWP1 setWaypointType "MOVE";
	_pWP1 setWaypointBehaviour "AWARE";
	_pWP1 setWaypointSpeed "LIMITED";

	_pWP1 = _groupVehicle addWaypoint [_PP1, 5];
	_pWP1 setWaypointType "CYCLE";
	_pWP1 setWaypointBehaviour "AWARE";
	_pWP1 setWaypointSpeed "LIMITED";

	_allGroups pushBack _groupVehicle;
	_allVehicles pushBack _vehicle;
	sleep 1;
} else {
	_buildings = nearestObjects [_markerPos,["Land_TTowerBig_1_F","Land_TTowerBig_2_F","Land_Communication_F"], _size];
	if (count _buildings > 0) then {
		_radioTower = _buildings select 0;

		if ((typeOf _radioTower == "Land_TTowerBig_1_F") OR (typeOf _radioTower == "Land_TTowerBig_2_F")) then {
			private ["_pos","_pos2","_dir"];
			_pos = getPosATL _radioTower;
			_dir = getDir _radioTower;
			_pos2 = _pos getPos [2,_dir];
			_pos2 set [2,23.1];
			if (typeOf _radioTower == "Land_TTowerBig_2_F") then {
				_pos2 = _pos getPos [1,_dir];
				_pos2 set [2,24.3];
			};
			_unit = _tempGroup createUnit [sol_SN, _markerPos, [], _dir, "NONE"];
			_unit setPosATL _pos2;
			_unit forceSpeed 0;
			_unit setUnitPos "UP";
		};
	};

	if (_isFrontline) then {
		_base = [bases,_markerPos] call BIS_fnc_nearestPosition;
		if ((_base in mrkFIA) or ((getMarkerPos _base) distance _markerPos > 1000)) then {
			_position = [_markerPos] call mortarPos;
			_vehicle = statMortar createVehicle _position;
			_vehicle enableDynamicSimulation true;
			_unit = ([_markerPos, 0, infGunner, _tempGroup] call bis_fnc_spawnvehicle) select 0;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
			sleep 1;
		};

		_roads = _markerPos nearRoads _size;
		if (count _roads != 0) then {
			_data = [_markerPos, _roads, statAT] call AS_fnc_spawnBunker;
			_allVehicles pushBack (_data select 0);
			_vehicle = (_data select 1);
			_vehicle enableDynamicSimulation true;
			_allVehicles pushBack _vehicle;
			_unit = ([_markerPos, 0, infGunner, _tempGroup] call bis_fnc_spawnvehicle) select 0;
			_unit moveInGunner _vehicle;
		};
	};
};

_allGroups pushBack _tempGroup;

_position = _markerPos findEmptyPosition [5,_size,enemyMotorpoolDef];
if !(count _position == 0) then {
	_vehicle = createVehicle [selectRandom vehTrucks, _position, [], 0, "NONE"];
	_vehicle setDir random 360;
	_allVehicles pushBack _vehicle;
	sleep 1;
};

// spawn garrison squad
_groupType = [infSquad, side_green] call AS_fnc_pickGroup;
_groupGarrison = [_markerPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
_initialGroupSetup pushBack [_groupType, "garrison", _markerPos];
_allGroups pushBack _groupGarrison;

// spawn AA
if (_marker in puestosAA) then {
	while {true} do {
		_spawnPos = [_markerPos, 50 + (random 100), random 360] call BIS_fnc_relPos;
		if (!surfaceIsWater _spawnPos) exitWith {};
	};
	_groupType = [infAA, side_green] call AS_fnc_pickGroup;
	_group = [_spawnPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
	_initialGroupSetup pushBack [_groupType, "patrol", _spawnPos];
	[_group, _markerPos, 75, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
	[_group, _marker, (units _group), 400, true] spawn AS_fnc_monitorGroup;
	_localIDs pushBack (_group call BIS_fnc_netId);
	grps_VCOM pushBackUnique (_group call BIS_fnc_netId);
	_allGroups pushBack _group;
	sleep 1;
};

while {true} do {
	_spawnPos = [_markerPos, 50 + (random 100), random 360] call BIS_fnc_relPos;
	if (!surfaceIsWater _spawnPos) exitWith {};
};
_groupType = [infSquad, side_green] call AS_fnc_pickGroup;
_groupPatrol = [_spawnPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
_initialGroupSetup pushBack [_groupType, "patrol", _spawnPos];
[_groupPatrol, _markerPos, 300, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
[_groupPatrol, _marker, (units _groupPatrol), 400, true] spawn AS_fnc_monitorGroup;
_localIDs pushBack (_groupPatrol call BIS_fnc_netId);
grps_VCOM pushBackUnique (_groupPatrol call BIS_fnc_netId);
_allGroups pushBack _groupPatrol;

{
	_tempGroup = _x;
	{
		[_x] spawn genInitBASES;
		_allSoldiers pushBack _x;
	} forEach (units _tempGroup);
} forEach _allGroups;

if (_marker in puertos) then {
	_crate addItemCargo ["V_RebreatherIA",round random 5];
	_crate addItemCargo ["G_I_Diving",round random 5];
};

sleep 3;

publicVariable "grps_VCOM";
([_marker,count _allSoldiers] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];
[_groupGarrison,_size min 50] spawn AS_fnc_forceGarrison;

_observer = objNull;
if ((random 100 < (((server getVariable "prestigeNATO") + (server getVariable "prestigeCSAT"))/10)) AND (spawner getVariable _marker)) then {
	_position = [];
	_group = createGroup civilian;
	while {true} do {
		_position = [_markerPos, round (random _size), random 360] call BIS_Fnc_relPos;
		if !(surfaceIsWater _position) exitWith {};
	};
	_observer = _group createUnit [selectRandom CIV_journalists, _position, [],0, "NONE"];
	[_observer] spawn CIVinit;
	_allGroups pushBack _group;
	[_group, _markerPos, 150, 5, "MOVE", "SAFE", "BLUE", "LIMITED", "STAG COLUMN", "", [2,6,10]] call CBA_fnc_taskPatrol;
};

{
	_x enableDynamicSimulation true;
	[_x] spawn genVEHinit;
} forEach _allVehicles;

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