if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_markerPos","_size","_cmpInfo","_posCmp","_cmp","_objs","_allGroups","_allSoldiers","_allVehicles","_statics","_SPAA","_hasSPAA","_truck","_crate","_unit","_groupCrew","_groupGunners","_markerPatrol","_UAV","_groupUAV","_groupType","_groupPatrol","_fullStrength","_mrk"];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;

_allGroups = [];
_allSoldiers = [];
_allVehicles = [];
_statics = [];
_hasSPAA = false;
_groupGunners = createGroup side_red;

_cmpInfo = [_marker] call AS_fnc_selectCMPData;
_posCmp = _cmpInfo select 0;
_cmp = _cmpInfo select 1;

_objs = [_posCmp, 0, _cmp] call BIS_fnc_ObjectsMapper;

{
	call {
		if (typeOf _x == opSPAA) exitWith {_SPAA = _x; _allVehicles pushBack _x; _hasSPAA = true;_x enableDynamicSimulation true;};
		if (typeOf _x == opTruck) exitWith {_truck = _x; _allVehicles pushBack _truck};
		if (typeOf _x in [statMG, statAT, statAA, statAA2, statMGlow, statMGtower]) exitWith {_statics pushBack _x;_x enableDynamicSimulation true;};
		if (typeOf _x == statMortar) exitWith {_statics pushBack _x; [_x] execVM "scripts\UPSMON\MON_artillery_add.sqf";_x enableDynamicSimulation true;};
		if (typeOf _x == opCrate) exitWith {_crate = _x; _allVehicles pushBack _x};
		if (typeOf _x == opFlag) exitWith {_allVehicles pushBack _x};
	};
} forEach _objs;

_objs = _objs - [_truck];

if (_hasSPAA) then {
	_groupCrew = createGroup side_red;
	_unit = ([_markerPos, 0, opI_CREW, _groupCrew] call bis_fnc_spawnvehicle) select 0;
	_unit moveInGunner _SPAA;
	_unit = ([_markerPos, 0, opI_CREW, _groupCrew] call bis_fnc_spawnvehicle) select 0;
	_unit moveInCommander _SPAA;
	_SPAA lock 2;
	_allGroups pushBack _groupCrew;
	{[_x] spawn CSATinit; _allSoldiers pushBack _x} forEach units _groupCrew;
};

{
	_unit = ([_markerPos, 0, opI_CREW, _groupGunners] call bis_fnc_spawnvehicle) select 0;
	_unit moveInGunner _x;
	if (str typeof _x find statAA > -1) then {
		_unit = ([_markerPos, 0, opI_CREW, _groupGunners] call bis_fnc_spawnvehicle) select 0;
		_unit moveInCommander _x;
	};
} forEach _statics;

{[_x] spawn CSATinit; _allSoldiers pushBack _x} forEach units _groupGunners;
_allGroups pushBack _groupGunners;

_markerPatrol = createMarkerLocal [format ["specops%1", random 100],_posCmp];
_markerPatrol setMarkerShapeLocal "RECTANGLE";
_markerPatrol setMarkerSizeLocal [200,200];
_markerPatrol setMarkerTypeLocal "hd_warning";
_markerPatrol setMarkerColorLocal "ColorRed";
_markerPatrol setMarkerBrushLocal "DiagGrid";

[leader _groupGunners, _markerPatrol, "AWARE", "SPAWNED","NOVEH", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";

_UAV = createVehicle [opUAVsmall, _posCmp, [], 0, "FLY"];
_allVehicles pushBack _UAV;
createVehicleCrew _UAV;
_UAV enableDynamicSimulation true;
_groupUAV = group (crew _UAV select 1);
[leader _groupUAV, _markerPatrol, "SAFE", "SPAWNED","NOVEH", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";
{[_x] spawn genInitBASES; _allSoldiers pushBack _x} forEach units _groupUAV;
_allGroups pushBack _groupUAV;

_spawnGroup = {
	params ["_type","_spawnPos"];
	while {true} do {
		_spawnPos = [_markerPos, 10 + (random 50) ,random 360] call BIS_fnc_relPos;
		if (!surfaceIsWater _spawnPos) exitWith {};
	};
	_groupType = [_type, side_green] call AS_fnc_pickGroup;
	_groupPatrol = [_spawnPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
	sleep 1;
	[leader _groupPatrol, _marker, "SAFE","SPAWNED","NOFOLLOW","NOVEH2"] execVM "scripts\UPSMON.sqf";
	{[_x] spawn genInitBASES; _allSoldiers pushBack _x} forEach units _groupPatrol;
	_allGroups pushBack _groupPatrol;
};

{
	[_x] call _spawnGroup;
} forEach [infTeamATAA, infAA, infTeam];

{
	_x enableDynamicSimulation true;
	[_x] spawn genVEHinit;
} forEach _allVehicles;


// Dynamic Simulation
([_marker,_allGroups] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];

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

diag_log "Strength check triggered.";
if (spawner getVariable _marker) then {
	garrison setVariable [format ["%1_reduced", _marker],true,true];
};

if (_hasSPAA) then {
	waitUntil {sleep 3; !(spawner getVariable _marker) OR ((count ((_markerPos nearEntities ["Man", (_size max 200)]) select {side _x == side_blue})) > (3*count (_allSoldiers select {alive _x AND !captive _x})) AND !(alive _SPAA)) OR !(garrison getVariable [format ["%1_reduced", _marker],false])};

	call {
		// Garrison was overwhelmed
		if ((spawner getVariable _marker) AND !(_marker in mrkFIA)) exitWith {
			[-5,0,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
			[0,-20] remoteExec ["prestige",2];
			[["TaskSucceeded", ["", format [localize "STR_TSK_AAWP_DESTROYED", A3_Str_RED]]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
			_mrk = format ["Dum%1",_marker];
			deleteMarker _mrk;
			mrkAAF = mrkAAF - [_marker];
			mrkFIA = mrkFIA + [_marker];
			publicVariable "mrkAAF";
			publicVariable "mrkFIA";
			[_markerPos] remoteExec ["patrolCA",HCattack];
			if (activeBE) then {["cl_loc"] remoteExec ["fnc_BE_XP", 2]};
		};

		// Zone was despawned
		if !(spawner getVariable _marker) exitWith {

		};

		// Garrison was replenished
		if !(garrison getVariable [format ["%1_reduced", _marker],false]) exitWith {
			spawer setVariable [format ["%1_respawning", _marker],true,true];
		};
	};

} else {
	waitUntil {sleep 3; !(spawner getVariable _marker) OR ((count ((_markerPos nearEntities ["Man", (_size max 200)]) select {side _x == side_blue})) > (3*count (_allSoldiers select {alive _x AND !captive _x}))) OR !(garrison getVariable [format ["%1_reduced", _marker],false])};

	call {
		// Garrison was overwhelmed
		if ((spawner getVariable _marker) AND !(_marker in mrkFIA)) exitWith {
			[-5,0,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
			[0,-10] remoteExec ["prestige",2];
			[["TaskSucceeded", ["", format [localize "STR_TSK_AAWP_DESTROYED", A3_Str_RED]]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
			_mrk = format ["Dum%1",_marker];
			deleteMarker _mrk;
			mrkAAF = mrkAAF - [_marker];
			mrkFIA = mrkFIA + [_marker];
			publicVariable "mrkAAF";
			publicVariable "mrkFIA";
			[_markerPos] remoteExec ["patrolCA",HCattack];
			if (activeBE) then {["cl_loc"] remoteExec ["fnc_BE_XP", 2]};
		};

		// Zone was despawned
		if !(spawner getVariable _marker) exitWith {

		};

		// Garrison was replenished
		if !(garrison getVariable [format ["%1_reduced", _marker],false]) exitWith {
			spawer setVariable [format ["%1_respawning", _marker],true,true];
		};
	};
};

spawner setVariable [_marker,false,true];
waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

[_allGroups, _allSoldiers, _allVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)])] spawn AS_fnc_despawnUnits;


if (spawner getVariable [format ["%1_respawning", _marker],false]) then {
	sleep 15;
	waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

	[_marker] call AS_fnc_respawnZone;
};