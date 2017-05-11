params [
	"_unit",
	["_timeout", 20, [0]],
	["_punish", 0, [0]]
];

if (isDedicated) exitWith {};
if !(isMultiplayer) exitWith {};
if !(player == _unit) exitWith {};

_punish = _unit getVariable ["punish", 0];
_punish = _punish + _timeout;

systemChat format ["%1 has displayed reckless behaviour. Hit the deck, give me %2!", name player, _punish];
for "_i" from 1 to (round (_punish / 10)) do {
	player playMove "AmovPercMstpSnonWnonDnon_exercisePushup";
	sleep 10;
};

player setVariable ["punish", _punish, true];