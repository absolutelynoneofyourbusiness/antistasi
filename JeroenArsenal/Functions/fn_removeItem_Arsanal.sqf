
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
_amount = [_this,2,1] call BIS_fnc_param;

if(_index == -1)exitWith{"ERROR in removeitemarsenal:"+str _this};

_indexFix = _index;
if(_indexFix == IDC_RSCDISPLAYARSENAL_TAB_CARGOMAG)then{_indexFix = IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL};

_break = false;
{
	if (((_x select 0) isEqualTo _item) AND ((_x select 1) == -1)) exitWith {_break = true};
} forEach (jna_dataList select _indexFix);
if (_break) exitWith {};

jna_dataList set [_indexFix, [jna_dataList select _indexFix, [_item, _amount]] call jna_fnc_removeFromArray];

["UpdateItemRemove",[_index,_item, _amount]] call jna_fnc_arsenal;