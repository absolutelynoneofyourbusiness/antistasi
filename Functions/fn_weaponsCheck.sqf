params ["_weapons", ["_reset", false]];

if (_reset) then {
	server setVariable ["genLMGlocked",true,true];
	server setVariable ["genGLlocked",true,true];
	server setVariable ["genSNPRlocked",true,true];
	server setVariable ["genATlocked",true,true];
	server setVariable ["genAAlocked",true,true];

	[unlockedWeapons] call AS_fnc_weaponsCheck;
} else {
	{
		call {
			if (_x in gear_machineGuns) exitWith {server setVariable ["genLMGlocked",false,true];};
			if (_x in genGL) exitWith {server setVariable ["genGLlocked",false,true];};
			if (_x in gear_sniperRifles) exitWith {server setVariable ["genSNPRlocked",false,true];};
			if (_x in genATLaunchers) exitWith {server setVariable ["genATlocked",false,true];};
			if (_x in genAALaunchers) exitWith {server setVariable ["genAAlocked",false,true];};
		};
	} forEach _weapons;
};