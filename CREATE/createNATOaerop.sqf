if (!isServer and hasInterface) exitWith {};

params ["_marker", ["_localIDs", []]];
private ["_allVehicles","_allGroups","_allSoldiers","_guerSoldiers","_guerVehicles","_markerPos","_guerGroups","_size","_support","_buildings","_statics","_pos1","_pos2","_direction","_group","_spawnPos","_vehicleType","_vehicle","_static","_observer","_counter","_unit","_flag","_maxVehicles","_groupType","_gunnerGroup"];

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];

_guerSoldiers = [];
_guerGroups = [];
_guerVehicles = [];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;

_support = (server getVariable "prestigeNATO")/100;
_statics = staticsToSave select {_x distance _markerPos < (_size max 50)};

_fn_initGroup = {
	params ["_group","_side"];
	_group enableDynamicSimulation true;
	if (_side == "FIA") then {
		_guerGroups pushBackUnique _group;
		{
			[_x] spawn AS_fnc_initialiseFIAGarrisonUnit;
			_guerSoldiers pushBackUnique _x;
		} forEach units _group;
		_group enableDynamicSimulation true;
	} else {
		_allGroups pushBackUnique _group;
		{
			[_x] spawn NATOinit;
			_allSoldiers pushBackUnique _x;
		} forEach units _group;
		_group enableDynamicSimulation true;
	};
};

// helicopters/planes and pilots
_buildings = nearestObjects [_markerPos, ["Land_LandMark_F"], _size / 2];
if (count _buildings > 1) then {
	_pos1 = getPos (_buildings select 0);
	_pos2 = getPos (_buildings select 1);
	_direction = [_pos1, _pos2] call BIS_fnc_DirTo;

	_spawnPos = [_pos1, 5,_direction] call BIS_fnc_relPos;
	_group = createGroup side_blue;

	_counter = 0;
	while {(spawner getVariable _marker) AND (_counter < round (5*_support))} do {
		_vehicleType = (planesNATO - bluCASFW) call BIS_fnc_selectRandom;
		_vehicle = createVehicle [_vehicleType, _spawnPos, [],3, "NONE"];
		_vehicle setDir (_direction + 90);
		_allVehicles pushBack _vehicle;
		sleep 1;

		_spawnPos = [_spawnPos, 20,_direction] call BIS_fnc_relPos;
		_unit = ([_markerPos, 0, bluPilot, _group] call bis_fnc_spawnvehicle) select 0;
		_counter = _counter + 1;
	};
};

[_group,"NATO"] call _fn_initGroup;

_spawnPos = [_markerPos, 3,0] call BIS_fnc_relPos;
_flag = createVehicle [bluFlag, _spawnPos, [],0, "CAN_COLLIDE"];
_flag allowDamage false;
_allVehicles pushBack _flag;
[_flag,"unit"] remoteExec ["AS_fnc_addActionMP"];
[_flag,"vehicle"] remoteExec ["AS_fnc_addActionMP"];
[_flag,"garage"] remoteExec ["AS_fnc_addActionMP"];

// vehicles
_maxVehicles = round ((_size/100)*_support);
_counter = 0;
while {(spawner getVariable _marker) AND (_counter < _maxVehicles)} do {
	if (diag_fps > minimoFPS) then {
		_vehicleType = vehNATO call BIS_fnc_selectRandom;
		_spawnPos = [_markerPos, 10, _size/2, 10, 0, 0.3, 0] call BIS_Fnc_findSafePos;
		_vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, "NONE"];
		_vehicle setDir random 360;
		_vehicle lock 3;
		_allVehicles pushBack _vehicle;
		sleep 1;
	};

	_counter = _counter + 1;
};

// garrison squad
_groupType = [bluSquad, side_blue] call AS_fnc_pickGroup;
_groupGarrison = [_markerPos, side_blue, _groupType] call BIS_Fnc_spawnGroup;
[_groupGarrison,"NATO"] call _fn_initGroup;
sleep 1;

// patrols
for "_i" from 1 to 3 do {
	while {true} do {
		_spawnPos = [_markerPos, random _size,random 360] call BIS_fnc_relPos;
		if (!surfaceIsWater _spawnPos) exitWith {};
	};

	_groupType = [bluTeam, side_blue] call AS_fnc_pickGroup;
	_group = [_spawnPos,side_blue, _groupType] call BIS_Fnc_spawnGroup;
	[_group,"NATO"] call _fn_initGroup;
	[_group, _markerPos, 300, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
	[_group, _marker, (units _group), 400, true] spawn AS_fnc_monitorGroup;
	_localIDs pushBack (_group call BIS_fnc_netId);
	grps_VCOM pushBackUnique (_group call BIS_fnc_netId);
	_allGroups pushBack _group;
	sleep 1;
};

_gunnerGroup = createGroup side_blue;
_guerGroups pushBackUnique _gunnerGroup;
_group = createGroup side_blue;
_guerGroups pushBackUnique _group;
_garrison = garrison getVariable [_marker,[]];
_strength = count _garrison;
_counter = 0;
while {(spawner getVariable _marker) AND (_counter < _strength)} do {
	_unitType = _garrison select _counter;

	call {
		if (_unitType == guer_sol_UN) exitWith {
			_unit = _gunnerGroup createUnit [_unitType, _markerPos, [], 0, "NONE"];
			_spawnPos = [_markerPos] call mortarPos;
			_vehicle = guer_stat_mortar createVehicle _spawnPos;
			_guerVehicles pushBack _vehicle;
			_unit assignAsGunner _vehicle;
			_unit moveInGunner _vehicle;
		};

		if ((_unitType == guer_sol_RFL) AND (count _statics > 0)) exitWith {
			_static = _statics select 0;
			if (typeOf _static == guer_stat_mortar) then {
				_unit = _gunnerGroup createUnit [_unitType, _markerPos, [], 0, "NONE"];
				_unit triggerDynamicSimulation false;
				_unit moveInGunner _static;
			} else {
				_unit = _gunnerGroup createUnit [_unitType, _markerPos, [], 0, "NONE"];
				_unit triggerDynamicSimulation false;
				_unit moveInGunner _static;
			};
			_statics = _statics - [_static];
		};

		_unit = _group createUnit [_unitType, _markerPos, [], 0, "NONE"];
		_unit triggerDynamicSimulation false;
		if (_unitType == guer_sol_SL) then {_group selectLeader _unit};
	};

	_counter = _counter + 1;
	sleep 0.5;
	if (count units _group == 8) then {
		_group = createGroup side_blue;
		_guerGroups pushBackUnique _group;
	};
};

{
	[_x,"FIA"] call _fn_initGroup;
} forEach _guerGroups;

{
	[_x] spawn VEHinit;
} forEach _guerVehicles;

{
	[_x] spawn NATOVEHinit;
} forEach _allVehicles;

// Dynamic Simulation
{
	_x enableDynamicSimulation true;
} forEach (_allVehicles + _guerVehicles);

publicVariable "grps_VCOM";
([_marker,count _allSoldiers] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];
[_groupGarrison,_size min 50] spawn AS_fnc_forceGarrison;

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
	_group enableDynamicSimulation true;
	_allGroups pushBack _group;
	[_observer,_marker,"observe"] spawn AS_fnc_addToUPSMON;
};


while {(count (_allSoldiers select {alive _x AND !captive _x}) > _reinfStrength) AND (spawner getVariable _marker)} do {
	while {(count ((_markerPos nearEntities ["Man", 1000]) select {_x getVariable ["OPFORSpawn",true]}) < 1) AND (spawner getVariable _marker)} do {
		sleep 10;
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

_soldiers =+ (_allSoldiers + _guerSoldiers);

waitUntil {sleep 3; !(spawner getVariable _marker) OR ((count ((_markerPos nearEntities ["Man", (_size max 200)]) select {_x getVariable ["OPFORSpawn",true]})) > (3*count (_soldiers select {alive _x AND !captive _x}))) OR !(garrison getVariable [format ["%1_reduced", _marker],false])};

call {
	// Garrison was overwhelmed
	if ((count ((_markerPos nearEntities ["Man", (_size max 200)]) select {_x getVariable ["OPFORSpawn",true]})) > (3*count (_soldiers select {alive _x AND !captive _x}))) exitWith {
		[_marker] remoteExec ["mrkLOOSE",2];
	};

	// Zone was despawned or modified
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

if (spawner getVariable [format ["%1_respawning", _marker],false]) exitWith {
	sleep 1;

	{
		deleteVehicle _x;
	} forEach (_soldiers + _allVehicles + _guerVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)]));

	{
		_x deleteGroupWhenEmpty true;
	} forEach (_allGroups + _guerGroups);

	grps_VCOM = grps_VCOM - _localIDs; publicVariable "grps_VCOM";

	sleep 2;
	[_marker] call AS_fnc_respawnZone;
};

waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

[_allGroups + _guerGroups, _soldiers, _allVehicles + _guerVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)])] spawn AS_fnc_despawnUnits;
if (!isNull _observer) then {deleteVehicle _observer};
grps_VCOM = grps_VCOM - _localIDs; publicVariable "grps_VCOM";