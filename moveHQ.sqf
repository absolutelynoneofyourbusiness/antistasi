if (player != Slowhand) exitWith {hint "Only Commander Slowhand has access to this function"};

if ((count weaponCargo caja > 0) OR {count magazineCargo caja > 0} OR {count itemCargo caja > 0} OR {count backpackCargo caja > 0}) exitWith {hint "You must first empty your Ammobox in order to move HQ"};

petros enableAI "MOVE";
petros enableAI "AUTOTARGET";
petros forceSpeed -1;

[[petros,"remove"],"AS_fnc_addActionMP"] call BIS_fnc_MP;
[petros] join Slowhand;
petros setBehaviour "AWARE";

if (isMultiplayer) then {
	caja hideObjectGlobal true;
	cajaVeh hideObjectGlobal true;
	mapa hideObjectGlobal true;
	fuego hideObjectGlobal true;
	bandera hideObjectGlobal true;
} else {
	caja hideObject true;
	cajaVeh hideObject true;
	mapa hideObject true;
	fuego hideObject true;
	bandera hideObject true;
};

fuego inflame false;

if (count (server getVariable ["obj_vehiclePad",[]]) > 0) then {
	[obj_vehiclePad, {deleteVehicle _this}] remoteExec ["call", 0];
	[obj_vehiclePad, {obj_vehiclePad = nil}] remoteExec ["call", 0];
	server setVariable ["AS_vehicleOrientation", 0, true];
	server setVariable ["obj_vehiclePad",[],true];
};

guer_respawn setMarkerAlpha 0;

_garrison = garrison getVariable ["FIA_HQ", []];
_posicion = getMarkerPos "FIA_HQ";
_size = ["FIA_HQ"] call sizeMarker;
_clear = true;
if (count _garrison > 0) then {
	_coste = 0;
	_hr = 0;

	if ({(alive _x) AND {!captive _x} AND {_x distance _posicion < 500} AND {(side _x == side_green) OR {side _x == side_red}}} count allUnits > 0) then {
		hint "The garrison will delay the enemy while you run like a whimp.";
	} else {
		_clear = false;
		{
			if ((side _x == side_blue) AND {!(_x getVariable ["BLUFORSpawn",false])} AND {_x distance _posicion < _size} AND {_x != petros}) then {
				if !(alive _x) then {
					if (typeOf _x in guer_soldierArray) then {
						if (typeOf _x == guer_sol_UN) then {_coste = _coste - ([guer_stat_mortar] call vehiclePrice)};
						_hr = _hr - 1;
						_coste = _coste - (server getVariable (typeOf _x));
						};
					};
				if (typeOf (vehicle _x) == guer_stat_mortar) then {deleteVehicle vehicle _x};
				deleteVehicle _x;
			};
		} forEach allUnits;
	};

	{
		if (_x == guer_sol_UN) then {_coste = _coste + ([guer_stat_mortar] call vehiclePrice)};
		_hr = _hr + 1;
		_coste = _coste + (server getVariable _x);
	} forEach _garrison;
	[_hr,_coste] remoteExec ["resourcesFIA",2];
	garrison setVariable ["FIA_HQ",[],true];
	hint format ["Garrison removed\n\nRecovered Money: %1 €\nRecovered HR: %2",_coste,_hr];
};

_statics = staticsToSave select {_x distance _posicion < _size};

if ((count _statics > 0) AND {_clear}) then {
	staticsQuery = false;
	[] spawn {
		createDialog "statics_query";

		sleep 1;
		disableSerialization;

		_display = findDisplay 100;

		if (str (_display) != "no display") then {
			_ChildControl = _display displayCtrl 104;
			_ChildControl  ctrlSetTooltip "Disassemble all static weapons at HQ and have them reassembled at the new location.";
			_ChildControl = _display displayCtrl 105;
			_ChildControl  ctrlSetTooltip "Leave the static weapons as they are.";
		};
	};

	sleep 1;

	_timeout = diag_tickTime + 10;
	waitUntil {sleep 0.5; !(dialog) OR {diag_tickTime > _timeout}};

	if (staticsQuery) then {
		{
			staticsToSave = staticsToSave - [_x];
			vehInGarage pushBack (typeOf _x);
			deleteVehicle _x;
		} forEach _statics;

		publicVariable "staticsToSave";
		publicVariable "vehInGarage";
	};
};

sleep 5;

petros addAction [localize "STR_ACT_BUILDHQ", {[] spawn buildHQ},nil,0,false,true];