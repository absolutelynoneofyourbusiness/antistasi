params ["_leader","_marker",["_order","patrol",[""]]];
private ["_parameters"];

if (isNull _leader) exitWith {diag_log format ["Error in addToUPSMON: %1 is undefined near %2.",_leader,_marker]};
if !(alive _leader) exitWith {diag_log format ["Error in addToUPSMON: %1 is dead near %2.",_leader,_marker]};

call {
	if (toLower _order isEqualTo "patrol") exitWith {
		_parameters = ["SAFE","SPAWNED","NOVEH2"];
	};

	if (toLower _order isEqualTo "garrison") exitWith {
		_parameters = ["SAFE","SPAWNED","NOFOLLOW","NOVEH2"];
	};

	if (toLower _order isEqualTo "fortify") exitWith {
		_parameters = ["SAFE","RANDOMA","SPAWNED","NOVEH","NOFOLLOW","FORTIFY"];
	};

	if (toLower _order isEqualTo "guard") exitWith {
		_parameters = ["AWARE","RANDOMA","SPAWNED","NOVEH","NOFOLLOW","FORTIFY"];
	};

	if (toLower _order isEqualTo "gunner") exitWith {
		_parameters = ["AWARE","SPAWNED","NOFOLLOW","NOVEH"];
	};

	if (toLower _order isEqualTo "observe") exitWith {
		_parameters = ["SAFE", "SPAWNED","NOFOLLOW", "NOVEH2","NOSHARE","DoRelax"];
	};
};

([_leader,_marker] + _parameters) spawn UPSMON;