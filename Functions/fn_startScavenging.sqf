/*
    Description:
        - Sends selected units scavenging.
        - They will loot corpses/surrender-boxes within a set distance and deposit all gear within the specified vehicle/container.

    Parameters:
        0: OBJECT - Container to use for storage (default: vehicle of first selected unit)

    Returns:
        Nothing

    Example:
        [vehicle player] spawn AS_fnc_startScavenging;
        [cursorTarget] spawn AS_fnc_startScavenging;
*/

params [
	["_specificContainer", objNull],

	["_units", groupSelectedUnits player],
	["_break", false],
	["_container", objNull],
	["_vehicle", objNull],
	["_looting", true],
	["_driver", ""],
	["_commander", ""],
	["_gunner", ""]
];

private ["_unit", "_fnc_message", "_rtv"];

#define CAPACITY 100 // minimum spare capacity of a vehicle

if !(count _units > 0) exitWith {hintSilent "Please select the units who should start scavenging."};

_fnc_message = {
	params ["_unit", "_text"];
	_unit groupChat _text;
};

{
	if (_x getVariable ["AS_lootingCorpses", false]) exitWith {
		_break = true;
		[_x, "I am already looking for gear."] call _fnc_message;
	};
} forEach _units;

if (_break) exitWith {hintSilent "Some of your selected units are occupied."};

// return to your vehicles
_rtv = {
	params ["_crew", "_vehicle", "_role"];
	_crew doMove (getPosATL _vehicle);
	[_crew] allowGetIn true;
	[_crew] orderGetIn true;
	waitUntil {sleep 0.5; (_crew distance2D _vehicle) < 6};

	switch (_role) do {
		case "driver": {
			_crew assignAsDriver _vehicle;
			diag_log format ["Driver: %1; vehicle: %2", _crew, _vehicle];
			_crew action ["getInDriver", _vehicle];
		};
		case "commander": {
			_crew assignAsCommander _vehicle;
			diag_log format ["Commander: %1", _crew];
			_crew action ["getInCommander", _vehicle];
		};
		case "gunner": {
			_crew assignAsGunner _vehicle;
			diag_log format ["Gunner: %1", _crew];
			_crew action ["getInGunner", _vehicle];
		};

		default {
			_crew assignAsCargo _vehicle;
			diag_log format ["cargo: %1; vehicle: %2", _crew, _vehicle];
			_crew action ["getInCargo", _vehicle];
		};
	};
};

// if units are mounted, note the roles
_unit = _units select 0;
if !(vehicle _unit == _unit) then {
	_vehicle = vehicle _unit;
	if ((_vehicle isKindOf "Car") OR {_vehicle isKindOf "Tank"}) then {
		_driver = ["", driver _vehicle] select !(isNull (driver _vehicle));
		_container = _vehicle;
		_commander = ["", commander _vehicle] select !(isNull (commander _vehicle));
		_gunner = ["", gunner _vehicle] select !(isNull (gunner _vehicle));
	};
};

// only vehicles classify as containers
if !(isNull (_specificContainer)) then {
	if (_specificContainer isKindOf "LandVehicle") then {
		_container = _specificContainer;
	};
};

if (isNull (_container)) exitWith {hintSilent "Please specify a container."};
if (([_container] call AS_fnc_getSpareCapacity) < 100) exitWith {[_x, "If we add more load to it, it'll break..."] call _fnc_message};

// make a note of the vehicles a unit belongs to, save the current inventory, start looting
{
	if !(vehicle _x == _x) then {
		_x setVariable ["vehicle", vehicle _x, true];
		doGetOut _x;
		sleep 1;
	};

	if (typeName (_x getVariable ["bis_fnc_saveInventory_data",""]) == "STRING") then {
		[_x, [_x, "unit_inventory"]] call BIS_fnc_saveInventory;
	};

	[_x, _container] spawn AS_fnc_lootCorpses;
	sleep 1;
} forEach _units;

sleep 5;

while {_looting} do {
	_looting = false;
	{
		if (_x getVariable ["AS_lootingCorpses", false]) exitWith {_looting = true};
	} forEach _units;
	sleep 3;
};

// return to your leader/vehicles
{
	_x doFollow (leader (group _x));
	if !(isNull (_x getVariable ["vehicle", objNull])) then {
		_x doMove (getPosATL (_x getVariable "vehicle"));
	};
} forEach _units;

// take your assigned positions
if !(isNull _vehicle) then {
	if (alive _vehicle) then {
		if !(typeName _driver == "STRING") then {
			if ((isNull (driver _vehicle)) AND {alive _driver}) then {
				[_driver, _vehicle, "driver"] spawn _rtv;
			};
		};
		if !(typeName _commander == "STRING") then {
			if ((isNull (commander _vehicle)) AND {alive _commander}) then {
				[_commander, _vehicle, "commander"] spawn _rtv;
			};
		};
		if !(typeName _gunner == "STRING") then {
			if ((isNull (gunner _vehicle)) AND {alive _gunner}) then {
				[_gunner, _vehicle, "gunner"] spawn _rtv;
			};
		};
	};
} else {
	{
		if !(isNull (_x getVariable ["vehicle", objNull])) then {
			if ((alive (_x getVariable "vehicle")) AND {alive _x} AND {vehicle _x == _x}) then {
				_vehicle = _x getVariable "vehicle";
				_x action ["getInCargo", _vehicle];
			};
		};
	} forEach _units;
};

[_units, true] call AS_fnc_resetAIStatus;

[_unit, "We are done here. Ready to move out."] call _fnc_message;