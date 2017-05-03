/*
 	Description:
		Spawn an attack helicopter, send it on a mission, RTB after specified duration

	Parameters:
		0: STRING/ARRAY - Marker name or position of zone to spawn the helicopter at
		1: ARRAY - Target position
		2: STRING - Type of helicopter to use
		3: STRING - Side affiliation of the helicopter
		4: STRING - Order of the helicopter, either loiter or attack
		5: INT - Duration of the mission

 	Returns:
		0: OBJECT - Helicopter
		1: ARRAY - Crew
		2: GROUP - Group of the helicopter

 	Example:
		_gunshipData = ["airport_1", getMarkerPos "Ioannina", heli_escort, side_green, "loiter", 15*60] call AS_fnc_spawnGunship;
*/

params [
	["_spawnPosition","spawnCSAT",["", []]],
	["_targetPosition",[],[[]]],
	["_vehicleType", opHeliSD, [""]],
	["_side", side_red, [west]],
	["_order", "loiter", [""]],
	["_duration", 15*60, [1]]
];

private ["_distance", "_direction","_div","_approachPosition","_wpAir1","_wpAir2"];

#define	LOITERRADIUS	400

if (typeName _spawnPosition isEqualTo "STRING") then {
	_spawnPosition = getMarkerPos _spawnPosition;
};

if (typeName _targetPosition isEqualTo "STRING") then {
	_targetPosition = getMarkerPos _targetPosition;
};

// determine a position to start the final approach from
_distance = _spawnPosition distance2d _targetPosition;
_direction = _spawnPosition getDir _targetPosition;
_div = (floor (_distance / (LOITERRADIUS * 1.5))) - 1;

_x1 = _spawnPosition select 0;
_y1 = _spawnPosition select 1;
_x2 = _targetPosition select 0;
_y2 = _targetPosition select 1;

_x3 = (_x1 + _div*_x2) / (_div + 1);
_y3 = (_y1 + _div*_y2) / (_div + 1);
_z3 = 50;

_approachPosition = [_x3, _y3, _z3];

// spawn the helicopter
([_spawnPosition, _direction, _vehicleType, _side] call bis_fnc_spawnvehicle) params ["_vehicle", "_vehicleCrew", "_vehicleGroup"];
[_vehicle, true] remoteExec ["AS_fnc_lockVehicle", [0,-2] select isDedicated, true];
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
_wpAir1 = _vehicleGroup addWaypoint [_approachPosition, 50];
_wpAir1 setWaypointSpeed "FULL";
_wpAir1 setWaypointBehaviour "CARELESS";

// set following behaviour according to order
switch (_order) do {
	case "loiter": {
		_wpAir2 = _vehicleGroup addWaypoint [_targetPosition, LOITERRADIUS];
		_wpAir2 setWaypointType "LOITER";
		_wpAir2 setWaypointLoiterType "CIRCLE";
		_wpAir2 setWaypointLoiterRadius LOITERRADIUS;
		_wpAir2 setWaypointSpeed "LIMITED";
	};

	case "attack": { //todo reintroduce the attack orders
		_wpAir2 = _vehicleGroup addWaypoint [_targetPosition, 50];
		_wpAir2 setWaypointType "LOITER";
		_wpAir2 setWaypointLoiterType "CIRCLE";
		_wpAir2 setWaypointLoiterRadius LOITERRADIUS;
		_wpAir2 setWaypointSpeed "LIMITED";
	};

	default {

	};
};

// call RTB function
[_vehicleGroup, _spawnPosition, _duration] spawn {
	params ["_group", "_homePosition", "_delay"];
	sleep _delay;
	[_group, _homePosition] spawn AS_fnc_QRF_RTB;
};

// return the gunship's data to the calling script to be used for checks
[_vehicle, _vehicleCrew, _vehicleGroup]