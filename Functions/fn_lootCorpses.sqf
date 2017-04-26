/*
    Description:
        - Dispatches a single unit to collect gear from every corpse/surrender-box within a set distance

    Parameters:
        0: Unit
        1: Container to use for storage

    Returns:
        Nothing

    Example:
        [(groupSelectedUnits player) select 0, vehicle player] spawn AS_fnc_lootCorpses
*/

params ["_unit", "_targetContainer"];
private ["_corpses", "_corpse", "_foundCorpse", "_params", "_timeOut", "_containers", "_container", "_timer", "_box", "_boxes", "_foundBox"];

#define DIS 50
#define DUR 30

if ((!alive _unit) OR (isPlayer _unit) OR (vehicle _unit != _unit) OR (player != leader group player) OR (captive _unit)) exitWith {};
if (_unit getVariable "inconsciente") exitWith {};

if (_unit getVariable ["ayudando", false]) exitWith {_unit groupChat "I cannot grab gear right now, I'm busy treating someone's wounds."};
if (_unit getVariable ["AS_storingGear", false]) exitWith {_unit groupChat "I am currently storing my gear."};
if (_unit getVariable ["AS_lootingCorpses", false]) exitWith {_unit groupChat "I am already looking for gear."};

scopeName "main";

_corpses = [];
{
	if (_x distance _unit < DIS) then {
		if !(_x getVariable ["stripped", false]) then {
			_corpses pushBackUnique _x;
		};
	};
} forEach allDead;

_boxes = [];
{
	if (_x distance _unit < DIS) then {
		if !(_x getVariable ["stripped", false]) then {
			_boxes pushBackUnique _x;
		};
	};
} forEach (nearestObjects [position _unit, ["Box_IND_Wps_F"], DIS]);

if ((count _corpses == 0) && (count _boxes == 0)) exitWith {hintSilent "No corpses nearby."};

_unit setVariable ["AS_lootingCorpses", true, true];
_unit setBehaviour "SAFE";

_timer = time + 120;
while {true} do {
	scopeName "outerLoop";

	if !(behaviour _unit == "SAFE") exitWith {_unit groupChat "My spidey-senses are tinglin'."};
	if (_timer < time) exitWith {_unit groupChat "We should get going..."};
	_foundCorpse = false;
	{
		_corpse = _x;
		if !(_corpse getVariable ["stripped", false]) exitWith {
			_foundCorpse = true;
			_corpse setVariable ["stripped", true, true];
		};
	} forEach _corpses;

	if (_foundCorpse) then {
		_unit setBehaviour "SAFE";
		_params = [[_unit, _targetContainer, true], [_unit, "", true]] select (typeName _targetContainer == "STRING");
		_unit setVariable ["AS_storingGear", true, true];
		_params spawn AS_fnc_storeGear;

		waitUntil {sleep 1; !(alive _unit) OR !(_unit getVariable ["AS_storingGear", false]) OR (isNull _corpse) OR (_unit getVariable ["AS_cannotComply", false])};
		if (_unit getVariable ["AS_cannotComply", false]) then {breakTo "main"};

		_unit stop false;
		_unit doMove (getPosATL _corpse);
		_timeOut = time + 60;

		waitUntil {sleep 1; !(alive _unit) OR (isNull _corpse) OR (_unit distance _corpse < 3) OR (_timeOut < time)};

		if (_unit distance _corpse < 3) then {
			_unit stop true;
			[_unit, _corpse] spawn AS_fnc_stripCorpse;
			_unit setVariable ["AS_strippingCorpse", true, true];

			waitUntil {sleep 1; !(alive _unit) OR (isNull _corpse) OR !(_unit getVariable ["AS_strippingCorpse", false])};
			if (!(alive _unit) OR (isNull _corpse)) then {breakTo "main"};
			_unit stop false;
			_unit doFollow player;
		};

		_containers = nearestObjects [_unit, ["WeaponHolderSimulated", "GroundWeaponHolder", "WeaponHolder"], 10];
		if (count _containers == 0) then {breakTo "outerLoop"};
		_container = _containers select 0;
		if (count (weaponCargo _container) > 0) then {
			_unit doMove (getPosATL _container);
			_timeOut = time + 20;

			waitUntil {sleep 1; !(alive _unit) OR (isNull _container) OR (_unit distance _container < 3) OR (_timeOut < time)};
			if (isNull _container) then {breakTo "outerLoop"};
			_unit action ["rearm",_container];
			sleep 1;
			[_unit, (weaponCargo _container) select 0, 0] call BIS_fnc_addWeapon;
			deleteVehicle _container;
		};
	} else {
		_containers = nearestObjects [_unit, ["WeaponHolderSimulated", "GroundWeaponHolder", "WeaponHolder"], DIS];
		if (count _containers == 0) then {breakTo "main"};
		_container = _containers select 0;
		if (count (weaponCargo _container) > 0) then {
			_unit doMove (getPosATL _container);
			_timeOut = time + 20;

			waitUntil {sleep 1; !(alive _unit) OR (isNull _container) OR (_unit distance _container < 3) OR (_timeOut < time)};
			if (isNull _container) then {breakTo "outerLoop"};
			_unit action ["rearm",_container];
			sleep 1;
			[_unit, (weaponCargo _container) select 0, 0] call BIS_fnc_addWeapon;
			deleteVehicle _container;
		};
	};
	sleep 1;
};

if (count _boxes > 0) then {
	if (_unit getVariable ["AS_cannotComply", false]) then {breakTo "main"};
	while {true} do {

		_foundBox = false;
		{
			_box = _x;
			if !(_box getVariable ["stripped", false]) exitWith {
				_foundBox = true;
				_box setVariable ["stripped", true, true];
			};
		} forEach _boxes;

		if (_foundBox) then {
			_unit setBehaviour "SAFE";
			_params = [[_unit, _targetContainer, true], [_unit, "", true]] select (typeName _targetContainer == "STRING");
			_unit setVariable ["AS_storingGear", true, true];
			_params spawn AS_fnc_storeGear;

			waitUntil {sleep 1; !(alive _unit) OR !(_unit getVariable ["AS_storingGear", false]) OR (isNull _box) OR (_unit getVariable ["AS_cannotComply", false])};
			if (_unit getVariable ["AS_cannotComply", false]) then {breakTo "main"};

			_unit stop false;
			_unit doMove (getPosATL _box);
			_timeOut = time + DUR;

			waitUntil {sleep 1; !(alive _unit) OR (isNull _box) OR (_unit distance _box < 5) OR (_timeOut < time)};

			if (_unit distance _box < 5) then {
				_unit stop true;
				[_unit, _box] spawn AS_fnc_stripCorpse;
				_unit setVariable ["AS_strippingCorpse", true, true];

				waitUntil {sleep 1; !(alive _unit) OR (isNull _box) OR !(_unit getVariable ["AS_strippingCorpse", false])};
				if (!(alive _unit) OR (isNull _box)) then {breakTo "main"};
				_unit stop false;
				_unit doFollow player;
			};
		} else {
			breakTo "main";
		};
		sleep 1;
	};
};

_unit setBehaviour "SAFE";
_params = [[_unit, _targetContainer, true, true], [_unit, "", true, true]] select (typeName _targetContainer == "STRING");
_unit setVariable ["AS_storingGear", true, true];
_params spawn AS_fnc_storeGear;

waitUntil {sleep 1; !(alive _unit) OR !(_unit getVariable ["AS_storingGear", false]) OR (_unit getVariable ["AS_cannotComply", false])};

_unit setVariable ["AS_cannotComply", nil, true];
_unit setVariable ["AS_lootingCorpses", nil, true];
_unit stop false;
_unit doFollow player;