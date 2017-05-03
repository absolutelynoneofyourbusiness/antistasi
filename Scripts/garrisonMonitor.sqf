if !(isServer) exitWith {};

#define THRESHOLD_LOW 5
#define THRESHOLD_MID 10
#define THRESHOLD_HIGH 15

#define COOLDOWN 3600
#define PERIOD 60

#define WGT_BASE 1
#define WGT_OP 0.5
#define WGT_RES 0.3
#define WGT_RB 0.2
#define WGT_MTN 0.7

GarMonZones = [];

private ["_targets","_weights","_marker","_target"];

waitUntil {sleep 1; allZonesSetup};

while {true} do {
	_targets = [];
	_weights = [];
	{
		_marker = _x;
		if (_marker in mrkAAF) then {
			call {
				if (_marker in (bases+aeropuertos)) exitWith {
					_targets pushBackUnique _marker;
					_weights pushBack WGT_BASE;
				};

				if (_marker in (puestos)) exitWith {
					_targets pushBackUnique _marker;
					_weights pushBack WGT_OP;
				};

				if (_marker in (colinasAA+power)) exitWith {
					_targets pushBackUnique _marker;
					_weights pushBack WGT_MTN;
				};

				if (_marker in (controles+colinas)) exitWith {
					_targets pushBackUnique _marker;
					_weights pushBack WGT_RB;
				};

				if (_marker in (recursos+fabricas+puestos)) exitWith {
					_targets pushBackUnique _marker;
					_weights pushBack WGT_RES;
				};
			}
		}
	} forEach (reducedGarrisons - GarMonZones);

	if (count _targets > 0) then {
		_target = [_targets, _weights] call BIS_fnc_selectRandomWeighted;

		diag_log format ["target: %1; options: %2; weights: %3; array: %4",_target,_targets,_weights,reducedGarrisons];

		if ({toLower _x find "int_" > 0} count misiones < 4) then {
			[_target] remoteExec ["INT_Replenishment", HCattack];
			GarMonZones pushBackUnique _target;
			[_target,COOLDOWN] spawn {
				params ["_zone","_time"];
				sleep ((_time/2) + random _time);
				GarMonZones = GarMonZones - [_zone];
			};
		};
	};

	sleep PERIOD;
};