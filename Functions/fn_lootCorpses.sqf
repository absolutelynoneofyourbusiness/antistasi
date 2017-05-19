/*
    Description:
        Dispatches a single unit to collect gear from every corpse/surrender-box within a set distance

    Parameters:
        0: OBJECT - Unit
        1: OBJECT - Container to use for storage

    Returns:
        Nothing

    Example:
        [(groupSelectedUnits player) select 0, vehicle player] spawn AS_fnc_lootCorpses
*/

params [
	"_unit",
	"_targetContainer",

	["_corpses", []],
	["_corpse", objNull],
	["_foundCorpse", false],
	["_params", []],
	["_timeOut", diag_tickTime + 60],
	["_containers", []],
	["_container", objNull],
	["_timer", diag_tickTime + 120],
	["_box", objNull],
	["_boxes", []],
	["_foundBox", false]
];

#define DIS 50
#define DUR 30

if ((!alive _unit) OR (isPlayer _unit) OR (vehicle _unit != _unit) OR (player != leader group player) OR (captive _unit)) exitWith {};
if (_unit getVariable "inconsciente") exitWith {};

if (_unit getVariable ["ayudando", false]) exitWith {_unit groupChat "I cannot grab gear right now, I'm busy treating someone's wounds."};
if (_unit getVariable ["AS_storingGear", false]) exitWith {_unit groupChat "I am currently storing my gear."};
if (_unit getVariable ["AS_lootingCorpses", false]) exitWith {_unit groupChat "I am already looking for gear."};

_fnc_grabItem = {
	params ["_unit", ["_type", "weapon"], ["_break", true]];

	_containers = nearestObjects [_unit, ["WeaponHolderSimulated", "GroundWeaponHolder", "WeaponHolder"], DIS];
	if (count _containers == 0) then {breakTo "main"};
	_container = _containers select 0;
	if (_container getVariable ["marked", false]) then {breakTo "outerLoop"};

	call {
		if (count (weaponCargo _container) > 0) exitWith {
			_type = "weapon";
			_break = false;
		};

		if (count (backpackCargo _container) > 0) exitWith {
			_type = "backpack";
			_break = false;
		};
	};

	if (_break) then {breakTo "outerLoop"};

	_container setVariable ["marked", true, false];

	if (((_type == "weapon") AND ((primaryWeapon _unit != "") OR (secondaryWeapon _unit != ""))) OR ((_type == "backpack") AND (backpack _unit != ""))) then {
		_unit setBehaviour "SAFE";
		_params = [[_unit, _targetContainer, true], [_unit, "", true]] select (typeName _targetContainer == "STRING");
		_unit setVariable ["AS_storingGear", true, false];
		_params spawn AS_fnc_storeGear;

		waitUntil {sleep 1; !(alive _unit) OR !(_unit getVariable ["AS_storingGear", false]) OR (isNull _container) OR (_unit getVariable ["AS_cannotComply", false])};
		if (_unit getVariable ["AS_cannotComply", false]) then {breakTo "main"};

		_unit stop false;
	};

	_unit doMove (getPosATL _container);
	_timeOut = diag_tickTime + 20;

	waitUntil {sleep 1; !(alive _unit) OR (isNull _container) OR (_unit distance _container < 3) OR (_timeOut < diag_tickTime)};
	if (isNull _container) then {breakTo "outerLoop"};
	_unit action ["rearm",_container];
	sleep 1;

	call {
		if (_type == "weapon") exitWith {
			[_unit, (weaponCargo _container) select 0, 0] call BIS_fnc_addWeapon;
		};

		if (_type == "backpack") exitWith {
			_unit addBackpack ((backpackCargo _container) select 0);
		};
	};

	if !((count (weaponCargo _container) > 0) AND (count (backpackCargo _container) > 0)) then {
		deleteVehicle _container;
	} else {
		_container setVariable ["marked", false, false];
	}

};

scopeName "main";

{
	if (_x distance _unit < DIS) then {
		if !(_x getVariable ["stripped", false]) then {
			_corpses pushBackUnique _x;
		};
	};
} forEach allDead;

{
	if (_x distance _unit < DIS) then {
		if !(_x getVariable ["stripped", false]) then {
			_boxes pushBackUnique _x;
		};
	};
} forEach (nearestObjects [position _unit, ["Box_IND_Wps_F"], DIS]);

if ((count _corpses == 0) && (count _boxes == 0)) exitWith {hintSilent "No corpses nearby."};

_unit setVariable ["AS_lootingCorpses", true, false];
_unit setBehaviour "SAFE";

while {true} do {
	scopeName "outerLoop";

	if !(behaviour _unit == "SAFE") exitWith {_unit groupChat "My spidey-senses are tinglin'."};
	if (_timer < diag_tickTime) exitWith {_unit groupChat "We should get going..."};
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
		_unit setVariable ["AS_storingGear", true, false];
		_params spawn AS_fnc_storeGear;

		waitUntil {sleep 1; !(alive _unit) OR !(_unit getVariable ["AS_storingGear", false]) OR (isNull _corpse) OR (_unit getVariable ["AS_cannotComply", false])};
		if (_unit getVariable ["AS_cannotComply", false]) then {breakTo "main"};

		_unit stop false;
		_unit doMove (getPosATL _corpse);
		_timeOut = diag_tickTime + 60;

		waitUntil {sleep 1; !(alive _unit) OR (isNull _corpse) OR (_unit distance _corpse < 3) OR (_timeOut < diag_tickTime)};

		if (_unit distance _corpse < 3) then {
			_unit stop true;
			[_unit, _corpse] spawn AS_fnc_stripCorpse;
			_unit setVariable ["AS_strippingCorpse", true, false];

			waitUntil {sleep 1; !(alive _unit) OR (isNull _corpse) OR !(_unit getVariable ["AS_strippingCorpse", false])};
			if (!(alive _unit) OR (isNull _corpse)) then {breakTo "main"};
			_unit stop false;
			_unit doFollow player;
		};

		[_unit] call _fnc_grabItem;
	} else {
		[_unit] call _fnc_grabItem;
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
			_unit setVariable ["AS_storingGear", true, false];
			_params spawn AS_fnc_storeGear;

			waitUntil {sleep 1; !(alive _unit) OR !(_unit getVariable ["AS_storingGear", false]) OR (isNull _box) OR (_unit getVariable ["AS_cannotComply", false])};
			if (_unit getVariable ["AS_cannotComply", false]) then {breakTo "main"};

			_unit stop false;
			_unit doMove (getPosATL _box);
			_timeOut = diag_tickTime + DUR;

			waitUntil {sleep 1; !(alive _unit) OR (isNull _box) OR (_unit distance _box < 5) OR (_timeOut < diag_tickTime)};

			if (_unit distance _box < 5) then {
				_unit stop true;
				[_unit, _box] spawn AS_fnc_stripCorpse;
				_unit setVariable ["AS_strippingCorpse", true, false];

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
_unit setVariable ["AS_storingGear", true, false];
_params spawn AS_fnc_storeGear;

waitUntil {sleep 1; !(alive _unit) OR !(_unit getVariable ["AS_storingGear", false]) OR (_unit getVariable ["AS_cannotComply", false])};

_unit setVariable ["AS_cannotComply", nil, true];
_unit setVariable ["AS_lootingCorpses", nil, true];
_unit stop false;
_unit doFollow player;