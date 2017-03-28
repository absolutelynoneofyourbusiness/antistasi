params [["_FIA", false]];
private ["_veh","_vehType", "_permission", "_text"];

_veh = cursorTarget;

if (isNull _veh) exitWith {hint "You are not looking at a vehicle"};
if !(alive _veh) exitWith {hint "You cannot add destroyed vehicles to your garage"};
if (_veh distance getMarkerPos guer_respawn > 50) exitWith {hint "Vehicle must be within 50m of the flag"};
if ({isPlayer _x} count crew _veh > 0) exitWith {hint "In order to store vehicle, its crew must disembark."};

_vehType = typeOf _veh;

if ((_vehType in vehNATO) or (_vehType in planesNATO)) exitWith {hint format ["You cannot keep %1 vehicles", A3_Str_BLUE]};
if (_veh isKindOf "Man") exitWith {hint "Are you kidding?"};
if !(_veh isKindOf "AllVehicles") exitWith {hint "The vehicle you are looking cannot be kept in our Garage"};

_exit = false;
if !(_FIA) then {
	_owner = _veh getVariable "duenyo";
	if !(isNil "_owner") then {
		if (_owner isEqualType "") then {
			if (getPlayerUID player != _owner) then {_exit = true};
		};
	};
};

if (_exit) exitWith {hint "You are not owner of this vehicle and you cannot garage it"};

// BE module
_permission = true;
_text = "Error in permission system, module garage.";
if (activeBE) then {
	if (_FIA) then {
		_permission = ["FIA_garage"] call fnc_BE_permission;
		diag_log format ["GARAGE -- perm 1: %1", _permission];
		_text = "There's not enough space in our garage...";
	} else {
		_permission = ["pers_garage"] call fnc_BE_permission;
		diag_log format ["GARAGE -- perm 2: %1", _permission];
		_text = "There's not enough space in your garage...";
	};

	if (_permission) then {
		_permission = ["vehicle", _vehType, _veh] call fnc_BE_permission;
		diag_log format ["GARAGE -- perm 3: %1", _permission];
		_text = "We cannot maintain this type of vehicle.";
	};
};

if !(_permission) exitWith {hint _text};
// BE module

if (_veh in staticsToSave) then {staticsToSave = staticsToSave - [_veh]; publicVariable "staticsToSave"};

if (server getVariable "lockTransfer") exitWith {
	{
		if (_x distance caja < 20) then {
			[petros,"hint","Currently unloading another ammobox. Please wait a few seconds."] remoteExec ["commsMP",_x];
		};
	} forEach playableUnits;
};

[_veh,true] call vaciar;
if (_veh in reportedVehs) then {reportedVehs = reportedVehs - [_veh]; publicVariable "reportedVehs"};
if (_veh isKindOf "StaticWeapon") then {deleteVehicle _veh};

if ((count FIA_texturedVehicles > 0) && !(_vehType in FIA_texturedVehicles)) then {
	for "_i" from 0 to (count FIA_texturedVehicleConfigs - 1) do {
		if ((_vehType == configName (inheritsFrom (FIA_texturedVehicleConfigs select _i))) || (configName (inheritsFrom (configFile >> "CfgVehicles" >> _vehType)) == configName (inheritsFrom (FIA_texturedVehicleConfigs select _i)))) exitWith {
			_vehType = configName (FIA_texturedVehicleConfigs select _i);
		};
	};
};

if (_FIA) then {
	vehInGarage = vehInGarage + [_vehType];
	publicVariable "vehInGarage";
	hint "Vehicle added to FIA Garage";
} else {
	personalGarage = personalGarage + [_vehType];
	hint "Vehicle added to Personal Garage";
};