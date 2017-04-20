#include "\A3\ui_f\hpp\defineDIKCodes.inc"
#include "\A3\Ui_f\hpp\defineResinclDesign.inc"

#define IDCS_LEFT\
	IDC_RSCDISPLAYARSENAL_TAB_PRIMARYWEAPON,\
	IDC_RSCDISPLAYARSENAL_TAB_SECONDARYWEAPON,\
	IDC_RSCDISPLAYARSENAL_TAB_HANDGUN,\
	IDC_RSCDISPLAYARSENAL_TAB_UNIFORM,\
	IDC_RSCDISPLAYARSENAL_TAB_VEST,\
	IDC_RSCDISPLAYARSENAL_TAB_BACKPACK,\
	IDC_RSCDISPLAYARSENAL_TAB_HEADGEAR,\
	IDC_RSCDISPLAYARSENAL_TAB_GOGGLES,\
	IDC_RSCDISPLAYARSENAL_TAB_NVGS,\
	IDC_RSCDISPLAYARSENAL_TAB_BINOCULARS,\
	IDC_RSCDISPLAYARSENAL_TAB_MAP,\
	IDC_RSCDISPLAYARSENAL_TAB_GPS,\
	IDC_RSCDISPLAYARSENAL_TAB_RADIO,\
	IDC_RSCDISPLAYARSENAL_TAB_COMPASS,\
	IDC_RSCDISPLAYARSENAL_TAB_WATCH,\
	IDC_RSCDISPLAYARSENAL_TAB_FACE,\
	IDC_RSCDISPLAYARSENAL_TAB_VOICE,\
	IDC_RSCDISPLAYARSENAL_TAB_INSIGNIA

#define IDCS_RIGHT\
	IDC_RSCDISPLAYARSENAL_TAB_ITEMOPTIC,\
	IDC_RSCDISPLAYARSENAL_TAB_ITEMACC,\
	IDC_RSCDISPLAYARSENAL_TAB_ITEMMUZZLE,\
	IDC_RSCDISPLAYARSENAL_TAB_ITEMBIPOD,\
	IDC_RSCDISPLAYARSENAL_TAB_CARGOMAG,\
	IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL,\
	IDC_RSCDISPLAYARSENAL_TAB_CARGOTHROW,\
	IDC_RSCDISPLAYARSENAL_TAB_CARGOPUT,\
	IDC_RSCDISPLAYARSENAL_TAB_CARGOMISC\
///////////////////////////////////////////////////////////////////////////////////////////

jna_minItemMember = [10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,500,20,20,20,10,500];

jna_fnc_arsenal = compile preprocessFileLineNumbers "JeroenArsenal\fn_arsenal.sqf";
jna_fnc_loadinventory = compile preprocessFileLineNumbers "JeroenArsenal\fn_loadinventory.sqf";

//functions
jna_fnc_cargoToArray = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_cargoToArray.sqf";
jna_fnc_addItem_Arsanal = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_addItem_Arsanal.sqf";
jna_fnc_addItems_Arsanal = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_addItems_Arsanal.sqf";
jna_fnc_addToArray = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_addToArray.sqf";
jna_fnc_inList = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_inList.sqf";
jna_fnc_removeFromArray = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_removeFromArray.sqf";
jna_fnc_removeItem_Arsanal = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_removeItem_Arsanal.sqf";
jna_fnc_removeItems_Arsanal = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_removeItems_Arsanal.sqf";
jna_fnc_itemCount = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_itemCount.sqf";
jna_fnc_itemType = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_itemType.sqf";


diag_log "init ars";
//preload the ammobox so you dont need to wait the first time
["Preload"] call jna_fnc_arsenal;

//server

if(isServer)then{
    diag_log "init ars setr";
    server setVariable ["jna_playersInArsenal",[],true];
    //load default if it was not loaded from savegame
    if(isnil "jna_dataList" )then{jna_dataList = [[],[],[],[],[],[],[],[],[],[],[["ItemMap",40]],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]];};

    jna_fnc_requestOpen = {
        jna_dataList remoteExecCall ["jna_fnc_Open", _this];
    };

    jna_fnc_invToArs = {

        //update arsenal
        _array = (caja call jna_fnc_cargoToArray);
        [_array,true] remoteExecCall ["jna_fnc_addItems_Arsanal",server getVariable ["jna_playersInArsenal",[]]];
        [] spawn {
            sleep 3;
            [unlockedWeapons,true] call AS_fnc_weaponsCheck;
        };

        //clear cargo
        clearMagazineCargoGlobal caja;
        clearItemCargoGlobal caja;
        clearweaponCargoGlobal caja;
        clearbackpackCargoGlobal caja;
    };
};


//player
removeAllActions caja;
prefentloop = 0;//DEBUG
if(hasInterface)then{
        diag_log "init ars player";
    jna_fnc_Open = {
        jna_dataList = _this;
        ["Open",[nil,caja,player,false]] call bis_fnc_arsenal;
    };
    //add arsenal button
    _action = caja addaction [
        localize"STR_ACT_ARSENAL",
        {
            ["jna_fnc_arsenal"] call bis_fnc_startloadingscreen;
            prefentloop = 0;
            missionNamespace setVariable ["jna_magazines_init",  [
                magazinesAmmoCargo (uniformContainer player),
                magazinesAmmoCargo (vestContainer player),
                magazinesAmmoCargo (backpackContainer player)
            ]];

            _attachmentsContainers = [[],[],[]];
            {
                _container = _x;
                _weaponAtt = weaponsItemsCargo _x;
                _attachments = [];

                if!(isNil "_weaponAtt")then{

                    {
                        _atts = [_x select 1,_x select 2,_x select 3,_x select 5];
                        _atts = _atts - [""];
                        _attachments = _attachments + _atts;
                    } forEach _weaponAtt;
                    _attachmentsContainers set [_foreachindex,_attachments];
                }
            } forEach [uniformContainer player,vestContainer player,backpackContainer player];
            missionNamespace setVariable ["jna_containerCargo_init", _attachmentsContainers];


            jna_fnc_arsenal = compile preprocessFileLineNumbers "JeroenArsenal\fn_arsenal.sqf";
            jna_fnc_loadinventory = compile preprocessFileLineNumbers "JeroenArsenal\fn_loadinventory.sqf";
            jna_fnc_cargoToArray = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_cargoToArray.sqf";
            jna_fnc_addItem_Arsanal = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_addItem_Arsanal.sqf";
            jna_fnc_addItems_Arsanal = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_addItems_Arsanal.sqf";
            jna_fnc_addToArray = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_addToArray.sqf";
            jna_fnc_inList = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_inList.sqf";
            jna_fnc_removeFromArray = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_removeFromArray.sqf";
            jna_fnc_removeItem_Arsanal = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_removeItem_Arsanal.sqf";
            jna_fnc_removeItems_Arsanal = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_removeItems_Arsanal.sqf";
            jna_fnc_itemCount = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_itemCount.sqf";
            jna_fnc_itemType = compile preprocessFileLineNumbers "JeroenArsenal\Functions\fn_itemType.sqf";


            [clientOwner] remoteExecCall ["jna_fnc_requestOpen",2];
        },
        [],
        6,
        true,
        false,
        "",
        "alive _target && {_target distance _this < 5}"
    ];

    caja setvariable ["bis_fnc_arsenal_action",_action];

    [missionNamespace, "arsenalOpened", {
        disableSerialization;
        UINamespace setVariable ["arsanalDisplay",(_this select 0)];
        [] spawn {
            disableSerialization;
            ["customInit", [uiNamespace getVariable "arsanalDisplay"]] call jna_fnc_arsenal;
        };
        _temp = server getVariable ["jna_playersInArsenal",[]];
        _temp pushBackUnique clientOwner;
        server setVariable ["jna_playersInArsenal",_temp,true];
    }] call BIS_fnc_addScriptedEventHandler;

    [missionNamespace, "arsenalClosed", {
        _temp = server getVariable ["jna_playersInArsenal",[]];
        _temp = _temp - [clientOwner];
        server setVariable ["jna_playersInArsenal",_temp,true];
    }] call BIS_fnc_addScriptedEventHandler;
};