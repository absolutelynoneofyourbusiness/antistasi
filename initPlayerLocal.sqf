waitUntil {!isNull player};
waitUntil {player == player};

player removeweaponGlobal "itemmap";
player removeweaponGlobal "itemgps";
if (isMultiplayer) then
	{
	[] execVM "briefing.sqf";
	if (!isServer) then
		{
		call compile preprocessFileLineNumbers "initVar.sqf";
		if (!hasInterface) then {call compile preprocessFileLineNumbers "roadsDB.sqf"};
		call compile preprocessFileLineNumbers "initFuncs.sqf";
		};
	};

_isJip = _this select 1;
private ["_colorWest", "_colorEast"];
_colorWest = west call BIS_fnc_sideColor;
_colorEast = east call BIS_fnc_sideColor;
{
_x set [3, 0.33]
} forEach [_colorWest, _colorEast];
_introShot =
	[
    position petros, // Target position
    "Altis Island", // SITREP text
    50, //  altitude
    50, //  radius
    90, //  degrees viewing angle
    0, // clockwise movement
    [
    	["\a3\ui_f\data\map\markers\nato\o_inf.paa", _colorWest, markerPos "insertMrk", 1, 1, 0, "Insertion Point", 0],
        ["\a3\ui_f\data\map\markers\nato\o_inf.paa", _colorEast, markerPos "towerBaseMrk", 1, 1, 0, "Radio Towers", 0]
    ]
    ] spawn BIS_fnc_establishingShot;

if (isMultiplayer) then {waitUntil {!isNil "initVar"}; diag_log format ["Antistasi MP Client. initVar is public. Version %1",antistasiVersion];};
_titulo = ["A3 - Antistasi","by Barbolani",antistasiVersion] spawn BIS_fnc_infoText;

if (isMultiplayer) then
	{
	player setVariable ["elegible",true,true];
	musicON = false;
	waitUntil {scriptdone _introshot};
	disableUserInput true;
	cutText ["Waiting for Players and Server Init","BLACK",0];
	diag_log "Antistasi MP Client. Waiting for serverInitDone";
	waitUntil {(!isNil "serverInitDone")};
	cutText ["Starting Mission","BLACK IN",0];
	diag_log "Antistasi MP Client. serverInitDone is public";
	diag_log format ["Antistasi MP Client: JIP?: %1",_isJip];
	caja addEventHandler ["ContainerOpened", {
	    _jugador = _this select 1;
	    if (not([_jugador] call isMember)) then {
	    	_jugador setPos position petros;
			hint format ["You are not in the Member's List of this Server.\n\nAsk the Commander in order to be allowed to access the HQ Ammobox.\n\nIn the meantime you may use the other box to store equipment and share it with others.\n\nArsenal Unlocking Requirements\nWeapons: %1\nBackpacks: %5\nMagazines/Usables: %2\nOptics: %3\nVests: %3\nOther Items: %4\nImported Items: %6",
				["weapons"] call AS_fnc_getUnlockRequirement,
				["magazines"] call AS_fnc_getUnlockRequirement,
				["vests"] call AS_fnc_getUnlockRequirement,
				["items"] call AS_fnc_getUnlockRequirement,
				["backpacks"] call AS_fnc_getUnlockRequirement,
				(["items"] call AS_fnc_getUnlockRequirement) + 10];
	    };
	}];
    player addEventHandler ["InventoryOpened", {
		_control = false;
		if !([_this select 0] call isMember) then {
			if ((_this select 1 == caja) or ((_this select 0) distance caja < 3)) then {
				_control = true;
				hint format ["You are not in the Member's List of this Server.\n\nAsk the Commander in order to be allowed to access the HQ Ammobox.\n\nIn the meantime you may use the other box to store equipment and share it with others.\n\nArsenal Unlocking Requirements\nWeapons: %1\nBackpacks: %5\nMagazines/Usables: %2\nOptics: %3\nVests: %3\nOther Items: %4\nImported Items: %6",
					["weapons"] call AS_fnc_getUnlockRequirement,
					["magazines"] call AS_fnc_getUnlockRequirement,
					["vests"] call AS_fnc_getUnlockRequirement,
					["items"] call AS_fnc_getUnlockRequirement,
					["backpacks"] call AS_fnc_getUnlockRequirement,
					(["items"] call AS_fnc_getUnlockRequirement) + 10];
			};
		};
		_control
	}];
	player addEventHandler ["Fired",
		{
		_tipo = _this select 1;
		if ((_tipo == "Put") or (_tipo == "Throw")) then
			{
			if (player distance petros < 50) then
				{
				deleteVehicle (_this select 6);
				if (_tipo == "Put") then
					{
					if (player distance petros < 10) then {[player,60] spawn AS_fnc_punishPlayer};
					};
				};
			};
		}];

	player addEventHandler ["InventoryClosed", {
		[] spawn AS_fnc_skillAdjustments;
	}];

	player addEventHandler ["Take",{
	    [] spawn AS_fnc_skillAdjustments;
	}];

	[missionNamespace, "arsenalClosed", {
		[] spawn AS_fnc_skillAdjustments;
	}] call BIS_fnc_addScriptedEventHandler;

	if (("AS_virtualArsenal" call BIS_fnc_getParamValue) == 0) then {
		caja addEventHandler ["ContainerOpened", {
			if !(isNil "AS_currentlySelling") then {
				(_this select 1) setPos position petros;
			};
	    }];
    	player addEventHandler ["InventoryOpened", {
    		_control = false;
    		if !(isNil "AS_currentlySelling") then {
				if ((_this select 1 == caja) or ((_this select 0) distance caja < 5)) then {
					_control = true;
				};
			};
			_control
		}];
	};
	}
else
	{
	Slowhand = player;
	grupo = group player;
	grupo setGroupId ["Slowhand","GroupColor4"];
	player setIdentity "protagonista";
	player setUnitRank "COLONEL";
	player hcSetGroup [group player];
	waitUntil {(scriptdone _introshot) and (!isNil "serverInitDone")};
	addMissionEventHandler ["Loaded", {[] execVM "statistics.sqf";[] execVM "reinitY.sqf";}];
	};
disableUserInput false;
player addWeaponGlobal "itemmap";
player addWeaponGlobal "itemgps";
player setVariable ["owner",player,true];
player setVariable ["punish",0,true];
player setVariable ["dinero",100,true];
player setVariable ["BLUFORSpawn",true,true];
player setVariable ["rango",rank player,true];
if (player!=Slowhand) then {player setVariable ["score", 0,true]} else {player setVariable ["score", 25,true]};
rezagados = creategroup WEST;
(group player) enableAttack false;
if (!activeACE) then
	{
	[player] execVM "Revive\initRevive.sqf";
	tags = [] execVM "tags.sqf";
	if ((cadetMode) and (isMultiplayer)) then {[] execVM "playerMarkers.sqf"};
	}
else
	{
	if (activeACEhearing) then {player addItem "ACE_EarPlugs"};
	if (!activeACEMedical) then {[player] execVM "Revive\initRevive.sqf"} else {player setVariable ["inconsciente",false,true]};
	[] execVM "playerMarkers.sqf";
	};
gameMenu = (findDisplay 46) displayAddEventHandler ["KeyDown",AS_fnc_keyDownMain];
if (activeAFRF) then {[player] execVM "Municion\RHSdress.sqf"};
player setvariable ["compromised",0];
player addEventHandler ["FIRED",
	{
	_player = _this select 0;
	if (captive _player) then
		{
		if ({((side _x== side_red) or (side _x== side_green)) and ((_x knowsAbout player > 1.4) || (_x distance player < 200))} count allUnits > 0) then
			{
			_player setCaptive false;
			if (vehicle _player != _player) then
				{
				{if (isPlayer _x) then {[_x,false] remoteExec ["setCaptive",_x]}} forEach ((assignedCargo (vehicle _player)) + (crew (vehicle _player)));
				};
			}
		else
			{
			_ciudad = [ciudades,_player] call BIS_fnc_nearestPosition;
			_size = [_ciudad] call sizeMarker;
			_datos = server getVariable _ciudad;
			if (random 100 < _datos select 2) then
				{
				if (_player distance getMarkerPos _ciudad < _size * 1.5) then
					{
					_player setCaptive false;
					if (vehicle _player != _player) then
						{
						{if (isPlayer _x) then {[_x,false] remoteExec ["setCaptive",_x]}} forEach ((assignedCargo (vehicle _player)) + (crew (vehicle _player)));
						};
					};
				};
			};
		}
	}
	];
player addEventHandler ["HandleHeal",
	{
	_player = _this select 0;
	if (captive _player) then
		{
		if ({((side _x== side_red) or (side _x== side_green)) and (_x knowsAbout player > 1.4)} count allUnits > 0) then
			{
			_player setCaptive false;
			}
		else
			{
			_ciudad = [ciudades,_player] call BIS_fnc_nearestPosition;
			_size = [_ciudad] call sizeMarker;
			_datos = server getVariable _ciudad;
			if (random 100 < _datos select 2) then
				{
				if (_player distance getMarkerPos _ciudad < _size * 1.5) then
					{
					_player setCaptive false;
					};
				};
			};
		}
	}
	];
player addEventHandler ["WeaponAssembled",{
	params ["_EHunit", "_EHobj"];
	if (_EHunit isKindOf "StaticWeapon") then {
		_EHobj addAction [localize "STR_ACT_MOVEASSET", {[_this select 0,_this select 1,_this select 2,"static"] spawn AS_fnc_moveObject},nil,0,false,true,"","(_this == Slowhand)"];
		if !(_EHunit in staticsToSave) then {
			staticsToSave pushBack _EHunit;
			publicVariable "staticsToSave";
			[_EHunit] spawn VEHinit;
		};
	} else {
		_EHobj addEventHandler ["Killed",{[_this select 0] remoteExec ["postmortem",2]}];
	};
}];
player addEventHandler ["WeaponDisassembled",
		{
		_bag1 = _this select 1;
		_bag2 = _this select 2;
		//_bag1 = objectParent (_this select 1);
		//_bag2 = objectParent (_this select 2);
		[_bag1] spawn VEHinit;
		[_bag2] spawn VEHinit;
		}
	];

player addEventHandler ["GetInMan",
	{
	private ["_unit","_veh"];
	_unit = _this select 0;
	_veh = _this select 2;
	_exit = false;
	if (isMultiplayer) then
		{
		_owner = _veh getVariable "duenyo";
		if (!isNil "_owner") then
			{
			if (_owner isEqualType "") then
				{
				if ({getPlayerUID _x == _owner} count (units group player) == 0) then
					{
					hint "You cannot board other player vehicle if you are not in the same group";
					moveOut _unit;
					_exit = true;
					};
				};
			};
		};
	if (!_exit) then
		{
		if (((typeOf _veh) in CIV_vehicles) or ((typeOf _veh) == civHeli))  then
			{
			if (!(_veh in reportedVehs)) then
				{
				[] spawn undercover;
				};
			};
		if (_veh isKindOf "Truck_F") then {
			if ((not (_veh isKindOf "C_Van_01_fuel_F")) and (not (_veh isKindOf "I_Truck_02_fuel_F")) and (not (_veh isKindOf "B_G_Van_01_fuel_F"))) then {
				if (_this select 1 == "driver") then {
					_EHid = _unit addAction [localize "Str_act_loadAmmobox", "Municion\transfer.sqf",nil,0,false,true];
					_unit setVariable ["transferID", _EHid, true];
				};
			};
		};
	};
}];

player addEventHandler ["GetOutMan",{
	if !((player getVariable ["transferID", -1]) == -1) then {
		player removeaction (player getVariable "transferID");
		player setVariable ["transferID", nil, true];
	};
}];

if (activeACE) then {
	player addEventHandler ["GetInMan", {
		private ["_unit","_veh"];
		_unit = _this select 0;
		_veh = _this select 2;
		_testEH = _unit addEventHandler ["HandleDamage", {
			_unit = _this select 0;
			_part = _this select 1;
			_damage = _this select 2;
			_source = _this select 3;
			_projectile = _this select 4;
			if (_damage > 0.9) then {player setVariable ["ACE_isUnconscious",true,true]; player setCaptive true; 0.9} else {_damage};
		}];
		_unit setVariable ["testEH", _testEH, true];
	}];

	player addEventHandler ["GetOutMan", {
		if !((player getVariable ["testEH", -1]) == -1) then {
			player removeEventHandler ["HandleDamage", (player getVariable ["testEH", -1])];
			player setVariable ["testEH", nil, true];
		};
	}];
};


if (isMultiplayer) then
	{
	["InitializePlayer", [player]] call BIS_fnc_dynamicGroups;//Exec on client
	["InitializeGroup", [player,WEST,true]] call BIS_fnc_dynamicGroups;
	personalGarage = [];
	if (!isNil "placementDone") then {_isJip = true};//workaround for BIS fail on JIP detection
	};
caja addEventHandler ["ContainerOpened", {
	hint format ["Arsenal Unlocking Requirements\nWeapons: %1\nBackpacks: %5\nMagazines/Usables: %2\nOptics: %3\nVests: %3\nOther Items: %4\nImported Items: %6",
		["weapons"] call AS_fnc_getUnlockRequirement,
		["magazines"] call AS_fnc_getUnlockRequirement,
		["vests"] call AS_fnc_getUnlockRequirement,
		["items"] call AS_fnc_getUnlockRequirement,
		["backpacks"] call AS_fnc_getUnlockRequirement,
		(["items"] call AS_fnc_getUnlockRequirement) + 10];
}];

if (_isJip) then
	{
	waitUntil {scriptdone _introshot};
	[] execVM "modBlacklist.sqf";
	//player setVariable ["score",0,true];
	//player setVariable ["owner",player,true];
	player setVariable ["punish",0,true];
	player setUnitRank "PRIVATE";
	waitUntil {!isNil "posHQ"};
	player setPos  (server getVariable ["posHQ", getMarkerPos guer_respawn]);
	[true] execVM "reinitY.sqf";
	if (not([player] call isMember)) then
		{
		if (serverCommandAvailable "#logout") then
			{
			miembros pushBack (getPlayerUID player);
			publicVariable "miembros";
			hint "You are not in the member's list, but as you are Server Admin, you have been added up. Welcome!"
			}
		else
			{
			hint "Welcome Guest\n\nYou have joined this server as guest";
			//if ((count playableUnits == maxPlayers) and (({[_x] call isMember} count playableUnits) < count miembros) and (serverName in servidoresOficiales)) then {["serverFull",false,1,false,false] call BIS_fnc_endMission};
			};
		}
	else
		{
		hint format ["Welcome back %1", name player];
		if (serverName in servidoresOficiales) then
			{
			if ((count playableUnits == maxPlayers) and (({[_x] call isMember} count playableUnits) < count miembros)) then
				{
				{
				if (not([_x] call isMember)) exitWith {["serverFull",false,1,false,false] remoteExec ["BIS_fnc_endMission",_x]};
				} forEach playableUnits;
				};
			};
		if ({[_x] call isMember} count playableUnits == 1) then
			{
			[player] call stavrosInit;
			[] remoteExec ["assignStavros",2];
			};
		};
	{
	if (_x isKindOf "FlagCarrier") then
		{
		_marcador = [marcadores,getPos _x] call BIS_fnc_nearestPosition;
		if ((not(_marcador in colinas)) and (not(_marcador in controles))) then
			{
			if (_marcador in mrkAAF) then
				{
				_x addAction [localize "Str_act_takeFlag", {[[_this select 0, _this select 1],"mrkWIN"] call BIS_fnc_MP;},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
				}
			else
				{
				_x addAction [localize "Str_act_recruitUnit", {nul=[] execVM "Dialogs\unit_recruit.sqf";;},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
				_x addAction [localize "Str_act_buyVehicle", {createDialog "vehicle_option";},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
				_x addAction [localize "Str_act_persGarage", {[true] spawn garage},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
				};
			};
		};
	} forEach vehicles - [bandera,fuego,caja,cajaVeh];
	{
	if (typeOf _x == guer_POW) then
		{
		if (!isPlayer (leader group _x)) then
			{
			_x addAction [localize "Str_act_orderRefugee", "AI\liberaterefugee.sqf",nil,0,false,true];
			};
		};
	} forEach allUnits;
	if (petros == leader group petros) then
		{
		removeAllActions petros;
		petros addAction [localize "Str_act_missionRequest", {nul=CreateDialog "mission_menu";},nil,0,false,true];
		}
	else
		{
		removeAllActions petros;
		petros addAction [localize "Str_act_buildHQ", {[] spawn buildHQ},nil,0,false,true];
		};

	if ((player == Slowhand) and (isNil "placementDone") and (isMultiplayer)) then {
		[] execVM "UI\startMenu.sqf";
	} else {
		[true] execVM "Dialogs\firstLoad.sqf";
	};
	diag_log "Antistasi MP Client. JIP client finished";
}
else {
	if (isNil "placementDone") then {
		waitUntil {!isNil "Slowhand"};
		if (player == Slowhand) then {
		    if (isMultiplayer) then {
		    	HC_comandante synchronizeObjectsAdd [player];
				player synchronizeObjectsAdd [HC_comandante];
				if (!(serverName in servidoresOficiales) or (enableRestart)) then {[] execVM "UI\startMenu.sqf"};
				diag_log "Antistasi MP Client. Client finished";
		    } else {
		    	miembros = [];
		    	[] execVM "Dialogs\firstLoad.sqf";
		    };
		};
	};
};

waitUntil {scriptDone _titulo};

statistics = [] execVM "statistics.sqf";
removeAllActions caja;

// XLA fixed arsenal
if !(isnil "XLA_fnc_addVirtualItemCargo") then {
	["AmmoboxInit",[caja,false,{true},"Arsenal",true]] call xla_fnc_arsenal;
	caja addAction [localize "STR_ACT_ARSENAL", {["Open",[false,caja,player,true]] call xla_fnc_arsenal;},[],6,true,false,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",5];
} else {
	_action = caja addaction [localize "Str_act_arsenal",
	{_this call accionArsenal;},
	[],
	6,
	true,
	false,
	"",
	"
	_cargo = _target getvariable ['bis_addVirtualWeaponCargo_cargo',[[],[],[],[]]];
	if ({count _x > 0} count _cargo == 0) then
		{
		_target removeaction (_target getvariable ['bis_fnc_arsenal_action',-1]);
		_target setvariable ['bis_fnc_arsenal_action',nil];
		};
	_condition = _target getvariable ['bis_fnc_arsenal_condition',{true}];
	alive _target && {_target distance _this < 5} && {call _condition}
	"
	];
	caja setvariable ["bis_fnc_arsenal_action",_action];
};

// add a new TFAR radio to your loadout everytime you close the XLA arsenal -- if anyone knows of a way to actually keep your radio with the current XLA setting, give us a shout
if ((activeTFAR) && !(isnil "XLA_fnc_addVirtualItemCargo")) then {
	[missionNamespace, "arsenalClosed", {
		if !(count (player call TFAR_fnc_radiosList) > 0) then {
			player linkItem guer_radio_TFAR;
			[player] spawn AS_fnc_loadTFARsettings;
		};
	}] call BIS_fnc_addScriptedEventHandler;
};

if !(isMultiplayer) then {
	if (activeACEMedical) then {
		player setVariable ["inconsciente",false,true];
		player setVariable ["respawning",false];
		player addEventHandler ["HandleDamage", {
			if (player getVariable ["ACE_isUnconscious", false]) then {
				0 = [player] spawn ACErespawn;
			};
		}
		];
	};
};

caja addAction [localize "STR_ACT_UNLOADCARGO", "[] call vaciar"];
caja addAction [localize "STR_ACT_MOVEASSET", {[_this select 0,_this select 1,_this select 2] spawn AS_fnc_moveObject},nil,0,false,true,"","(_this == Slowhand)"];
//caja addAction [localize "STR_ACT_SELLMENU", "UI\sellMenu.sqf",nil,0,false,true,"","(_this == Slowhand)", 5];

[player] execVM "OrgPlayers\unitTraits.sqf";
[player] call cleanGear;
[player] spawn rankCheck;
[player] spawn localSupport;