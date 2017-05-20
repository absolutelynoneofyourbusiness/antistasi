if (!isServer and hasInterface) exitWith{};

params ["_marker", ["_localIDs", []]];
private ["_allGroups","_allSoldiers","_markerPos","_size","_data","_prestigeOPFOR","_prestigeBLUFOR","_isHostile","_isFrontline","_groupType","_groupParams","_group","_counter","_dog"];

_allGroups = [];
_allSoldiers = [];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;
_size = round (_size / 100);

_data = server getVariable _marker;
_prestigeOPFOR = _data select 2;
_prestigeBLUFOR = _data select 3;
_isHostile = true;

if (_marker in mrkAAF) then {
	_size = round (_size * ((_prestigeOPFOR + _prestigeBLUFOR)/100));
	_isFrontline = [_marker] call AS_fnc_isFrontline;
	if (_isFrontline) then {_size = _size * 2};
	_groupType = [infGarrisonSmall, side_green] call AS_fnc_pickGroup;
	_groupParams = [_markerPos, side_green, _groupType];

	if (random 10 < 5) then {
		_groupType = [opGroup_Sniper, side_red] call AS_fnc_pickGroup;
		_group = [_markerPos, side_red, _groupType] call BIS_Fnc_spawnGroup;
		{[_x, true] spawn CSATinit; _allSoldiers pushBack _x} forEach units _group;
		[_group, _markerPos, 150, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
		[_group, _marker, (units _group), 400, false] spawn AS_fnc_monitorGroup;
		_localIDs pushBack (_group call BIS_fnc_netId);
		grps_VCOM pushBackUnique (_group call BIS_fnc_netId);
		_allGroups pushBack _group;
	};
} else {
	_isHostile = false;
	_size = round (_size * (_prestigeBLUFOR/100));
	_groupParams = [_markerPos, side_blue, [guer_grp_sentry, "guer"] call AS_fnc_pickGroup];
};

if (_size < 1) then {_size = 1};

_counter = 0;
while {(spawner getVariable _marker) AND (_counter < _size)} do {
	_group = _groupParams call BIS_Fnc_spawnGroup;
	if (_isHostile) then {
		{[_x] spawn genInitBASES; _allSoldiers pushBack _x} forEach units _group;
		sleep 1;
		if (random 10 < 2.5) then {
			_dog = _group createUnit ["Fin_random_F",_markerPos,[],0,"FORM"];
			_allSoldiers pushBack _dog;
			[_dog] spawn guardDog;
		};
	} else {
		{[_x] spawn AS_fnc_initialiseFIAGarrisonUnit; _allSoldiers pushBack _x} forEach units _group;
	};
	[_group, _markerPos, 150, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
	[_group, _marker, (units _group), 400, true] spawn AS_fnc_monitorGroup;
	_localIDs pushBack (_group call BIS_fnc_netId);
	grps_VCOM pushBackUnique (_group call BIS_fnc_netId);
	_allGroups pushBack _group;
	_counter = _counter + 1;
};

// Dynamic Simulation
publicVariable "grps_VCOM";
([_marker,count _allSoldiers] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];

sleep 10;
{
	_x enableDynamicSimulation true;
} forEach _allGroups;

while {(count (_allSoldiers select {alive _x AND !captive _x}) > _reinfStrength) AND {spawner getVariable _marker}} do {
	if (_isHostile) then {
		while {([_markerPos, side_blue] call AS_fnc_proximityCheck) AND {spawner getVariable _marker}} do {
			sleep 10;
		};
	} else {
		while {([_markerPos, side_green] call AS_fnc_proximityCheck) AND {spawner getVariable _marker}} do {
			sleep 10;
		};
	};


	sleep 5;
};

sleep 5;

diag_log format ["Reduced garrison at %1", _marker];
if (spawner getVariable _marker) then {
	garrison setVariable [format ["%1_reduced", _marker],true,true];
};

//_marker remoteExec ["INT_Replenishment", HCattack];

waitUntil {sleep 3; !(spawner getVariable _marker) OR ({alive _x} count _allSoldiers == 0) OR ({fleeing _x} count _allSoldiers == {alive _x} count _allSoldiers)};

call {
	// Enemy garrison was overwhelmed
	if ((({alive _x} count _allSoldiers == 0) OR ({fleeing _x} count _allSoldiers == {alive _x} count _allSoldiers)) AND (_marker in mrkAAF)) then {
		[_markerPos] remoteExec ["patrolCA",HCattack];
	};

	// Zone was despawned
	if !(spawner getVariable _marker) exitWith {

	};
};

[_allGroups, _allSoldiers, _markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)], !_isHostile] spawn AS_fnc_despawnUnits;
grps_VCOM = grps_VCOM - _localIDs; publicVariable "grps_VCOM";

// If garrison was overwhelmed, respawn the zone after 30 minutes.
if (spawner getVariable _marker) then {
	sleep 1800;
	if (spawner getVariable _marker) then {
		waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};
		spawner setVariable [_marker,false,true];
		[_marker] call AS_fnc_respawnZone;
	};
};