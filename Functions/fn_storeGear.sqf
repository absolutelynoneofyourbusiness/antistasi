/*
    Description:
        Orders a unit to place all its gear in a pre-defined container

    Parameters:
        0: OBJECT - Unit
        1: OBJECT - Container to use for storage
        2: BOOLEAN - Force unit to drop the gear
        3: BOOLEAN - Restore the unit's saved loadout after dropping the current gear

    Returns:
        Nothing

    Example:
        [(groupSelectedUnits player) select 0, vehicle player, false, true] spawn AS_fnc_storeGear
*/

params [
	"_unit",
	["_container", ""],
	["_force", false],
	["_restoreGear", false],

	["_timeOut", diag_tickTime + 60]
];

#define DIS 50

_unit setVariable ["AS_cannotComply", true, false];

if ((!alive _unit) OR {isPlayer _unit} OR {vehicle _unit != _unit} OR {player != leader group player} OR {captive _unit}) exitWith {};
if (_unit getVariable ["inconsciente", false]) exitWith {};
if (_unit getVariable ["ayudando", false]) exitWith {_unit groupChat "I cannot go salvaging right now, I'm busy treating someone's wounds."};
if (_unit getVariable ["AS_storingGear", false] AND !(_force)) exitWith {diag_log "SG: unit already storing gear."};

if (typeName _container == "STRING") then {
	_containers = nearestObjects [position _unit, ["Car", "Tank"], DIS];
	if (count _containers > 0) then {
		_container = _containers select 0;
	} else {
		if (_unit distance2D cajaVeh < DIS) then {_container = cajaVeh};
	} ;
};

if (typeName _container == "STRING") exitWith {diag_log "SG: no containers found."};

_unit setVariable ["AS_cannotComply", nil, false];
_unit setVariable ["AS_storingGear", true, false];

_unit doMove (getPosATL _container);
_unit groupChat format ["Storing my gear in %1", getText (configFile >> "CfgVehicles" >> typeOf _container >> "DisplayName")];

waitUntil {sleep 1; !(alive _unit) OR {!(alive _container)} OR {_unit distance _container < 8} OR {_timeOut < diag_tickTime} OR {unitReady _unit}};
if ((_unit distance _container < 8) AND {alive _unit}) then {
	_unit stop true;
	if (_restoreGear) then {
		[_unit, [_unit, "scav_inventory"]] call BIS_fnc_loadInventory;
		_unit setVariable ["gearStored",nil,false];
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
_unit setVariable ["AS_storingGear", nil, false];