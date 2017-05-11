/*
 	Description:
		Spawn a transport truck and troops to insert

	Parameters:
		0: STRING/ARRAY - Marker name or position of zone to spawn the truck at
		1: ARRAY - Target position
		2: STRING - Type of truck to use
		3: STRING - Type of infantry group to use
		4: STRING - Side affiliation of both truck and troops
		5: STRING - Mission type of the infantry: patrol, none
		6: INT - Patrol radius around the target, 0 if not required
		7: INT - Duration of the infantry's mission -- 0 means no time limit for the infantry
		8: STRING - (optional) - Name of a variable to use as a flag for a successful insertion

 	Returns:
		0: OBJECT - Truck
		1: ARRAY - Crew
		2: GROUP - Group of the truck
		3: GROUP - Group of the troops

 	Example:
		_transportData = ["base_1", getMarkerPos "Dorida", enemyMotorpoolDef, infSquad, side_green, "none", 200, 15*60] call AS_fnc_transportTroops;
*/

params [
	["_spawnPosition", "base_4", ["", []]],
	["_targetPosition", [], [[], ""]],
	["_vehicleType", enemyMotorpoolDef, [""]],
	["_groupType", infSquad],
	["_side", side_green, [west]],
	["_order", "patrol", [""]],
	["_patrolRadius", 300, [0]],
	["_duration", 15, [0]],
	["_flagName", "", [""]]
];

private ["_group", "_wpVeh1", "_wpInf1", "_wpInf2"];

if (typeName _spawnPosition isEqualTo "STRING") then {
	_spawnPosition = getMarkerPos _spawnPosition;
};

if (typeName _targetPosition isEqualTo "STRING") then {
	_targetPosition = getMarkerPos _targetPosition;
};

([_spawnPosition, _targetPosition] call AS_fnc_findSpawnSpots) params ["_spawnPosition", "_direction"];

if (_flagName == "") then {
	_flagName = format ["transport_flag_%1", round (random 1000)];
};

missionNamespace setVariable [_flagName, false, true];

// spawn the truck
([_spawnPosition, _direction, _vehicleType, _side] call bis_fnc_spawnvehicle) params ["_vehicle", "_vehicleCrew", "_vehicleGroup"];
[_vehicle, 10] spawn AS_fnc_protectVehicle;
_vehicleGroup allowFleeing 0;

// spawn the troops, place them in the cargo hold
_groupType = [_groupType, side_green] call AS_fnc_pickGroup;
_group = [_spawnPosition, _side, _groupType] call BIS_Fnc_spawnGroup;

{
	_x assignAsCargo _vehicle;
	_x moveInCargo _vehicle;
} forEach units _group;

// initialise the spawned units/vehicle
if (_side isEqualTo side_red) then {
	[_vehicle] spawn CSATVEHinit;
	{[_x] spawn CSATinit} forEach _vehicleCrew;
} else {
	[_vehicle] spawn genVEHinit;
	{[_x] spawn genInit} forEach _vehicleCrew + (units _group);
};

_group enableDynamicSimulation true;
[_group, _vehicle, _targetPosition] spawn {
	waitUntil {sleep 2; (_this select 1) distance2D (_this select 2) < 100};
	(_this select 0) enableDynamicSimulation false;
};

// send the truck to the dropoff position
_wpVeh1 = _vehicleGroup addWaypoint [_targetPosition, 10];
_wpVeh1 setWaypointSpeed "FULL";
_wpVeh1 setWaypointBehaviour "CARELESS";
_wpVeh1 setWaypointType "TR UNLOAD";
_vehicle limitSpeed 60;

_wpInf1 = _group addWaypoint [_targetPosition, 10];
_wpInf1 setWaypointType "GETOUT";
_wpInf1 synchronizeWaypoint [_wpVeh1];

// send the truck back to base once all troops have dismounted
[_vehicleGroup, _spawnPosition, _targetPosition, _flagName] spawn {
	params ["_group", "_homePosition", "_target", "_varName"];
	private _truck = vehicle (leader _group);
	waitUntil {sleep 2; (count (assignedCargo _truck) < 1) OR {(!alive _truck)} OR {!canMove _truck}};
	[_group, _homePosition] spawn AS_fnc_QRF_RTB;
	missionNamespace setVariable [_varName, true, true];
};

call {
	if (_order == "none") exitWith {

	};

	if (_order == "patrol") exitWith {
		[_group, _targetPosition, _patrolRadius] call bis_fnc_taskPatrol
	};
};

if (_duration > 0) then {
	// call RTB function for infantry
	[_group, _spawnPosition, _duration] spawn {
		params ["_group", "_homePosition", "_delay"];
		sleep _delay;
		[_group, _homePosition] spawn AS_fnc_QRF_RTB;
		[[_group], units _group, []] spawn AS_fnc_despawnUnits;
	};
};

// return the data from the heli, the troops, and the name of the used variable to the calling script
[_vehicle, _vehicleCrew, _vehicleGroup, _group, _flagName]