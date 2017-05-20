if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_allVehicles","_allGroups","_allSoldiers","_workers","_markerPos","_flag","_group","_unit","_garrison","_statics","_strength","_counter","_gunnerGroup","_unitType","_spawnPos","_vehicle","_static","_observer"];

#define HQ_SIZE 50

_allVehicles = [];
_allGroups = [];
_allSoldiers = [];

_markerPos = getMarkerPos (_marker);
_statics = staticsToSave select {_x distance _markerPos < HQ_SIZE};

_gunnerGroup = createGroup side_blue;
_allGroups pushBack _gunnerGroup;
_group = createGroup side_blue;
_allGroups pushBack _group;
_garrison = garrison getVariable [_marker,[]];
_strength = count _garrison;
_counter = 0;
while {(spawner getVariable _marker) AND (_counter < _strength)} do {
	_unitType = _garrison select _counter;

	call {
		if (_unitType == guer_sol_UN) exitWith {
			_unit = _gunnerGroup createUnit [_unitType, _markerPos, [], 0, "NONE"];
			_unit triggerDynamicSimulation false;
			_spawnPos = [_markerPos] call mortarPos;
			_vehicle = guer_stat_mortar createVehicle _spawnPos;
			_vehicle enableDynamicSimulation true;
			_allVehicles pushBack _vehicle;
			_unit assignAsGunner _vehicle;
			_unit moveInGunner _vehicle;
		};

		if ((_unitType == guer_sol_RFL) AND (count _statics > 0)) exitWith {
			_static = _statics select 0;
			_static enableDynamicSimulation true;
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
		_allGroups pushBack _group;
	};
};

{
	_x enableDynamicSimulation true;
} forEach _allGroups;

{
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
		_spawnPos = [_markerPos, round (random HQ_SIZE), random 360] call BIS_Fnc_relPos;
		if !(surfaceIsWater _spawnPos) exitWith {};
	};
	_observer = _group createUnit [selectRandom CIV_journalists, _spawnPos, [],0, "NONE"];
	[_observer] spawn CIVinit;
	_allGroups pushBack _group;
	[_observer, _marker, "SAFE", "SPAWNED","NOFOLLOW", "NOVEH2","NOSHARE","DoRelax"] execVM "scripts\UPSMON.sqf";
};

waitUntil {sleep 3; !(spawner getVariable _marker) OR (spawner getVariable [format ["%1_respawning", _marker],false])};

diag_log "Respawning HQ";
spawner setVariable [_marker,false,true];

if (spawner getVariable [format ["%1_respawning", _marker],false]) exitWith {
	sleep 1;

	{
		deleteVehicle _x;
	} forEach _allSoldiers;
	{
		_x deleteGroupWhenEmpty true;
	} forEach _allGroups;

	sleep 2;
	[_marker] call AS_fnc_respawnZone;
};

waitUntil {sleep 1; !(spawner getVariable _marker)};

[_allGroups, _allSoldiers, _allVehicles, true] spawn AS_fnc_despawnUnits;
if !(isNull _observer) then {deleteVehicle _observer};