if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_allVehicles","_allGroups","_allSoldiers","_markerPos","_spawnPos","_size","_statics","_buildings","_groupGunners","_building","_type","_vehicle","_unit","_flag","_direction","_antenna","_garrison","_strength","_counter","_observer","_group"];

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;
_isFrontline = [_marker] call AS_fnc_isFrontline;

_buildings = nearestObjects [_markerPos, listMilBld, _size*1.5];
_statics = staticsToSave select {_x distance _markerPos < (_size max 50)};

_groupGunners = createGroup side_green;
_allGroups pushBack _groupGunners;
for "_i" from 0 to (count _buildings) - 1 do {
	_building = _buildings select _i;
	_type = typeOf _building;
	call {
		if 	((_type == "Land_Cargo_HQ_V1_F") OR (_type == "Land_Cargo_HQ_V2_F") OR (_type == "Land_Cargo_HQ_V3_F")) exitWith {
			_vehicle = createVehicle [guer_stat_AA, (_building buildingPos 8), [],0, "CAN_COLLIDE"];
			_vehicle setPosATL [(getPos _building select 0),(getPos _building select 1),(getPosATL _vehicle select 2)];
			_vehicle setDir (getDir _building);
			_vehicle enableDynamicSimulation true;
			_unit = _groupGunners createUnit [guer_sol_AR, _markerPos, [], 0, "NONE"];
			_unit triggerDynamicSimulation false;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
			sleep 1;
		};

		if 	((_type == "Land_Cargo_Patrol_V1_F") or (_type == "Land_Cargo_Patrol_V2_F") or (_type == "Land_Cargo_Patrol_V3_F")) exitWith {
			_vehicle = createVehicle [guer_stat_MGH, (_building buildingPos 1), [], 0, "CAN_COLLIDE"];
			_direction = (getDir _building) - 180;
			_spawnPos = [getPosATL _vehicle, 2.5, _direction] call BIS_Fnc_relPos;
			_vehicle setPosATL _spawnPos;
			_vehicle setDir (getDir _building) - 180;
			_vehicle enableDynamicSimulation true;
			_unit = _groupGunners createUnit [guer_sol_AR, _markerPos, [], 0, "NONE"];
			_unit triggerDynamicSimulation false;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
			sleep 1;
		};

		if 	(_type in listbld) then {
			_vehicle = createVehicle [guer_stat_MGH, (_building buildingPos 11), [], 0, "CAN_COLLIDE"];
			_vehicle enableDynamicSimulation true;
			_unit = _groupGunners createUnit [guer_sol_AR, _markerPos, [], 0, "NONE"];
			_unit triggerDynamicSimulation false;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
			sleep 1;
			_vehicle = createVehicle [guer_stat_MGH, (_building buildingPos 13), [], 0, "CAN_COLLIDE"];
			_vehicle enableDynamicSimulation true;
			_unit = _groupGunners createUnit [guer_sol_AR, _markerPos, [], 0, "NONE"];
			_unit triggerDynamicSimulation false;
			_unit moveInGunner _vehicle;
			_allVehicles pushBack _vehicle;
			sleep 1;
		};
	};
};

_flag = createVehicle [guer_flag, _markerPos, [],0, "CAN_COLLIDE"];
_flag allowDamage false;
_allVehicles pushBack _flag;
[_flag,"unit"] remoteExec ["AS_fnc_addActionMP"];
[_flag,"vehicle"] remoteExec ["AS_fnc_addActionMP"];
[_flag,"garage"] remoteExec ["AS_fnc_addActionMP"];

if (_marker in puertos) then {
	[_flag,"seaport"] remoteExec ["AS_fnc_addActionMP"];
};

_antenna = [antenas,_markerPos] call BIS_fnc_nearestPosition;
if (getPos _antenna distance _markerPos < 100) then {
	[_flag,"jam"] remoteExec ["AS_fnc_addActionMP"];
};

_group = createGroup side_blue;
_allGroups pushBack _group;
_garrison = garrison getVariable [_marker,[]];
_strength = count _garrison;
_counter = 0;
while {(spawner getVariable _marker) AND (_counter < _strength)} do {
	_unitType = _garrison select _counter;

	call {
		if (_unitType == guer_sol_UN) exitWith {
			_unit = _groupGunners createUnit [_unitType, _markerPos, [], 0, "NONE"];
			_unit triggerDynamicSimulation false;
			_spawnPos = [_markerPos] call mortarPos;
			_vehicle = guer_stat_mortar createVehicle _spawnPos;
			_allVehicles pushBack _vehicle;
			_vehicle enableDynamicSimulation true;
			[_vehicle] execVM "scripts\UPSMON\MON_artillery_add.sqf";
			_unit assignAsGunner _vehicle;
			_unit moveInGunner _vehicle;
		};

		if ((_unitType == guer_sol_RFL) AND (count _statics > 0)) exitWith {
			_static = _statics select 0;
			if (typeOf _static == guer_stat_mortar) then {
				_unit = _groupGunners createUnit [_unitType, _markerPos, [], 0, "NONE"];
				_unit triggerDynamicSimulation false;
				_unit moveInGunner _static;
				[_static] execVM "scripts\UPSMON\MON_artillery_add.sqf";
			} else {
				_unit = _groupGunners createUnit [_unitType, _markerPos, [], 0, "NONE"];
				_unit triggerDynamicSimulation false;
				_unit moveInGunner _static;
			};
			_statics = _statics - [_static];
			_static enableDynamicSimulation true;
		};

		_unit = _group createUnit [_unitType, _markerPos, [], 0, "NONE"];
		_unit triggerDynamicSimulation false;
		if (_unitType == guer_sol_SL) then {_group selectLeader _unit};
	};

	_counter = _counter + 1;
	sleep 0.5;
	if (count units _group == 8) then {
		_group = createGroup side_blue;
		_allGroups pushBack _group;
	};
};

{
	_x enableDynamicSimulation true;
	[leader _x,_marker,"fortify"] spawn AS_fnc_addToUPSMON;
} forEach _allGroups;

{
	_x enableDynamicSimulation true;
	[_x] spawn VEHinit;
} forEach _allVehicles;

{
	_group = _x;
	{
		[_x] spawn AS_fnc_initialiseFIAGarrisonUnit;
		_allSoldiers pushBack _x;
	} forEach units _group;
} forEach _allGroups;

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
	_observer triggerDynamicSimulation false;
	_allGroups pushBack _group;
	[_observer, _marker, "SAFE", "SPAWNED","NOFOLLOW", "NOVEH2","NOSHARE","DoRelax"] execVM "scripts\UPSMON.sqf";
};


// Dynamic Simulation
sleep 10;
{
	_x enableDynamicSimulation true;
} forEach _allGroups;

while {(count (_allSoldiers select {alive _x AND !captive _x}) > 0) AND (spawner getVariable _marker)} do {
	while {(count ((_markerPos nearEntities ["Man", 1000]) select {_x getVariable ["OPFORSpawn",true]}) < 1) AND (spawner getVariable _marker)} do {
		sleep 10;
	};

	sleep 5;
};

sleep 5;

waitUntil {sleep 3; !(spawner getVariable _marker) OR ((count ((_markerPos nearEntities ["Man", (_size max 200)]) select {_x getVariable ["OPFORSpawn",true]})) > (3*count (_allSoldiers select {alive _x AND !captive _x})))};

call {
	// Garrison was overwhelmed
	if ((count ((_markerPos nearEntities ["Man", (_size max 200)]) select {_x getVariable ["OPFORSpawn",true]})) > (3*count (_allSoldiers select {alive _x AND !captive _x}))) exitWith {
		[_marker] remoteExec ["mrkLOOSE",2];
	};

	// Zone was despawned or modified
	if !(spawner getVariable _marker) exitWith {

	};
};

spawner setVariable [_marker,false,true];

if (spawner getVariable [format ["%1_respawning", _marker],false]) exitWith {
	sleep 1;

	{
		deleteVehicle _x;
	} forEach (_allSoldiers + _allVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)]));
	{
		_x deleteGroupWhenEmpty true;
	} forEach _allGroups;

	sleep 2;
	[_marker] call AS_fnc_respawnZone;
};

waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

[_allGroups, _allSoldiers, _allVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)])] spawn AS_fnc_despawnUnits;
if (!isNull _observer) then {deleteVehicle _observer};