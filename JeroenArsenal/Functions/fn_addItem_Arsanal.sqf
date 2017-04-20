
#include "\A3\ui_f\hpp\defineDIKCodes.inc"
#include "\A3\Ui_f\hpp\defineResinclDesign.inc"

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

private["_item","_index","_indexFix","_display"];
_index = _this select 0;
_item = _this select 1;
if(_item isEqualTo "")exitwith{};

if(_index == -1)exitWith{"ERROR in additemarsenal:"+str _this};

_amount = [_this,2,1] call BIS_fnc_param;
_restricted = [_this,3,false] call BIS_fnc_param;

_indexFix = _index;
if(_indexFix == IDC_RSCDISPLAYARSENAL_TAB_CARGOMAG)then{_indexFix = IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL};

jna_dataList set [_indexFix, [jna_dataList select _indexFix, [_item, _amount]] call jna_fnc_addToArray];

if (_restricted) then {
	["UpdateItemAdd",[_indexFix,_item, _amount]] remoteExecCall ["jna_fnc_arsenal",server getVariable ["jna_playersInArsenal",[]]];
} else {
	["UpdateItemAdd",[_indexFix,_item, _amount]] call jna_fnc_arsenal;
};