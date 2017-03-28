if (!isServer and hasInterface) exitWith{};

private ["_marcador","_vehiculos","_grupos","_soldados","_posicion","_pos","_size","_veh","_estaticas","_garrison","_tam","_cuenta","_grupo","_grupoMort","_tipo","_unit"];

_marcador = _this select 0;

_vehiculos = [];
_grupos = [];
_soldados = [];
_civs = [];
_tipoCiv = "";
_posicion = getMarkerPos (_marcador);
_pos = [];

_size = [_marcador] call sizeMarker;

if (_marcador != "FIA_HQ") then
	{
	_veh = createVehicle [guer_flag, _posicion, [],0, "CAN_COLLIDE"];
	_veh allowDamage false;
	_vehiculos = _vehiculos + [_veh];
	[[_veh,"unit"],"AS_fnc_addActionMP"] call BIS_fnc_MP;
	[[_veh,"vehicle"],"AS_fnc_addActionMP"] call BIS_fnc_MP;
	[[_veh,"garage"],"AS_fnc_addActionMP"] call BIS_fnc_MP;
	if (not(_marcador in destroyedCities)) then
		{
		if ((daytime > 8) and (daytime < 18)) then
			{
			_grupo = createGroup civilian;
			_grupos = _grupos + [_grupo];
			for "_i" from 1 to 8 do
				{
				_civ = _grupo createUnit [selectRandom CIV_workers, _posicion, [],0, "NONE"];
				[_civ] spawn CIVinit;
				_civs = _civs + [_civ];
				sleep 0.5;
				};
			[_marcador,_civs] spawn destroyCheck;
			[leader _grupo, _marcador, "SAFE", "SPAWNED","NOFOLLOW", "NOSHARE","DORELAX","NOVEH2"] execVM "scripts\UPSMON.sqf";
			};
		};
	};
_estaticas = staticsToSave select {_x distance _posicion < _size};

_garrison = garrison getVariable [_marcador,[]];
_tam = count _garrison;
_cuenta = 0;
_grupo = createGroup side_blue;
_grupos = _grupos + [_grupo];

if ((guer_sol_UN in _garrison) or ({typeOf _x == guer_stat_mortar} count _estaticas > 0))then
	{
	_grupoMort = createGroup side_blue;
	};
_grupoEst = grpNull;
if (count _estaticas > 0) then
	{
	_grupoEst = createGroup side_blue;
	};

while {(spawner getVariable _marcador) and (_cuenta < _tam)} do
	{
	_tipo = _garrison select _cuenta;
	if (_tipo == guer_sol_UN) then
		{
		_unit = _grupoMort createUnit [_tipo, _posicion, [], 0, "NONE"];
		_pos = [_posicion] call mortarPos;
		_veh = guer_stat_mortar createVehicle _pos;
		_vehiculos = _vehiculos + [_veh];
		[_veh] execVM "scripts\UPSMON\MON_artillery_add.sqf";
		_unit assignAsGunner _veh;
		_unit moveInGunner _veh;
		[_veh] spawn VEHinit;
		}
	else
		{
		if ((_tipo == guer_sol_RFL) and (count _estaticas > 0)) then
			{
			_estatica = _estaticas select 0;
			if (typeOf _estatica == guer_stat_mortar) then
				{
				_unit = _grupoMort createUnit [_tipo, _posicion, [], 0, "NONE"];
				_unit moveInGunner _estatica;
				[_estatica] execVM "scripts\UPSMON\MON_artillery_add.sqf";
				}
			else
				{
				_unit = _grupoEst createUnit [_tipo, _posicion, [], 0, "NONE"];
				_unit moveInGunner _estatica;
				};
			_estaticas = _estaticas - [_estatica];
			}
		else
			{
			_unit = _grupo createUnit [_tipo, _posicion, [], 0, "NONE"];
			if (_tipo == guer_sol_SL) then {_grupo selectLeader _unit};
			};
		};
	[_unit,_marcador] call AS_fnc_initialiseFIAGarrisonUnit;
	_soldados = _soldados + [_unit];
	_cuenta = _cuenta + 1;
	sleep 0.5;
	if (count units _grupo == 8) then
		{
		_grupo = createGroup side_blue;
		_grupos = _grupos + [_grupo];
		};
	};

for "_i" from 0 to (count _grupos) - 1 do
	{
	_grupo = _grupos select _i;
	if (_i == 0) then
		{
		[leader _grupo, _marcador, "SAFE","SPAWNED","RANDOMUP","NOVEH2","NOFOLLOW"] execVM "scripts\UPSMON.sqf";
		}
	else
		{
		[leader _grupo, _marcador, "SAFE","SPAWNED","RANDOM","NOVEH2","NOFOLLOW"] execVM "scripts\UPSMON.sqf";
		};
	};

if (guer_sol_UN in _garrison) then
	{
	_grupos = _grupos + [_grupoMort];
	};

_periodista = objNull;
if ((random 100 < (((server getVariable "prestigeNATO") + (server getVariable "prestigeCSAT"))/10)) and (spawner getVariable _marcador)) then
	{
	_pos = [];
	_grupo = createGroup civilian;
	while {true} do
		{
		_pos = [_posicion, round (random _size), random 360] call BIS_Fnc_relPos;
		if (!surfaceIsWater _pos) exitWith {};
		};
	_periodista = _grupo createUnit [selectRandom CIV_journalists, _pos, [],0, "NONE"];
	[_periodista] spawn CIVinit;
	_grupos pushBack _grupo;
	[_periodista, _marcador, "SAFE", "SPAWNED","NOFOLLOW", "NOVEH2","NOSHARE","DoRelax"] execVM "scripts\UPSMON.sqf";
	};

waitUntil {sleep 1; (not (spawner getVariable _marcador)) or (({not(vehicle _x isKindOf "Air")} count ([_size,0,_posicion,"OPFORSpawn"] call distanceUnits)) > 3*(({alive _x} count _soldados) + count ([_size,0,_posicion,"BLUFORSpawn"] call distanceUnits)))};

if (spawner getVariable _marcador) then
	{
	if (_marcador != "FIA_HQ") then {[_marcador] remoteExec ["mrkLOOSE",2]};
	};

waitUntil {sleep 1; not (spawner getVariable _marcador)};

{
_soldado = _x;
if (alive _soldado) then
	{
	deleteVehicle _x
	};
} forEach _soldados;
{deleteVehicle _x} forEach _civs;
if (!isNull _periodista) then {deleteVehicle _periodista};
{deleteGroup _x} forEach _grupos;
deleteGroup _grupoEst;
{if (!(_x in staticsToSave)) then {deleteVehicle _x}} forEach _vehiculos;
