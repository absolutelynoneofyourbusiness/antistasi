/*
 	Description:
		Spawn a transport helicopter and troops to insert

	Parameters:
		0: STRING/ARRAY - Marker name or position of zone to spawn the helicopter at
		1: ARRAY - Target position
		2: STRING - Type of helicopter to use
		3: STRING - Type of infantry group to use
		4: STRING - Side affiliation of both helicopter and troops
		5: STRING - Type of insert, fastrope or dismount
		6: ARRAY - Minimum/maximum distance from target
		7: INT - Duration of the infantry's mission -- 0 means no time limit for the infantry
		8: POSITION - (optional) - Specific position to use for dismount/fastrope
		9: STRING - (optional) - Name of a variable to use as a flag for a successful insertion

 	Returns:
		0: OBJECT - Helicopter
		1: ARRAY - Crew
		2: GROUP - Group of the helicopter
		3: GROUP - Group of the troops

 	Example:
		_insertionData = ["airport_1", getMarkerPos "Chalkeia", heli_default, infTeam, side_green, "dismount", [100, 250], 0] call AS_fnc_insertTroops;
*/

params [
	["_spawnPosition","spawnCSAT",["", []]],
	["_targetPosition",[],[[]]],
	["_vehicleType", opHeliFR, [""]],
	["_groupType", opGroup_Recon_Team],
	["_side", side_red, [west]],
	["_order", "fastrope", [""]],
	["_minmaxDistances", [100, 300], [[]]],
	["_duration", 15, [1]],
	["_padPosition", [], [[]]],
	["_flagName", "", [""]]
];

private ["_distance", "_direction","_div","_approachPosition", "_group", "_wpAir1", "_wpAir2", "_padPosition", "_ghostPad", "_wpInf1","_vehicleData"];

_minmaxDistances params ["_minDistance", "_maxDistance"];

if (typeName _spawnPosition isEqualTo "STRING") then {
	_spawnPosition = getMarkerPos _spawnPosition;
};

if (typeName _targetPosition isEqualTo "STRING") then {
	_targetPosition = getMarkerPos _targetPosition;
};

_maxDistance = _maxDistance max (_minDistance + 50);

if (_flagName == "") then {
	_flagName = format ["insertion_flag_%1", round (random 1000)];
};

missionNamespace setVariable [_flagName, false, true];

// check for suitable landing positions
if (count _padPosition == 0) then {
	_padPosition = [_targetPosition, _minDistance, _maxDistance, 10, 0, 0.3, 0, [], [[], []]] call BIS_Fnc_findSafePos;
};

// break if no dismount position could be found
if ((_order isEqualTo "dismount") AND {(count _padPosition == 0)}) exitWith {diag_log format ["Error in insertTroops: no suitable place found between %2m and %3m from %1", _targetPosition, _minDistance, _maxDistance]};

// determine a position to start the final approach from
_distance = _spawnPosition distance2d _targetPosition;
_direction = _spawnPosition getDir _targetPosition;
_div = (floor (_distance / 500)) - 1;

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
[_vehicle, 10] spawn AS_fnc_protectVehicle;
_vehicleGroup allowFleeing 0;

// spawn the troops, place them in the cargo hold
_groupType = [_groupType, _side] call AS_fnc_pickGroup;
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
[_group, _vehicle, _padPosition] spawn {
	waitUntil {sleep 2; (_this select 1) distance2D (_this select 2) < 100};
	(_this select 0) enableDynamicSimulation false;
};

// send them to the first position, restrict speed afterwards
_wpAir1 = _vehicleGroup addWaypoint [_approachPosition, 50];
_wpAir1 setWaypointSpeed "FULL";
_wpAir1 setWaypointBehaviour "CARELESS";
_wpAir1 setWaypointCombatMode "BLUE";
_wpAir1 setWaypointStatements ["true", "(vehicle this) limitSpeed 80"];

call {
	if (_order isEqualTo "dismount") exitWith {
		// create a landing pad to allow for dismounts
		_padPosition set [2, 0];
		_ghostPad = createVehicle ["Land_HelipadEmpty_F", _padPosition, [], 0, "NONE"];

		// send the helicopter to the pad position, dismount the troops, lift speed restriction
		_wpAir2 = _vehicleGroup addWaypoint [_padPosition, 0];
		_wpAir2 setWaypointBehaviour "CARELESS";
		_wpAir2 setWaypointType "TR UNLOAD";
		_wpAir2 setWaypointCombatMode "GREEN";
		_wpAir2 setWaypointStatements ["true", "(vehicle this) land 'GET OUT'; (vehicle this) limitSpeed 250"];

		_wpInf1 = _group addWaypoint [_padPosition, 0];
		_wpInf1 setWaypointType "GETOUT";
		_wpInf1 synchronizeWaypoint [_wpAir2];
		_wpInf1 setWaypointStatements ["true", "[group this] call AS_fnc_clearWaypoints"];
	};

	// trigger the fast rope script once the helicopter is reasonably stationary
	if (_order isEqualTo "fastrope") exitWith {
		_wpAir2 = _vehicleGroup addWaypoint [_padPosition, 0];
		_wpAir2 setWaypointType "MOVE";
		_wpAir2 setWaypointBehaviour "CARELESS";
		_wpAir2 setWaypointCombatMode "GREEN";
		_wpAir2 setWaypointStatements ["true", "[vehicle this] spawn AS_fnc_triggerFastRope; (vehicle this) limitSpeed 250"];
	};
};

// send the helicopter back to base once all troops have dismounted
[_vehicleGroup, _spawnPosition, _flagName] spawn {
	params ["_group", "_homePosition", "_varName"];
	private _heli = vehicle (leader _group);
	waitUntil {sleep 2; (count (assignedCargo _heli) < 1) OR {(!alive _heli)} OR {!canMove _heli}};
	sleep 2;
	[_group, _homePosition] spawn AS_fnc_QRF_RTB;
	missionNamespace setVariable [_varName, true, true];
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

if (_order isEqualTo "dismount") then {
	deleteVehicle _ghostPad;
};

// return the data from the heli, the troops, and the name of the used variable to the calling script
[_vehicle, _vehicleCrew, _vehicleGroup, _group, _flagName]