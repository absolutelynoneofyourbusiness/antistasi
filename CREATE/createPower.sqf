if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_markerPos","_size","_isFrontline","_allVehicles","_allGroups","_allSoldiers","_workers","_patrolMarker","_currentStrength","_spawnPos","_groupType","_group","_dog","_flag","_truck","_maxStrength","_patrolParams","_observer","_unit"];

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;
_isFrontline = [_marker] call AS_fnc_isFrontline;
_patrolMarker = [_marker] call AS_fnc_createPatrolMarker;

_workers = [];

_currentStrength = 0;
while {(spawner getVariable _marker) AND (_currentStrength < 2)} do {
	while {true} do {
		_spawnPos = [_markerPos, 150 + (random 350) ,random 360] call BIS_fnc_relPos;
		if !(surfaceIsWater _spawnPos) exitWith {};
	};
	_groupType = [infPatrol, side_green] call AS_fnc_pickGroup;
	_group = [_spawnPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
	sleep 1;
	if (random 10 < 2.5) then {
		_dog = _group createUnit ["Fin_random_F",_spawnPos,[],0,"FORM"];
		[_dog] spawn guardDog;
	};
	[leader _group, _patrolMarker, "SAFE","SPAWNED", "NOVEH2"] execVM "scripts\UPSMON.sqf";
	_allGroups pushBack _group;
	_currentStrength = _currentStrength +1;
};

_flag = createVehicle [cFlag, _markerPos, [],0, "CAN_COLLIDE"];
_flag allowDamage false;
[_flag,"take"] remoteExec ["AS_fnc_addActionMP"];
_allVehicles pushBack _flag;

_spawnPos = _markerPos findEmptyPosition [10,_size*1.5,enemyMotorpoolDef];
_truck = createVehicle [selectRandom vehTrucks, _spawnPos, [], 0, "NONE"];
_truck setDir random 360;
_allVehicles pushBack _truck;
sleep 1;

_maxStrength = 1 max (round (_size/50));
_spawnPos = [];
_groupType = "";
_currentStrength = 0;
if (_isFrontline) then {_maxStrength = _maxStrength * 2};
while {(spawner getVariable _marker) AND (_currentStrength < _maxStrength)} do {
	if ((diag_fps > minimoFPS) OR (_currentStrength == 0)) then {
		_groupType = [infTeam, side_green] call AS_fnc_pickGroup;
		_group = [_markerPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
		_patrolParams = [leader _group, _marker, "SAFE","SPAWNED","NOVEH2","NOFOLLOW"];
		if (_currentStrength == 0) then {_patrolParams pushBack "FORTIFY"};
		_patrolParams execVM "scripts\UPSMON.sqf";
		_allGroups pushBack _group;
	};
	_currentStrength = _currentStrength + 1;
};

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
	[_observer, _marker, "SAFE", "SPAWNED","NOFOLLOW", "NOVEH2","NOSHARE","DoRelax"] execVM "scripts\UPSMON.sqf";
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
	_x enableDynamicSimulation true;
	[_x] spawn genVEHinit;
} forEach _allVehicles;

([_marker,_allGroups] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];

if !(_marker in destroyedCities) then {
	if ((daytime > 8) AND (daytime < 18)) then {
		_group = createGroup civilian;
		_allGroups pushBack _group;
		for "_i" from 1 to 8 do {
			_unit = _group createUnit [selectRandom CIV_workers, _markerPos, [],0, "NONE"];
			[_unit] spawn CIVinit;
			_workers pushBack _unit;
			sleep 0.5;
		};
		[_marker,_workers] spawn destroyCheck;
		[leader _group, _marker, "SAFE", "SPAWNED","NOFOLLOW", "NOSHARE","DORELAX"] execVM "scripts\UPSMON.sqf";
	};
};

// Dynamic Simulation
sleep 10;
{
	_x enableDynamicSimulation true;
} forEach _allGroups;

while {(count (_allSoldiers select {alive _x AND !captive _x}) > _reinfStrength) AND (spawner getVariable _marker)} do {
	while {(count ((_markerPos nearEntities ["Man", 1500]) select {side _x == side_blue}) < 1) AND (spawner getVariable _marker)} do {
		sleep 10;
	};

	sleep 5;
};

sleep 5;

diag_log format ["Reduced garrison at %1", _marker];
if (spawner getVariable _marker) then {
	garrison setVariable [format ["%1_reduced", _marker],true,true];
};

//_marker remoteExec ["INT_Replenishment", HCattack];

waitUntil {sleep 3; !(spawner getVariable _marker) OR ((count ((_markerPos nearEntities ["Man", (_size max 200)]) select {side _x == side_blue})) > (3*count (_allSoldiers select {alive _x AND !captive _x}))) OR !(garrison getVariable [format ["%1_reduced", _marker],false])};

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
	};
};

spawner setVariable [_marker,false,true];
waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

deleteMarker _patrolMarker;
[_allGroups, _allSoldiers + _workers, _allVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)])] spawn AS_fnc_despawnUnits;
if (!isNull _observer) then {deleteVehicle _observer};

if (spawner getVariable [format ["%1_respawning", _marker],false]) then {
	sleep 15;
	waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

	[_marker] call AS_fnc_respawnZone;
};