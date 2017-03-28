if (!isServer and hasInterface) exitWith {};

private ["_marcador","_posicion","_escarretera","_tam","_road","_veh","_grupo","_unit","_roadcon","_vehicles", "_advanced", "_posDes"];

_marcador = _this select 0;
_posicion = getMarkerPos _marcador;

_advanced = false;
_vehicles = [];

_escarretera = false;
if (isOnRoad _posicion) then {_escarretera = true};

// BE module
if (activeBE) then {
	if (BE_current_FIA_RB_Style == 1) exitWith {_advanced = true};
};
// BE module

if (_escarretera) then {
	if (_advanced) then {
		_data = [_posicion] call fnc_RB_placeDouble;
		_vehicles = _data select 0;
		sleep 1;

		_infData = _data select 2;
		_grupo = [(_infData select 0), side_blue, ([guer_grp_AT, "guer"] call AS_fnc_pickGroup), [], [], [], [], [], (_infData select 1)] call BIS_Fnc_spawnGroup;
		(_data select 1) joinSilent _grupo;
	} else {
		_tam = 1;

		while {true} do
			{
			_road = _posicion nearRoads _tam;
			if (count _road > 0) exitWith {};
			_tam = _tam + 5;
			};

		_roadcon = roadsConnectedto (_road select 0);
		_dirveh = [_road select 0, _roadcon select 0] call BIS_fnc_DirTo;


		_veh = guer_veh_technical createVehicle getPos (_road select 0);
		_vehicles pushBack _veh;
		_veh setDir _dirveh + 90;
		_veh lock 3;
		[_veh] spawn VEHinit;
		sleep 1;

		_grupo = [_posicion, side_blue, ([guer_grp_AT, "guer"] call AS_fnc_pickGroup), [], [], [], [], [], _dirveh] call BIS_Fnc_spawnGroup;
		_unit = _grupo createUnit [guer_sol_RFL, _posicion, [], 0, "NONE"];
		_unit moveInGunner _veh;
	};
}
else
	{
	_grupo = [_posicion, side_blue, ([guer_grp_sniper, "guer"] call AS_fnc_pickGroup)] call BIS_Fnc_spawnGroup;
	_grupo setBehaviour "STEALTH";
	_grupo setCombatMode "GREEN";
};

{[_x] spawn AS_fnc_initialiseFIAGarrisonUnit;} forEach units _grupo;

waitUntil {sleep 1; (not(spawner getVariable _marcador)) or ({alive _x} count units _grupo == 0) or (not(_marcador in puestosFIA))};

if ({alive _x} count units _grupo == 0) then
	{
	puestosFIA = puestosFIA - [_marcador]; publicVariable "puestosFIA";
	mrkFIA = mrkFIA - [_marcador]; publicVariable "mrkFIA";
	marcadores = marcadores - [_marcador]; publicVariable "marcadores";
	[5,-5,_posicion] remoteExec ["AS_fnc_changeCitySupport",2];
	deleteMarker _marcador;
	if (_escarretera) then
		{
		FIA_RB_list = FIA_RB_list - [_marcador]; publicVariable "FIA_RB_list";
		[["TaskFailed", ["", "Roadblock Lost"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
		}
	else
		{
		FIA_WP_list = FIA_WP_list - [_marcador]; publicVariable "FIA_WP_list";
		[["TaskFailed", ["", "Watchpost Lost"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
		deleteVehicle (nearestObjects [getMarkerPos _marcador, [guer_rem_des], 50] select 0);
		};
	};

waitUntil {sleep 1; (not(spawner getVariable _marcador)) or (not(_marcador in puestosFIA))};

if ((_advanced) || (_escarretera)) then {
	{deleteVehicle _x;} forEach _vehicles;
};

{deleteVehicle _x} forEach units _grupo;
deleteGroup _grupo;