if !(isServer) exitWith {};

private ["_tiempo","_marcador","_posicionMRK", "_bluUnits", "_opUnits", "_colinas"];

debugperf = false;
_tiempo = time;

while {true} do {
	sleep 1;
	if (debugperf) then {hint format ["Tiempo transcurrido: %1 para %2 marcadores", time - _tiempo, count marcadores]};
	_tiempo = time;

	_colinas = colinas - colinasAA;

	waitUntil {!isNil "Slowhand"};

	_bluUnits = [];
	_opUnits = [];
	{
		if (_x getVariable ["BLUFORSpawn",false]) then {
			_bluUnits pushBack _x;
			if (isPlayer _x) then {
				if !(isNull (getConnectedUAV _x)) then {
					_bluUnits pushBack (getConnectedUAV _x);
				};
			};
		} else {
			if (_x getVariable ["OPFORSpawn",false]) then {
				_opUnits pushBack _x;
			};
		}
	} forEach allUnits;

	{
		_marcador = _x;
		_posicionMRK = getMarkerPos (_marcador);

		if (_marcador in mrkAAF) then {
			if !(spawner getVariable _marcador) then {
				if ((({(_x distance _posicionMRK < distanciaSPWN)} count _bluUnits > 0) or (_marcador in forcedSpawn))) then {
					spawner setVariable [_marcador,true,true];
					call {
						if (_marcador in _colinas) exitWith {[_marcador] remoteExec ["createWatchpost",HCGarrisons]};
						if (_marcador in colinasAA) exitWith {diag_log "colina!!!!";[_marcador] remoteExec ["createAAsite",HCGarrisons]};
						if (_marcador in ciudades) exitWith {[_marcador] remoteExec ["createCIV",HCciviles]; [_marcador] remoteExec ["createCity",HCGarrisons]};
						if (_marcador in power) exitWith {[_marcador] remoteExec ["createPower",HCGarrisons]};
						if (_marcador in bases) exitWith {[_marcador] remoteExec ["createBase",HCGarrisons]};
						if (_marcador in controles) exitWith {[_marcador] remoteExec ["createRoadblock",HCGarrisons]};
						if (_marcador in aeropuertos) exitWith {[_marcador] remoteExec ["createAirbase",HCGarrisons]};
						if ((_marcador in recursos) or (_marcador in fabricas)) exitWith {[_marcador] remoteExec ["createResources",HCGarrisons]};
						if ((_marcador in puestos) or (_marcador in puertos)) exitWith {[_marcador] remoteExec ["createOutpost",HCGarrisons]};
						if ((_marcador in artyEmplacements) AND (_marcador in forcedSpawn)) exitWith {[_marcador] remoteExec ["createArtillery",HCGarrisons]};
					};
				};
			} else {
				if (({_x distance _posicionMRK < distanciaSPWN} count _bluUnits == 0) and !(_marcador in forcedSpawn)) then {
					spawner setVariable [_marcador,false,true];
				};
			};
		} else {
			if !(spawner getVariable _marcador) then {
				if ((({_x distance _posicionMRK < distanciaSPWN} count _opUnits > 0) or ({((_x getVariable ["owner",objNull]) == _x) and (_x distance _posicionMRK < distanciaSPWN)} count _bluUnits > 0) or (_marcador in forcedSpawn))) then {
					spawner setVariable [_marcador,true,true];
					if (_marcador in ciudades) then {
						if (({((_x getVariable ["owner",objNull]) == _x) and (_x distance _posicionMRK < distanciaSPWN)} count _bluUnits > 0) or (_marcador in forcedSpawn)) then {[_marcador] remoteExec ["createCIV",HCciviles]};
						[_marcador] remoteExec ["createCity",HCGarrisons]
					} else {
						call {
							if ((_marcador in recursos) or (_marcador in fabricas)) exitWith {[_marcador] remoteExec ["createFIArecursos",HCGarrisons]};
							if ((_marcador in power) or (_marcador == "FIA_HQ")) exitWith {[_marcador] remoteExec ["createFIApower",HCGarrisons]};
							if (_marcador in aeropuertos) exitWith {[_marcador] remoteExec ["createNATOaerop",HCGarrisons]};
							if (_marcador in bases) exitWith {[_marcador] remoteExec ["createNATObases",HCGarrisons]};
							if (_marcador in puestosFIA) exitWith {[_marcador] remoteExec ["createFIApuestos2",HCGarrisons]};
							if ((_marcador in puestos) or (_marcador in puertos)) exitWith {[_marcador] remoteExec ["createFIApuestos",HCGarrisons]};
							if (_marcador in campsFIA) exitWith {[_marcador] remoteExec ["createCampFIA",HCGarrisons]};
							if (_marcador in puestosNATO) exitWith {[_marcador] remoteExec ["createNATOpuesto",HCGarrisons]};
						};
					};
				};
			} else {
				if ((({_x distance _posicionMRK < distanciaSPWN} count _opUnits == 0) and ({((_x getVariable ["owner",objNull]) == _x) and (_x distance _posicionMRK < distanciaSPWN)} count _bluUnits == 0)) and !(_marcador in forcedSpawn)) then {
					spawner setVariable [_marcador,false,true];
				};
			};
		};
	} forEach marcadores;
};