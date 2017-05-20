if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_markerPos","_size","_isFrontline","_allVehicles","_allGroups","_allSoldiers","_workers","_currentStrength","_spawnPos","_groupType","_group","_dog","_flag","_truck","_maxStrength","_patrolParams","_observer","_unit","_hidden","_initialGroupSetup","_localIDs"];

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];
_workers = [];

_initialGroupSetup = [];
_localIDs = [];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;
_isFrontline = [_marker] call AS_fnc_isFrontline;

_flag = createVehicle [cFlag, _markerPos, [], 0, "CAN_COLLIDE"];
_flag allowDamage false;
[_flag,"take"] remoteExec ["AS_fnc_addActionMP",[0,-2] select isDedicated,_flag];
_allVehicles pushBack _flag;

_spawnPos = _markerPos findEmptyPosition [10,_size*1.5,enemyMotorpoolDef];
_truck = createVehicle [selectRandom vehTrucks, _spawnPos, [], 0, "NONE"];
_truck setDir random 360;
_allVehicles pushBack _truck;
sleep 1;

_groupType = [infTeam, side_green] call AS_fnc_pickGroup;
_groupGarrison = [_markerPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
_initialGroupSetup pushBack [_groupType, "garrison", _markerPos];
_allGroups pushBack _groupGarrison;

while {true} do {
	_spawnPos = [_markerPos, 50 + (random 100), random 360] call BIS_fnc_relPos;
	if (!surfaceIsWater _spawnPos) exitWith {};
};
_groupType = [infSquad, side_green] call AS_fnc_pickGroup;
_groupPatrol = [_spawnPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
if (random 10 < 2.5) then {
	_dog = _groupPatrol createUnit ["Fin_random_F",_spawnPos,[],0,"FORM"];
	[_dog] spawn guardDog;
};
_initialGroupSetup pushBack [_groupType, "patrol", _spawnPos];
[_groupPatrol, _markerPos, 150, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
[_groupPatrol, _marker, (units _groupPatrol), 400, true] spawn AS_fnc_monitorGroup;
_localIDs pushBack (_groupPatrol call BIS_fnc_netId);
grps_VCOM pushBackUnique (_groupPatrol call BIS_fnc_netId);
_allGroups pushBack _groupPatrol;

_observer = objNull;
if ((random 100 < (((server getVariable "prestigeNATO") + (server getVariable "prestigeCSAT"))/10)) AND (spawner getVariable _marker)) then {
	_group = createGroup civilian;
	while {true} do {
		_spawnPos = [_markerPos, round (random _size), random 360] call BIS_Fnc_relPos;
		if !(surfaceIsWater _spawnPos) exitWith {};
	};
	_observer = _group createUnit [selectRandom CIV_journalists, _spawnPos, [], 0, "NONE"];
	[_observer] spawn CIVinit;
	_allGroups pushBack _group;
	[_group, _markerPos, 150, 5, "MOVE", "SAFE", "BLUE", "LIMITED", "STAG COLUMN", "", [2,6,10]] call CBA_fnc_taskPatrol;
};

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

{
	[_x] spawn genVEHinit
} forEach _allVehicles;

([_marker,count _allSoldiers] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];
publicVariable "grps_VCOM";
[_groupGarrison,_size min 50] spawn AS_fnc_forceGarrison;

if !(_marker in destroyedCities) then {
	if ((daytime > 8) AND (daytime < 18)) then {
		_group = createGroup civilian;
		_allGroups pushBack _group;
		for "_i" from 1 to 8 do {
			_unit = _group createUnit [selectRandom CIV_workers, _markerPos, [], 0, "NONE"];
			[_unit] spawn CIVinit;
			_workers pushBack _unit;
			sleep 0.5;
		};
		[_marker,_workers] spawn destroyCheck;
	};
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

while {(count (_allSoldiers select {alive _x AND !captive _x}) > _reinfStrength) AND {spawner getVariable _marker}} do {
	while {([_markerPos, side_blue] call AS_fnc_proximityCheck) AND {spawner getVariable _marker}} do {
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
	{((count ((_markerPos nearEntities [baseClasses_PLAYER, (_size max 200)]) select {_x getVariable ["BLUFORSpawn",false]})) > (3*count (_allSoldiers select {alive _x AND !captive _x})))} OR
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
		spawner setVariable [format ["%1_respawning", _marker],true,true];
		reducedGarrisons = reducedGarrisons - [_marker];
		publicVariable "reducedGarrisons";
	};
};

spawner setVariable [_marker,false,true];
waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

[_allGroups, _allSoldiers + _workers, _allVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)])] spawn AS_fnc_despawnUnits;
if (!isNull _observer) then {deleteVehicle _observer};
grps_VCOM = grps_VCOM - _localIDs; publicVariable "grps_VCOM";

if (spawner getVariable [format ["%1_respawning", _marker],false]) then {
	sleep 15;
	waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

	[_marker] call AS_fnc_respawnZone;
};