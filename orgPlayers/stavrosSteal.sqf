private ["_resourcesFIA"];

_resourcesFIA = server getVariable ["resourcesFIA",0];
if (_resourcesFIA < 100) exitWith {hint localize "STR_HINTS_GEN_STEAL_FAIL"};
[100] call resourcesPlayer;
server setvariable ["resourcesFIA",_resourcesFIA - 100, true];
["scorePlayer", player getVariable "score",getPlayerUID player] call fn_savePlayerData;

hint localize "STR_HINTS_GEN_STEAL_SUC";