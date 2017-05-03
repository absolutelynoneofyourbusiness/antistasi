/*
 	Description:
		Spawn a single armed transport plus a group of dismounts

	Parameters:
		0: STRING/ARRAY - Marker name or position of base to spawn the vehicle at
		1: ARRAY - Target position
		2: STRING - Type of vehicle to use
		2: STRING - Type of group to use
		4: STRING - Side affiliation of both vehicle and infantry
		5: STRING - Order of the group, either attack or reinforce
		6: INT - Duration of the mission, 0 means unlimited, despawning has to be done by the calling script
		7: STRING - (optional) - Name of a variable to use as a flag for a successful insertion

 	Returns:
		0: OBJECT - Vehicle
		1: ARRAY - Crew
		2: GROUP - Group of the vehicle

 	Example:
		_mechInfData = ["base_1", getMarkerPos "Dorida", selectRandom vehAPC, infSquad, side_green, "secure", 15*60] call AS_fnc_spawnMechInf;
*/

params [
	["_spawnPosition", "base_4", ["", []]],
	["_targetPosition",[],["", []]],
	["_vehicleType", selectRandom vehLead, [""]],
	["_groupType", infSquad],
	["_side", side_green, [west]],
	["_order", "attack", [""]],
	["_duration", 5*60, [1]],
	["_flagName", "", [""]]
];

private ["_wpVeh1", "_wpVeh2", "_rallyPoint", "_overwatchPos"];

if (typeName _spawnPosition isEqualTo "STRING") then {
	_spawnPosition = getMarkerPos _spawnPosition;
};

if (typeName _targetPosition isEqualTo "STRING") then {
	_targetPosition = getMarkerPos _targetPosition;
};

([_spawnPosition, _targetPosition] call AS_fnc_findSpawnSpots) params ["_spawnPosition", "_direction"];

if (_flagName == "") then {
	_flagName = format ["mechInf_flag_%1", round (random 1000)];
};

missionNamespace setVariable [_flagName, false, true];

// spawn the vehicle
([_spawnPosition, _direction, _vehicleType, _side] call bis_fnc_spawnvehicle) params ["_vehicle", "_vehicleCrew", "_vehicleGroup"];
[_vehicle, 10] spawn AS_fnc_protectVehicle;

// spawn the troops, place them in the cargo hold
_groupType = [_groupType, side_green] call AS_fnc_pickGroup;
_group = [_spawnPosition, _side, _groupType] call BIS_Fnc_spawnGroup;

{
	_x assignAsCargo _vehicle;
	_x moveInCargo _vehicle;
} forEach units _group;

(units _group) joinSilent _vehicleGroup;
_vehicleCrew = units _vehicleGroup;

// initialise the spawned units/vehicle
if (_side isEqualTo side_red) then {
	[_vehicle] spawn CSATVEHinit;
	{[_x] spawn CSATinit} forEach _vehicleCrew;
} else {
	[_vehicle] spawn genVEHinit;
	{[_x] spawn genInit} forEach _vehicleCrew;
};

_rallyPoint = [_spawnPosition, _targetPosition, 300, 600] call AS_fnc_findDropoffPoint;

// send it to the first position
_wpVeh1 = _vehicleGroup addWaypoint [_rallyPoint, 20];
_wpVeh1 setWaypointSpeed "FULL";
_wpVeh1 setWaypointBehaviour "AWARE";
_vehicle limitSpeed 75;

// set following behaviour according to order
switch (_order) do {
	case "reinforce": {
		[_vehicleGroup] spawn AS_fnc_clearWaypoints;
	};

	case "attack": {
		_wpVeh2 = _vehicleGroup addWaypoint [_targetPosition, 50];
		_wpVeh2 setWaypointType "SAD";
		_wpVeh2 setWaypointSpeed "LIMITED";
		_wpVeh2 setwaypointStatements ["true", "[group this] spawn AS_fnc_clearWaypoints"];
	};

	default {
		[_vehicleGroup] spawn AS_fnc_clearWaypoints;
	};
};

if (_duration > 0) then {
	// call RTB function
	[_vehicleGroup, _spawnPosition, _duration] spawn {
		params ["_group", "_homePosition", "_delay"];
		sleep _delay;
		[_group, _homePosition] spawn AS_fnc_QRF_RTB;
	};
};

// return the vehicle's data to the calling script to be used for checks, and the name of the used variable to the calling script
[_vehicle, _vehicleCrew, _vehicleGroup, _flagName]