params ["_unit", ["_container", ""], ["_combined", false],["_restoreGear",false]];
private ["_timeOut"];

#define DIS 50

_unit setVariable ["AS_cannotComply", true, true];

if ((!alive _unit) or (isPlayer _unit) or (vehicle _unit != _unit) or (player != leader group player) or (captive _unit)) exitWith {};
if (_unit getVariable ["inconsciente", false]) exitWith {};
if (_unit getVariable ["ayudando", false]) exitWith {_unit groupChat "I cannot go salvaging right now, I'm busy treating someone's wounds."};
if (_unit getVariable ["AS_storingGear", false] && !(_combined)) exitWith {diag_log "SG: unit already storing gear."};

if (typeName _container == "STRING") then {
	_containers = nearestObjects [position _unit, ["Car", "Tank"], DIS];
	if (count _containers > 0) then {
		_container = _containers select 0;
	} else {
		if (_unit distance2D cajaVeh < DIS) then {_container = cajaVeh};
	} ;
};

if (typeName _container == "STRING") exitWith {diag_log "SG: no containers found."};

_unit setVariable ["AS_cannotComply", nil, true];
_unit setVariable ["AS_storingGear", true, true];

_unit doMove (getPosATL _container);
_unit groupChat format ["Storing my gear in %1", getText (configFile >> "CfgVehicles" >> typeOf _container >> "DisplayName")];
_timeOut = time + 60;

waitUntil {sleep 1; !(alive _unit) OR !(alive _container) OR (_unit distance _container < 8) OR (_timeOut < time) OR (unitReady _unit)};
if ((_unit distance _container < 8) && (alive _unit)) then {
	_unit stop true;
	if (_restoreGear) then {
		[_unit, [_unit, "scav_inventory"]] call BIS_fnc_loadInventory;
		_unit setVariable ["gearStored",nil,true];
		_unit groupChat "Got my gear back, boss man.";
	} else {
		if !(_unit getVariable ["gearStored",false]) then {
			[_unit, _container, true] call AS_fnc_dropAllGear;
		} else {
			[_unit, _container] call AS_fnc_dropAllGear;
		};
		sleep 2;
		_unit stop false;
		if (vest _unit == "") then {_unit groupChat "I have stored all my gear."} else {_unit groupChat "I couldn't store my gear."};
	};
} else {
	_unit groupChat "Unable to comply.";
};

_unit doFollow player;
_unit setVariable ["AS_storingGear", nil, true];