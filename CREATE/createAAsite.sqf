if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_markerPos","_size","_isFrontline","_objs","_SPAA","_truck","_crate","_unit","_groupCrew","_groupGunners","_markerPatrol","_UAV","_groupUAV","_groupType","_groupPatrol","_fullStrength","_mrk","_hidden","_groupGarrison","_bldCount","_spawnPos","_tempGroup"];

[[],[],[],[],false,[],[],[]] params ["_allGroups","_allSoldiers","_allVehicles","_statics","_hasSPAA","_presetBuildings","_initialGroupSetup","_localIDs"];

_markerPos = getMarkerPos (_marker);
_size = [_marker] call sizeMarker;
_isFrontline = [_marker] call AS_fnc_isFrontline;

_groupGunners = createGroup side_red;

([_marker] call AS_fnc_selectCMPData) params ["_posCmp","_cmp"];
_objs = [_posCmp, 0, _cmp] call BIS_fnc_ObjectsMapper;

{
	call {
		if (typeOf _x == opSPAA) exitWith {_SPAA = _x; _allVehicles pushBack _x; _hasSPAA = true;_x enableDynamicSimulation true};
		if (typeOf _x == opTruck) exitWith {_truck = _x; _allVehicles pushBack _truck};
		if (typeOf _x in [statMG, statAT, statAA, statAA2, statMGlow, statMGtower]) exitWith {_statics pushBack _x;_x enableDynamicSimulation true};
		if (typeOf _x == statMortar) exitWith {_statics pushBack _x; _x enableDynamicSimulation true}; // UPSMON
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
};

{
	_unit = ([_markerPos, 0, opI_CREW, _groupGunners] call bis_fnc_spawnvehicle) select 0;
	_unit moveInGunner _x;
	if (str typeof _x find statAA > -1) then {
		_unit = ([_markerPos, 0, opI_CREW, _groupGunners] call bis_fnc_spawnvehicle) select 0;
		_unit moveInCommander _x;
	};
} forEach _statics;
_allGroups pushBack _groupGunners;

_UAV = createVehicle [opUAVsmall, _posCmp, [], 0, "FLY"];
_allVehicles pushBack _UAV;
createVehicleCrew _UAV;
_UAV enableDynamicSimulation true;
_groupUAV = group (crew _UAV select 1);
_allGroups pushBack _groupUAV;
[_groupUAV, _markerPos, _size] call bis_fnc_taskPatrol;

_bldCount = server getVariable [format ["%1_bldCount", _marker],5];
for "_i" from 1 to _bldCount do {
	if !(typeName (missionNamespace getVariable [format ["%1_cmp_%2", _marker,_i], ""]) == "STRING") then {
		_presetBuildings pushBackUnique (missionNamespace getVariable (format ["%1_cmp_%2", _marker,_i]));
	};
};

if (count _presetBuildings > 0) then {
	{
		_x hideObjectGlobal false;
		_x enableSimulationGlobal true;
	} count _presetBuildings;
};


while {true} do {
	_spawnPos = [_markerPos, 50 + (random 100) ,random 360] call BIS_fnc_relPos;
	if (!surfaceIsWater _spawnPos) exitWith {};
};

_groupType = [opGroup_Squad, side_red] call AS_fnc_pickGroup;
_groupPatrol = [_spawnPos, side_red, _groupType] call BIS_Fnc_spawnGroup;
_initialGroupSetup pushBack [_groupType,"patrol", _spawnPos];
[_groupPatrol, _markerPos, 300, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
[_groupPatrol, _marker, (units _groupPatrol), 400, true] spawn AS_fnc_monitorGroup;
_localIDs pushBack (_groupPatrol call BIS_fnc_netId);
grps_VCOM pushBackUnique (_groupPatrol call BIS_fnc_netId);
_allGroups pushBack _groupPatrol;

// spawn garrison team
_groupType = [[opI_AR,opI_MK2,opI_LAT,opI_AR,opI_MK2,opI_LAT], side_red] call AS_fnc_pickGroup;
_groupGarrison = [_markerPos, side_red, _groupType] call BIS_Fnc_spawnGroup;
_initialGroupSetup pushBack [_groupType, "garrison", _markerPos];
_allGroups pushBack _groupGarrison;

// spawn additional squad if location is near the front
if (_isFrontline) then {
	_groupType = [opGroup_Squad, side_red] call AS_fnc_pickGroup;
	_groupPatrol = [_spawnPos, side_red, _groupType] call BIS_Fnc_spawnGroup;
	_initialGroupSetup pushBack [_groupType, "patrol", _spawnPos];
	[_groupPatrol, _markerPos, _size min 100] call bis_fnc_taskPatrol;
	_allGroups pushBack _groupPatrol;
};

// initialise all units
{
	_tempGroup = _x;
	{
		[_x,true] spawn CSATinit;
		_allSoldiers pushBack _x;
	} forEach (units _tempGroup);
} forEach _allGroups;

sleep 1;

publicVariable "grps_VCOM";
[_groupGarrison,_size min 150] spawn AS_fnc_forceGarrison;

{
	_x enableDynamicSimulation true;
	[_x] spawn genVEHinit;
} forEach _allVehicles;

sleep 1;


([_marker,count _allSoldiers] call AS_fnc_setGarrisonSize) params ["_fullStrength","_reinfStrength"];

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

if (_hasSPAA) then {
	waitUntil {sleep 3;
		!(spawner getVariable _marker) OR
		{((count ((_markerPos nearEntities [solCat, (_size max 200)]) select {_x getVariable [ "BLUFORSpawn",false ]})) > (3*count (_allSoldiers select {alive _x AND !captive _x})) AND !(alive _SPAA))} OR
		{!(garrison getVariable [format ["%1_reduced", _marker],false])}
	};

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
	waitUntil {sleep 3;
		!(spawner getVariable _marker) OR
		{((count ((_markerPos nearEntities [solCat, (_size max 200)]) select {_x getVariable [ "BLUFORSpawn",false ]})) > (3*count (_allSoldiers select {alive _x AND !captive _x})))} OR
		{!(garrison getVariable [format ["%1_reduced", _marker],false])}
	};

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
			reducedGarrisons = reducedGarrisons - [_marker];
			publicVariable "reducedGarrisons";
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
};

spawner setVariable [_marker,false,true];
waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};
[_allGroups, _allSoldiers, _allVehicles + (_markerPos nearObjects ["Box_IND_Wps_F", (_size max 200)])] spawn AS_fnc_despawnUnits;
grps_VCOM = grps_VCOM - _localIDs; publicVariable "grps_VCOM";

{deleteVehicle _x} forEach _objs;

if (spawner getVariable [format ["%1_respawning", _marker],false]) then {
	sleep 15;
	waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

	[_marker] call AS_fnc_respawnZone;
};

if !(_marker in mrkFIA) then {
	if (count _presetBuildings > 0) then {
			{
				deleteVehicle _x;
			} count _presetBuildings;
		};
} else {
	if (count _presetBuildings > 0) then {
		{
			_x hideObjectGlobal true;
			_x enableSimulationGlobal false;
		} count _presetBuildings;
	};
};