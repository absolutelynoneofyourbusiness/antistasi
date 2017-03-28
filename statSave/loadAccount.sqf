// session ID, needs to be loaded prior to the personal data
if (isServer) then {
	["AS_session_server"] call fn_LoadID;
};
if (!isDedicated) then {
	["AS_session_client"] call fn_LoadStat;
	{player removeMagazine _x} forEach magazines player;
	{player removeWeaponGlobal _x} forEach weapons player;
	removeBackpackGlobal player;
	if ("ItemGPS" in (assignedItems player)) then {player unlinkItem "ItemGPS"};
	if ((!activeTFAR) and ("ItemRadio" in (assignedItems player))) then {player unlinkItem "ItemRadio"};
	player setPos (server getVariable ["posHQ", getMarkerPos guer_respawn]);

	waitUntil {!isNil "sessionIDloaded"};
	[format ["server ID: %1; player ID: %2", (server getVariable ["AS_session_server", -2]), (player getVariable ["AS_session_client", -1])]] remoteExec ["AS_fnc_logOutput", 2];

	if (isMultiplayer) then {
		if ((player getVariable ["AS_session_client", -1]) == (server getVariable ["AS_session_server", -2])) then {
			["gogglesPlayer"] call fn_LoadStat;
			["vestPlayer"] call fn_LoadStat;
			["outfit"] call fn_LoadStat;
			["hat"] call fn_LoadStat;

			if ([player] call isMember) then {
				["scorePlayer"] call fn_LoadStat;
				["rankPlayer"] call fn_LoadStat;
			};
			["dinero"] call fn_LoadStat;
			["personalGarage"] call fn_LoadStat;
			diag_log "Antistasi MP: Personal player stats loaded";
		} else {
			[player] call cleanGear;
			diag_log "Antistasi MP: new campaign";
		};
	} else {
		["gogglesPlayer"] call fn_LoadStat;
		["vestPlayer"] call fn_LoadStat;
		["outfit"] call fn_LoadStat;
		["hat"] call fn_LoadStat;
		diag_log "Antistasi: SP Personal player stats loaded";
	};
};

if (!isServer) exitWith {};
statsLoaded = 0; publicVariable "statsLoaded";
//ADD STATS THAT NEED TO BE LOADED HERE.
petros allowdamage false;

["enableMemAcc"] call fn_LoadStat;
["enableFTold"] call fn_LoadStat;
["campList"] call fn_LoadStat; publicVariable "campList";
["campsFIA"] call fn_LoadStat; publicVariable "campsFIA";
["puestosFIA"] call fn_LoadStat; publicVariable "puestosFIA";
["mrkFIA"] call fn_LoadStat; mrkFIA = mrkFIA + puestosFIA; publicVariable "mrkFIA"; if (isMultiplayer) then {sleep 5};
["mrkAAF"] call fn_LoadStat;
["destroyedCities"] call fn_LoadStat;
["minas"] call fn_LoadStat;
["cuentaCA"] call fn_LoadStat;
["antenas"] call fn_LoadStat;
["prestigeNATO"] call fn_LoadStat;
["prestigeCSAT"] call fn_LoadStat;
["hr"] call fn_LoadStat;
["planesAAFcurrent"] call fn_LoadStat;
["helisAAFcurrent"] call fn_LoadStat;
["APCAAFcurrent"] call fn_LoadStat;
["tanksAAFcurrent"] call fn_LoadStat;
["armas"] call fn_LoadStat;
["municion"] call fn_LoadStat;
["items"] call fn_LoadStat;
["mochis"] call fn_LoadStat;
["fecha"] call fn_LoadStat;
["prestigeOPFOR"] call fn_LoadStat;
["prestigeBLUFOR"] call fn_LoadStat;
["resourcesAAF"] call fn_LoadStat;
["resourcesFIA"] call fn_LoadStat;
["garrison"] call fn_LoadStat;
["skillFIA"] call fn_LoadStat;
["skillAAF"] call fn_LoadStat;
["distanciaSPWN"] call fn_LoadStat;
["civPerc"] call fn_LoadStat;
["minimoFPS"] call fn_LoadStat;
["smallCAmrk"] call fn_LoadStat;
["miembros"] call fn_LoadStat;
["unlockedItems"] call fn_LoadStat;
["unlockedMagazines"] call fn_LoadStat;
["unlockedWeapons"] call fn_LoadStat;
["unlockedBackpacks"] call fn_LoadStat;
["vehInGarage"] call fn_LoadStat;
["destroyedBuildings"] call fn_LoadStat;
["idleBases"] call fn_LoadStat;
["AS_destroyedZones"] call fn_LoadStat;
//===========================================================================

unlockedRifles = unlockedweapons - gear_sidearms - gear_missileLaunchers - gear_rocketLaunchers - gear_sniperRifles - gear_machineGuns; publicVariable "unlockedRifles";

_marcadores = mrkFIA + mrkAAF + campsFIA;

{
_posicion = getMarkerPos _x;
_cercano = [_marcadores,_posicion] call BIS_fnc_nearestPosition;
if (_cercano in mrkFIA) then
	{
	mrkAAF = mrkAAF - [_x];
	mrkFIA = mrkFIA + [_x];
	}
else
	{
	mrkAAF = mrkAAF + [_x];
	};
} forEach controles;

{
if ((not(_x in mrkAAF)) and (not(_x in mrkFIA)) and (_x != "FIA_HQ")) then {mrkAAF pushBack _x};
} forEach marcadores;

_marcadores = _marcadores + controles;

{

	if (_x in mrkFIA) then {
		private ["_mrkD"];
		call {
			if (_x != "FIA_HQ") then {
				_mrkD = format ["Dum%1",_x];
				_mrkD setMarkerColor guer_marker_colour;
			};

			if (_x in aeropuertos) exitWith {
				_mrkD setMarkerText format ["%2 Airport: %1",count (garrison getVariable _x), A3_Str_BLUE];
				_mrkD setMarkerType guer_marker_type;
				planesAAFmax = planesAAFmax - 1;
			    helisAAFmax = helisAAFmax - 2;
			};

			if (_x in bases) exitWith {
				_mrkD setMarkerText format ["%2 Base: %1",count (garrison getVariable _x), A3_Str_BLUE];
				_mrkD setMarkerType guer_marker_type;
				APCAAFmax = APCAAFmax - 2;
		    	tanksAAFmax = tanksAAFmax - 1;
			};

			if (_x in puestos) exitWith {
				_mrkD setMarkerText format ["%2 Outpost: %1",count (garrison getVariable _x), A3_Str_PLAYER];
			};

			if (_x in ciudades) exitWith {
				_power = [power, getMarkerPos _x] call BIS_fnc_nearestPosition;
				if ((not (_power in mrkFIA)) or (_power in destroyedCities)) then {
					[_x,false] spawn AS_fnc_adjustLamps;
				};
				if (_x in destroyedCities) then {[_x] call AS_fnc_destroyCity};
			};

			if ((_x in recursos) or (_x in fabricas)) exitWith {
				if (_x in recursos) then {_mrkD setMarkerText format ["Resource: %1",count (garrison getVariable _x)]} else {_mrkD setMarkerText format ["Factory: %1",count (garrison getVariable _x)]};
				_power = [power, getMarkerPos _x] call BIS_fnc_nearestPosition;
				if ((not (_power in mrkFIA))  or (_power in destroyedCities)) then {
					[_x,false] spawn AS_fnc_adjustLamps;
				};
				if (_x in destroyedCities) then {[_x] call AS_fnc_destroyCity};
			};

			if (_x in puertos) exitWith {
				_mrkD setMarkerText format ["Sea Port: %1",count (garrison getVariable _x)];
			};

			if (_x in power) exitWith {
				_mrkD setMarkerText format ["Power Plant: %1",count (garrison getVariable _x)];
				if (_x in destroyedCities) then {[_x] call AS_fnc_destroyCity};
			};
		};
	};

	if (_x in mrkAAF) then {
		call {
			if (_x in ciudades) exitWith {
				_power = [power, getMarkerPos _x] call BIS_fnc_nearestPosition;
				if ((not (_power in mrkAAF))  or (_power in destroyedCities)) then {
					[_x,false] spawn AS_fnc_adjustLamps;
				};
				if (_x in destroyedCities) then {[_x] call AS_fnc_destroyCity};
			};

			if ((_x in recursos) or (_x in fabricas)) exitWith {
				_power = [power, getMarkerPos _x] call BIS_fnc_nearestPosition;
				if ((not (_power in mrkAAF))  or (_power in destroyedCities)) then {
					[_x,false] spawn AS_fnc_adjustLamps;
				};
				if (_x in destroyedCities) then {[_x] call AS_fnc_destroyCity};
			};

			if ((_x in power) and (_x in destroyedCities)) exitWith {[_x] call AS_fnc_destroyCity};
		};
	};
} forEach _marcadores;

{if (not (_x in _marcadores)) then {if (_x != "FIA_HQ") then {_marcadores pushBack _x; mrkAAF pushback _x} else {mrkAAF = mrkAAF - ["FIA_HQ"]; if (not("FIA_HQ" in mrkFIA)) then {mrkFIA = mrkFIA + ["FIA_HQ"]}}}} forEach marcadores;//por si actualizo zonas.

marcadores = _marcadores;
publicVariable "marcadores";
publicVariable "mrkAAF";
publicVariable "mrkFIA";

["posHQ"] call fn_LoadStat;
["estaticas"] call fn_LoadStat;//tiene que ser el último para que el sleep del borrado del contenido no haga que despawneen

sleep 1;
if (isMultiplayer) then
	{
	{
	_jugador = _x;
	if ([_jugador] call isMember) then
		{
		{_jugador removeMagazine _x} forEach magazines _jugador;
		{_jugador removeWeaponGlobal _x} forEach weapons _jugador;
		removeBackpackGlobal _jugador;
		};
	_jugador setPos (getMarkerPos guer_respawn);
	} forEach playableUnits;
	}
else
	{
	{player removeMagazine _x} forEach magazines player;
	{player removeWeaponGlobal _x} forEach weapons player;
	removeBackpackGlobal player;
	player setPos (getMarkerPos guer_respawn);
	};

[] call AS_fnc_updateArsenal;
server setVariable ["genLMGlocked",true,true];
server setVariable ["genGLlocked",true,true];
server setVariable ["genSNPRlocked",true,true];
server setVariable ["genATlocked",true,true];
server setVariable ["genAAlocked",true,true];
[unlockedWeapons] spawn AS_fnc_weaponsCheck;

["BE_data"] call fn_LoadStat;
[false] call AS_fnc_MAINT_arsenal;

// [[petros,"hintCS","Persistent Savegame Loaded"],"commsMP"] call BIS_fnc_MP;
ASA3_saveLoaded = true;
diag_log "Antistasi: Server sided Persistent Load done";

sleep 25;
["tasks"] call fn_LoadStat;

_tmpCAmrk = + smallCAmrk;
smallCAmrk = [];

{
_base = [_x] call AS_fnc_findBaseForCA;
//if (_x == "puesto_13") then {_base = ""};
_radio = [_x] call AS_fnc_radioCheck;
if ((_base != "") and (_radio) and (_x in mrkFIA) and (not(_x in smallCAmrk))) then
	{
	[_x] remoteExec ["patrolCA",HCattack];
	sleep 5;
	smallCAmrk pushBackUnique _x;
	[_x] remoteExec ["autoGarrison",HCattack];
	};
} forEach _tmpCAmrk;
publicVariable "smallCAmrk";

petros allowdamage true;
//END
//hint "Stats loaded";
