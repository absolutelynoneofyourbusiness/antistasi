params [["_isPersonalGarage",false,[false]]];
[false,false] params ["_enemiesNearby","_noSpace"];
private ["_isPersonalGarage","_enemiesNearby","_type"];

if (_isPersonalGarage AND !([player] call isMember)) exitWith {hint "You cannot access the garage as you are a guest on this server"};
if (player != player getVariable "owner") exitWith {hint "You cannot access the garage while you are controlling AI"};

{
	if (((side _x == side_red) OR (side _x == side_green)) AND (_x distance player < safeDistance_garage) and !(captive _x)) then {_enemiesNearby = true};
} forEach allUnits;

if (_enemiesNearby) exitWith {Hint "You cannot manage the garage with enemies nearby"};

vehInGarageShow = [vehInGarage, personalGarage] select _isPersonalGarage;

if (count vehInGarageShow == 0) exitWith {hintC "The garage is empty"};

garagePos = [];

if (!(count (server getVariable ["obj_vehiclePad",[]]) > 0) OR ((position player) distance2D (server getVariable ["posHQ", getMarkerPos guer_respawn]) > 50)) then {
	garagePos = position player findEmptyPosition [5,45,"B_MBT_01_TUSK_F"];
} else {
	garagePos = (server getVariable ["obj_vehiclePad",[]]);
	if (count (garagePos nearObjects ["AllVehicles",7]) > 0) then {_noSpace = true};
};

if (_noSpace) exitWith {hintC "Clear the area, not enough space to spawn a vehicle."};
if (count garagePos == 0) exitWith {hintC "Couldn't find a safe position to spawn the vehicle, or the area is too crowded to spawn it safely"};

cuentaGarage = 0;

garageVeh = (vehInGarageShow select cuentaGarage) createVehicle garagePos;
garageVeh setDir (server getVariable ["AS_vehicleOrientation", 0]);
garageVeh allowDamage false;
garageVeh enableSimulationGlobal false;

eph_chems = [];
if ((count (server getVariable ["obj_vehiclePad",[]]) > 0) AND (sunOrMoon < 1)) then {
	private ["_spawnPos"];
	for "_i" from 0 to 330 step 30 do {
		_spawnPos = [garagePos, 5, _i] call BIS_Fnc_relPos;
		eph_chems pushBack ("Chemlight_blue" createVehicle _spawnPos);
	};
};

Cam = "camera" camCreate (player modelToWorld [0,15,5]);
Cam camSetTarget garagePos;
Cam cameraEffect ["internal", "BACK"];
Cam camCommit 0;

["<t size='0.6'>Garage Keys.<t size='0.5'><br/>A-D Navigate<br/>SPACE to Select<br/>ENTER to Exit",0,0,5,0,0,4] spawn bis_fnc_dynamicText;

garageKeys = (findDisplay 46) displayAddEventHandler ["KeyDown", {
	params ["_ctrl", "_dikCode", "_shift", "_ctrlKey", "_alt"];
	[false,false,false,false] params ["_handled","_leave","_changeVehicle","_exit"];

	["<t size='0.6'>Garage Keys.<t size='0.5'><br/>A-D Navigate<br/>SPACE to Select<br/>ENTER to Exit",0,0,5,0,0,4] spawn bis_fnc_dynamicText;

	// space
	if (_dikCode == 57) then {
		_leave = true;
		_exit = true;
	};

	// enter
	if (_dikCode == 28) then {
		_leave = true;
		deleteVehicle garageVeh;
	};

	// d
	if (_dikCode == 32) then {
		if (cuentaGarage + 1 > (count vehInGarageShow) - 1) then {cuentaGarage = 0} else {cuentaGarage = cuentaGarage + 1};
		_changeVehicle = true;
	};

	// a
	if (_dikCode == 30) then {
		if (cuentaGarage - 1 < 0) then {cuentaGarage = (count vehInGarageShow) - 1} else {cuentaGarage = cuentaGarage - 1};
		_changeVehicle = true;
	};

	if (_changeVehicle) then {
		garageVeh enableSimulationGlobal false;
		deleteVehicle garageVeh;
		_type = vehInGarageShow select cuentaGarage;
		if (isNil "_type") then {_leave = true};
		if (typeName _type != typeName "") then {_leave = true};

		if (!_leave) then {
			garageVeh = _type createVehicle garagePos;
			garageVeh setDir (server getVariable ["AS_vehicleOrientation", 0]);
			garageVeh allowDamage false;
			garageVeh enableSimulationGlobal false;
		};
	};

	if (_leave) then {
		Cam camSetPos position player;
		Cam camCommit 1;
		Cam cameraEffect ["terminate", "BACK"];
		camDestroy Cam;
		(findDisplay 46) displayRemoveEventHandler ["KeyDown", garageKeys];

		[] spawn {
			sleep 15;
			{deleteVehicle _x} forEach eph_chems;
			eph_chems = nil;
		};

		if (!_exit) then {
			["",0,0,5,0,0,4] spawn bis_fnc_dynamicText;
		} else {
			[garageVeh] spawn VEHinit;
			["<t size='0.6'>Vehicle retrieved from Garage",0,0,3,0,0,4] spawn bis_fnc_dynamicText;
			_isPersonalGarage = (vehInGarageShow isEqualTo vehInGarage);

			_newArr = [];
			_found = false;
			if (_isPersonalGarage) then {
				{
					if ((_x != (vehInGarageShow select cuentaGarage)) or (_found)) then {_newArr pushBack _x} else {_found = true};
				} forEach vehInGarage;
				vehInGarage = _newArr;
				publicVariable "vehInGarage";
			} else {
				{
					if ((_x != (vehInGarageShow select cuentaGarage)) or (_found)) then {_newArr pushBack _x} else {_found = true};
				} forEach personalGarage;
				personalGarage = _newArr;
				["personalGarage",_newArr] call fn_SaveStat;
				garageVeh setVariable ["duenyo",getPlayerUID player,true];
			};

			if (garageVeh isKindOf "StaticWeapon") then {[garageVeh, {_this setOwner 2; staticsToSave pushBackUnique _this; publicVariable "staticsToSave"}] remoteExec ["call", 2]};
			clearMagazineCargoGlobal garageVeh;
			clearWeaponCargoGlobal garageVeh;
			clearItemCargoGlobal garageVeh;
			clearBackpackCargoGlobal garageVeh;
			garageVeh allowDamage true;
			garageVeh enableSimulationGlobal true;
		};
	};

	_handled;
}];