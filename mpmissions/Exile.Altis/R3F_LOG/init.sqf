
#include "R3F_LOG_ENABLE.h"

#ifdef R3F_LOG_enable

	R3F_LOG_CFG_can_tow = [];
	R3F_LOG_CFG_can_be_towed = [];
	R3F_LOG_CFG_can_lift = [];
	R3F_LOG_CFG_can_be_lifted = [];
	R3F_LOG_CFG_can_transport_cargo = [];
	R3F_LOG_CFG_can_be_transported_cargo = [];
	R3F_LOG_CFG_can_be_moved_by_player = [];
	R3F_LOG_CFG_CF_whitelist_full_categories = [];
	R3F_LOG_CFG_CF_whitelist_medium_categories = [];
	R3F_LOG_CFG_CF_whitelist_light_categories = [];
	R3F_LOG_CFG_CF_blacklist_categories = [];
	
	#include "config.sqf"
	call compile preprocessFile format ["R3F_LOG\%1_strings_lang.sqf", R3F_LOG_CFG_language];
	reverse R3F_LOG_CFG_can_tow;
	reverse R3F_LOG_CFG_can_be_towed;
	reverse R3F_LOG_CFG_can_lift;
	reverse R3F_LOG_CFG_can_be_lifted;
	reverse R3F_LOG_CFG_can_transport_cargo;
	reverse R3F_LOG_CFG_can_be_transported_cargo;
	reverse R3F_LOG_CFG_can_be_moved_by_player;
	
	{R3F_LOG_CFG_can_tow set [_forEachIndex, toLower _x];} forEach R3F_LOG_CFG_can_tow;
	{R3F_LOG_CFG_can_be_towed set [_forEachIndex, toLower _x];} forEach R3F_LOG_CFG_can_be_towed;
	{R3F_LOG_CFG_can_lift set [_forEachIndex, toLower _x];} forEach R3F_LOG_CFG_can_lift;
	{R3F_LOG_CFG_can_be_lifted set [_forEachIndex, toLower _x];} forEach R3F_LOG_CFG_can_be_lifted;
	{R3F_LOG_CFG_can_transport_cargo select _forEachIndex set [0, toLower (_x select 0)];} forEach R3F_LOG_CFG_can_transport_cargo;
	{R3F_LOG_CFG_can_be_transported_cargo select _forEachIndex set [0, toLower (_x select 0)];} forEach R3F_LOG_CFG_can_be_transported_cargo;
	{R3F_LOG_CFG_can_be_moved_by_player set [_forEachIndex, toLower _x];} forEach R3F_LOG_CFG_can_be_moved_by_player;
	
	R3F_LOG_classes_transporteurs = [];
	{
		R3F_LOG_classes_transporteurs pushBack (_x select 0);
	} forEach R3F_LOG_CFG_can_transport_cargo;
	
	R3F_LOG_classes_objets_transportables = [];
	{
		R3F_LOG_classes_objets_transportables pushBack (_x select 0);
	} forEach R3F_LOG_CFG_can_be_transported_cargo;
	
	R3F_LOG_objets_depl_heli_remorq_transp = [];
	{
		if !(_x in R3F_LOG_objets_depl_heli_remorq_transp) then
		{
			R3F_LOG_objets_depl_heli_remorq_transp pushBack _x;
		};
	} forEach (R3F_LOG_CFG_can_be_moved_by_player + R3F_LOG_CFG_can_be_lifted + R3F_LOG_CFG_can_be_towed + R3F_LOG_classes_objets_transportables);
	
	if (isNil "R3F_LOG_CFG_lock_objects_mode") then {R3F_LOG_CFG_lock_objects_mode = "side";};
	if (isNil "R3F_LOG_CFG_unlock_objects_timer") then {R3F_LOG_CFG_unlock_objects_timer = 30;};
	if (isNil "R3F_LOG_CFG_CF_sell_back_bargain_rate") then {R3F_LOG_CFG_CF_sell_back_bargain_rate = 0.75;};
	if (isNil "R3F_LOG_CFG_CF_creation_cost_factor") then {R3F_LOG_CFG_CF_creation_cost_factor = [];};
	
	if (isServer) then
	{
		R3F_LOG_PUBVAR_point_attache = "Land_HelipadEmpty_F" createVehicle [0,0,0];
		R3F_LOG_PUBVAR_point_attache setPosASL [0,0,0];
		R3F_LOG_PUBVAR_point_attache setVectorDirAndUp [[0,1,0], [0,0,1]];
		
		publicVariable "R3F_LOG_PUBVAR_point_attache";
		
		R3F_LOG_liste_objets_a_proteger = [];
		
		execVM "R3F_LOG\surveiller_objets_a_proteger.sqf";
	};
	
	R3F_LOG_FNCT_PVEH_commande_MP =
	{
		private ["_argument", "_commande", "_parametre"];
		_argument = _this select 1 select 0;
		_commande = _this select 1 select 1;
		_parametre = if (count (_this select 1) == 3) then {_this select 1 select 2} else {0};
		
		switch (_commande) do
		{
		};
		
		if (local _argument) then
		{
			switch (_commande) do
			{
				case "setDir": {_argument setDir _parametre;};
				case "setVelocity": {_argument setVelocity _parametre;};
				case "detachSetVelocity": {detach _argument; _argument setVelocity _parametre;};
			};
		};
		
		if (isServer) then
		{
			if (_commande == "setOwnerTo") then
			{
				_argument setOwner (owner _parametre);
			};
		};
	};
	"R3F_LOG_PV_commande_MP" addPublicVariableEventHandler R3F_LOG_FNCT_PVEH_commande_MP;

	R3F_LOG_FNCT_exec_commande_MP =
	{
		R3F_LOG_PV_commande_MP = _this;
		publicVariable "R3F_LOG_PV_commande_MP";
		["R3F_LOG_PV_commande_MP", R3F_LOG_PV_commande_MP] spawn R3F_LOG_FNCT_PVEH_commande_MP;
	};
	
	R3F_LOG_mutex_local_verrou = false;
	
	call compile preprocessFile "R3F_LOG\fonctions_generales\lib_geometrie_3D.sqf";
	
	R3F_LOG_IDX_can_be_depl_heli_remorq_transp = 0;
	R3F_LOG_IDX_can_be_moved_by_player = 1;
	R3F_LOG_IDX_can_lift = 2;
	R3F_LOG_IDX_can_be_lifted = 3;
	R3F_LOG_IDX_can_tow = 4;
	R3F_LOG_IDX_can_be_towed = 5;
	R3F_LOG_IDX_can_transport_cargo = 6;
	R3F_LOG_IDX_can_transport_cargo_cout = 7;
	R3F_LOG_IDX_can_be_transported_cargo = 8;
	R3F_LOG_IDX_can_be_transported_cargo_cout = 9;
	R3F_LOG_CST_zero_log = [false, false, false, false, false, false, false, 0, false, 0];
	
	R3F_LOG_FNCT_determiner_fonctionnalites_logistique = compile preprocessFile "R3F_LOG\fonctions_generales\determiner_fonctionnalites_logistique.sqf";
	
	R3F_LOG_FNCT_calculer_chargement_vehicule = compile preprocessFile "R3F_LOG\transporteur\calculer_chargement_vehicule.sqf";
	R3F_LOG_FNCT_transporteur_charger_auto = compile preprocessFile "R3F_LOG\transporteur\charger_auto.sqf";
	
	if !(isDedicated) then
	{
		waitUntil {!isNil "R3F_LOG_PUBVAR_point_attache"};
		
		R3F_LOG_joueur_deplace_objet = objNull;
		
		R3F_LOG_objet_selectionne = objNull;
		
		R3F_LOG_CF_liste_usines = [];
		
		call compile preprocessFile "R3F_LOG\fonctions_generales\lib_visualisation_objet.sqf";
		
		R3F_LOG_FNCT_objet_relacher = compile preprocessFile "R3F_LOG\objet_deplacable\relacher.sqf";
		R3F_LOG_FNCT_objet_deplacer = compile preprocessFile "R3F_LOG\objet_deplacable\deplacer.sqf";
		
		R3F_LOG_FNCT_heliporteur_heliporter = compile preprocessFile "R3F_LOG\heliporteur\heliporter.sqf";
		R3F_LOG_FNCT_heliporteur_larguer = compile preprocessFile "R3F_LOG\heliporteur\larguer.sqf";
		R3F_LOG_FNCT_heliporteur_init = compile preprocessFile "R3F_LOG\heliporteur\heliporteur_init.sqf";
		
		R3F_LOG_FNCT_remorqueur_detacher = compile preprocessFile "R3F_LOG\remorqueur\detacher.sqf";
		R3F_LOG_FNCT_remorqueur_remorquer_deplace = compile preprocessFile "R3F_LOG\remorqueur\remorquer_deplace.sqf";
		R3F_LOG_FNCT_remorqueur_remorquer_direct = compile preprocessFile "R3F_LOG\remorqueur\remorquer_direct.sqf";
		R3F_LOG_FNCT_remorqueur_init = compile preprocessFile "R3F_LOG\remorqueur\remorqueur_init.sqf";
		
		R3F_LOG_FNCT_transporteur_charger_deplace = compile preprocessFile "R3F_LOG\transporteur\charger_deplace.sqf";
		R3F_LOG_FNCT_transporteur_charger_selection = compile preprocessFile "R3F_LOG\transporteur\charger_selection.sqf";
		R3F_LOG_FNCT_transporteur_decharger = compile preprocessFile "R3F_LOG\transporteur\decharger.sqf";
		R3F_LOG_FNCT_transporteur_selectionner_objet = compile preprocessFile "R3F_LOG\transporteur\selectionner_objet.sqf";
		R3F_LOG_FNCT_transporteur_voir_contenu_vehicule = compile preprocessFile "R3F_LOG\transporteur\voir_contenu_vehicule.sqf";
		R3F_LOG_FNCT_transporteur_init = compile preprocessFile "R3F_LOG\transporteur\transporteur_init.sqf";
		
		R3F_LOG_FNCT_usine_remplir_liste_objets = compile preprocessFile "R3F_LOG\usine_creation\remplir_liste_objets.sqf";
		R3F_LOG_FNCT_usine_creer_objet = compile preprocessFile "R3F_LOG\usine_creation\creer_objet.sqf";
		R3F_LOG_FNCT_usine_ouvrir_usine = compile preprocessFile "R3F_LOG\usine_creation\ouvrir_usine.sqf";
		R3F_LOG_FNCT_usine_init = compile preprocessFile "R3F_LOG\usine_creation\usine_init.sqf";
		R3F_LOG_FNCT_usine_revendre_deplace = compile preprocessFile "R3F_LOG\usine_creation\revendre_deplace.sqf";
		R3F_LOG_FNCT_usine_revendre_selection = compile preprocessFile "R3F_LOG\usine_creation\revendre_selection.sqf";
		R3F_LOG_FNCT_usine_revendre_direct = compile preprocessFile "R3F_LOG\usine_creation\revendre_direct.sqf";
		R3F_LOG_FNCT_recuperer_liste_cfgVehicles_par_categories = compile preprocessFile "R3F_LOG\usine_creation\recuperer_liste_cfgVehicles_par_categories.sqf";
		R3F_LOG_FNCT_determiner_cout_creation = compile preprocessFile "R3F_LOG\usine_creation\determiner_cout_creation.sqf";
		
		R3F_LOG_FNCT_objet_init = compile preprocessFile "R3F_LOG\objet_commun\objet_init.sqf";
		R3F_LOG_FNCT_objet_est_verrouille = compile preprocessFile "R3F_LOG\objet_commun\objet_est_verrouille.sqf";
		R3F_LOG_FNCT_deverrouiller_objet = compile preprocessFile "R3F_LOG\objet_commun\deverrouiller_objet.sqf";
		R3F_LOG_FNCT_definir_proprietaire_verrou = compile preprocessFile "R3F_LOG\objet_commun\definir_proprietaire_verrou.sqf";
		
		R3F_LOG_FNCT_formater_fonctionnalites_logistique = compile preprocessFile "R3F_LOG\fonctions_generales\formater_fonctionnalites_logistique.sqf";
		R3F_LOG_FNCT_formater_nombre_entier_milliers = compile preprocessFile "R3F_LOG\fonctions_generales\formater_nombre_entier_milliers.sqf";
		
		R3F_LOG_action_charger_deplace_valide = false;
		R3F_LOG_action_charger_selection_valide = false;
		R3F_LOG_action_contenu_vehicule_valide = false;
		
		R3F_LOG_action_remorquer_deplace_valide = false;
		
		R3F_LOG_action_heliporter_valide = false;
		R3F_LOG_action_heliport_larguer_valide = false;
		
		R3F_LOG_action_deplacer_objet_valide = false;
		R3F_LOG_action_remorquer_direct_valide = false;
		R3F_LOG_action_detacher_valide = false;
		R3F_LOG_action_selectionner_objet_charge_valide = false;
		
		R3F_LOG_action_ouvrir_usine_valide = false;
		R3F_LOG_action_revendre_usine_direct_valide = false;
		R3F_LOG_action_revendre_usine_deplace_valide = false;
		R3F_LOG_action_revendre_usine_selection_valide = false;
		
		R3F_LOG_action_deverrouiller_valide = false;
		
		R3F_LOG_FNCT_PUBVAR_reveler_au_joueur =
		{
			private ["_objet"];
			_objet = _this select 1;
			
			if (alive player) then
			{
				player reveal _objet;
			};
		};
		"R3F_LOG_PUBVAR_reveler_au_joueur" addPublicVariableEventHandler R3F_LOG_FNCT_PUBVAR_reveler_au_joueur;
		
		R3F_LOG_FNCT_EH_GetIn =
		{
			if (local (_this select 2)) then
			{
				_this spawn
				{
					sleep 0.1;
					if ((!(isNull (_this select 0 getVariable "R3F_LOG_est_deplace_par")) && (alive (_this select 0 getVariable "R3F_LOG_est_deplace_par")) && (isPlayer (_this select 0 getVariable "R3F_LOG_est_deplace_par"))) || !(isNull (_this select 0 getVariable "R3F_LOG_est_transporte_par"))) then
					{
						(_this select 2) action ["GetOut", _this select 0];
						(_this select 2) action ["Eject", _this select 0];
						if (player == _this select 2) then {hintC format [STR_R3F_LOG_objet_en_cours_transport, getText (configFile >> "CfgVehicles" >> (typeOf (_this select 0)) >> "displayName")];};
					};
				};
			};
		};
		
		0 spawn
		{
			waitUntil {!isNull player};
			
			player addEventHandler ["WeaponDisassembled",
			{
				private ["_objet"];
				
				_objet = cursorTarget;
				
				if (!isNull _objet && {!isNull (_objet getVariable ["R3F_LOG_est_deplace_par", objNull])}) then
				{
					_objet setVariable ["R3F_LOG_est_deplace_par", objNull, true];
				};
			}];
		};
		
		R3F_LOG_PUBVAR_nouvel_objet_a_initialiser = false;
		
		execVM "R3F_LOG\surveiller_conditions_actions_menu.sqf";
		
		execVM "R3F_LOG\surveiller_nouveaux_objets.sqf";
		
		execVM "R3F_LOG\systeme_protection_blessures.sqf";
	};
	
	R3F_LOG_active = true;
#else
	R3F_LOG_joueur_deplace_objet = objNull;
	R3F_LOG_active = false;
#endif