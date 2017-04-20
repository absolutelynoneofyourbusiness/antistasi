/*
	Data format: worldName_Side_Locality_Variable
	Example: Tanoa_G_S_jna_dataList -- Tanoa, Green, Server, content of JNA
	Example: Altis_B_P_GUID_gear_uniform -- Altis, Blue, Player, PlayerUID, player's uniform
*/

// player
fn_savePlayerData = {
	params [["_varName","",[""]],"_varValue",["_playerUID","1",[""]]];
	if ((isNil "_varValue") OR (_varName == "") OR (count _playerUID < 16)) exitWith {diag_log format ["Error in fn_savePlayerData -- name: %1; value: %2; UID: %3", _varname,_varvalue,_playerUID]};
	if (_varvalue isEqualTo "") exitWith {};
	profileNameSpace setVariable [format ["%1_%2_P_%3_%4",worldName,static_playerSide,_playerUID,_varName],_varvalue];
};

fn_loadPlayerData = {
	params [["_varName","",[""]],["_playerUID","1",[""]]];
	if ((_varName == "") OR (count _playerUID < 16)) exitWith {diag_log format ["Error in fn_loadPlayerData -- name: %1; UID: %2", _varname,_playerUID]};
	_varValue = profileNameSpace getVariable (format ["%1_%2_P_%3_%4",worldName,static_playerSide,_playerUID,_varName]);
	if (isNil "_varValue") exitWith {diag_log format ["Error in fn_loadPlayerData, no value -- name: %1; UID: %2", _varname,_playerUID]};
	[_varName,_varValue] call fn_setPlayerData;
};

// server
fn_saveData = {
	params [["_varName","",[""]],"_varValue"];
	if (_varName == "") exitWith {diag_log format ["Error in fn_saveData, no name --  name: %1; value: %2", _varname,_varvalue]};
	if (isNil "_varValue") exitWith {diag_log format ["Error in fn_saveData, no value --  name: %1; value: %2", _varname,_varvalue]};
	profileNameSpace setVariable [format ["%1_%2_S_%3",worldName,static_playerSide,_varname],_varvalue];
};

fn_loadData = {
	params [["_varname","",[""]]];
	if (_varName == "") exitWith {diag_log format ["Error in fn_loadData, no name -- name: %1", _varname]};
	_varValue = profileNameSpace getVariable (format ["%1_%2_S_%3",worldName,static_playerSide,_varname]);
	if (isNil "_varValue") exitWith {};
	[_varName,_varValue] call fn_setData;
};

fn_saveProfile = {saveProfileNamespace};

//===========================================================================

fn_setPlayerData = {
	params ["_varName","_varValue"];
	call {
		if(_varName == 'gear_goggles') exitWith {removeGoggles player; player addGoggles _varValue};
		if(_varName == 'gear_vest') exitWith {removeVest player; player addVest _varValue};
		if(_varName == 'gear_uniform') exitWith {removeUniform player; player forceAddUniform _varValue};
		if(_varName == 'gear_head') exitWith {removeHeadGear player; player addHeadGear _varValue};

		if(_varName == 'pers_funds') exitWith {player setVariable ["dinero",_varValue,true];};
		if(_varName == 'stat_score') exitWith {player setVariable ["score",_varValue,true];};
		if(_varName == 'stat_rank') exitWith {player setRank _varValue; player setVariable ["rango",_varValue,true]; [player, _varValue] remoteExec ["ranksMP"]};
		if(_varName == 'pers_garage') exitWith {personalGarage = _varValue};
	};
};

//ADD VARIABLES TO THIS ARRAY THAT NEED SPECIAL SCRIPTING TO LOAD
specialVarLoads =
["campaign_playerList","cuentaCA","miembros","antenas","posHQ","prestigeNATO","prestigeCSAT","APCAAFcurrent","tanksAAFcurrent","planesAAFcurrent","helisAAFcurrent","time","resourcesAAF","skillFIA","skillAAF","destroyedBuildings","flag_chopForest","BE_data","enableOldFT","enableMemAcc","hr","resourcesFIA","vehicles","weapons","magazines","items","backpacks","objectsHQ","addObjectsHQ","supportOPFOR","supportBLUFOR","garrison","mines","emplacements","campList","tasks","idleBases","unlockedWeapons","unlockedItems","unlockedMagazines","unlockedBackpacks"];

/*
	Variables that are loaded, but do not require special procedures
	["smallCAmrk","mrkAAF","mrkFIA","destroyedCities","distanciaSPWN","civPerc","minimoFPS","AS_destroyedZones","jna_dataList","vehInGarage"]
*/

//THIS FUNCTIONS HANDLES HOW STATS ARE LOADED
fn_setData = {
	params ["_varName","_varValue"];

	if (_varName in specialVarLoads) then {
		call {
			if(_varName == 'campaign_playerList') exitWith {server setVariable ["campaign_playerList",_varValue,true]};
			if(_varName == 'cuentaCA') exitWith {cuentaCA = _varValue max 2700};
			if(_varName == 'flag_chopForest') then {
				flag_chopForest = _varValue;
				if (flag_chopForest) then {[] spawn AS_fnc_clearForest};
			};
			if(_varName == 'BE_data') exitWith {[_varValue] call fnc_BE_load};
			if(_varName == 'unlockedWeapons') exitWith {
				unlockedWeapons = _varvalue;
				lockedWeapons = lockedWeapons - unlockedWeapons;
				if (activeJNA) exitWith {};
				// XLA fixed arsenal
				if (activeXLA) then {
					[caja,unlockedWeapons,true] call XLA_fnc_addVirtualWeaponCargo;
				} else {
					[caja,unlockedWeapons,true] call BIS_fnc_addVirtualWeaponCargo;
				};
			};
			if(_varName == 'unlockedBackpacks') exitWith {
				unlockedBackpacks = _varvalue;
				genBackpacks = genBackpacks - unlockedBackpacks;
				if (activeJNA) exitWith {};
				// XLA fixed arsenal
				if (activeXLA) then {
					[caja,unlockedBackpacks,true] call XLA_fnc_addVirtualBackpackCargo;
				} else {
					[caja,unlockedBackpacks,true] call BIS_fnc_addVirtualBackpackCargo;
				};
			};
			if(_varName == 'unlockedItems') exitWith {
				unlockedItems = _varValue;
				if (activeJNA) exitWith {};
				// XLA fixed arsenal
				if (activeXLA) then {
					[caja,unlockedItems,true] call XLA_fnc_addVirtualItemCargo;
				} else {
					[caja,unlockedItems,true] call BIS_fnc_addVirtualItemCargo;
				};
				{
				if (_x in unlockedItems) then {unlockedOptics pushBack _x};
				} forEach genOptics;
			};
			if(_varName == 'unlockedMagazines') exitWith {
				unlockedMagazines = _varValue;
				if (activeJNA) exitWith {};
				// XLA fixed arsenal
				if (activeXLA) then {
					[caja,unlockedMagazines,true] call XLA_fnc_addVirtualMagazineCargo;
				} else {
					[caja,unlockedMagazines,true] call BIS_fnc_addVirtualMagazineCargo;
				};
			};
			if(_varName == 'prestigeNATO') exitWith {server setVariable ["prestigeNATO",_varValue,true]};
			if(_varName == 'prestigeCSAT') exitWith {server setVariable ["prestigeCSAT",_varValue,true]};
			if(_varName == 'hr') exitWith {server setVariable ["HR",_varValue,true]};
			if(_varName == 'planesAAFcurrent') exitWith {
				planesAAFcurrent = _varValue max 0;
				if ((planesAAFcurrent > 0) and (count indAirForce < 2)) then {indAirForce = indAirForce + planes; publicVariable "indAirForce"}
			};
			if(_varName == 'helisAAFcurrent') exitWith {
				helisAAFcurrent = _varValue max 0;
				if (helisAAFcurrent > 0) then {
					indAirForce = indAirForce - heli_armed;
					indAirForce = indAirForce + heli_armed;
					publicVariable "indAirForce";
				};
			};
			if(_varName == 'APCAAFcurrent') exitWith {
				APCAAFcurrent = _varValue max 0;
				if (APCAAFcurrent > 0) then {
					enemyMotorpool = enemyMotorpool -  vehAPC - vehIFV;
					enemyMotorpool = enemyMotorpool +  vehAPC + vehIFV;
					publicVariable "enemyMotorpool";
				};
			};
			if(_varName == 'tanksAAFcurrent') exitWith {
				tanksAAFcurrent = _varValue max 0;
				if (tanksAAFcurrent > 0) then {
					enemyMotorpool = enemyMotorpool - vehTank;
					enemyMotorpool = enemyMotorpool +  vehTank;
					publicVariable "enemyMotorpool"
				};
			};
			if(_varName == 'time') exitWith {setDate _varValue; forceWeatherChange};
			if(_varName == 'resourcesAAF') exitWith {server setVariable ["resourcesAAF",_varValue,true]};
			if(_varName == 'resourcesFIA') exitWith {server setVariable ["resourcesFIA",_varValue,true]};
			if(_varName == 'destroyedBuildings') exitWith {
				for "_i" from 0 to (count _varValue) - 1 do {
					_posBuild = _varValue select _i;
					if (typeName _posBuild == "ARRAY") then {
						_buildings = [];
						_dist = 5;
						while {count _buildings == 0} do {
							_buildings = nearestObjects [_posBuild, listMilBld, _dist];
							_dist = _dist + 5;
						};
						if (count _buildings > 0) then {
							_milBuild = _buildings select 0;
							_milBuild setDamage 1;
						};
						destroyedBuildings = destroyedBuildings + [_posBuild];
					};
				};
			};
			if(_varName == 'skillFIA') exitWith {
				server setVariable ["skillFIA",_varValue,true];
				{
					_coste = server getVariable _x;
					for "_i" from 1 to _varValue do {
						_coste = round (_coste + (_coste * (_i/280)));
					};
					server setVariable [_x,_coste,true];
				} forEach guer_soldierArray;
			};
			if(_varName == 'skillAAF') exitWith {
				skillAAF = _varvalue;
				{
					_coste = server getVariable _x;
					for "_i" from 1 to skillAAF do {
						_coste = round (_coste + (_coste * (_i/280)));
					};
					server setVariable [_x,_coste,true];
				} forEach units_enemySoldiers;
			};
			if(_varName == 'mines') exitWith {
				/*for "_i" from 0 to (count _varvalue) - 1 do {
					_unknownMine = false;
					_tipoMina = _varvalue select _i select 0;
					switch _tipoMina do {
						case apMine_type: {_tipoMina = apMine_placed};
						case atMine_type: {_tipoMina = atMine_placed};
						case "APERSBoundingMine_Range_Ammo": {_tipoMina = "APERSBoundingMine"};
						case "SLAMDirectionalMine_Wire_Ammo": {_tipoMina = "SLAMDirectionalMine"};
						case "APERSTripMine_Wire_Ammo": {_tipoMina = "APERSTripMine"};
						case "ClaymoreDirectionalMine_Remote_Ammo": {_tipoMina = "Claymore_F"};
						default {
							_unknownMine = true;
						};
					};
					if !(_unknownMine) then {
						_posMina = _varvalue select _i select 1;
						_dirMina = _varvalue select _i select 2;
						_mina = createMine [_tipoMina, _posMina, [], _dirMina];
						_detectada = _varvalue select _i select 3;
						if (_detectada) then {side_blue revealMine _mina};
					};
				};*/
			};
			if(_varName == 'garrison') exitWith {
				_marcadores = mrkFIA - puestosFIA - controles - ciudades;
				_garrison = _varvalue;
				for "_i" from 0 to (count _marcadores - 1) do
					{
					garrison setVariable [_marcadores select _i,_garrison select _i,true];
					};
				};
			if(_varName == 'emplacements') exitWith {
				{
					_mrk = createMarker [format ["FIApost%1", random 1000], _x];
					_mrk setMarkerShape "ICON";
					_mrk setMarkerType "loc_bunker";
					_mrk setMarkerColor "ColorYellow";
					if (isOnRoad _x) then {
						_mrk setMarkerText "FIA Roadblock";
						FIA_RB_list pushBackUnique _mrk;
					} else {
						_mrk setMarkerText "FIA Watchpost";
						FIA_WP_list pushBackUnique _mrk;
					};
					spawner setVariable [_mrk,false,true];
					puestosFIA pushBack _mrk;
				} forEach _varvalue;
			};
			if (_varName == 'campList') exitWith {
				if (count _varvalue != 0) then {
					{
						_mrk = createMarker [format ["FIACamp%1", random 1000], (_x select 0)];
						_mrk setMarkerShape "ICON";
						_mrk setMarkerType "loc_bunker";
						_mrk setMarkerColor "ColorOrange";
						_txt = _x select 1;
						_mrk setMarkerText _txt;
						usedCN pushBackUnique _txt;
						spawner setVariable [_mrk,false,true];
						campList pushBack [_mrk, _txt];
						campsFIA pushBack _mrk;
					} forEach _varvalue;
				};
			};
			if(_varName == 'enableOldFT') exitWith {server setVariable ["enableFTold",_varValue,true]};
			if(_varName == 'enableMemAcc') exitWith {server setVariable ["enableMemAcc",_varValue,true]};
			if(_varName == 'antenas') exitWith {
				antenasmuertas = _varvalue;
				for "_i" from 0 to (count _varvalue - 1) do {
				    _posAnt = _varvalue select _i;
				    _mrk = [mrkAntenas, _posAnt] call BIS_fnc_nearestPosition;
				    _antena = [antenas,_mrk] call BIS_fnc_nearestPosition;
				    antenas = antenas - [_antena];
				    _antena removeAllEventHandlers "Killed";
				    sleep 1;
				    _antena setDamage 1;
				    deleteMarker _mrk;
				};
				antenasmuertas = _varvalue;
			};
			if(_varName == 'weapons') exitWith {
				clearWeaponCargoGlobal caja;
				{caja addWeaponCargoGlobal [_x,1]} forEach _varValue;
			};
			if(_varName == 'magazines') exitWith {
				clearMagazineCargoGlobal caja;
				{caja addMagazineCargoGlobal [_x,1]} forEach _varValue;
			};
			if(_varName == 'items') exitWith {
				clearItemCargoGlobal caja;
				{caja addItemCargoGlobal [_x,1]} forEach _varValue;
			};
			if(_varName == 'backpacks') exitWith {
				clearBackpackCargoGlobal caja;
				{caja addBackpackCargoGlobal [_x,1]} forEach _varValue;
			};
			if(_varname == 'supportOPFOR') exitWith {
				for "_i" from 0 to (count ciudades) - 1 do {
					_ciudad = ciudades select _i;
					_datos = server getVariable _ciudad;
					_numCiv = _datos select 0;
					_numVeh = _datos select 1;
					_prestigeOPFOR = _varvalue select _i;
					_prestigeBLUFOR = _datos select 3;
					_datos = [_numCiv,_numVeh,_prestigeOPFOR,_prestigeBLUFOR];
					server setVariable [_ciudad,_datos,true];
				};
			};
			if(_varname == 'supportBLUFOR') exitWith {
				for "_i" from 0 to (count ciudades) - 1 do {
					_ciudad = ciudades select _i;
					_datos = server getVariable _ciudad;
					_numCiv = _datos select 0;
					_numVeh = _datos select 1;
					_prestigeOPFOR = _datos select 2;
					_prestigeBLUFOR = _varvalue select _i;
					_datos = [_numCiv,_numVeh,_prestigeOPFOR,_prestigeBLUFOR];
					server setVariable [_ciudad,_datos,true];
				};
			};
			if(_varname == 'idleBases') exitWith {
				{
					server setVariable [(_x select 0),(_x select 1),true];
				} forEach _varValue;
			};

			// HQ
			if(_varName == 'posHQ') exitWith {
				{
					if (getMarkerPos _x distance _varvalue < 1000) then {
						mrkAAF = mrkAAF - [_x];
						mrkFIA = mrkFIA + [_x];
					};
				} forEach controles;

				"FIA_HQ" setMarkerPos _varValue;
				posHQ = _varValue;
				guer_respawn setMarkerPos _varValue;
				guer_respawn setMarkerAlpha 1;
				server setVariable ["posHQ", _varValue, true];
			};
			if(_varName == 'objectsHQ') exitWith {
				{
					_type = _x select 0;
					switch (_type) do {
						case "bandera": {
							bandera setDir (_x select 2);
							bandera setPosATL (_x select 1);
						};
						case "caja": {
							caja setDir (_x select 2);
							caja setPosATL (_x select 1);
						};
						case "cajaveh": {
							cajaveh setDir (_x select 2);
							cajaveh setPosATL (_x select 1);
						};
						case "fuego": {
							fuego setDir (_x select 2);
							fuego setPosATL (_x select 1);
							fuego inflame true
						};
						case "mapa": {
							mapa setDir (_x select 2);
							mapa setPosATL (_x select 1);
						};
						case "petros": {
							petros setDir (_x select 2);
							petros setPosATL (_x select 1);
						};
					};
				} forEach _varvalue;
			};
			if(_varName == 'addObjectsHQ') exitWith {
				if (count _varvalue == 0) exitWith {};
				{
					_obj = (_x select 0) createVehicle [0,0,0];
					_obj setDir (_x select 2);
					_obj setPosATL (_x select 1);

					if ((_x select 0) == "Land_JumpTarget_F") then {
						obj_vehiclePad = _obj;
						[obj_vehiclePad,"removeObj"] remoteExec ["AS_fnc_addActionMP"];
						server setVariable ["obj_vehiclePad",getPosATL obj_vehiclePad,true];
					} else {
						[_obj,"moveObject"] remoteExec ["AS_fnc_addActionMP"];
						[_obj,"removeObj"] remoteExec ["AS_fnc_addActionMP"];
					};
				} forEach _varvalue;
			};
			//

			if(_varname == 'vehicles') exitWith {
				for "_i" from 0 to (count _varvalue) - 1 do {
					_tipoVeh = _varvalue select _i select 0;
					_posVeh = _varvalue select _i select 1;
					_dirVeh = _varvalue select _i select 2;

					_veh = _tipoVeh createVehicle [0,0,0];
					_veh setDir _dirVeh;
					_veh setPosATL _posVeh;

					if (_tipoVeh in (statics_allMGs + statics_allATs + statics_allAAs + statics_allMortars)) then {
						staticsToSave pushBack _veh;
					};
					[_veh] spawn VEHinit;
				};
			};
			if(_varname == 'tasks') exitWith {
				{
					if (_x == "AtaqueAAF") then {
						[] spawn AS_fnc_spawnAttack;
					} else {
						if (_x == "DEF_HQ") then {
							[] spawn ataqueHQ;
						} else {
							[_x,true] call missionRequest;
						};
					};
				} forEach _varvalue;
			};
			if(_varname == 'jna_dataList') exitWith {
				_firstPart = _varvalue select [0,18];
				_secondPart = _varvalue select [18,10];

				_fullArray = _firstPart + _secondPart;
				_fullArray set [26,_varvalue select 26];
				jna_dataList = +_fullArray;
			};
		};
	} else {
		call compile format ["%1 = %2",_varName,_varValue];
	};
};

//==================================================================================================================================================================================================
saveFuncsLoaded = true;