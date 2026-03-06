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

public void OnConfigsExecuted()
{
	GetConVarString(g_Cvar_DBConnection, g_DBConnection, sizeof(g_DBConnection));
	GetConVarString(g_Cvar_TablePrefix, g_TablePrefix, sizeof(g_TablePrefix));
	g_iGraceInactiveDays = g_Cvar_InactiveDays.IntValue;
	
	if(g_DBConnectionOld[0] != EOS && strcmp(g_DBConnectionOld, g_DBConnection) != 0)
	{
		delete db;
	}
	
	if(db == null)
	{
		g_iDatabaseState = 0;
		Database.Connect(SQLConnectCallback, g_DBConnection);
	}
	else
	{
		DeleteInactivePlayerData();
	}
	
	strcopy(g_DBConnectionOld, sizeof(g_DBConnectionOld), g_DBConnection);
	
	g_Cvar_ChatPrefix.GetString(g_ChatPrefix, sizeof(g_ChatPrefix));
	g_iKnifeStatTrakMode = g_Cvar_KnifeStatTrakMode.IntValue;
	g_bEnableFloat = g_Cvar_EnableFloat.BoolValue;
	g_bEnableNameTag = g_Cvar_EnableNameTag.BoolValue;
	g_bEnableStatTrak = g_Cvar_EnableStatTrak.BoolValue;
	g_bEnableSeed = g_Cvar_EnableSeed.BoolValue;
	g_fFloatIncrementSize = g_Cvar_FloatIncrementSize.FloatValue;
	g_iFloatIncrementPercentage = RoundFloat(g_fFloatIncrementSize * 100.0);
	g_bOverwriteEnabled = g_Cvar_EnableWeaponOverwrite.BoolValue;
	g_bEnablePublicWS = g_Cvar_EnablePublicWS.BoolValue;
	g_iGracePeriod = g_Cvar_GracePeriod.IntValue;
	g_fDropChance = g_Cvar_DropChance.FloatValue;
	char cosmeticsMode[16];
	g_Cvar_CosmeticsMode.GetString(cosmeticsMode, sizeof(cosmeticsMode));
	ParseCosmeticsMode(cosmeticsMode);
	if (g_fDropChance < 0.0) g_fDropChance = 0.0;
	if (g_fDropChance > 1.0) g_fDropChance = 1.0;
	g_bDropShowRollStats = g_Cvar_DropShowRollStats.BoolValue;
	g_bDropDebug = g_Cvar_DropDebug.BoolValue;
	g_fDropStatTrakChance = g_Cvar_DropStatTrakChance.FloatValue;
	if (g_fDropStatTrakChance < 0.0) g_fDropStatTrakChance = 0.0;
	if (g_fDropStatTrakChance > 1.0) g_fDropStatTrakChance = 1.0;
	g_iDropSeedMin = g_Cvar_DropSeedMin.IntValue;
	g_iDropSeedMax = g_Cvar_DropSeedMax.IntValue;
	if (g_iDropSeedMin > g_iDropSeedMax)
	{
		int seedSwap = g_iDropSeedMin;
		g_iDropSeedMin = g_iDropSeedMax;
		g_iDropSeedMax = seedSwap;
	}
	g_fDropWearDefaultMin = g_Cvar_DropWearDefaultMin.FloatValue;
	g_fDropWearDefaultMax = g_Cvar_DropWearDefaultMax.FloatValue;
	if (g_fDropWearDefaultMin > g_fDropWearDefaultMax)
	{
		float wearSwap = g_fDropWearDefaultMin;
		g_fDropWearDefaultMin = g_fDropWearDefaultMax;
		g_fDropWearDefaultMax = wearSwap;
	}

	g_fDropWeightKnife = g_Cvar_DropWeightKnife.FloatValue;
	if (g_fDropWeightKnife < 0.0) g_fDropWeightKnife = 0.0;
	g_fDropWeightAK47 = g_Cvar_DropWeightAK47.FloatValue;
	if (g_fDropWeightAK47 < 0.0) g_fDropWeightAK47 = 0.0;
	g_fDropWeightM4A1 = g_Cvar_DropWeightM4A1.FloatValue;
	if (g_fDropWeightM4A1 < 0.0) g_fDropWeightM4A1 = 0.0;
	g_fDropWeightM4A1S = g_Cvar_DropWeightM4A1S.FloatValue;
	if (g_fDropWeightM4A1S < 0.0) g_fDropWeightM4A1S = 0.0;
	g_fDropWeightPistol = g_Cvar_DropWeightPistol.FloatValue;
	if (g_fDropWeightPistol < 0.0) g_fDropWeightPistol = 0.0;
	g_fDropWeightOther = g_Cvar_DropWeightOther.FloatValue;
	if (g_fDropWeightOther < 0.0) g_fDropWeightOther = 0.0;
	g_Cvar_InventoryImportSourceTable.GetString(g_InventoryImportSourceTable, sizeof(g_InventoryImportSourceTable));
	g_fInventoryImportSyncInterval = g_Cvar_InventoryImportSyncInterval.FloatValue;
	g_Cvar_InventoryBackendUrl.GetString(g_InventoryBackendUrl, sizeof(g_InventoryBackendUrl));
	g_Cvar_InventoryBackendApiKey.GetString(g_InventoryBackendApiKey, sizeof(g_InventoryBackendApiKey));
	g_Cvar_InventorySteamId64Override.GetString(g_InventorySteamId64Override, sizeof(g_InventorySteamId64Override));
	TrimString(g_InventorySteamId64Override);
	if (g_fInventoryImportSyncInterval < 0.0)
	{
		g_fInventoryImportSyncInterval = 0.0;
	}
	RefreshInventoryImportTimer();

	if (g_bDropDebug)
	{
		char overrideDisplay[32];
		if (g_InventorySteamId64Override[0] != EOS)
		{
			strcopy(overrideDisplay, sizeof(overrideDisplay), g_InventorySteamId64Override);
		}
		else
		{
			strcopy(overrideDisplay, sizeof(overrideDisplay), "<empty>");
		}
		LogMessage("[weapons:drop-debug] inventory config loaded: mode=%d backend_url_set=%d backend_key_set=%d steamid_override=%s", g_iCosmeticsMode, g_InventoryBackendUrl[0] != EOS, g_InventoryBackendApiKey[0] != EOS, overrideDisplay);
	}
	if(g_iGracePeriod > 0)
	{
		HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
	
	ReadConfig();
	g_smWeaponIndex.GetValue("weapon_ak47", g_iWeaponIndexAK47);
	g_smWeaponIndex.GetValue("weapon_m4a1", g_iWeaponIndexM4A1);
	g_smWeaponIndex.GetValue("weapon_m4a1_silencer", g_iWeaponIndexM4A1S);
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client))
	{
		if(g_bEnableStatTrak)
			SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	else if(IsValidClient(client))
	{
		g_iIndex[client] = 0;
		g_FloatTimer[client] = INVALID_HANDLE;
		g_bWaitingForNametag[client] = false;
		g_bWaitingForSeed[client] = false;
		for (int i = 0; i < sizeof(g_WeaponClasses); i++)
		{
			g_iSeedRandom[client][i] = 0;
		}
		g_iCTDefaultPistolVariant[client] = 6;
		g_iCTM4Variant[client] = 2;
		g_iCTAutoPistolVariant[client] = 11;
		g_iTAutoPistolVariant[client] = 12;
		g_iHeavyPistolVariant[client] = 4;
		g_iMidSMGVariant[client] = 22;
		g_iUnlockedItemCount[client] = 0;
		HookPlayer(client);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(g_iDatabaseState > 1 && IsValidClient(client))
	{
		GetPlayerData(client);
		SyncInventoryFromBackendForClient(client);
		LoadClientUnlockedItems(client);
		GetLoadoutSelection(client);
		QueryClientConVar(client, "cl_language", ConVarCallBack);
	}
}

public void ConVarCallBack(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if(!g_smLanguageIndex.GetValue(cvarValue, g_iClientLanguage[client]))
	{
		g_iClientLanguage[client] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
	{
		if(g_bEnableStatTrak)
			SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	else if(IsValidClient(client))
	{
		UnhookPlayer(client);
		for(int i = 0; i < sizeof(g_WeaponClasses); i++)
		{
			g_iSkins[client][i] = 0;
			g_iStatTrak[client][i] = 0;
			g_iStatTrakCount[client][i] = 0;
			g_NameTag[client][i] = "";
			g_fFloatValue[client][i] = 0.0;
			g_iWeaponSeed[client][i] = -1;
		}
		g_iKnife[client] = 0;
		g_iUnlockedItemCount[client] = 0;
		g_iCTDefaultPistolVariant[client] = 6;
		g_iCTM4Variant[client] = 2;
		g_iCTAutoPistolVariant[client] = 11;
		g_iTAutoPistolVariant[client] = 12;
		g_iHeavyPistolVariant[client] = 4;
		g_iMidSMGVariant[client] = 22;
	}
}

public void OnPluginEnd()
{
	if (g_hInventoryImportTimer != INVALID_HANDLE)
	{
		delete g_hInventoryImportTimer;
		g_hInventoryImportTimer = INVALID_HANDLE;
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientDisconnect(i);
		}
	}
}
