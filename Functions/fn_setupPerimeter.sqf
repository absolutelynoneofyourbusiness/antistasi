params [["_units",groupSelectedUnits player]];
private ["_count","_coef","_distance","_direction","_position","_targetPos"];

if ({alive _x} count _units < 1) exitWith {diag_log format ["Error in setupPerimeter, %1 are all dead",_units]};

_count = count _units;
_coef = 360/_count;

for "_i" from 0 to (_count - 1) do {
	_distance = (floor random 10) + 10;
	_direction = _i * _coef;
	_position = [getPosATL (leader (group (_units select 0))), _distance, _direction] call BIS_fnc_relPos;
	_targetPos = [getPosATL (leader (group (_units select 0))), 100, _direction] call BIS_fnc_relPos;
	_units select _i doMove _position;
	_units select _i doWatch _targetPos;
	_units select _i setUnitPos "MIDDLE";
};