params ["_isCom"];
private ["_vehicle", "_owner"];

_vehicle = cursortarget;

if (isNull _vehicle) exitWith {hint "You are not looking at any vehicle"};
if ({isPlayer _x} count crew _vehicle > 0) exitWith {hint "You cannot (un-)lock a vehicle with people inside."};

if !(isMultiplayer) exitWith {
	if (locked _vehicle > 1) then {
		_vehicle lock 0;
		hint "Vehicle unlocked";
	} else {
		_vehicle lock 2;
		hint "Vehicle locked";
	};
};

_owner = _vehicle getVariable ["duenyo", ""];

if (!(_isCom) AND {!(getPlayerUID player == _owner)}) exitWith {hint "You are not owner of this vehicle and you cannot unlock it"};

if (locked _vehicle > 1) then {
	[_vehicle, false] remoteExec ["AS_fnc_lockVehicle", [0,-2] select isDedicated, true];
	if (_isCom) then {_vehicle setVariable ["duenyo",nil,true]};
	hint "Vehicle unlocked";
} else {
	[_vehicle, true] remoteExec ["AS_fnc_lockVehicle", [0,-2] select isDedicated, true];
	hint "Vehicle locked";
};