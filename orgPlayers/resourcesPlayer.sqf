params ["_money"];

_money = (_money + (player getVariable ["dinero",0])) max 0;
player setVariable ["dinero",_money,true];
["dinero",_money] call fn_savePlayerData;
true
