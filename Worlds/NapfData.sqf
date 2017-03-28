if !(worldName == "Napf") exitWith {};

power = []; // power plants
bases = []; // army bases
aeropuertos = []; // airports
recursos = []; // resources
fabricas = []; // factories
puestos = []; // outposts
puestosAA = []; // AA outposts
puertos = []; // harbours
controles = []; // roadblocks
colinas = []; // mountaintops
colinasAA = []; // mountaintops for special purposes (compositions, etc)
artyEmplacements = []; // artillery encampments
seaMarkers = []; // naval patrol zones

posAntenas = [[16070.8,18728.7,0.954071],[16105.7,18770.7,1.18446],[15110.4,16165.1,0.776001],[16855,13751.4,0.000402451],[11110.4,11832.6,0],[10978.9,16997.1,7.60431],[9907.12,16868.7,0],[8410.67,17166.2,-3.8147e-006],[5809.04,15678,-1.90735e-005],[6539.08,13680.5,0],[6993.03,9640.53,-3.8147e-006],[4971,12145.6,19.5774],[8862.57,11069.1,-0.00062561],[10142.6,7573.33,0.892677],[13022.3,7666.49,0],[16135.4,8015.4,0.00234985],[17036.6,9705.19,-0.00144958],[15731.1,11408.6,0.000213623],[14745.5,14058.3,15.58],[12787.8,5307.9,0.67067],[8886.64,5414,-8.39233e-005],[5151.94,4478.55,0.272263],[8086.47,2926.47,0],[9683.31,2941.17,1.07095],[1915.22,2531.94,4.76837e-007],[2911.67,6244.56,-0.000724792],[2484.53,8348.84,3.8147e-006],[2339.39,11281.3,-0.00195313],[14653,3201.34,0.000709534],[18109.9,2065.21,0.470627],[17163.8,3466.25,0.000549316],[19112.5,6732.14,0],[11691.7,10256.6,-0.00038147]];

posbancos = [];

safeDistance_undercover = 350;
safeDistance_garage = 500;
safeDistance_recruit = 500;
safeDistance_garrison = 500;
safeDistance_fasttravel = 500;

bld_smallBunker = "Land_BagBunker_Small_F";