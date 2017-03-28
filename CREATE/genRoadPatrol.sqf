private ["_soldados","_vehiculos","_grupos","_base","_posbase","_roads","_tipoCoche","_arrayBases","_arrayDestinos","_tam","_road","_veh","_vehCrew","_grupoVeh","_grupo","_grupoP","_distancia"];

_soldados = [];
_vehiculos = [];
_grupos = [];
_base = "";
_roads = [];

_tipos = vehPatrol + vehPatrolBoat;

while {true} do
	{
	_tipoCoche = selectRandom _tipos;
	if (_tipoCoche in heli_unarmed) then
		{
		_arrayBases = aeropuertos - mrkFIA;
		}
	else
		{
		if (_tipoCoche in vehPatrolBoat) then
			{
			_arrayBases = puertos - mrkFIA;
			}
		else
			{
			_arrayBases = bases - mrkFIA;
			};
		};
	if (count _arraybases == 0) then
		{
		_tipos = _tipos - [_tipoCoche];
		}
	else
		{
		while {true} do
			{
			_base = [_arraybases,getMarkerPos guer_respawn] call BIS_fnc_nearestPosition;
			if (not (spawner getVariable _base)) exitWith {};
			if (spawner getVariable _base) then {_arraybases = _arraybases - [_base]};
			if (count _arraybases == 0) exitWith {};
			};
		if (count _arraybases == 0) then {_tipos = _tipos - [_tipoCoche]};
		};
	if (count _tipos == 0) exitWith {};
	if (not (spawner getVariable _base)) exitWith {};
	};

if (count _tipos == 0) exitWith {};

_posbase = getMarkerPos _base;

if (_tipoCoche isKindOf "helicopter") then
	{
	_arrayDestinos = mrkAAF;
	_distancia = 300;
	}
else
	{
	if (_tipoCoche in vehPatrolBoat) then
		{
		_arraydestinos = seaMarkers select {(getMarkerPos _x) distance _posbase < 2500};
		_distancia = 100;
		}
	else
		{
		_arraydestinos = [mrkAAF] call AS_fnc_getPatrolTargets;
		_distancia = 50;
		};
	};

if (count _arraydestinos < 1) exitWith {};

AAFpatrols = AAFpatrols + 1; publicVariableServer "AAFpatrols";

if !(_tipoCoche isKindOf "helicopter") then
	{
	if (_tipoCoche in vehPatrolBoat) then
		{
		_posbase = [_posbase,80,200,10,2,0,0] call BIS_Fnc_findSafePos;
		}
	else
		{
		_tam = 10;
		while {true} do
			{
			_roads = _posbase nearRoads _tam;
			if (count _roads > 0) exitWith {};
			_tam = _tam + 10;
			};
		_road = _roads select 0;
		_posbase = position _road;
		};
	};

_vehicle=[_posbase, 0,_tipoCoche, side_green] call bis_fnc_spawnvehicle;
_veh = _vehicle select 0;
if (_veh iskindof "ship") then {
	_beach = [_veh,0,200,0,0,90,1] call BIS_Fnc_findSafePos;
	_veh setdir ((_veh getRelDir _beach) + 180);
};
[_veh] spawn genVEHinit;
[_veh,"Patrol"] spawn inmuneConvoy;
_vehCrew = _vehicle select 1;
{[_x] spawn genInit} forEach _vehCrew;
_grupoVeh = _vehicle select 2;
_soldados = _soldados + _vehCrew;
_grupos = _grupos + [_grupoVeh];
_vehiculos = _vehiculos + [_veh];


if (_tipoCoche isKindOf "Car") then
	{
	sleep 1;
	_tipoGrupo = [infGarrisonSmall, side_green] call AS_fnc_pickGroup;
	_grupo = [_posbase, side_green, _tipogrupo] call BIS_Fnc_spawnGroup;
	{_x assignAsCargo _veh; _x moveInCargo _veh; _soldados = _soldados + [_x]; [_x] join _grupoveh; [_x] spawn genInit} forEach units _grupo;
	deleteGroup _grupo;
	[_veh] spawn smokeCover;
	};

while {alive _veh} do
	{
	_destino = _arraydestinos call bis_Fnc_selectRandom;
	if (debug) then {player globalChat format ["Patrulla AAF generada. Origen: %2 Destino %1", _destino, _base]; sleep 3;};
	_posdestino = getMarkerPos _destino;
	deleteWaypoint [_grupoVeh, 1];
	_Vwp0 = _grupoVeh addWaypoint [_posdestino, 0];
	if (_veh isKindOf "helicopter") then {_Vwp0 setWaypointType "LOITER";} else {_Vwp0 setWaypointType "MOVE";};
	_Vwp0 setWaypointBehaviour "SAFE";
	_Vwp0 setWaypointSpeed "LIMITED";
	_veh setFuel 1;
	while {true} do
		{
		sleep 60;
		{
		if (_x select 2 == side_blue) then
			{
			//hint format ["%1",_x];
			_arevelar = _x select 4;
			_nivel = (driver _veh) knowsAbout _arevelar;
			if (_nivel > 1.4) then
				{
				{
				_grupoP = _x;
				if (leader _grupoP distance _veh < distanciaSPWN) then {_grupoP reveal [_arevelar,_nivel]};
				} forEach allGroups;
				};
			};
		} forEach (driver _veh nearTargets distanciaSPWN);
		if ((_veh distance2d _posdestino < _distancia) or ({alive _x} count _soldados == 0) or ({fleeing _x} count _soldados == {alive _x} count _soldados) or (!canMove _veh)) exitWith {};
		};

	if (({alive _x} count _soldados == 0) or ({fleeing _x} count _soldados == {alive _x} count _soldados) or (!canMove _veh)) exitWith {};
	if (_tipoCoche isKindOf "helicopter") then
		{
		_arrayDestinos = mrkAAF;
		}
	else
		{
		if (_tipoCoche in vehPatrolBoat) then
			{
			_arraydestinos = seaMarkers select {(getMarkerPos _x) distance position _veh < 2500};
			}
		else
			{
			_arraydestinos = [mrkAAF] call AS_fnc_getPatrolTargets;
			};
		};
	};


AAFpatrols = AAFpatrols - 1;publicVariableServer "AAFpatrols";
{_unit = _x;
waitUntil {sleep 1;!([distanciaSPWN,1,_unit,"BLUFORSpawn"] call distanceUnits)};deleteVehicle _unit} forEach _soldados;

{_veh = _x;
if !([distanciaSPWN,1,_veh,"BLUFORSpawn"] call distanceUnits) then {deleteVehicle _veh}} forEach _vehiculos;
{deleteGroup _x} forEach _grupos;
