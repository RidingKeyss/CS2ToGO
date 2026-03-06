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

enum LoadoutFamily
{
	LoadoutFamily_None = 0,
	LoadoutFamily_CTPistol,
	LoadoutFamily_CTM4,
	LoadoutFamily_CTAutoPistol,
	LoadoutFamily_TAutoPistol,
	LoadoutFamily_HeavyPistol,
	LoadoutFamily_MidSMG
};


void DebugLoadoutLog(int client, const char[] fmt, any ...)
{
	if (!g_bDropDebug)
	{
		return;
	}

	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 3);
	LogMessage("[weapons:loadout-debug] %s", buffer);

	if (IsValidClient(client))
	{
		PrintToChat(client, " %s \x02[loadout-debug]\x01 %s", g_ChatPrefix, buffer);
	}
}

bool CosmeticsModeAllowsDrops()
{
	return g_iCosmeticsMode != CosmeticsMode_Inventory;
}

void GetCosmeticsModeLabel(char[] buffer, int size)
{
	switch (g_iCosmeticsMode)
	{
		case CosmeticsMode_Inventory:
		{
			strcopy(buffer, size, "inventory");
		}
		case CosmeticsMode_Hybrid:
		{
			strcopy(buffer, size, "hybrid");
		}
		default:
		{
			strcopy(buffer, size, "drops");
		}
	}
}

void ParseCosmeticsMode(const char[] value)
{
	if (StrEqual(value, "inventory", false))
	{
		g_iCosmeticsMode = CosmeticsMode_Inventory;
		return;
	}

	if (StrEqual(value, "hybrid", false))
	{
		g_iCosmeticsMode = CosmeticsMode_Hybrid;
		return;
	}

	g_iCosmeticsMode = CosmeticsMode_Drops;
}

void NormalizeInventoryLookupToken(const char[] input, char[] output, int size)
{
	if (size <= 0)
	{
		return;
	}

	output[0] = EOS;

	int out = 0;
	bool previousUnderscore = false;
	for (int i = 0; input[i] != EOS && out < size - 1; i++)
	{
		int c = CharToLower(input[i]);
		bool isAlphaNum = (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9');
		if (isAlphaNum)
		{
			output[out++] = c;
			previousUnderscore = false;
			continue;
		}

		if (out <= 0 || previousUnderscore)
		{
			continue;
		}

		output[out++] = '_';
		previousUnderscore = true;
	}

	while (out > 0 && output[out - 1] == '_')
	{
		out--;
	}

	output[out] = EOS;
}

void DebugDropLog(int client, const char[] fmt, any ...)
{
	if (!g_bDropDebug)
	{
		return;
	}

	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 3);
	LogMessage("[weapons:drop-debug] %s", buffer);

	if (IsValidClient(client))
	{
		PrintToChat(client, " %s \x02[drop-debug]\x01 %s", g_ChatPrefix, buffer);
	}
}

LoadoutFamily GetLoadoutFamily(const char[] weaponClass)
{
	if (StrEqual(weaponClass, "weapon_hkp2000") || StrEqual(weaponClass, "weapon_p2000") || StrEqual(weaponClass, "weapon_usp_silencer") || StrEqual(weaponClass, "hkp2000") || StrEqual(weaponClass, "p2000") || StrEqual(weaponClass, "usp_silencer"))
	{
		return LoadoutFamily_CTPistol;
	}

	if (StrEqual(weaponClass, "weapon_m4a1") || StrEqual(weaponClass, "weapon_m4a1_silencer") || StrEqual(weaponClass, "m4a1") || StrEqual(weaponClass, "m4a1_silencer"))
	{
		return LoadoutFamily_CTM4;
	}

	if (StrEqual(weaponClass, "weapon_fiveseven") || StrEqual(weaponClass, "fiveseven"))
	{
		return LoadoutFamily_CTAutoPistol;
	}

	if (StrEqual(weaponClass, "weapon_tec9") || StrEqual(weaponClass, "tec9"))
	{
		return LoadoutFamily_TAutoPistol;
	}

	if (StrEqual(weaponClass, "weapon_deagle") || StrEqual(weaponClass, "weapon_revolver") || StrEqual(weaponClass, "deagle") || StrEqual(weaponClass, "revolver"))
	{
		return LoadoutFamily_HeavyPistol;
	}

	if (StrEqual(weaponClass, "weapon_mp7") || StrEqual(weaponClass, "weapon_mp5sd") || StrEqual(weaponClass, "mp7") || StrEqual(weaponClass, "mp5sd"))
	{
		return LoadoutFamily_MidSMG;
	}

	return LoadoutFamily_None;
}

int GetLoadoutFamilySelectedIndex(int client, LoadoutFamily family)
{
	switch (family)
	{
		case LoadoutFamily_CTPistol:
		{
			return g_iCTDefaultPistolVariant[client];
		}
		case LoadoutFamily_CTM4:
		{
			return g_iCTM4Variant[client];
		}
		case LoadoutFamily_CTAutoPistol:
		{
			return g_iCTAutoPistolVariant[client];
		}
		case LoadoutFamily_TAutoPistol:
		{
			return g_iTAutoPistolVariant[client];
		}
		case LoadoutFamily_HeavyPistol:
		{
			return g_iHeavyPistolVariant[client];
		}
		case LoadoutFamily_MidSMG:
		{
			return g_iMidSMGVariant[client];
		}
	}

	return -1;
}

void SetLoadoutFamilySelection(int client, LoadoutFamily family, int weaponIndex)
{
	switch (family)
	{
		case LoadoutFamily_CTPistol:
		{
			g_iCTDefaultPistolVariant[client] = weaponIndex == 5 ? 5 : 6;
		}
		case LoadoutFamily_CTM4:
		{
			g_iCTM4Variant[client] = weaponIndex == 3 ? 3 : 2;
		}
		case LoadoutFamily_CTAutoPistol:
		{
			g_iCTAutoPistolVariant[client] = weaponIndex == 10 ? 10 : 11;
		}
		case LoadoutFamily_TAutoPistol:
		{
			g_iTAutoPistolVariant[client] = weaponIndex == 10 ? 10 : 12;
		}
		case LoadoutFamily_HeavyPistol:
		{
			g_iHeavyPistolVariant[client] = weaponIndex == 13 ? 13 : 4;
		}
		case LoadoutFamily_MidSMG:
		{
			g_iMidSMGVariant[client] = weaponIndex == 47 ? 47 : 22;
		}
	}
}

void ResolveLoadoutClassForClient(int client, const char[] weaponClass, char[] output, int size)
{
	LoadoutFamily family = LoadoutFamily_None;
	if (StrEqual(weaponClass, "weapon_cz75a") || StrEqual(weaponClass, "cz75a"))
	{
		family = GetClientTeam(client) == CS_TEAM_T ? LoadoutFamily_TAutoPistol : LoadoutFamily_CTAutoPistol;
	}
	else
	{
		family = GetLoadoutFamily(weaponClass);
	}

	if (family == LoadoutFamily_None)
	{
		strcopy(output, size, weaponClass);
		return;
	}

	int selectedIndex = GetLoadoutFamilySelectedIndex(client, family);
	if (selectedIndex > -1)
	{
		strcopy(output, size, g_WeaponClasses[selectedIndex]);
	}
	else
	{
		strcopy(output, size, weaponClass);
	}
}

void StripHtml(const char[] source, char[] output, int size)
{
	int start, end;
	strcopy(output, size, source);
	while((start = StrContains(output, ">")) > 0)
	{
		strcopy(output, size, output[start+1]);
		if((end = StrContains(output, "<")) > 0)
		{
			output[end] = '\0';
		}
	}
}

void CleanNameTag(char[] nameTag, int size)
{
	ReplaceString(nameTag, size, "%", "％");
	while(StrContains(nameTag, "  ") > -1)
	{
		ReplaceString(nameTag, size, "  ", " ");
	}
	StripQuotes(nameTag);
}

int GetRandomSkin(int client, int index)
{
	int max = menuWeapons[g_iClientLanguage[client]][index].ItemCount;
	int random = GetRandomInt(2, max);
	char idStr[6];
	menuWeapons[g_iClientLanguage[client]][index].GetItem(random, idStr, sizeof(idStr));
	return StringToInt(idStr);
}

int GetRandomKnife()
{
	return g_iKnifeIndices[GetRandomInt(0, sizeof(g_iKnifeIndices) - 1)];
}


bool GetClientSteamID64(int client, char[] steamid64, int size)
{
	if (g_InventorySteamId64Override[0] != EOS)
	{
		char steamAuth[32];
		if (GetClientAuthId(client, AuthId_Steam2, steamAuth, sizeof(steamAuth), true)
			&& StrEqual(steamAuth, "STEAM_ID_LAN", false))
		{
			DebugDropLog(client, "Steam auth is STEAM_ID_LAN; using override steamid64=%s", g_InventorySteamId64Override);
			strcopy(steamid64, size, g_InventorySteamId64Override);
			return true;
		}
	}

	if (GetClientAuthId(client, AuthId_SteamID64, steamid64, size, true))
	{
		if (StrEqual(steamid64, "STEAM_ID_LAN", false))
		{
			if (g_InventorySteamId64Override[0] != EOS)
			{
				strcopy(steamid64, size, g_InventorySteamId64Override);
				return true;
			}

			DebugDropLog(client, "Steam auth is STEAM_ID_LAN and no override configured (sm_weapons_inventory_steamid64_override)");
			return false;
		}

		DebugDropLog(client, "Resolved SteamID64=%s", steamid64);
		return true;
	}

	// Fallback for environments where SteamID64 is unavailable (LAN/non-Steam auth).
	// The backing DB columns are VARCHAR(32), so Steam2 identifiers are also supported.
	if (GetClientAuthId(client, AuthId_Steam2, steamid64, size, true))
	{
		DebugDropLog(client, "SteamID64 unavailable, using Steam2 auth=%s", steamid64);
		return true;
	}

	steamid64[0] = EOS;
	DebugDropLog(client, "Could not resolve any auth id (SteamID64 or Steam2)");
	return false;
}

bool IsSteamID64String(const char[] steamid)
{
	if (strlen(steamid) != 17)
	{
		return false;
	}

	for (int i = 0; i < 17; i++)
	{
		if (steamid[i] < '0' || steamid[i] > '9')
		{
			return false;
		}
	}

	return true;
}

bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}
	return true;
}

stock int GetWeaponIndex(int entity)
{
	return GetWeaponIndexForClient(0, entity);
}

int GetWeaponIndexForClient(int client, int entity)
{
	char class[32];
	if(GetWeaponClass(entity, class, sizeof(class)))
	{
		if (client > 0)
		{
			char normalized[32];
			ResolveLoadoutClassForClient(client, class, normalized, sizeof(normalized));
			strcopy(class, sizeof(class), normalized);
		}

		int index;
		if(g_smWeaponIndex.GetValue(class, index))
		{
			return index;
		}
	}
	return -1;
}

bool GetWeaponClass(int entity, char[] weaponClass, int size)
{
	int id = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
	return ClassByDefIndex(id, weaponClass, size);
}

bool IsKnifeClass(const char[] classname)
{
	if ((StrContains(classname, "knife") > -1 && strcmp(classname, "weapon_knifegg") != 0) || StrContains(classname, "bayonet") > -1)
		return true;
	return false;
}

bool IsKnife(int entity)
{
	char classname[32];
	if(GetWeaponClass(entity, classname, sizeof(classname)))
		return IsKnifeClass(classname);
	return false;
}

/*
int DefIndexByClass(char[] class)
{
	if (StrEqual(class, "weapon_knife"))
	{
		return 42;
	}
	if (StrEqual(class, "weapon_knife_t"))
	{
		return 59;
	}
	int index;
	g_smWeaponDefIndex.GetValue(class, index);
	if(index > -1)
		return index;
	return 0;
}
*/

void RemoveWeaponPrefix(const char[] source, char[] output, int size)
{
	strcopy(output, size, source[7]);
}

bool ClassByDefIndex(int index, char[] class, int size)
{
	switch(index)
	{
		case 42:
		{
			FormatEx(class, size, "weapon_knife");
			return true;
		}
		case 59:
		{
			FormatEx(class, size, "weapon_knife_t");
			return true;
		}
		default:
		{
			for(int i = 0; i < sizeof(g_iWeaponDefIndex); i++)
			{
				if(g_iWeaponDefIndex[i] == index)
				{
					FormatEx(class, size, g_WeaponClasses[i]);
					return true;
				}
			}
		}
	}
	return false;
}

bool IsValidWeapon(int weaponEntity)
{
	if (weaponEntity > 4096 && weaponEntity != INVALID_ENT_REFERENCE) {
		weaponEntity = EntRefToEntIndex(weaponEntity);
	}
	
	if (!IsValidEdict(weaponEntity) || !IsValidEntity(weaponEntity) || weaponEntity == -1) {
		return false;
	}
	
	char weaponClass[64];
	GetEdictClassname(weaponEntity, weaponClass, sizeof(weaponClass));
	
	return StrContains(weaponClass, "weapon_") == 0;
}

void FirstCharUpper(char[] string)
{
	if (strlen(string) > 0)
	{
		string[0] = CharToUpper(string[0]);
	}
}

int GetTotalKnifeStatTrakCount(int client)
{
	int count = 0;
	for (int i = 0; i < sizeof(g_WeaponClasses); i++)
	{
		if (IsKnifeClass(g_WeaponClasses[i]))
		{
			count += g_iStatTrakCount[client][i];
		}
	}
	return count;
}

int GetRemainingGracePeriodSeconds(int client)
{
	if(g_iGracePeriod == 0 || g_iRoundStartTime == 0 || (IsClientInGame(client) && !IsPlayerAlive(client)))
	{
		return MENU_TIME_FOREVER;
	}
	else
	{
		int remaining = g_iRoundStartTime + g_iGracePeriod - GetTime();
		return remaining > 0 ? remaining : -1;
	}
}

void GetClientKnife(int client, char[] KnifeName, int Size)
{
	if(g_iKnife[client] == 0)
	{
		Format(KnifeName, Size, "weapon_knife");
	}
	else if(g_iKnife[client] == -1)
	{
		Format(KnifeName, Size, "random");
	}
	else
	{
		Format(KnifeName, Size, g_WeaponClasses[g_iKnife[client]]);
	}
}

int SetClientKnife(int client, char[] sKnife, bool Native = false, bool update = true)
{
	int knife;
	if(strcmp(sKnife, "weapon_knife") == 0)
	{
		knife = 0;
	}
	else
	{
		int count = -1;
		for(int i = 33; i < sizeof(g_WeaponClasses); i++)
		{
			if(strcmp(sKnife, g_WeaponClasses[i]) == 0)
			{
				count = i;
				break;
			}
		}
		if(count == -1)
		{
			if(Native)
			{
				return ThrowNativeError(25, "Knife (%s) is not valid.", sKnife);
			}
			else
			{
				return -1;
			}
		}
		knife = count;
	}
	g_iKnife[client] = knife;
	if(update)
	{
		char updateFields[16];
		Format(updateFields, sizeof(updateFields), "knife = %d", knife);
		UpdatePlayerData(client, updateFields);
	}
	RefreshWeapon(client, knife, knife == 0);
	return 0;
}

bool IsWarmUpPeriod()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}


int GetRandomDropSkinForWeapon(int weaponIndex)
{
	if (menuWeapons[0][weaponIndex] == null)
	{
		return 0;
	}
	int max = menuWeapons[0][weaponIndex].ItemCount;
	if (max <= 2)
	{
		return 0;
	}
	int random = GetRandomInt(2, max - 1);
	char idStr[16];
	menuWeapons[0][weaponIndex].GetItem(random, idStr, sizeof(idStr));
	return StringToInt(idStr);
}

bool IsPistolWeaponIndex(int weaponIndex)
{
	return (weaponIndex >= 4 && weaponIndex <= 13);
}

float GetDropWeightForWeaponIndex(int weaponIndex)
{
	if (weaponIndex == g_iWeaponIndexAK47)
	{
		return g_fDropWeightAK47;
	}
	if (weaponIndex == g_iWeaponIndexM4A1)
	{
		return g_fDropWeightM4A1;
	}
	if (weaponIndex == g_iWeaponIndexM4A1S)
	{
		return g_fDropWeightM4A1S;
	}
	if (IsKnifeClass(g_WeaponClasses[weaponIndex]))
	{
		return g_fDropWeightKnife;
	}
	if (IsPistolWeaponIndex(weaponIndex))
	{
		return g_fDropWeightPistol;
	}
	return g_fDropWeightOther;
}

bool GetRandomGlobalDropSkin(int &weaponIndex, int &skinId)
{
	int eligibleWeaponIndices[sizeof(g_WeaponClasses)];
	float eligibleWeights[sizeof(g_WeaponClasses)];
	int eligibleCount = 0;
	float totalWeight = 0.0;

	for (int i = 0; i < sizeof(g_WeaponClasses); i++)
	{
		if (menuWeapons[0][i] == null || menuWeapons[0][i].ItemCount <= 2)
		{
			continue;
		}

		float weight = GetDropWeightForWeaponIndex(i);
		if (weight <= 0.0)
		{
			continue;
		}

		eligibleWeaponIndices[eligibleCount] = i;
		eligibleWeights[eligibleCount] = weight;
		eligibleCount++;
		totalWeight += weight;
	}

	if (eligibleCount <= 0 || totalWeight <= 0.0)
	{
		weaponIndex = -1;
		skinId = 0;
		return false;
	}

	float roll = GetRandomFloat(0.0, totalWeight);
	float cumulative = 0.0;
	for (int i = 0; i < eligibleCount; i++)
	{
		cumulative += eligibleWeights[i];
		if (roll <= cumulative)
		{
			weaponIndex = eligibleWeaponIndices[i];
			skinId = GetRandomDropSkinForWeapon(weaponIndex);
			return (skinId > 0);
		}
	}

	weaponIndex = eligibleWeaponIndices[eligibleCount - 1];
	skinId = GetRandomDropSkinForWeapon(weaponIndex);
	return (skinId > 0);
}

stock int FindUnlockedItemCacheIndex(int client, int unlockedId)
{
	for (int i = 0; i < g_iUnlockedItemCount[client]; i++)
	{
		if (g_iUnlockedItemId[client][i] == unlockedId)
		{
			return i;
		}
	}
	return -1;
}
