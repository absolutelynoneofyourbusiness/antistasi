if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_allVehicles","_allGroups","_allSoldiers","_markerPos","_size","_position","_bunker","_vehicle","_normalPos","_group","_unit","_groupType","_tempGroup","_hidden","_initialGroupSetup","_localIDs","_spawnPos"];

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];

_initialGroupSetup = [];
_localIDs = [];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;

_group = createGroup side_green;

_vehicle = createVehicle ["Land_BagBunker_Tower_F", _markerPos, [],0, "NONE"];
_vehicle setVectorUp (surfacenormal (getPosATL _vehicle));
_allVehicles pushBack _vehicle;
_vehicle setDir (markerDir _marker);
_normalPos = surfaceNormal (position _vehicle);
_vehicle setVectorUp _normalPos;

sleep 0.25;

_vehicle = createVehicle [cFlag, _markerPos, [],0, "NONE"];
_allVehicles pushBack _vehicle;

sleep 0.25;

_vehicle = createVehicle ["I_supplyCrate_F", _markerPos, [],0, "NONE"];
_allVehicles pushBack _vehicle;
[_vehicle] call cajaAAF;

sleep 0.25;

_position = _markerPos findEmptyPosition [5,50,enemyMotorpoolDef];
if !(count _position == 0) then {
	_vehicle = createVehicle [selectRandom vehTrucks, _position, [], 0, "NONE"];
	_vehicle setDir ((_vehicle getDir (_allVehicles select 0)) + 90);
	_allVehicles pushBack _vehicle;
};

sleep 1;

while {true} do {
	_spawnPos = [_markerPos, 50 + (random 100), random 360] call BIS_fnc_relPos;
	if (!surfaceIsWater _spawnPos) exitWith {};
};
_groupType = [infTeamATAA, side_green] call AS_fnc_pickGroup;
_groupPatrol = [_spawnPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
if (random 10 < 2.5) then {
	_dog = _groupPatrol createUnit ["Fin_random_F",_spawnPos,[],0,"FORM"];
	[_dog] spawn guardDog;
};
_initialGroupSetup pushBack [_groupType, "patrol", _spawnPos];
[_groupPatrol, _markerPos, 100, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
[_groupPatrol, _marker, (units _groupPatrol), 400, true] spawn AS_fnc_monitorGroup;
_localIDs pushBack (_groupPatrol call BIS_fnc_netId);
grps_VCOM pushBackUnique (_groupPatrol call BIS_fnc_netId);
_allGroups pushBack _groupPatrol;
_groupPatrol allowFleeing 0;

if !(worldName == "Tanoa") then {
	_position = [_markerPos] call mortarPos;
	_vehicle = statMortar createVehicle _position;
	_vehicle enableDynamicSimulation true;
	_unit = ([_markerPos, 0, infGunner, _groupPatrol] call bis_fnc_spawnvehicle) select 0;
	_unit moveInGunner _vehicle;
	_allVehicles pushBack _vehicle;
	sleep 1;
};

{
	_tempGroup = _x;
	{
		[_x] spawn genInitBASES; _allSoldiers pushBack _x
	} forEach units _tempGroup;
} forEach _allGroups;

{
	_x enableDynamicSimulation true;
	[_x] spawn genVEHinit;
} forEach _allVehicles;

publicVariable "grps_VCOM";
([_marker,count _allSoldiers] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];

{
	_x hideObjectGlobal true;
	_x enableSimulationGlobal false;
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
				_x enableSimulationGlobal false;
			} forEach _allSoldiers + _allVehicles;
			_hidden = true;

			{
				_x enableDynamicSimulation false;
			} forEach _allGroups;
		};
		sleep 1;
	};

	if (_hidden) then {
		{
			_x hideObjectGlobal false;
			_x enableSimulationGlobal true;
		} forEach _allSoldiers + _allVehicles;
		_hidden = false;

		{
			_x enableDynamicSimulation true;
		} forEach _allGroups;
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
	if (count (_allSoldiers select {alive _x AND !captive _x}) < 1) exitWith {
		[-5,0,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		[["TaskSucceeded", ["", localize "STR_TSK_WP_DESTROYED"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
		_mrk = format ["Dum%1",_marker];
		deleteMarker _mrk;
		mrkAAF = mrkAAF - [_marker];
		mrkFIA = mrkFIA + [_marker];
		publicVariable "mrkAAF";
		publicVariable "mrkFIA";
		[_markerPos] remoteExec ["patrolCA",HCattack];
		if (activeBE) then {["cl_loc"] remoteExec ["fnc_BE_XP", 2]};
		reducedGarrisons = reducedGarrisons - [_marker];
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
grps_VCOM = grps_VCOM - _localIDs; publicVariable "grps_VCOM";

if (spawner getVariable [format ["%1_respawning", _marker],false]) then {
	sleep 15;
	waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

	[_marker] call AS_fnc_respawnZone;
};