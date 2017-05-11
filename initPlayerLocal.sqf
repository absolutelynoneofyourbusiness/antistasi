params ["_unit","_isJIP"];
private ["_colorWest", "_colorEast","_introShot","_title","_nearestMarker"];

waitUntil {!isNull player};
waitUntil {player == player};

player removeweaponGlobal "itemmap";
player removeweaponGlobal "itemgps";

if (isMultiplayer) then {
	[] execVM "briefing.sqf";
	if (!isServer) then {
		call compile preprocessFileLineNumbers "initVar.sqf";
		if (!hasInterface) then {
			call compile preprocessFileLineNumbers "roadsDB.sqf";
		};
		call compile preprocessFileLineNumbers "initFuncs.sqf";
	};
};

_colorWest = west call BIS_fnc_sideColor;
_colorEast = east call BIS_fnc_sideColor;
{
	_x set [3, 0.33]
} forEach [_colorWest, _colorEast];

_introShot = [
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

if (isMultiplayer) then {
	waitUntil {!isNil "initVar"};
	diag_log format ["Antistasi MP Client. initVar is public. Version %1",antistasiVersion];
};

_title = ["A3 - Antistasi","by Barbolani",antistasiVersion] spawn BIS_fnc_infoText;

if (isMultiplayer) then {
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

} else {
	Slowhand = player;
	(group player) setGroupId ["Slowhand","GroupColor4"];
	player setIdentity "protagonista";
	player setUnitRank "COLONEL";
	player hcSetGroup [group player];
	waitUntil {(scriptdone _introshot) and (!isNil "serverInitDone")};
	addMissionEventHandler ["Loaded", {[] execVM "statistics.sqf";[] execVM "reinitY.sqf";}];
};

disableUserInput false;
player addWeaponGlobal "itemmap";
player addWeaponGlobal "itemgps";

// In order: controller, TK counter, funds, spawn-trigger, rank, score, known by hostile AI
player setVariable ["owner",player,true];
player setVariable ["punish",0,true];
player setVariable ["dinero",100,true];
player setVariable ["BLUFORSpawn",true,true];
player setVariable ["rango",rank player,true];
player setVariable ["score", [0,25] select (player == Slowhand),true];
player setvariable ["compromised",0];

rezagados = creategroup side_blue;
(group player) enableAttack false;

if (!activeACE) then {
	[player] execVM "Revive\initRevive.sqf";
	tags = [] execVM "tags.sqf";
	if (cadetMode AND isMultiplayer) then {
		[] execVM "playerMarkers.sqf";
	};
} else {
	if (activeACEhearing) then {
		player addItem "ACE_EarPlugs";
	};

	if (!activeACEMedical) then {
		[player] execVM "Revive\initRevive.sqf";
	} else {
		player setVariable ["inconsciente",false,true];
	};

	[] execVM "playerMarkers.sqf";
};

gameMenu = (findDisplay 46) displayAddEventHandler ["KeyDown",AS_fnc_keyDownMain];

[false] call AS_fnc_initPlayerEH;

if (isMultiplayer) then {
	["InitializePlayer", [player]] call BIS_fnc_dynamicGroups;//Exec on client
	//["InitializeGroup", [player,WEST,true]] call BIS_fnc_dynamicGroups;
	personalGarage = [];
	if (!isNil "placementDone") then {
		_isJip = true;
	};
};

if (_isJip) then {
	waitUntil {scriptdone _introshot};
	[] execVM "modBlacklist.sqf";
	player setUnitRank "PRIVATE";
	waitUntil {!isNil "posHQ"};
	player setPos (server getVariable ["posHQ", getMarkerPos guer_respawn]);
	[true] execVM "reinitY.sqf";
	if !([player] call isMember) then {
		if (serverCommandAvailable "#logout") then {
			miembros pushBack (getPlayerUID player);
			publicVariable "miembros";
			hint localize "STR_HINTS_INIT_ADMIN_MEMBER"
		} else {
			hint format [localize "STR_HINTS_INIT_GUEST_WELCOME", name player];
		};
	} else {
		hint format [localize "STR_HINTS_INIT_MEMBER_RETURN", name player];

		if (serverName in servidoresOficiales) then {
			if ((count playableUnits == maxPlayers) AND (({[_x] call isMember} count playableUnits) < count miembros)) then {
				{
					if !([_x] call isMember) exitWith {
						["serverFull",false,1,false,false] remoteExec ["BIS_fnc_endMission",_x];
					};
				} forEach playableUnits;
			};
		};

		if ({[_x] call isMember} count playableUnits == 1) then {
			[player] call stavrosInit;
			[] remoteExec ["assignStavros",2];
		};
	};

	// Add actions to flags
	{
		if (_x isKindOf "FlagCarrier") then {
			_nearestMarker = [marcadores,getPos _x] call BIS_fnc_nearestPosition;

			if (!(_nearestMarker in colinas) AND !(_nearestMarker in controles)) then {
				if (_nearestMarker in mrkAAF) then {
					_x addAction [localize "STR_ACT_TAKEFLAG", {[_this select 0, _this select 1] remoteExec ["mrkWIN",2]},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
				} else {
					_x addAction [localize "STR_ACT_RECRUITUNIT", {nul=[] execVM "Dialogs\unit_recruit.sqf";;},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
					_x addAction [localize "STR_ACT_BUYVEHICLE", {createDialog "vehicle_option";},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
					_x addAction [localize "STR_ACT_PERSGARAGE", {[true] spawn garage},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"];
				};
			};
		};
	} forEach vehicles - [bandera,fuego,caja,cajaVeh];

	// Add actions to POWs
	{
		if (typeOf _x == guer_POW) then {
			if (!isPlayer (leader group _x)) then {
				_x addAction [localize "STR_ACT_ORDERREFUGEE", "AI\liberaterefugee.sqf",nil,0,false,true];
			};
		};
	} forEach allUnits;

	// If HQ is set up properly, add mission request action to Petros, otherwise add build HQ action
	if (petros == leader group petros) then {
		removeAllActions petros;
		petros addAction [localize "STR_ACT_MISSIONREQUEST", {nul=CreateDialog "mission_menu";},nil,0,false,true];
	} else {
		removeAllActions petros;
		petros addAction [localize "STR_ACT_BUILDHQ", {[] spawn buildHQ},nil,0,false,true];
		};

	if ((player == Slowhand) AND (isNil "placementDone") AND (isMultiplayer)) then {
		[] execVM "UI\startMenu.sqf";
	} else {
		[true] execVM "Dialogs\firstLoad.sqf";
	};

	diag_log "Antistasi MP Client. JIP client finished";
} else {
	if (isNil "placementDone") then {
		waitUntil {!isNil "Slowhand"};
		if (player == Slowhand) then {
		    if (isMultiplayer) then {
		    	HC_comandante synchronizeObjectsAdd [player];
				player synchronizeObjectsAdd [HC_comandante];
				if (!(serverName in servidoresOficiales) OR (server getVariable ["enableRestart", false])) then {
					[] execVM "UI\startMenu.sqf";
				} else {
					[] remoteExec ["AS_fnc_autoStart",2];
				};
				diag_log "Antistasi MP Client. Client finished";
		    } else {
		    	miembros = [];
		    	[] execVM "Dialogs\firstLoad.sqf";
		    };
		};
	};
};

waitUntil {scriptDone _title};

statistics = [] execVM "statistics.sqf";

// Add arsenal action if Jeroen's arsenal isn't active
if !(activeJNA) then {
	removeAllActions caja;
	// XLA fixed arsenal
	if !(isnil "XLA_fnc_addVirtualItemCargo") then {
		["AmmoboxInit",[caja,false,{true},"Arsenal",true]] call xla_fnc_arsenal;
		caja addAction [localize "STR_ACT_ARSENAL", {["Open",[false,caja,player,true]] call xla_fnc_arsenal;},[],6,true,false,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",5];
	} else {
		_action = caja addaction [localize "STR_ACT_ARSENAL",
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
};

// add a new TFAR radio to your loadout everytime you close the XLA arsenal -- if anyone knows of a way to actually keep your radio with the current XLA setting, give us a shout
if ((activeTFAR) && !(isnil "XLA_fnc_addVirtualItemCargo") AND !(activeJNA)) then {
	[missionNamespace, "arsenalClosed", {
		if !(count (player call TFAR_fnc_radiosList) > 0) then {
			player linkItem guer_radio_TFAR;
			[player] spawn AS_fnc_loadTFARsettings;
		};
	}] call BIS_fnc_addScriptedEventHandler;
};

// Add respawn in SP if ACE is active
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

mapa addAction [localize "STR_ACT_JUNGLE",{[] spawn AS_fnc_clearForest},nil,0,false,true,"","(_this == Slowhand)"];
caja addAction [localize "STR_ACT_UNLOADCARGO", "[] call vaciar"];
caja addAction [localize "STR_ACT_MOVEASSET", {[_this select 0,_this select 1,_this select 2] spawn AS_fnc_moveObject},nil,0,false,true,"","(_this == Slowhand)"];
//caja addAction [localize "STR_ACT_SELLMENU", "UI\sellMenu.sqf",nil,0,false,true,"","(_this == Slowhand)", 5];

cajaVeh addAction ["Get Funky!",{[] spawn AS_fnc_switchUniformTexture},nil,0,false,true,"","name _this in ['Chris','Ken']"];

[player] execVM "OrgPlayers\unitTraits.sqf";
[player] call cleanGear;
[player] spawn rankCheck;
[player] spawn localSupport;

player setVariable ["VCOM_FiredTimeHearing", diag_tickTime, false];