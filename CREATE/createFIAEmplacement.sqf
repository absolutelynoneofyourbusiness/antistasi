if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_markerPos","_markerPos","_advanced","_allVehicles","_allGroups","_allSoldiers","_onRoad","_data","_infData","_group","_range","_road","_connectedRoads","_direction","_vehicle"];

_markerPos = getMarkerPos _marker;

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];

_advanced = false;
_onRoad = false;
if (isOnRoad _markerPos) then {_onRoad = true};

// BE module
if (activeBE) then {
	if (BE_current_FIA_RB_Style == 1) exitWith {_advanced = true};
};
// BE module

if (_onRoad) then {
	if (_advanced) then {
		_data = [_markerPos] call fnc_RB_placeDouble;
		_allVehicles = _data select 0;
		sleep 1;

		_infData = _data select 2;
		_group = [(_infData select 0), side_blue, ([guer_grp_AT, "guer"] call AS_fnc_pickGroup), [], [], [], [], [], (_infData select 1)] call BIS_Fnc_spawnGroup;
		{[_x] spawn AS_fnc_initialiseFIAGarrisonUnit} forEach units _group;
		(_data select 1) joinSilent _group;
		_allGroups pushBack _group;
	} else {
		_spawnData = [_markerPos, [ciudades, _markerPos] call BIS_fnc_nearestPosition] call AS_fnc_findRoadspot;
		if (count _spawnData < 1) exitWith {diag_log format ["Roadblock error report -- bad position: %1", _markerPos]};
		_roadPos = _spawnData select 0;
		_direction = _spawnData select 1;

		_vehicle = guer_veh_technical createVehicle _roadPos;
		_allVehicles pushBack _vehicle;
		_vehicle setDir _direction + 90;
		_vehicle lock 3;

		sleep 1;

		_group = [_markerPos, side_blue, ([guer_grp_AT, "guer"] call AS_fnc_pickGroup), [], [], [], [], [], _direction] call BIS_Fnc_spawnGroup;
		_unit = _group createUnit [guer_sol_RFL, _markerPos, [], 0, "NONE"];
		_unit moveInGunner _vehicle;
		{[_x] spawn AS_fnc_initialiseFIAGarrisonUnit} forEach units _group;
		_allGroups pushBack _group;
	};
} else {
	_group = [_markerPos, side_blue, ([guer_grp_sniper, "guer"] call AS_fnc_pickGroup)] call BIS_Fnc_spawnGroup;
	_group setBehaviour "STEALTH";
	_group setCombatMode "GREEN";
	{[_x] spawn AS_fnc_initialiseFIAGarrisonUnit;} forEach units _group;
	_allGroups pushBack _group;
};

{_allSoldiers pushBack _x} forEach units _group;

// Dynamic Simulation
([_marker,_allGroups] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];

{
	_x enableDynamicSimulation true;
	[_x] spawn genVEHinit
} forEach _allVehicles;

sleep 10;
{
	_x enableDynamicSimulation true;
} forEach _allGroups;

while {(count (_allSoldiers select {alive _x AND !captive _x}) > _reinfStrength) AND (spawner getVariable _marker) AND (_marker in puestosFIA)} do {
	while {(count ((_markerPos nearEntities ["Man", 1000]) select {_x getVariable ["OPFORSpawn",true]}) < 1) AND (spawner getVariable _marker) AND (_marker in puestosFIA)} do {
		sleep 10;
	};

	sleep 5;
};

waitUntil {sleep 3; !(spawner getVariable _marker) OR ({alive _x} count units _group == 0) OR !(_marker in puestosFIA)};

call {
	// Garrison was overwhelmed
	if ({alive _x} count units _group == 0) then {
		puestosFIA = puestosFIA - [_marker]; publicVariable "puestosFIA";
		mrkFIA = mrkFIA - [_marker]; publicVariable "mrkFIA";
		marcadores = marcadores - [_marker]; publicVariable "marcadores";
		[5,-5,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		deleteMarker _marker;
		if (_onRoad) then {
			FIA_RB_list = FIA_RB_list - [_marker]; publicVariable "FIA_RB_list";
			[["TaskFailed", ["", "Roadblock Lost"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
		} else {
			FIA_WP_list = FIA_WP_list - [_marker]; publicVariable "FIA_WP_list";
			[["TaskFailed", ["", "Watchpost Lost"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
			deleteVehicle (nearestObjects [getMarkerPos _marker, [guer_rem_des], 50] select 0);
		};
	};

	// Zone was despawned
	if !(spawner getVariable _marker) exitWith {

	};
};

waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};
[_allGroups, _allSoldiers, _allVehicles] spawn AS_fnc_despawnUnits;
spawner setVariable [_marker,false,true];