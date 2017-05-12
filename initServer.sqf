if (!isMultiplayer) exitWith {};
if (!(isNil "serverInitDone")) exitWith {};
diag_log "Antistasi MP Server init";
call compile preprocessFileLineNumbers "initVar.sqf";
initVar = true; publicVariable "initVar";
diag_log format ["Antistasi MP. InitVar done. Version: %1",antistasiVersion];
call compile preprocessFileLineNumbers "initFuncs.sqf";
diag_log "Antistasi MP Server. Funcs init finished";
call compile preprocessFileLineNumbers "initZones.sqf";
diag_log "Antistasi MP Server. Zones init finished";
initZones = true; publicVariable "initZones";
 call compile preprocessFileLineNumbers "initPetros.sqf";

["Initialize"] call BIS_fnc_dynamicGroups;//Exec on Server

waitUntil {(count playableUnits) > 0};
waitUntil {({(isPlayer _x) AND (!isNull _x) AND (_x == _x)} count allUnits) == (count playableUnits)};
[] execVM "modBlacklist.sqf";

lockedWeapons = lockedWeapons - unlockedWeapons;
if !(activeJNA) then {
    // XLA fixed arsenal
    if (activeXLA) then {
        [caja,unlockedItems,true] call XLA_fnc_addVirtualItemCargo;
        [caja,unlockedMagazines,true] call XLA_fnc_addVirtualMagazineCargo;
        [caja,unlockedWeapons,true] call XLA_fnc_addVirtualWeaponCargo;
        [caja,unlockedBackpacks,true] call XLA_fnc_addVirtualBackpackCargo;
    } else {
        [caja,unlockedItems,true] call BIS_fnc_addVirtualItemCargo;
        [caja,unlockedMagazines,true] call BIS_fnc_addVirtualMagazineCargo;
        [caja,unlockedWeapons,true] call BIS_fnc_addVirtualWeaponCargo;
        [caja,unlockedBackpacks,true] call BIS_fnc_addVirtualBackpackCargo;
    };
};

diag_log "Antistasi MP Server. Arsenal config finished";
[[petros,"hint","Server Init Completed"],"commsMP"] call BIS_fnc_MP;

addMissionEventHandler ["HandleDisconnect",{[_this select 0, _this select 3, _this select 2] call onPlayerDisconnect;false}];

Slowhand = objNull;
maxPlayers = playableSlotsNumber west;

if (serverName in servidoresOficiales) then {
    [] execVM "serverAutosave.sqf";
 } else {
    if (isNil "comandante") then {comandante = (playableUnits select 0)};
    if (isNull comandante) then {comandante = (playableUnits select 0)};

    {
        if (_x ==comandante) then {
            Slowhand = _x;
            publicVariable "Slowhand";
            _x setRank "CORPORAL";
            [_x,"CORPORAL"] remoteExec ["ranksMP"];
        };
    } forEach playableUnits;
    diag_log "Antistasi MP Server. Players are in";
    };
publicVariable "maxPlayers";

hcArray = [];

if (!isNil "HC1") then {hcArray pushBack HC1};
if (!isNil "HC2") then {hcArray pushBack HC2};
if (!isNil "HC3") then {hcArray pushBack HC3};

HCciviles = 2;
HCgarrisons = 2;
HCattack = 2;
if (count hcArray > 0) then {
    HCattack = hcArray select 0;
    diag_log "Antistasi MP Server. Headless Client 1 detected";
    if (count hcArray > 1) then {
        HCciviles = hcArray select 1;
        diag_log "Antistasi MP Server. Headless Client 2 detected";
        if (count hcArray > 2) then {
            HCgarrisons = hcArray select 2;
            diag_log "Antistasi MP Server. Headless Client 3 detected";
        };
    };
};

publicVariable "HCciviles";
publicVariable "HCgarrisons";
publicVariable "HCattack";
publicVariable "hcArray";

if !(activeJNA) then {
    caja addEventHandler ["ContainerOpened", {
        params ["_container","_unit"];
        if !([_unit] call isMember) then {
            _unit setPos position petros;
            [localize "STR_HINTS_INIT_NOTMEMBER_INV"] remoteExecCall ["hint", _unit];
        };
    }];
};

dedicatedServer = false;
if (isDedicated) then {dedicatedServer = true};
publicVariable "dedicatedServer";

serverInitDone = true; publicVariable "serverInitDone";
diag_log "Antistasi MP Server. serverInitDone set to true.";