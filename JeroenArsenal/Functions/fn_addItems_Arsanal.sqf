params ["_array",["_restricted",false]];

{

	_index = _forEachIndex;

	{
		_item = _x select 0;
		_amount = _x select 1;

		[_index, _item, _amount,_restricted] remoteExecCall ["jna_fnc_addItem_Arsanal",[0,2] select _restricted];
	} forEach _x;
}foreach _array;