if (!isServer and hasInterface) exitWith{};

/*
 	Description:
		Spawns 1-2 vehicles, with or without troops, and dispatches them to the target area

	Parameters:
		0: STRING/ARRAY - Marker name or position of zone to spawn the units at
		1: ARRAY - Target position
		2: STRING - Composition to be used: destroy, transport, mixed
		3: STRING - Size of the force: small, large
		4: INT - Duration of the mission, units will RTB afterwards
		5: INT - (optional) - Patrol radius for dismounted troops in the target area
		6: STRING - (optional) - Variable to be used as a flag for status of the force, will be set to true once all units are dead or have despawned

 	Returns:
		Nothing

 	Example:
		["airport_1", getMarkerPos "Ioannina", "transport", "small", 15*60, 250] remoteExec ["enemyQRF", HCattack];
*/

params [
	["_startPosition", "spawnCSAT", [""]],
	["_targetPosition", [], [[]]],
	["_composition", "transport", [""]],
	["_size", "small", [""]],
	["_duration", 15, [1]],
	["_searchAreaRadius", 100, [1]],
	["_varName", "", []],
	["_allGroups", [], [[]], 0],
	["_allSoldiers", [], [[]], 0],
	["_allVehicles", [], [[]], 0]
];

private ["_bases","_airports","_type","_method","_side","_faction","_lead","_transportType","_dismountGroupType","_dismountGroupEscort","_spawnPosition","_endTime","_vehicleData","_dismountFlag","_dismountGroup","_rallyPoint","_transport", "_endTime"];

_endTime = [date select 0, date select 1, date select 2, date select 3, (date select 4) + _duration];
_endTime = dateToNumber _endTime;

if !(_varName isEqualTo "") then {
	server setVariable [_varName, false, true];
};

// FIA bases/airports
_bases = bases arrayIntersect mrkAAF;
_airports = aeropuertos arrayIntersect mrkAAF;

// setup the default configuration
_type = ["air", "land"] select (_startPosition in _bases);
_method = ["land", "rope"] select (_startPosition == "spawnCSAT");
_side = [side_green, side_red] select (_startPosition == "spawnCSAT");
_faction = ["GREEN", "RED"] select (_startPosition == "spawnCSAT");
_dismountFlag = format ["QRF_%1", round (random 1000)];

call {
	// main force, army
	if (_startPosition in _bases) exitWith {
		_lead = [selectRandom vehLead, selectRandom vehAPC] select (toLower _size isEqualTo "large");
		_transportType = enemyMotorpoolDef;
		_dismountGroupType = [[infTeam, infSquad] select (toLower _size isEqualTo "large"), side_green] call AS_fnc_pickGroup;
	};

	// main force, air force
	if (_startPosition in _airports) exitWith {
		_lead = heli_escort;
		_transportType = [heli_default, heli_transport] select (toLower _size isEqualTo "large");
		_dismountGroupType = [[infTeam, infSquad] select (toLower _size isEqualTo "large"), side_green] call AS_fnc_pickGroup;
	};

	// support, air force
	if (_startPosition == "spawnCSAT") exitWith {
		_lead = opHeliSD;
		_transportType = opHeliFR;
		_dismountGroupType = [[opGroup_Recon_Team, opGroup_Squad] select (toLower _size isEqualTo "large"), side_red] call AS_fnc_pickGroup;
	};
};

_spawnPosition = getMarkerPos _startPosition;

_endTime = [date select 0, date select 1, date select 2, date select 3, (date select 4) + _duration];
_endTime = dateToNumber _endTime;

fn_addData = {
	params ["_vehicle", "_soldiers", "_group", ["_infGroup", []]];
	_allVehicles pushBack _vehicle;
	_allSoldiers = _allSoldiers + _soldiers;
	_allGroups pushBack _group;

	if (typeName _infGroup == "GROUP") then {
		_transport = _vehicle;
		_dismountGroup = _infGroup;
		_allGroups pushBack _infGroup;
		_allSoldiers = _allSoldiers + (units _infGroup);
	};
};

_rallyPoint = +_targetPosition;

call {
	if (_type == "air") exitWith {
		// spawn gunship
		if (_composition in ["destroy", "mixed"]) then {
			([_spawnPosition, _rallyPoint, _lead, _side, "loiter", _duration*60] call AS_fnc_spawnGunship) call fn_addData;
		};

		// give the lead helicopter a head start
		if (_composition isEqualTo "mixed") then {
			sleep 5;
		};

		// spawn transport
		if (_composition in ["transport", "mixed"]) then {
			([_spawnPosition, _rallyPoint, _transportType, _dismountGroupType, _side, "fastrope", [300, 550], 0, [], _dismountFlag] call AS_fnc_insertTroops) call fn_addData;
		};
	};

	if (_type == "land") exitWith {
		_rallyPoint = [_targetPosition, [_spawnPosition, _targetPosition] call AS_fnc_findDropoffPoint] select (_composition != "destroy");
		// spawn lead vehicle
		if (_composition in ["destroy", "mixed"]) then {
			([_spawnPosition, _rallyPoint, _lead, _side, "secure", _duration*60] call AS_fnc_spawnLeadVehicle) call fn_addData;
		};

		// give the lead vehicle a head start
		if (_composition isEqualTo "mixed") then {
			sleep 5;
		};

		// spawn transport
		if (_composition in ["transport", "mixed"]) then {
			([_spawnPosition, _rallyPoint, _transportType, _dismountGroupType, _side, "none", 300, 0, _dismountFlag] call AS_fnc_transportTroops) call fn_addData;
		};
	};
};

if (_composition in ["transport", "mixed"]) then {
	if (_searchAreaRadius != 0) then {
		waitUntil {sleep 2; (missionNamespace getVariable [_dismountFlag, false]) OR {(!alive _transport)}};
		if (missionNamespace getVariable [_dismountFlag, false]) then {
			[_dismountGroup, _targetPosition, _searchAreaRadius, round (_searchAreaRadius / 60), "MOVE", "AWARE", "YELLOW", "FULL", "STAG COLUMN", "", [3,6,9]] call CBA_fnc_taskPatrol;
			//[_dismountGroup, _targetPosition, _searchAreaRadius] call BIS_fnc_taskPatrol;
		};
	};

	missionNamespace setVariable [_dismountFlag, nil, true];
};

diag_log format ["groups: %1; soldiers: %2; vehicles: %3", _allGroups, _allSoldiers, _allVehicles];

waitUntil {sleep 10; (dateToNumber date > _endTime) OR {({alive _x AND !captive _x} count _allSoldiers == 0)}};

if !(_varName isEqualTo "") then {
	server setVariable [_varName,true,true];
};

[_allGroups, _allSoldiers, _allVehicles] spawn AS_fnc_despawnUnits;