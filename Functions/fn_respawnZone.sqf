params ["_marker"];

spawner setVariable [_marker,true,true];
spawner setVariable [format ["%1_respawning", _marker],nil,true];

if (_marker in mrkFIA) then {
	call {
		if (_marker in ciudades) then {[_marker] remoteExec ["createCity",HCGarrisons];[_marker] remoteExec ["createCIV",HCciviles];};
		if ((_marker in recursos) OR (_marker in fabricas)) exitWith {[_marker] remoteExec ["createFIArecursos",HCGarrisons]};
		if (_marker in power) exitWith {[_marker] remoteExec ["createFIApower",HCGarrisons]};
		if (_marker in aeropuertos) exitWith {[_marker] remoteExec ["createNATOaerop",HCGarrisons]};
		if (_marker in bases) exitWith {[_marker] remoteExec ["createNATObases",HCGarrisons]};
		if (_marker in puestosFIA) exitWith {[_marker] remoteExec ["createFIAEmplacement",HCGarrisons]};
		if ((_marker in puestos) OR (_marker in puertos)) exitWith {[_marker] remoteExec ["createFIAOutpost",HCGarrisons]};
		if (_marker in campsFIA) exitWith {[_marker] remoteExec ["createCampFIA",HCGarrisons]};
		if (_marker in puestosNATO) exitWith {[_marker] remoteExec ["createNATOpuesto",HCGarrisons]};
		if (_marker == "FIA_HQ") exitWith {[_marker] remoteExec ["createFIAHQ",HCGarrisons]};
	};
} else {
	call {
		if (_marker in colinasAA) exitWith {[_marker] remoteExec ["createAAsite",HCGarrisons]};
		if (_marker in colinas) exitWith {[_marker] remoteExec ["createWatchpost",HCGarrisons]};
		if (_marker in ciudades) exitWith {[_marker] remoteExec ["createCIV",HCciviles]; [_marker] remoteExec ["createCity",HCGarrisons]};
		if (_marker in power) exitWith {[_marker] remoteExec ["createPower",HCGarrisons]};
		if (_marker in bases) exitWith {[_marker] remoteExec ["createBase",HCGarrisons]};
		if (_marker in controles) exitWith {[_marker] remoteExec ["createRoadblock",HCGarrisons]};
		if (_marker in aeropuertos) exitWith {[_marker] remoteExec ["createAirbase",HCGarrisons]};
		if ((_marker in recursos) OR (_marker in fabricas)) exitWith {[_marker] remoteExec ["createResources",HCGarrisons]};
		if ((_marker in puestos) OR (_marker in puertos)) exitWith {[_marker] remoteExec ["createOutpost",HCGarrisons]};
		if ((_marker in artyEmplacements) AND (_marker in forcedSpawn)) exitWith {[_marker] remoteExec ["createArtillery",HCGarrisons]};
	};
};