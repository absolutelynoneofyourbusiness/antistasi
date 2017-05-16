/*
 	Description:
		Check if weapons of a specific category are available in high enough numbers to equip AI with them

	Parameters:
		0: STRING - Item category

 	Returns:
		BOOL - Are there enough weapons in storage?

 	Example:
		_canEquipLMG = ["LMG"] call AS_fnc_JNA_checkAvailability;
*/

params [
	["_category", "LMG", [""]],

	["_baseList", [], [[]]],
	["_minCount", 10, [0]],
	["_index", 0, [0]],
	["_available", false, [true]]
];

switch (toUpper _category) do {
	case "LMG": {
		_baseList = gear_machineGuns;
		_minCount = jna_minItemMember select 0;
	};

	case "SNIPER": {
		_baseList = gear_sniperRifles;
		_minCount = jna_minItemMember select 0;
	};

	case "GL": {
		_baseList = genGL;
		_minCount = jna_minItemMember select 0;
	};

	case "AT": {
		_baseList = genATLaunchers;
		_minCount = jna_minItemMember select 1;
		_index = 1;
	};

	case "AA": {
		_baseList = genAALaunchers;
		_minCount = jna_minItemMember select 1;
		_index = 1;
	};

	default {
		_baseList = [];
		_minCount = 0;
	};
};


if (count _baseList == 0) exitWith {diag_log format ["Error in checkAvailability, %1 has not been defined", _category]};

{
	if (((_x select 0) in _baseList) AND {(_x select 1) >= _minCount}) exitWith {_available = true};
} forEach (jna_dataList select _index);

_available