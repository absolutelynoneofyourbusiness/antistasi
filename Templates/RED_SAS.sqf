
// (un-)armed transport helicopters
opHeliTrans = 		["UK3CB_BAF_Merlin_HC3_18_GPMG_DPMT","UK3CB_BAF_Merlin_HC3_18_GPMG_DPMT"];

// helicopter that dismounts troops
opHeliDismount = 	"UK3CB_BAF_Merlin_HC3_18_GPMG_DPMT"; // Mi-290 Taru (Bench)

// helicopter that fastropes troops in
opHeliFR = 			"UK3CB_BAF_Merlin_HC3_18_GPMG_DPMT"; // PO-30 Orca (Unarmed)

// small armed helicopter
opHeliSD = 			"UK3CB_BAF_Wildcat_HMA2_TRN_8A_DPMT"; // PO-30 Orca (Armed)

// gunship
opGunship = 		"UK3CB_BAF_Apache_AH1_JS_DPMT"; // Mi-48 Kajman

// CAS, fixed-wing
opCASFW = 			["CUP_B_F35B_CAS_BAF"]; // To-199 Neophron (CAS)


// small UAV (Darter, etc)
opUAVsmall = 		"B_UAV_01_F"; // Tayran AR-2

// air force
opAir = 			["UK3CB_BAF_Merlin_HC3_18_GPMG_DPMT","UK3CB_BAF_Merlin_HC3_18_GPMG_DPMT","UK3CB_BAF_Apache_AH1_JS_DPMT","heeresflieger_1","UK3CB_BAF_Wildcat_HMA2_TRN_8A_DPMT"];

// self-propelled anti air
opSPAA = 			"BWA3_Puma_Fleck";

opTruck = 			"UK3CB_BAF_LandRover_WMIK_HMG_FFR_Green_B_DPMT";

opMRAPu = 			"UK3CB_BAF_LandRover_Soft_FFR_Green_B_DPMT";

opIFV = 			["BWA3_Puma_Fleck","BWA3_Puma_Fleck"];

opArtillery = 		"rhsusf_m109_usarmy";
opArtilleryAmmoHE = "32Rnd_155mm_Mo_shells";

// infantry classes, to allow for class-specific skill adjustments and pricing
opI_OFF = 	"UK3CB_BAF_Officer_MTP_RM"; // officer/official
opI_PIL = 	"UK3CB_BAF_Pilot_RN"; // pilot
opI_OFF2 = 	"B_G_Soldier_unarmed_F"; // officer/traitor
opI_CREW = 	"UK3CB_BAF_Crewman_MTP_RM"; // crew
opI_MK = 	"UK3CB_BAF_Marksman_MTP_BPT_RM_H";
opI_MED =	"UK3CB_BAF_Medic_MTP_BPT_RM_H";
opI_RFL1 = 	"[UK3CB_BAF_Explosive_MTP_BPT_RM]";
opI_RFL2 = 	"UK3CB_BAF_Pointman_MTP_BPT_RM";
opI_AR = 	"UK3CB_BAF_MGLMG_MTP_BPT_RM";
opI_AR2 = 	"UK3CB_BAF_MGGPMG_MTP_RM";
opI_SL = 	"UK3CB_BAF_SC_MTP_BPT_RM";
opI_MK2 = 	"UK3CB_BAF_Sniper_MTP_Ghillie_L115_RM";
opI_AAR = 	"UK3CB_BAF_MGLMG_MTP_BPT_RM";
opI_SP = 	"UK3CB_BAF_Sniper_MTP_Ghillie_L135_RM";
opI_GL =	"UK3CB_BAF_FAC_MTP_BPT_RM";
opI_LAT = 	"UK3CB_BAF_LAT_MTP_RM";

// config path for infantry groups (not used)
opCfgInf = 			(configfile >> "CfgGroups" >> "West" >> "rhs_faction_usmc_wd" >> "rhs_group_nato_usmc_recon_wd_infantry");

// standard group arrays, used for spawning groups
opGroup_Sniper = 		[opI_MK, opI_MK2]; // sniper team
opGroup_SpecOps = 		[opI_SL, opI_MK, opI_MED, opI_RFL1, opI_RFL2, opI_GL, opI_LAT]; // spec opcs
opGroup_Squad = 		[opI_SL, opI_AR, opI_AAR, opI_MK, opI_SP, opI_MED, opI_GL, opI_LAT]; // squad
opGroup_Recon_Team = 	[opI_SL, opI_MK, opI_LAT, opI_MED];
opGroup_Security = 		[opI_SL, opI_AR2, opI_RFL2, opI_MED]; // security detail

// the affiliation
side_red = 			west;

opFlag = 			"FlagCarrierBAF";

opIR = "rhsusf_acc_anpeq15side";

opCrate = "Box_NATO_WpsLaunch_F";

// Colour of this faction's markers
OPFOR_marker_colour = "ColorWEST";

// Type of this faction's markers
OPFOR_marker_type = "flag_UK";

// Name of the faction
A3_Str_RED = localize "STR_GENIDENT_SAS";