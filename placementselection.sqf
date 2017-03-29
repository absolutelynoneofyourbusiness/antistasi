if (!isNil "placementDone") then {
	Slowhand allowDamage false;
	(localize "STR_HINTS_HQPLACE_DEATH_TITLE") hintC localize "STR_HINTS_HQPLACE_DEATH";
} else {
	diag_log "Antistasi: New Game selected";
	(localize "STR_HINTS_HQPLACE_START_TITLE") hintC [localize "STR_HINTS_HQPLACE_START_1",localize "STR_HINTS_HQPLACE_START_2",localize "STR_HINTS_HQPLACE_START_3"];
};

private ["_posicionTel","_marcador","_marcadores"];
_marcadores = mrkAAF;
if (isNil "placementDone") then
	{
	_marcadores = _marcadores - controles;
	openMap true;
	}
else
	{
	openMap [true,true];
	};
while {true} do
	{
	posicionTel = [];
	onMapSingleClick "posicionTel = _pos;";

	waitUntil {sleep 1; (count posicionTel > 0) or (not visiblemap)};
	onMapSingleClick "";
	if (not visiblemap) exitWith {};
	_posicionTel = posicionTel;
	_marcador = [_marcadores,_posicionTel] call BIS_fnc_nearestPosition;
	if (getMarkerPos _marcador distance _posicionTel < 1000) then {hint localize "STR_HINTS_HQPLACE_ZONES"};
	if (surfaceIsWater _posicionTel) then {hint localize "STR_HINTS_HQPLACE_WATER"};
	_enemigos = false;
	if (!isNil "placementDone") then
		{
		{
		if ((side _x == side_green) or (side _x == side_red)) then
			{
			if (_x distance _posicionTel < 1000) then {_enemigos = true};
			};
		} forEach allUnits;
		};
	if (_enemigos) then {hint localize "STR_HINTS_HQPLACE_ENEMIES"};
	if ((getMarkerPos _marcador distance _posicionTel > 1000) and (!surfaceIsWater _posicionTel) and (!_enemigos)) exitWith {};
	};

if (visiblemap) then
	{
	if (isNil "placementDone") then
		{
		{
		if (getMarkerPos _x distance _posicionTel < 1000) then
			{
			mrkAAF = mrkAAF - [_x];
			mrkFIA = mrkFIA + [_x];
			};
		} forEach controles;
		publicVariable "mrkAAF";
		publicVariable "mrkFIA";
		petros setPos _posicionTel;
		}
	else
		{
		_viejo = petros;
		grupoPetros = createGroup side_blue;
		publicVariable "grupoPetros";
        petros = grupoPetros createUnit [guer_sol_OFF, _posicionTel, [], 0, "NONE"];
        grupoPetros setGroupId ["Petros","GroupColor4"];
        petros setIdentity "amiguete";
        petros setName "Petros";
        petros disableAI "MOVE";
        petros disableAI "AUTOTARGET";
        if (group _viejo == grupoPetros) then {[[Petros,"mission"],"AS_fnc_addActionMP"] call BIS_fnc_MP;} else {[[Petros,"buildHQ"],"AS_fnc_addActionMP"] call BIS_fnc_MP;};
         call compile preprocessFileLineNumbers "initPetros.sqf";
        deleteVehicle _viejo;
        publicVariable "petros";
		};
	guer_respawn setMarkerPos _posicionTel;
	guer_respawn setMarkerAlpha 1;
	if !(isNil "vehiclePad") then {
		[vehiclePad, {deleteVehicle _this}] remoteExec ["call", 0];
		[vehiclePad, {vehiclePad = nil}] remoteExec ["call", 0];
		server setVariable ["AS_vehicleOrientation", 0, true];
	};
	if (isMultiplayer) then {hint localize "STR_HINTS_HQPLACE_MOVING"; sleep 5};
	_pos = [_posicionTel, 3, getDir petros] call BIS_Fnc_relPos;
	fuego setPos _pos;
	_rnd = getdir Petros;
	if (isMultiplayer) then {sleep 5};
	_pos = [getPos fuego, 3, _rnd] call BIS_Fnc_relPos;
	caja setPos _pos;
	_rnd = _rnd + 45;
	_pos = [getPos fuego, 3, _rnd] call BIS_Fnc_relPos;
	mapa setPos _pos;
	mapa setDir ([fuego, mapa] call BIS_fnc_dirTo);
	_rnd = _rnd + 45;
	_pos = [getPos fuego, 3, _rnd] call BIS_Fnc_relPos;
	bandera setPos _pos;
	_rnd = _rnd + 45;
	_pos = [getPos fuego, 3, _rnd] call BIS_Fnc_relPos;
	cajaVeh setPos _pos;
	if (isNil "placementDone") then {if (isMultiplayer) then {{_x setPos getPos petros} forEach playableUnits} else {Slowhand setPos (getMarkerPos guer_respawn)}} else {Slowhand allowDamage true};
	if (isMultiplayer) then
		{
		caja hideObjectGlobal false;
		cajaVeh hideObjectGlobal false;
		mapa hideObjectGlobal false;
		fuego hideObjectGlobal false;
		bandera hideObjectGlobal false;
		}
	else
		{
		caja hideObject false;
		cajaVeh hideObject false;
		mapa hideObject false;
		fuego hideObject false;
		bandera hideObject false;
		};
	openmap [false,false];
	};
"FIA_HQ" setMarkerPos (getMarkerPos guer_respawn);
posHQ = getMarkerPos guer_respawn; publicVariable "posHQ";
server setVariable ["posHQ", getMarkerPos guer_respawn, true];
if (isNil "placementDone") then {
	placementDone = true;
	publicVariable "placementDone";
};