/*
 	Description:
		Monitors a list of zones that have reported casualties, dispatches QRFs to zones in need of help

	Parameters:
		None

 	Returns:
		None

 	Example:
		ReinfMon = [] spawn reinforcementMonitor;
*/

if !(isServer) exitWith {};

#define AO_SIZE 		1500 	// radius around a zone to determine activity within a region
#define COOLDOWN 		1800 	// time before a zone is considered to quiet again
#define TIMEOUT 		600		// time between two subsequent reinforcements of the same zone
#define LARGE_TIMEOUT	1800	// cooldown between reinforcements of a zone when the region is considered hot
#define PERIOD 			60		// interval of the main loop
#define REGULAR_MIN		2		// minimum number of distress calls from a zone before anything is done about it
#define PRIORITY_MIN	10		// minimum number of diress calls from a zone to consider it a priority

#define RPL_INTERVAL	1800	// interval of patrol replacements

// weights for the selection of a zone to reinforce
#define WGT_BASE 		1
#define WGT_OP 			0.5
#define WGT_RES 		0.3
#define WGT_RB 			0.2
#define WGT_MTN 		0.7

params [
	["_priorityZones", []],
	["_regularZones", []],
	["_targets", []],
	["_weights", []],
	["_data", []],
	["_nextPatrol", diag_tickTime]
];

private ["_target", "_var"];

distressCalls = []; publicVariable "distressCalls";
distressZones = [];
resupplyQueue = []; publicVariable "resupplyQueue";

_fn_findTargets = {
	params ["_list", ["_targets", []], ["_weights", []]];
	private ["_zone"];

	{
		_zone = _x;
		call {
			if (_zone in (bases+aeropuertos)) exitWith {
				_targets pushBackUnique _zone;
				_weights pushBack WGT_BASE;
			};

			if (_zone in (puestos)) exitWith {
				_targets pushBackUnique _zone;
				_weights pushBack WGT_OP;
			};

			if (_zone in (colinasAA+power)) exitWith {
				_targets pushBackUnique _zone;
				_weights pushBack WGT_MTN;
			};

			if (_zone in (controles+colinas+ciudades)) exitWith {
				_targets pushBackUnique _zone;
				_weights pushBack WGT_RB;
			};

			if (_zone in (recursos+fabricas+puestos)) exitWith {
				_targets pushBackUnique _zone;
				_weights pushBack WGT_RES;
			};
		};
	} forEach _list;

	[_targets, _weights]
};

_fn_dispatch = {
	params ["_targetPosition", "_type", "_size"];
	private ["_base"];

	_base = [_targetPosition, false, true] call AS_fnc_findAirportForCA;
	if (_base != "") then {
		[_base, _targetPosition, _type, _size, 25*60, 250] remoteExec ["enemyQRF", HCattack];
	} else {
		_base = [_targetPosition, false, true] call AS_fnc_findBaseForCA;
		if (_base != "") then {
			[_base, _targetPosition, _type, _size, 25*60, 250] remoteExec ["enemyQRF", HCattack];
		} else {
			["spawnCSAT", _targetPosition, _type, _size, 25*60, 250] remoteExec ["enemyQRF", HCattack];
		};
	};

	diag_log format ["Units dispatched to %1 from %2", _targetPosition, _base];
};

waitUntil {sleep 1; allZonesSetup};

while {true} do {
	// ############ Reinforcements ############
	diag_log format ["active calls: %1; active reinforcements: %2; priority zones: %3", distressCalls, distressZones, _priorityZones];
	if (count distressCalls > 0) then {

		// remove zones that were overrun by now
		for "_i" from 0 to (count distressCalls - 1) do {
			if !((distressCalls select _i) in mrkAAF) then {
				distressCalls set [_i, -1];
			};
		};

		distressCalls = distressCalls - [-1];

		// prioritize zones with multiple active calls for help
		{
			_var = _x;
			call {
				if ({_x == _var} count distressCalls >= PRIORITY_MIN) exitWith {_priorityZones pushBackUnique _var};
				if ({_x == _var} count distressCalls >= REGULAR_MIN) exitWith {_regularZones pushBackUnique _var};
			};
		} forEach distressCalls;

		_data = [];

		call {
			if (count _priorityZones > 0) exitWith {
				_data = [_priorityZones] call _fn_findTargets;
			};

			if (count _regularZones > 0) exitWith {
				_data = [_regularZones] call _fn_findTargets;
			};
		};

		if (count _data != 0) then {
			_targets = _data select 0;
			_weights = _data select 1;
		};
	};

	if (count _targets > 0) then {

		while {(count _targets > 0)} do {
			_target = [_targets, _weights] call BIS_fnc_selectRandomWeighted;
			if (((server getVariable [format ["%1_reinfTime", _target], -TIMEOUT]) + TIMEOUT) < diag_tickTime) exitWith {};

			diag_log format ["%1 will not receive reinforcements, last wave sent at %2, current time is %3", _target, (server getVariable [format ["%1_reinfTime", _target], -TIMEOUT]), diag_tickTime];
			_weights set [_targets find _target, -1];
			_weights = _weights - [-1];
			_targets = _targets - [_target];
			_target = "";
		};

		diag_log format ["target: %1; options: %2; weights: %3; zones: %4; priority zones: %5", _target, _targets, _weights, distressCalls, _priorityZones];

		if !(_target isEqualTo "") then {
			call {
				// hot zone
				if ({getMarkerPos _x distance2D getMarkerPos _target < AO_SIZE} count distressZones > 3) exitWith {
					[getMarkerPos _target, "mixed", "large"] call _fn_dispatch;
					server setVariable [format ["%1_reinfTime", _target], diag_tickTime + LARGE_TIMEOUT];
				};

				// if reinforcements have already been dispatched to to this zone, send a stronger force
				if (_target in distressZones) exitWith {
					[getMarkerPos _target, "transport", "large"] call _fn_dispatch;
					server setVariable [format ["%1_reinfTime", _target], diag_tickTime + TIMEOUT];
				};

				[getMarkerPos _target, "transport", "small"] call _fn_dispatch;
				server setVariable [format ["%1_reinfTime", _target], diag_tickTime];
			};

			distressZones pushBackUnique _target;
			distressCalls = distressCalls - [_target];
			_priorityZones = _priorityZones - [_target];
			_targets = [];
			_weights = [];

			[_target] spawn {
				params ["_zone"];
				sleep COOLDOWN;
				if !(_zone in distressCalls) then {
					distressZones = distressZones - [_zone];
				};
			};
		};
	};

	// ############ Patrol Replacements ############
	if (count resupplyQueue > 0) then {

		// remove zones that were overrun by now
		for "_i" from 0 to (count resupplyQueue - 1) do {
			if !(((resupplyQueue select _i) select 1) in mrkAAF) then {
				resupplyQueue set [_i, -1];
			};
		};

		resupplyQueue = resupplyQueue - [-1];

		if (_nextPatrol < diag_tickTime) then {
			_targets = +resupplyQueue;
			_target = [];
			while {count _targets > 0} do {
				_var = selectRandom _targets;
				if (count (((_var select 1) nearEntities [solCat, 1500]) select {_x getVariable ["BLUFORSpawn", false]}) < 1) exitWith {_target = +_var};
				_targets = _targets - _var;
			};

			if (count _target > 0) then {
				_target spawn AS_fnc_replacePatrol;
				resupplyQueue = resupplyQueue - _target;
				_nextPatrol = diag_tickTime + RPL_INTERVAL;
			};
		};
	};

	sleep PERIOD;
};