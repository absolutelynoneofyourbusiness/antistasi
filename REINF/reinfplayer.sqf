params [
	["_unitType", guer_sol_RFL],
	["_enemiesNearby", false, [false]],
	["_available", true, [false]],
	["_cost", 100, [0]]
];

private ["_hr","_resourcesFIA","_unit"];

if !([player] call isMember) exitWith {hint "Only Server Members can recruit AI units"};
if !(allowPlayerRecruit) exitWith {hint "Server load is currently very high. \nWait a minute or change FPS settings."};
if (recruitCooldown > time) exitWith {hint format ["You need to wait %1 seconds to be able to recruit units again",round (recruitCooldown - time)]};
if (player != player getVariable ["owner",player]) exitWith {hint "You cannot recruit units while you are controlling AI"};
if (player != leader group player) exitWith {hint "You cannot recruit units as you are not your group leader"};
if ((count units group player) + (count units rezagados) > 9) exitWith {hint "Your squad is full or you have too many scattered units without radio contact"};

{
	if (((side _x == side_red) OR {(side _x == side_green)}) AND {(_x distance player < 500)} AND {!(captive _x)}) exitWith {_enemiesNearby = true};
} forEach allUnits;

if (_enemiesNearby) exitWith {Hint "You cannot recruit units with enemies nearby"};

if (activeJNA) then {
	call {
		if (_unitType == guer_sol_AR) exitWith {_available = ["LMG"] call AS_fnc_JNA_checkAvailability};
		if (_unitType == guer_sol_GL) exitWith {_available = ["GL"] call AS_fnc_JNA_checkAvailability};
		if (_unitType == guer_sol_MRK) exitWith {_available = ["SNIPER"] call AS_fnc_JNA_checkAvailability};
		if (_unitType == guer_sol_LAT) exitWith {_available = ["AT"] call AS_fnc_JNA_checkAvailability};
		if (_unitType == "Soldier_AA") exitWith {_available = ["AA"] call AS_fnc_JNA_checkAvailability};
	};
} else {
	call {
		if ((_unitType == guer_sol_AR) AND {(server getVariable "genLMGlocked")}) exitWith {_available = false};
		if ((_unitType == guer_sol_GL) AND {(server getVariable "genGLlocked")}) exitWith {_available = false};
		if ((_unitType == guer_sol_MRK)AND {(server getVariable "genSNPRlocked")}) exitWith {_available = false};
		if ((_unitType == guer_sol_LAT) AND {(server getVariable "genATlocked")}) exitWith {_available = false};
		if ((_unitType == "Soldier_AA") AND {(server getVariable "genAAlocked")}) exitWith {_available = false};
	};
};

if !(_available) exitWith {hint "Required weapon not unlocked yet."};

_hr = server getVariable ["hr", 0];

if (_hr < 1) exitWith {hint "You do not have enough HR for this request"};

_cost = server getVariable [_unitType, 150];
if (_unitType == "Soldier_AA") then {_cost = server getVariable [guer_sol_AA,150]};
if !(isMultiPlayer) then {_resourcesFIA = server getVariable ["resourcesFIA", 0]} else {_resourcesFIA = player getVariable ["dinero", 0]};

if (_cost > _resourcesFIA) exitWith {hint format ["You do not have enough money for this kind of unit (%1 € needed)",_cost]};


if !(_unitType == "Soldier_AA") then {
	_unit = group player createUnit [_unitType, position player, [], 0, "NONE"];
} else {
	_unit = group player createUnit [guer_sol_AA, position player, [], 0, "NONE"];
};

if !(isMultiPlayer) then {
	[-1, - _cost] remoteExec ["resourcesFIA",2];
} else {
	[-1, 0] remoteExec ["resourcesFIA",2];
	[- _cost] call resourcesPlayer;
	hint "Soldier Recruited.\n\nRemember: if you use the group menu to switch groups you will lose control of your recruited AI";
};

[_unit, ["", "AA"] select (_unitType == "Soldier_AA")] call AS_fnc_initialiseFIAUnit;
if (activeJNA) then {[_unit] call AS_fnc_JNA_removeAIGear};

_unit disableAI "AUTOCOMBAT";
sleep 1;
petros directSay "SentGenReinforcementsArrived";