/*  CS:GO Weapons&Knives SourceMod Plugin
 *
 *  Copyright (C) 2017 Kağan 'kgns' Üstüngel
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <PTaH>
#include <weapons>
#undef REQUIRE_PLUGIN
#include <updater>
#undef REQUIRE_EXTENSIONS
#include <SteamWorks>
#include <json>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 262144 // Required for SteamCommunity inventory JSON parsing; raise in stages for large inventories.

#include "weapons/globals.sp"
#include "weapons/forwards.sp"
#include "weapons/hooks.sp"
#include "weapons/helpers.sp"
#include "weapons/database.sp"
#include "weapons/config.sp"
#include "weapons/menus.sp"
#include "weapons/natives.sp"

#define UPDATE_URL "https://raw.githubusercontent.com/kgns/weapons/master/addons/sourcemod/updatefile.txt"


//#define DEBUG

public Plugin myinfo = 
{
	name = "Weapons & Knives",
	author = "kgns | oyunhost.net",
	description = "All in one CS:GO weapon skin management",
	version = "1.7.7",
	url = "https://github.com/kgns"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("weapons");

	CreateNative("Weapons_SetClientKnife", Weapons_SetClientKnife_Native);
	CreateNative("Weapons_GetClientKnife", Weapons_GetClientKnife_Native);
	
	g_hOnKnifeSelect_Pre = CreateGlobalForward("Weapons_OnClientKnifeSelectPre", ET_Event, Param_Cell, Param_Cell, Param_String);
	g_hOnKnifeSelect_Post = CreateGlobalForward("Weapons_OnClientKnifeSelectPost", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	return APLRes_Success;
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Only CS:GO servers are supported!");
		return;
	}
	
	if(PTaH_Version() < 101000)
	{
		char sBuf[16];
		PTaH_Version(sBuf, sizeof(sBuf));
		SetFailState("PTaH extension needs to be updated. (Installed Version: %s - Required Version: 1.1.0+) [ Download from: https://ptah.zizt.ru ]", sBuf);
		return;
	}
	
	LoadTranslations("weapons.phrases");
	
	g_Cvar_DBConnection 			= CreateConVar("sm_weapons_db_connection", 			"storage-local", 	"Database connection name in databases.cfg to use");
	g_Cvar_TablePrefix 			= CreateConVar("sm_weapons_table_prefix", 			"", 				"Prefix for database table (example: 'xyz_')");
	g_Cvar_ChatPrefix 			= CreateConVar("sm_weapons_chat_prefix", 			"[oyunhost.net]", 	"Prefix for chat messages");
	g_Cvar_KnifeStatTrakMode 		= CreateConVar("sm_weapons_knife_stattrak_mode", 	"0", 				"0: All knives show the same StatTrak counter (total knife kills) 1: Each type of knife shows its own separate StatTrak counter");
	g_Cvar_EnableFloat 			= CreateConVar("sm_weapons_enable_float", 			"1", 				"Enable/Disable weapon float options");
	g_Cvar_EnableNameTag 			= CreateConVar("sm_weapons_enable_nametag", 		"1", 				"Enable/Disable name tag options");
	g_Cvar_EnableStatTrak 			= CreateConVar("sm_weapons_enable_stattrak", 		"1", 				"Enable/Disable StatTrak options");
	g_Cvar_EnableSeed				= CreateConVar("sm_weapons_enable_seed",			"1",				"Enable/Disable Seed options");
	g_Cvar_FloatIncrementSize 		= CreateConVar("sm_weapons_float_increment_size", 	"0.05", 			"Increase/Decrease by value for weapon float");
	g_Cvar_EnableWeaponOverwrite 	= CreateConVar("sm_weapons_enable_overwrite", 		"1", 				"Enable/Disable players overwriting other players' weapons (picked up from the ground) by using !ws command");
	g_Cvar_EnablePublicWS			= CreateConVar("sm_weapons_enable_public_ws",		"0",				"Enable/Disable legacy public commands/chat triggers: !ws, !knife, !wslang, !seed, !nametag");
	g_Cvar_GracePeriod 			= CreateConVar("sm_weapons_grace_period", 			"0", 				"Grace period in terms of seconds counted after round start for allowing the use of !ws command. 0 means no restrictions");
	g_Cvar_InactiveDays 			= CreateConVar("sm_weapons_inactive_days", 			"30", 				"Number of days before a player (SteamID) is marked as inactive and his data is deleted. (0 or any negative value to disable deleting)");
	g_Cvar_DropChance 				= CreateConVar("sm_weapons_drop_chance", 			"0.02", 				"Base chance for receiving a skin drop on kill from 0.0 to 1.0");
	g_Cvar_CosmeticsMode 			= CreateConVar("sm_weapons_cosmetics_mode", 		"drops", 				"Cosmetics source mode: drops (kill drops only), inventory (imported inventory only), hybrid (both)");
	g_Cvar_DropShowRollStats 		= CreateConVar("sm_weapons_drop_show_roll_stats", 	"1", 				"Show per-kill drop roll statistics in chat to attacker");
	g_Cvar_DropDebug 				= CreateConVar("sm_weapons_drop_debug", 			"0", 				"Enable verbose drop/inventory debug messages in server logs and attacker chat");
	g_Cvar_DropStatTrakChance 		= CreateConVar("sm_weapons_drop_stattrak_chance", 	"0.1", 				"Drop StatTrak chance from 0.0 to 1.0");
	g_Cvar_DropSeedMin 			= CreateConVar("sm_weapons_drop_seed_min", 		"0", 				"Minimum random seed for dropped skins");
	g_Cvar_DropSeedMax 			= CreateConVar("sm_weapons_drop_seed_max", 		"1000", 				"Maximum random seed for dropped skins");
	g_Cvar_DropWearDefaultMin 		= CreateConVar("sm_weapons_drop_wear_default_min", 	"0.00", 				"Default minimum wear if skin config has no wear range");
	g_Cvar_DropWearDefaultMax 		= CreateConVar("sm_weapons_drop_wear_default_max", 	"1.00", 				"Default maximum wear if skin config has no wear range");
	g_Cvar_DropWeightKnife 		= CreateConVar("sm_weapons_drop_weight_knife", 		"0.05", 			"Relative drop weight for knives in global skin drop roll. 0 disables knife drops");
	g_Cvar_DropWeightAK47 		= CreateConVar("sm_weapons_drop_weight_ak47", 		"0.15", 			"Relative drop weight for AK-47 in global skin drop roll");
	g_Cvar_DropWeightM4A1 		= CreateConVar("sm_weapons_drop_weight_m4a1", 		"0.15", 			"Relative drop weight for M4A4 (weapon_m4a1) in global skin drop roll");
	g_Cvar_DropWeightM4A1S 		= CreateConVar("sm_weapons_drop_weight_m4a1s", 		"0.15", 			"Relative drop weight for M4A1-S in global skin drop roll");
	g_Cvar_DropWeightPistol 	= CreateConVar("sm_weapons_drop_weight_pistol", 	"1.0", 			"Relative drop weight for pistols in global skin drop roll");
	g_Cvar_DropWeightOther 		= CreateConVar("sm_weapons_drop_weight_other", 		"0.5", 			"Relative drop weight for other non-pistol, non-knife weapons in global skin drop roll");
	g_Cvar_InventoryImportSourceTable = CreateConVar("sm_weapons_inventory_import_source_table", "inventory_import_items", "Table name (without prefix) used as import source. Required columns: steamid64, weapon_class/weapon_defindex, skin_id/paintkit, wear, seed, stattrak_enabled/stattrak_count, obtained_at, external_item_id");
	g_Cvar_InventoryImportSyncInterval = CreateConVar("sm_weapons_inventory_import_sync_interval", "0", "Periodic inventory import interval (seconds). 0 disables automatic sync.");
	g_Cvar_InventoryBackendUrl = CreateConVar("sm_weapons_inventory_backend_url", "", "Backend base URL (example: http://127.0.0.1:3000). If set, plugin pulls inventory export from backend on player join.");
	g_Cvar_InventoryBackendApiKey = CreateConVar("sm_weapons_inventory_backend_api_key", "", "Backend server API key sent as X-Server-Api-Key for inventory export requests.");
	g_Cvar_InventorySteamId64Override = CreateConVar("sm_weapons_inventory_steamid64_override", "", "Temporary SteamID64 override used when auth resolves to STEAM_ID_LAN.");
	
	AutoExecConfig(true, "weapons");
	
	RegConsoleCmd("buyammo2", CommandKnife);
	RegConsoleCmd("sm_kf", CommandKnife);
	RegConsoleCmd("sm_skins", CommandSkins);
	RegConsoleCmd("sm_loadout", CommandLoadout);

	if(g_Cvar_EnablePublicWS.BoolValue)
	{
		RegConsoleCmd("buyammo1", CommandWeaponSkins);
		RegConsoleCmd("sm_ws", CommandWeaponSkins);
		RegConsoleCmd("sm_knife", CommandKnife);
		RegConsoleCmd("sm_nametag", CommandNameTag);
		RegConsoleCmd("sm_wslang", CommandWSLang);
		RegConsoleCmd("sm_seed", CommandSeedMenu);
	}
	RegAdminCmd("sm_wsreset", CommandResetWeaponSkins, ADMFLAG_ROOT, "Resets weapon skins and knife of a specific player.");
	RegAdminCmd("sm_wsimport", CommandImportInventory, ADMFLAG_ROOT, "Imports CS2 inventory items into unlocked_skins for a target.");
	
	PTaH(PTaH_GiveNamedItemPre, Hook, GiveNamedItemPre);
	PTaH(PTaH_GiveNamedItemPost, Hook, GiveNamedItemPost);
	
	ConVar g_cvGameType = FindConVar("game_type");
	ConVar g_cvGameMode = FindConVar("game_mode");
	
	if(g_cvGameType.IntValue == 1 && g_cvGameMode.IntValue == 2)
	{
		PTaH(PTaH_WeaponCanUsePre, Hook, WeaponCanUsePre);
	}
	
	AddCommandListener(ChatListener, "say");
	AddCommandListener(ChatListener, "say2");
	AddCommandListener(ChatListener, "say_team");
	AddCommandListener(BuyCommandListener, "buy");
	AddCommandListener(BuyCommandListener, "autobuy");
	AddCommandListener(BuyCommandListener, "rebuy");
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);

	#if defined DEBUG
	RegAdminCmd("sm_setknife", Command_SetKnife, ADMFLAG_ROOT, "Sets knife of specific player.");
	RegAdminCmd("sm_getknife", Command_GetClientKnife, ADMFLAG_ROOT, "Gets specific player's knife class name.");
	#endif
	
	for(int i = 0; i < sizeof(g_iWeaponSeed); i++)
	{
		for(int j = 0; j < sizeof(g_iWeaponSeed[]); j++)
		{
			g_iWeaponSeed[i][j] = -1;
		}
	}

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

#if defined DEBUG
public Action Command_SetKnife(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setknife <playername> <weaponname>");
		return Plugin_Handled;
	}
	char buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	int target = FindTarget(client, buffer);
	if(target == -1)
	{
		ReplyToCommand(client, "[SM] Please enter valid playername!");
		return Plugin_Handled;
	}
	GetCmdArg(2, buffer, sizeof(buffer));
	if(SetClientKnife(target, buffer) == -1)
	{
		ReplyToCommand(client, "[SM] Knife %s is not valid.", buffer);
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[SM] Successfully set %N's knife.", target);
	return Plugin_Handled;
}

public Action Command_GetClientKnife(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_getknife <playername>");
		return Plugin_Handled;
	}
	char buffer[32];
	GetCmdArg(1, buffer, sizeof(buffer));
	int target = FindTarget(client, buffer);
	if(target == -1)
	{
		ReplyToCommand(client, "[SM] Please enter valid playername!");
		return Plugin_Handled;
	}
	char sKnife[64];
	GetClientKnife(client, sKnife, sizeof(sKnife));
	ReplyToCommand(client, "[SM] %N's knife is %s.", target, sKnife);
	return Plugin_Handled;
}
#endif

public void PrintPublicWSDisabledHint(int client)
{
	if (client > 0)
	{
		PrintToChat(client, " %s \x04Legacy public commands are disabled. Use \x10!loadout\x04 and \x10!skins\x04.", g_ChatPrefix);
	}
}

public Action CommandWeaponSkins(int client, int args)
{
	if (IsValidClient(client))
	{
		PrintPublicWSDisabledHint(client);
	}
	return Plugin_Handled;
}


public Action CommandImportInventory(int client, int args)
{
	char steamid64[32];
	steamid64[0] = EOS;

	if (args >= 1)
	{
		char targetArg[64];
		GetCmdArg(1, targetArg, sizeof(targetArg));

		int target = FindTarget(client, targetArg, false, false);
		if (target > 0)
		{
			if (!GetClientSteamID64(target, steamid64, sizeof(steamid64)))
			{
				ReplyToCommand(client, "[SM] Could not resolve target SteamID64.");
				return Plugin_Handled;
			}
		}
		else
		{
			strcopy(steamid64, sizeof(steamid64), targetArg);
		}
	}
	else if (IsValidClient(client))
	{
		if (!GetClientSteamID64(client, steamid64, sizeof(steamid64)))
		{
			ReplyToCommand(client, "[SM] Could not resolve your SteamID64.");
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_wsimport <#userid|name|steamid64>");
		return Plugin_Handled;
	}

	bool queued;
	if (g_InventoryBackendUrl[0] == EOS)
	{
		queued = SyncInventoryFromSteamCommunityBySteamID64(steamid64, client);
	}
	else
	{
		queued = SyncInventoryFromBackendBySteamID64(steamid64, client);
	}

	if (!queued)
	{
		ImportInventoryForSteamID64(steamid64, client);
	}
	ReplyToCommand(client, "[SM] Inventory sync/import queued for %s", steamid64);
	return Plugin_Handled;
}

public Action CommandSkins(int client, int args)
{
	if (IsValidClient(client))
	{
		if (!CosmeticsModeAllowsDrops())
		{
			PrintToChat(client, " %s \x04Cosmetics mode:\x01 inventory (kill drops disabled)", g_ChatPrefix);
		}

		int menuTime;
		if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
		{
			CreateInventoryWeaponMenu(client).Display(client, menuTime);
		}
		else
		{
			PrintToChat(client, " %s \x02%t", g_ChatPrefix, "GracePeriod", g_iGracePeriod);
		}
	}
	return Plugin_Handled;
}

public Action CommandResetWeaponSkins(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_wsreset <playername>");
		return Plugin_Handled;
	}

	char buffer[32];
	GetCmdArg(1, buffer, sizeof(buffer));

	int target = FindTarget(client, buffer);
	if(target == -1)
	{
		ReplyToCommand(client, "[SM] Please enter valid playername!");
		return Plugin_Handled;
	}
	
	for(int i = 0; i < sizeof(g_WeaponClasses); i++)
	{
		g_iSkins[target][i] = 0;
		g_iStatTrak[target][i] = 0;
		g_iStatTrakCount[target][i] = 0;
		g_NameTag[target][i] = "";
		g_fFloatValue[target][i] = 0.0;
		g_iWeaponSeed[target][i] = -1;
	}
	g_iKnife[target] = 0;

	ResetPlayerData(target);

	return Plugin_Handled;
}

public Action CommandSeedMenu(int client, int args)
{
	if(!g_bEnableSeed)
	{
		ReplyToCommand(client, " %s \x02%T", g_ChatPrefix, "SeedDisabled", client);
		return Plugin_Handled;
	}
	ReplyToCommand(client, " %s \x04%T", g_ChatPrefix, "SeedExplanation", client);
	return Plugin_Handled;
}

public Action CommandKnife(int client, int args)
{
	if (IsValidClient(client))
	{
		int menuTime;
		if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
		{
			CreateKnifeMenu(client).Display(client, menuTime);
		}
		else
		{
			PrintToChat(client, " %s \x02%t", g_ChatPrefix, "GracePeriod", g_iGracePeriod);
		}
	}
	return Plugin_Handled;
}


public Action CommandLoadout(int client, int args)
{
	if (IsValidClient(client))
	{
		int menuTime;
		if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
		{
			CreateLoadoutMenu(client).Display(client, menuTime);
		}
		else
		{
			PrintToChat(client, " %s \x02%t", g_ChatPrefix, "GracePeriod", g_iGracePeriod);
		}
	}
	return Plugin_Handled;
}

public Action CommandWSLang(int client, int args)
{
	if (IsValidClient(client))
	{
		int menuTime;
		if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
		{
			CreateLanguageMenu(client).Display(client, menuTime);
		}
		else
		{
			PrintToChat(client, " %s \x02%t", g_ChatPrefix, "GracePeriod", g_iGracePeriod);
		}
	}
	return Plugin_Handled;
}

public Action CommandNameTag(int client, int args)
{
	if(!g_bEnableNameTag)
	{
		ReplyToCommand(client, " %s \x02%T", g_ChatPrefix, "NameTagDisabled", client);
		return Plugin_Handled;
	}
	ReplyToCommand(client, " %s \x04%T", g_ChatPrefix, "NameTagNew", client);
	return Plugin_Handled;
}

void SetWeaponProps(int client, int entity)
{
	int index = GetWeaponIndexForClient(client, entity);
	if (index > -1 && g_iSkins[client][index] != 0)
	{
		static int IDHigh = 16384;
		SetEntProp(entity, Prop_Send, "m_iItemIDLow", -1);
		SetEntProp(entity, Prop_Send, "m_iItemIDHigh", IDHigh++);
		SetEntProp(entity, Prop_Send, "m_nFallbackPaintKit", g_iSkins[client][index] == -1 ? GetRandomSkin(client, index) : g_iSkins[client][index]);
		SetEntPropFloat(entity, Prop_Send, "m_flFallbackWear", !g_bEnableFloat || g_fFloatValue[client][index] == 0.0 ? 0.000001 : g_fFloatValue[client][index] == 1.0 ? 0.999999 : g_fFloatValue[client][index]);
		if (g_bEnableSeed && g_iWeaponSeed[client][index] != -1)
		{
			SetEntProp(entity, Prop_Send, "m_nFallbackSeed", g_iWeaponSeed[client][index]);
		}
		else
		{
			g_iSeedRandom[client][index] = GetRandomInt(0, 8192);
			SetEntProp(entity, Prop_Send, "m_nFallbackSeed", g_iSeedRandom[client][index]);
		}
		
		if(!IsKnife(entity))
		{
			if(g_bEnableStatTrak)
			{
				SetEntProp(entity, Prop_Send, "m_nFallbackStatTrak", g_iStatTrak[client][index] == 1 ? g_iStatTrakCount[client][index] : -1);
				SetEntProp(entity, Prop_Send, "m_iEntityQuality", g_iStatTrak[client][index] == 1 ? 9 : 0);
			}
		}
		else
		{
			if(g_bEnableStatTrak)
			{
				SetEntProp(entity, Prop_Send, "m_nFallbackStatTrak", g_iStatTrak[client][index] == 0 ? -1 : g_iKnifeStatTrakMode == 0 ? GetTotalKnifeStatTrakCount(client) : g_iStatTrakCount[client][index]);
			}
			SetEntProp(entity, Prop_Send, "m_iEntityQuality", 3);
		}
		if (g_bEnableNameTag && strlen(g_NameTag[client][index]) > 0)
		{
			SetEntDataString(entity, FindSendPropInfo("CBaseAttributableItem", "m_szCustomName"), g_NameTag[client][index], 128);
		}
		SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Send, "m_hPrevOwner", -1);
	}
}

void RefreshWeapon(int client, int index, bool defaultKnife = false)
{
	int size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
	for (int i = 0; i < size; i++)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (IsValidWeapon(weapon))
		{
			bool isKnife = IsKnife(weapon);
			if ((!defaultKnife && GetWeaponIndexForClient(client, weapon) == index) || (isKnife && (defaultKnife || IsKnifeClass(g_WeaponClasses[index]))))
			{
				if(!g_bOverwriteEnabled)
				{
					int previousOwner;
					if ((previousOwner = GetEntPropEnt(weapon, Prop_Send, "m_hPrevOwner")) != INVALID_ENT_REFERENCE && previousOwner != client)
					{
						return;
					}
				}
				
				int clip = -1;
				int ammo = -1;
				int offset = -1;
				int reserve = -1;
				
				if (!isKnife)
				{
					offset = FindDataMapInfo(client, "m_iAmmo") + (GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType") * 4);
					ammo = GetEntData(client, offset);
					clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
					reserve = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
				}
				
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "KillHierarchy");
				
				if (!isKnife)
				{
					weapon = GivePlayerItem(client, g_WeaponClasses[index]);
					if (clip != -1)
					{
						SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
					}
					if (reserve != -1)
					{
						SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", reserve);
					}
					if (offset != -1 && ammo != -1)
					{
						DataPack pack;
						CreateDataTimer(0.1, ReserveAmmoTimer, pack);
						pack.WriteCell(GetClientUserId(client));
						pack.WriteCell(offset);
						pack.WriteCell(ammo);
					}
				}
				else
				{
					GivePlayerItem(client, "weapon_knife");
				}
				break;
			}
		}
	}
}

public Action ReserveAmmoTimer(Handle timer, DataPack pack)
{
	pack.Reset();
	int clientIndex = GetClientOfUserId(pack.ReadCell());
	int offset = pack.ReadCell();
	int ammo = pack.ReadCell();
	
	if(clientIndex > 0 && IsClientInGame(clientIndex))
	{
		SetEntData(clientIndex, offset, ammo, 4, true);
	}
	return Plugin_Stop;
}
