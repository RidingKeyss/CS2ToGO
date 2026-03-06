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

public void ReadConfig()
{
	delete g_smWeaponIndex;
	g_smWeaponIndex = new StringMap();
	delete g_smWeaponDefIndex;
	g_smWeaponDefIndex = new StringMap();
	delete g_smWeaponSkinIndex;
	g_smWeaponSkinIndex = new StringMap();
	delete g_smLanguageIndex;
	g_smLanguageIndex = new StringMap();
	delete g_smSkinWearMin;
	g_smSkinWearMin = new StringMap();
	delete g_smSkinWearMax;
	g_smSkinWearMax = new StringMap();
	delete g_smSkinDisplayName;
	g_smSkinDisplayName = new StringMap();
	delete g_smSkinDisplayNameFallback;
	g_smSkinDisplayNameFallback = new StringMap();
	delete g_smSkinIndexByNameAndWeapon;
	g_smSkinIndexByNameAndWeapon = new StringMap();
	
	for (int i = 0; i < sizeof(g_WeaponClasses); i++)
	{
		g_smWeaponIndex.SetValue(g_WeaponClasses[i], i);
		g_smWeaponDefIndex.SetValue(g_WeaponClasses[i], g_iWeaponDefIndex[i]);
	}
	
	int langCount = GetLanguageCount();
	int langCounter = 0;
	for (int i = 0; i < langCount; i++)
	{
		char code[4];
		char language[32];
		GetLanguageInfo(i, code, sizeof(code), language, sizeof(language));
		
		BuildPath(Path_SM, configPath, sizeof(configPath), "configs/weapons/weapons_%s.cfg", language);
		
		if(!FileExists(configPath)) continue;
		
		g_smLanguageIndex.SetValue(language, langCounter);
		FirstCharUpper(language);
		strcopy(g_Language[langCounter], 32, language);
		
		KeyValues kv = CreateKeyValues("Skins");
		FileToKeyValues(kv, configPath);
		
		if (!KvGotoFirstSubKey(kv))
		{
			SetFailState("CFG File not found: %s", configPath);
			CloseHandle(kv);
		}
		
		for (int k = 0; k < sizeof(g_WeaponClasses); k++)
		{
			if(menuWeapons[langCounter][k] != null)
			{
				delete menuWeapons[langCounter][k];
			}
			menuWeapons[langCounter][k] = new Menu(WeaponsMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);
			menuWeapons[langCounter][k].SetTitle("%T", g_WeaponClasses[k], LANG_SERVER);
			menuWeapons[langCounter][k].AddItem("0", "Default");
			menuWeapons[langCounter][k].AddItem("-1", "Random");
			menuWeapons[langCounter][k].ExitBackButton = true;
		}
		
		int counter = 0;
		char weaponTemp[20];
		do {
			char name[64];
			char index[5];
			char classes[1024];
			
			KvGetSectionName(kv, name, sizeof(name));
			KvGetString(kv, "classes", classes, sizeof(classes));
			KvGetString(kv, "index", index, sizeof(index));

			char key[16];
			FormatEx(key, sizeof(key), "%d", StringToInt(index));
			int minScaled = RoundToFloor(KvGetFloat(kv, "wear_min", g_fDropWearDefaultMin) * 100000.0);
			int maxScaled = RoundToCeil(KvGetFloat(kv, "wear_max", g_fDropWearDefaultMax) * 100000.0);
			g_smSkinWearMin.SetValue(key, minScaled);
			g_smSkinWearMax.SetValue(key, maxScaled);

			char displayNameKey[24];
			FormatEx(displayNameKey, sizeof(displayNameKey), "%d:%d", langCounter, StringToInt(index));
			g_smSkinDisplayName.SetString(displayNameKey, name);
			char fallbackProbe[2];
			if (!g_smSkinDisplayNameFallback.GetString(key, fallbackProbe, sizeof(fallbackProbe)))
			{
				g_smSkinDisplayNameFallback.SetString(key, name);
			}
			
			for (int k = 0; k < sizeof(g_WeaponClasses); k++)
			{
				Format(weaponTemp, sizeof(weaponTemp), "%s;", g_WeaponClasses[k]);
				if(StrContains(classes, weaponTemp) > -1)
				{
					menuWeapons[langCounter][k].AddItem(index, name);
					char compatibilityKey[24];
					FormatEx(compatibilityKey, sizeof(compatibilityKey), "%d:%s", StringToInt(index), g_WeaponClasses[k]);
					g_smWeaponSkinIndex.SetValue(compatibilityKey, 1);

					char normalizedSkinName[96];
					NormalizeInventoryLookupToken(name, normalizedSkinName, sizeof(normalizedSkinName));
					if (normalizedSkinName[0] != EOS)
					{
						char importLookupKey[160];
						FormatEx(importLookupKey, sizeof(importLookupKey), "%s::%s", normalizedSkinName, g_WeaponClasses[k]);
						int existingSkinId;
						if (!g_smSkinIndexByNameAndWeapon.GetValue(importLookupKey, existingSkinId))
						{
							g_smSkinIndexByNameAndWeapon.SetValue(importLookupKey, StringToInt(index));
						}
					}
				}
			}
			counter++;
		} while (KvGotoNextKey(kv));
		
		CloseHandle(kv);
		
		langCounter++;
	}
	
	if(langCounter == 0)
	{
		SetFailState("Could not find a config file for any languages.");
	}
}


bool GetSkinWearBounds(int skinId, float &minWear, float &maxWear)
{
	char key[16];
	FormatEx(key, sizeof(key), "%d", skinId);
	int minScaled;
	int maxScaled;
	if (g_smSkinWearMin != null && g_smSkinWearMax != null && g_smSkinWearMin.GetValue(key, minScaled) && g_smSkinWearMax.GetValue(key, maxScaled))
	{
		minWear = float(minScaled) / 100000.0;
		maxWear = float(maxScaled) / 100000.0;
		if (minWear > maxWear)
		{
			float swap = minWear;
			minWear = maxWear;
			maxWear = swap;
		}
		return true;
	}
	minWear = g_fDropWearDefaultMin;
	maxWear = g_fDropWearDefaultMax;
	if (minWear > maxWear)
	{
		float swap = minWear;
		minWear = maxWear;
		maxWear = swap;
	}
	return false;
}

bool GetSkinDisplayName(int client, int skinId, char[] displayName, int size)
{
	if (size <= 0)
	{
		return false;
	}

	displayName[0] = EOS;

	if (g_smSkinDisplayName == null)
	{
		return false;
	}

	char key[24];
	FormatEx(key, sizeof(key), "%d:%d", g_iClientLanguage[client], skinId);
	if (g_smSkinDisplayName.GetString(key, displayName, size))
	{
		return true;
	}

	FormatEx(key, sizeof(key), "%d", skinId);
	if (g_smSkinDisplayNameFallback != null && g_smSkinDisplayNameFallback.GetString(key, displayName, size))
	{
		return true;
	}

	return false;
}
