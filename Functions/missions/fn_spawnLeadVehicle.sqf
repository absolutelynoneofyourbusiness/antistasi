/*
 	Description:
		Spawn a single armed vehicle to serve as the recon element for a troop transport

	Parameters:
		0: STRING/ARRAY - Marker name or position of base to spawn the vehicle at
		1: ARRAY - Target position
		2: STRING - Type of vehicle to use
		3: STRING - Side affiliation of the vehicle
		4: STRING - Order of the vehicle, either secure or attack
		5: INT - Duration of the mission, 0 means unlimited, despawning has to be done by the calling script

 	Returns:
		0: OBJECT - Vehicle
		1: ARRAY - Crew
		2: GROUP - Group of the vehicle

 	Example:
		_vehicleData = ["base_1", getMarkerPos "Dorida", selectRandom vehLead, side_green, "secure", 15*60] call AS_fnc_spawnLeadVehicle;
*/

params [
	["_spawnPosition", "base_4", ["", []]],
	["_targetPosition",[],[[]]],
	["_vehicleType", selectRandom vehLead, [""]],
	["_side", side_green, [west]],
	["_order", "secure", [""]],
	["_duration", 5*60, [1]]
];

private ["_wpVeh1", "_wpVeh2"];

if (typeName _spawnPosition isEqualTo "STRING") then {
	_spawnPosition = getMarkerPos _spawnPosition;
};

if (typeName _targetPosition isEqualTo "STRING") then {
	_targetPosition = getMarkerPos _targetPosition;
};

([_spawnPosition, _targetPosition] call AS_fnc_findSpawnSpots) params ["_spawnPosition", "_direction"];

// spawn the vehicle
([_spawnPosition, _direction, _vehicleType, _side] call bis_fnc_spawnvehicle) params ["_vehicle", "_vehicleCrew", "_vehicleGroup"];
[_vehicle, 10] spawn AS_fnc_protectVehicle;

// initialise the spawned units/vehicle
if (_side isEqualTo side_red) then {
	[_vehicle] spawn CSATVEHinit;
	{[_x] spawn CSATinit} forEach _vehicleCrew;
} else {
	[_vehicle] spawn genVEHinit;
	{[_x] spawn genInit} forEach _vehicleCrew;
};

// send it to the first position
_wpVeh1 = _vehicleGroup addWaypoint [_targetPosition, 20];
_wpVeh1 setWaypointSpeed "FULL";
_wpVeh1 setWaypointBehaviour "AWARE";
_vehicle limitSpeed 75;

// set following behaviour according to order
switch (_order) do {
	case "secure": { //todo reintroduce the perimeter
		[_vehicleGroup] spawn AS_fnc_clearWaypoints;
	};

	case "attack": {
		_wpVeh2 = _vehicleGroup addWaypoint [_targetPosition, 50];
		_wpVeh2 setWaypointType "SAD";
		_wpVeh2 setWaypointSpeed "LIMITED";
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

// return the gunship's data to the calling script to be used for checks
[_vehicle, _vehicleCrew, _vehicleGroup]