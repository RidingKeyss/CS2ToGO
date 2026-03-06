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

public int WeaponsMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				int index = g_iIndex[client];
				
				char skinIdStr[32];
				menu.GetItem(selection, skinIdStr, sizeof(skinIdStr));
				int skinId = StringToInt(skinIdStr);
				
				g_iSkins[client][index] = skinId;
				char updateFields[256];
				char weaponName[32];
				RemoveWeaponPrefix(g_WeaponClasses[index], weaponName, sizeof(weaponName));
				Format(updateFields, sizeof(updateFields), "%s = %d", weaponName, skinId);
				UpdatePlayerData(client, updateFields);
				
				RefreshWeapon(client, index);
				
				DataPack pack;
				CreateDataTimer(0.5, WeaponsMenuTimer, pack);
				pack.WriteCell(menu);
				pack.WriteCell(GetClientUserId(client));
				pack.WriteCell(GetMenuSelectionPosition());
			}
		}
		case MenuAction_DisplayItem:
		{
			if(IsClientInGame(client))
			{
				char info[32];
				char display[64];
				menu.GetItem(selection, info, sizeof(info));
				
				if (StrEqual(info, "0"))
				{
					Format(display, sizeof(display), "%T", "DefaultSkin", client);
					return RedrawMenuItem(display);
				}
				else if (StrEqual(info, "-1"))
				{
					Format(display, sizeof(display), "%T", "RandomSkin", client);
					return RedrawMenuItem(display);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if (IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				int menuTime;
				if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
				{
					CreateWeaponMenu(client).Display(client, menuTime);
				}
			}
		}
	}
	return 0;
}

public Action WeaponsMenuTimer(Handle timer, DataPack pack)
{
	ResetPack(pack);
	Menu menu = pack.ReadCell();
	int clientIndex = GetClientOfUserId(pack.ReadCell());
	int menuSelectionPosition = pack.ReadCell();
	
	if(IsValidClient(clientIndex))
	{
		int menuTime;
		if((menuTime = GetRemainingGracePeriodSeconds(clientIndex)) >= 0)
		{
			menu.DisplayAt(clientIndex, menuSelectionPosition, menuTime);
		}
	}
	return Plugin_Stop;
}

public int WeaponMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				if(StrEqual(buffer, "skin"))
				{
					int menuTime;
					if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						menuWeapons[g_iClientLanguage[client]][g_iIndex[client]].Display(client, menuTime);
					}
				}
				else if(StrEqual(buffer, "float"))
				{
					int menuTime;
					if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						CreateFloatMenu(client).Display(client, menuTime);
					}
				}
				else if(StrEqual(buffer, "stattrak"))
				{
					g_iStatTrak[client][g_iIndex[client]] = 1 - g_iStatTrak[client][g_iIndex[client]];
					char updateFields[256];
					char weaponName[32];
					RemoveWeaponPrefix(g_WeaponClasses[g_iIndex[client]], weaponName, sizeof(weaponName));
					Format(updateFields, sizeof(updateFields), "%s_trak = %d", weaponName, g_iStatTrak[client][g_iIndex[client]]);
					UpdatePlayerData(client, updateFields);
					
					RefreshWeapon(client, g_iIndex[client]);
					
					CreateTimer(1.0, StatTrakMenuTimer, GetClientUserId(client));
				}
				else if(StrEqual(buffer, "nametag"))
				{
					int menuTime;
					if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						CreateNameTagMenu(client).Display(client, menuTime);
					}
				}
				else if (StrEqual(buffer, "seed"))
				{
					int menuTime;
					if ((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						CreateSeedMenu(client).Display(client, menuTime);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				int menuTime;
				if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
				{
					CreateMainMenu(client).Display(client, menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action StatTrakMenuTimer(Handle timer, int userid)
{
	int clientIndex = GetClientOfUserId(userid);
	if(IsValidClient(clientIndex))
	{
		int menuTime;
		if((menuTime = GetRemainingGracePeriodSeconds(clientIndex)) >= 0)
		{
			CreateWeaponMenu(clientIndex).Display(clientIndex, menuTime);
		}
	}
	return Plugin_Stop;
}

Menu CreateFloatMenu(int client)
{
	char buffer[60];
	Menu menu = new Menu(FloatMenuHandler);
	
	float fValue = g_fFloatValue[client][g_iIndex[client]];
	fValue = fValue * 100.0;
	int wear = 100 - RoundFloat(fValue);
	
	menu.SetTitle("%T%d%%", "SetFloat", client, wear);
	
	Format(buffer, sizeof(buffer), "%T", "Increase", client, g_iFloatIncrementPercentage);
	menu.AddItem("increase", buffer, wear == 100 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "%T", "Decrease", client, g_iFloatIncrementPercentage);
	menu.AddItem("decrease", buffer, wear == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int FloatMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				if(StrEqual(buffer, "increase"))
				{
					g_fFloatValue[client][g_iIndex[client]] = g_fFloatValue[client][g_iIndex[client]] - g_fFloatIncrementSize;
					if(g_fFloatValue[client][g_iIndex[client]] < 0.0)
					{
						g_fFloatValue[client][g_iIndex[client]] = 0.0;
					}
					if(g_FloatTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_FloatTimer[client]);
						g_FloatTimer[client] = INVALID_HANDLE;
					}
					DataPack pack;
					g_FloatTimer[client] = CreateDataTimer(1.0, FloatTimer, pack);
					pack.WriteCell(GetClientUserId(client));
					pack.WriteCell(g_iIndex[client]);
					int menuTime;
					if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						CreateFloatMenu(client).Display(client, menuTime);
					}
				}
				else if(StrEqual(buffer, "decrease"))
				{
					g_fFloatValue[client][g_iIndex[client]] = g_fFloatValue[client][g_iIndex[client]] + g_fFloatIncrementSize;
					if(g_fFloatValue[client][g_iIndex[client]] > 1.0)
					{
						g_fFloatValue[client][g_iIndex[client]] = 1.0;
					}
					if(g_FloatTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_FloatTimer[client]);
						g_FloatTimer[client] = INVALID_HANDLE;
					}
					DataPack pack;
					g_FloatTimer[client] = CreateDataTimer(1.0, FloatTimer, pack);
					pack.WriteCell(GetClientUserId(client));
					pack.WriteCell(g_iIndex[client]);
					int menuTime;
					if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						CreateFloatMenu(client).Display(client, menuTime);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				int menuTime;
				if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
				{
					CreateWeaponMenu(client).Display(client, menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action FloatTimer(Handle timer, DataPack pack)
{

	ResetPack(pack);
	int clientIndex = GetClientOfUserId(pack.ReadCell());
	int index = pack.ReadCell();
	
	if(IsValidClient(clientIndex))
	{
		char updateFields[256];
		char weaponName[32];
		RemoveWeaponPrefix(g_WeaponClasses[index], weaponName, sizeof(weaponName));
		Format(updateFields, sizeof(updateFields), "%s_float = %.2f", weaponName, g_fFloatValue[clientIndex][g_iIndex[clientIndex]]);
		UpdatePlayerData(clientIndex, updateFields);
		
		RefreshWeapon(clientIndex, index);
	}

	g_FloatTimer[clientIndex] = INVALID_HANDLE;
	return Plugin_Stop;
}

Menu CreateSeedMenu(int client)
{
	Menu menu = new Menu(SeedMenuHandler);

	char buffer[128];

	if (g_iWeaponSeed[client][g_iIndex[client]] != -1)
	{
		Format(buffer, sizeof(buffer), "%T", "SeedTitle", client, g_iWeaponSeed[client][g_iIndex[client]]);
	}
	else if (g_iSeedRandom[client][g_iIndex[client]] > 0)
	{
		Format(buffer, sizeof(buffer), "%T", "SeedTitle", client, g_iSeedRandom[client][g_iIndex[client]]);
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "SeedTitleNoSeed", client);
	}
	menu.SetTitle(buffer);

	Format(buffer, sizeof(buffer), "%T", "SeedRandom", client);
	menu.AddItem("rseed", buffer);

	Format(buffer, sizeof(buffer), "%T", "SeedManual", client);
	menu.AddItem("cseed", buffer);

	Format(buffer, sizeof(buffer), "%T", "SeedSave", client);
	menu.AddItem("sseed", buffer, g_iSeedRandom[client][g_iIndex[client]] == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	Format(buffer, sizeof(buffer), "%T", "ResetSeed", client);
	menu.AddItem("seedr", buffer, g_iWeaponSeed[client][g_iIndex[client]] == -1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	menu.ExitBackButton = true;
	
	return menu;
}

public int SeedMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				if(StrEqual(buffer, "rseed"))
				{
					g_iWeaponSeed[client][g_iIndex[client]] = -1;
					RefreshWeapon(client, g_iIndex[client]);
					CreateTimer(0.1, SeedMenuTimer, GetClientUserId(client));
				}
				else if (StrEqual(buffer, "cseed"))
				{
					g_bWaitingForSeed[client] = true;
					PrintToChat(client, " %s \x04%t", g_ChatPrefix, "SeedInstruction");
				}
				else if (StrEqual(buffer, "sseed"))
				{
					if(g_iSeedRandom[client][g_iIndex[client]] > 0) 
					{
						g_iWeaponSeed[client][g_iIndex[client]] = g_iSeedRandom[client][g_iIndex[client]];
					}
					g_iSeedRandom[client][g_iIndex[client]] = 0;
					RefreshWeapon(client, g_iIndex[client]);

					char updateFields[256];
					char weaponName[32];
					RemoveWeaponPrefix(g_WeaponClasses[g_iIndex[client]], weaponName, sizeof(weaponName));
					Format(updateFields, sizeof(updateFields), "%s_seed = %d", weaponName, g_iWeaponSeed[client][g_iIndex[client]]);
					UpdatePlayerData(client, updateFields);
					CreateTimer(0.1, SeedMenuTimer, GetClientUserId(client));

					PrintToChat(client, " %s \x04%t", g_ChatPrefix, "SeedSaved");
				}
				else if (StrEqual(buffer, "seedr"))
				{
					g_iWeaponSeed[client][g_iIndex[client]] = -1;
					g_iSeedRandom[client][g_iIndex[client]] = 0;
					
					char updateFields[256];
					char weaponName[32];
					RemoveWeaponPrefix(g_WeaponClasses[g_iIndex[client]], weaponName, sizeof(weaponName));
					Format(updateFields, sizeof(updateFields), "%s_seed = -1", weaponName);
					UpdatePlayerData(client, updateFields);
					CreateTimer(0.1, SeedMenuTimer, GetClientUserId(client));
					
					PrintToChat(client, " %s \x04%t", g_ChatPrefix, "SeedReset");
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				int menuTime;
				if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
				{
					CreateWeaponMenu(client).Display(client, menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action SeedMenuTimer(Handle timer, int userid)
{
	int clientIndex = GetClientOfUserId(userid);
	if(IsValidClient(clientIndex))
	{
		int menuTime;
		if((menuTime = GetRemainingGracePeriodSeconds(clientIndex)) >= 0)
		{
			CreateSeedMenu(clientIndex).Display(clientIndex, menuTime);
		}
	}
	return Plugin_Stop;
}

Menu CreateNameTagMenu(int client)
{
	Menu menu = new Menu(NameTagMenuHandler);
	
	char buffer[128];
	
	StripHtml(g_NameTag[client][g_iIndex[client]], buffer, sizeof(buffer));
	menu.SetTitle("%T: %s", "SetNameTag", client, buffer);
	
	Format(buffer, sizeof(buffer), "%T", "ChangeNameTag", client);
	menu.AddItem("nametag", buffer);
	
	/* NAMETAGCOLOR
	Format(buffer, sizeof(buffer), "%T", "NameTagColor", client);
	menu.AddItem("color", buffer, strlen(g_NameTag[client][g_iIndex[client]]) > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	*/
	
	Format(buffer, sizeof(buffer), "%T", "DeleteNameTag", client);
	menu.AddItem("delete", buffer, strlen(g_NameTag[client][g_iIndex[client]]) > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int NameTagMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				if(StrEqual(buffer, "nametag"))
				{
					g_bWaitingForNametag[client] = true;
					PrintToChat(client, " %s \x04%t", g_ChatPrefix, "NameTagInstruction");
				}
				/* NAMETAGCOLOR
				else if(StrEqual(buffer, "color"))
				{
					int menuTime;
					if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						CreateColorsMenu(client).Display(client, menuTime);
					}
				}
				*/
				else if(StrEqual(buffer, "delete"))
				{
					g_NameTag[client][g_iIndex[client]] = "";
					
					char updateFields[256];
					char weaponName[32];
					RemoveWeaponPrefix(g_WeaponClasses[g_iIndex[client]], weaponName, sizeof(weaponName));
					Format(updateFields, sizeof(updateFields), "%s_tag = ''", weaponName);
					UpdatePlayerData(client, updateFields);
					
					RefreshWeapon(client, g_iIndex[client]);
					
					int menuTime;
					if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						CreateWeaponMenu(client).Display(client, menuTime);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				int menuTime;
				if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
				{
					CreateWeaponMenu(client).Display(client, menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

/* NAMETAGCOLOR
Menu CreateColorsMenu(int client)
{
	Menu menu = new Menu(ColorsMenuHandler);
	menu.SetTitle("%T", "ChooseColor", client);
	
	char buffer[128];
	
	Format(buffer, sizeof(buffer), "%T", "DefaultColor", client);
	menu.AddItem("default", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Black", client);
	menu.AddItem("000000", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Yellow", client);
	menu.AddItem("FFFF00", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Red", client);
	menu.AddItem("FF0000", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Green", client);
	menu.AddItem("00FF00", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Blue", client);
	menu.AddItem("0000AA", buffer);
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int ColorsMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				
				char stripped[128];
				char escaped[257];
				char colored[128];
				char updateFields[512];
				StripHtml(g_NameTag[client][g_iIndex[client]], stripped, sizeof(stripped));
				if (StrEqual(buffer, "default"))
				{
					g_NameTag[client][g_iIndex[client]] = stripped;
					
					db.Escape(stripped, escaped, sizeof(escaped));
				}
				else
				{
					Format(colored, sizeof(colored), "<font color='#%s'>%s</font>", buffer, stripped);
					g_NameTag[client][g_iIndex[client]] = colored;
					
					db.Escape(colored, escaped, sizeof(escaped));
				}
				
				char weaponName[32];
				RemoveWeaponPrefix(g_WeaponClasses[g_iIndex[client]], weaponName, sizeof(weaponName));
				Format(updateFields, sizeof(updateFields), "%s_tag = '%s'", weaponName, escaped);
				UpdatePlayerData(client, updateFields);
				
				RefreshWeapon(client, g_iIndex[client]);
				
				CreateTimer(1.0, NameTagColorsMenuTimer, GetClientUserId(client));
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				int menuTime;
				if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
				{
					CreateNameTagMenu(client).Display(client, menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action NameTagColorsMenuTimer(Handle timer, int userid)
{
	int clientIndex = GetClientOfUserId(userid);
	if(IsValidClient(clientIndex))
	{
		int menuTime;
		if((menuTime = GetRemainingGracePeriodSeconds(clientIndex)) >= 0)
		{
			CreateColorsMenu(clientIndex).Display(clientIndex, menuTime);
		}
	}
}
*/

Menu CreateAllWeaponsMenu(int client)
{
	Menu menu = new Menu(AllWeaponsMenuHandler);
	menu.SetTitle("%T", "AllWeaponsMenuTitle", client);
	
	char name[32];
	for (int i = 0; i < sizeof(g_WeaponClasses); i++)
	{
		Format(name, sizeof(name), "%T", g_WeaponClasses[i], client);
		menu.AddItem(g_WeaponClasses[i], name);
	}
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int AllWeaponsMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char class[30];
				menu.GetItem(selection, class, sizeof(class));
				
				g_smWeaponIndex.GetValue(class, g_iIndex[client]);
				int menuTime;
				if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
				{
					CreateWeaponMenu(client).Display(client, menuTime);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				int menuTime;
				if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
				{
					CreateMainMenu(client).Display(client, menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

Menu CreateWeaponMenu(int client)
{
	int index = g_iIndex[client];
	
	Menu menu = new Menu(WeaponMenuHandler);
	menu.SetTitle("%T", g_WeaponClasses[index], client);
	
	char buffer[128];
	
	Format(buffer, sizeof(buffer), "%T", "SetSkin", client);
	menu.AddItem("skin", buffer);

	bool weaponHasSkin = (g_iSkins[client][index] != 0);
	
	if (g_bEnableFloat)
	{
		float fValue = g_fFloatValue[client][index];
		fValue = fValue * 100.0;
		int wear = 100 - RoundFloat(fValue);
		Format(buffer, sizeof(buffer), "%T%d%%", "SetFloat", client, wear);
		menu.AddItem("float", buffer, weaponHasSkin ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	if (g_bEnableStatTrak)
	{
		if (g_iStatTrak[client][index] == 1)
		{
			Format(buffer, sizeof(buffer), "%T%T", "StatTrak", client, "On", client);
		}
		else
		{
			Format(buffer, sizeof(buffer), "%T%T", "StatTrak", client, "Off", client);
		}
		menu.AddItem("stattrak", buffer, weaponHasSkin ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	if (g_bEnableNameTag)
	{
		Format(buffer, sizeof(buffer), "%T", "SetNameTag", client);
		menu.AddItem("nametag", buffer, weaponHasSkin ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	if (g_bEnableSeed)
	{
		Format(buffer, sizeof(buffer), "%T", "Seed", client);
		menu.AddItem("seed", buffer, weaponHasSkin ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	
	return menu;
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char info[64];
				menu.GetItem(selection, info, sizeof(info));
				int menuTime;
				if(StrEqual(info, "all"))
				{
					if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						CreateAllWeaponsMenu(client).Display(client, menuTime);
					}
				}
				else if(StrEqual(info, "lang"))
				{
					if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						CreateLanguageMenu(client).Display(client, menuTime);
					}
				}
				else
				{
					g_smWeaponIndex.GetValue(info, g_iIndex[client]);
					if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
					{
						CreateWeaponMenu(client).Display(client, menuTime);
					}
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

Menu CreateMainMenu(int client)
{
	char buffer[60];
	Menu menu = new Menu(MainMenuHandler, MENU_ACTIONS_DEFAULT);
	
	menu.SetTitle("%T", "WSMenuTitle", client);
	
	Format(buffer, sizeof(buffer), "%T", "ConfigAllWeapons", client);
	menu.AddItem("all", buffer);
	
	int index = 2;
	
	if (IsPlayerAlive(client))
	{
		char weaponClass[32];
		char weaponName[32];
		
		int size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
		for (int i = 0; i < size; i++)
		{
			int weaponEntity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
			if(weaponEntity != -1 && GetWeaponClass(weaponEntity, weaponClass, sizeof(weaponClass)))
			{
				Format(weaponName, sizeof(weaponName), "%T", weaponClass, client);
				menu.AddItem(weaponClass, weaponName, (IsKnifeClass(weaponClass) && g_iKnife[client] == 0) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
			// Moved index increment out of if-block
			index++;
		}
	}
	
	for(int i = index; i < 6; i++)
	{
		menu.AddItem("", "", ITEMDRAW_SPACER);
	}
	
	Format(buffer, sizeof(buffer), "%T", "ChangeLang", client);
	menu.AddItem("lang", buffer);

	// Iterates over main item menu and checks for the knife duplicate (usually appears at bottom half of main !ws menu)
	int menuItems = menu.ItemCount;
	if (menuItems == 6) 
	{
		char dupKnife[32];
		for (int menuItemIndex = 0, dupKnifeCounter = 0; menuItemIndex < menuItems; menuItemIndex++) 
		{
			bool menuItemExists = menu.GetItem(menuItemIndex, dupKnife, sizeof(dupKnife));
			if (menuItemExists && IsKnifeClass(dupKnife))
			{
				dupKnifeCounter++;
				for (int i = 0; i < dupKnifeCounter; i++) 
				{
					if (dupKnifeCounter >= 1) {
						menu.RemoveItem(menuItemIndex);
						return menu;	
					}
				}
			}
		}
	}	
	else if (menuItems == 5) 
	{
		char dupKnife_[32];
		for (int menuItemIndex = 0, dupKnifeCounter = 0; menuItemIndex < menuItems; menuItemIndex++) 
		{
			bool menuItemExists = menu.GetItem(menuItemIndex, dupKnife_, sizeof(dupKnife_));
			if (menuItemExists && IsKnifeClass(dupKnife_))
			{
				dupKnifeCounter++;
				for (int i = 0; i < dupKnifeCounter; i++) 
				{
					if (dupKnifeCounter > 1) {
						menu.RemoveItem(menuItemIndex);
						return menu;	
					}
				}
			}
		}
	}	

	return menu;
}


Menu CreateLoadoutMenu(int client)
{
	Menu menu = new Menu(LoadoutMenuHandler);
	menu.SetTitle("Loadout");

	char label[64];
	Format(label, sizeof(label), "CT Default Pistol: %s", g_WeaponClasses[g_iCTDefaultPistolVariant[client]]);
	menu.AddItem("ct_default_pistol", label);
	Format(label, sizeof(label), "CT M4: %s", g_WeaponClasses[g_iCTM4Variant[client]]);
	menu.AddItem("ct_m4", label);
	Format(label, sizeof(label), "Five-SeveN / CZ75-Auto: %s", g_WeaponClasses[g_iCTAutoPistolVariant[client]]);
	menu.AddItem("ct_auto_pistol", label);
	Format(label, sizeof(label), "Tec-9 / CZ75-Auto: %s", g_WeaponClasses[g_iTAutoPistolVariant[client]]);
	menu.AddItem("t_auto_pistol", label);
	Format(label, sizeof(label), "Deagle / R8 Revolver: %s", g_WeaponClasses[g_iHeavyPistolVariant[client]]);
	menu.AddItem("heavy_pistol", label);
	Format(label, sizeof(label), "MP7 / MP5-SD: %s", g_WeaponClasses[g_iMidSMGVariant[client]]);
	menu.AddItem("mid_smg", label);

	return menu;
}

public int LoadoutMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (IsClientInGame(client))
			{
				char info[64];
				menu.GetItem(selection, info, sizeof(info));

				int menuTime = GetRemainingGracePeriodSeconds(client);
				if (menuTime < 0)
				{
					PrintToChat(client, " %s \x02%t", g_ChatPrefix, "GracePeriod", g_iGracePeriod);
					return 0;
				}

				if (StrEqual(info, "ct_default_pistol"))
				{
					CreateLoadoutVariantMenu(client, LoadoutFamily_CTPistol).Display(client, menuTime);
				}
				else if (StrEqual(info, "ct_m4"))
				{
					CreateLoadoutVariantMenu(client, LoadoutFamily_CTM4).Display(client, menuTime);
				}
				else if (StrEqual(info, "ct_auto_pistol"))
				{
					CreateLoadoutVariantMenu(client, LoadoutFamily_CTAutoPistol).Display(client, menuTime);
				}
				else if (StrEqual(info, "t_auto_pistol"))
				{
					CreateLoadoutVariantMenu(client, LoadoutFamily_TAutoPistol).Display(client, menuTime);
				}
				else if (StrEqual(info, "heavy_pistol"))
				{
					CreateLoadoutVariantMenu(client, LoadoutFamily_HeavyPistol).Display(client, menuTime);
				}
				else if (StrEqual(info, "mid_smg"))
				{
					CreateLoadoutVariantMenu(client, LoadoutFamily_MidSMG).Display(client, menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

Menu CreateLoadoutVariantMenu(int client, LoadoutFamily family)
{
	Menu menu = new Menu(LoadoutVariantMenuHandler);

	if (family == LoadoutFamily_CTPistol)
	{
		menu.SetTitle("CT Default Pistol");
		menu.AddItem("ct_default_pistol:weapon_hkp2000", "weapon_hkp2000", g_iCTDefaultPistolVariant[client] == 6 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		menu.AddItem("ct_default_pistol:weapon_usp_silencer", "weapon_usp_silencer", g_iCTDefaultPistolVariant[client] == 5 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	else if (family == LoadoutFamily_CTM4)
	{
		menu.SetTitle("CT M4 Family");
		menu.AddItem("ct_m4:weapon_m4a1", "weapon_m4a1", g_iCTM4Variant[client] == 2 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		menu.AddItem("ct_m4:weapon_m4a1_silencer", "weapon_m4a1_silencer", g_iCTM4Variant[client] == 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	else if (family == LoadoutFamily_CTAutoPistol)
	{
		menu.SetTitle("Five-SeveN / CZ75-Auto");
		menu.AddItem("ct_auto_pistol:weapon_fiveseven", "weapon_fiveseven", g_iCTAutoPistolVariant[client] == 11 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		menu.AddItem("ct_auto_pistol:weapon_cz75a", "weapon_cz75a", g_iCTAutoPistolVariant[client] == 10 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}

	else if (family == LoadoutFamily_TAutoPistol)
	{
		menu.SetTitle("Tec-9 / CZ75-Auto");
		menu.AddItem("t_auto_pistol:weapon_tec9", "weapon_tec9", g_iTAutoPistolVariant[client] == 12 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		menu.AddItem("t_auto_pistol:weapon_cz75a", "weapon_cz75a", g_iTAutoPistolVariant[client] == 10 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	else if (family == LoadoutFamily_HeavyPistol)
	{
		menu.SetTitle("Deagle / R8 Revolver");
		menu.AddItem("heavy_pistol:weapon_deagle", "weapon_deagle", g_iHeavyPistolVariant[client] == 4 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		menu.AddItem("heavy_pistol:weapon_revolver", "weapon_revolver", g_iHeavyPistolVariant[client] == 13 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.SetTitle("MP7 / MP5-SD");
		menu.AddItem("mid_smg:weapon_mp7", "weapon_mp7", g_iMidSMGVariant[client] == 22 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		menu.AddItem("mid_smg:weapon_mp5sd", "weapon_mp5sd", g_iMidSMGVariant[client] == 47 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}

	menu.ExitBackButton = true;
	return menu;
}

public int LoadoutVariantMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char info[64];
				menu.GetItem(selection, info, sizeof(info));

				LoadoutFamily family = LoadoutFamily_None;
				char selectedClass[32];
				strcopy(selectedClass, sizeof(selectedClass), info);

				if (StrContains(info, "ct_default_pistol:") == 0)
				{
					family = LoadoutFamily_CTPistol;
					strcopy(selectedClass, sizeof(selectedClass), info[18]);
				}
				else if (StrContains(info, "ct_m4:") == 0)
				{
					family = LoadoutFamily_CTM4;
					strcopy(selectedClass, sizeof(selectedClass), info[6]);
				}
				else if (StrContains(info, "ct_auto_pistol:") == 0)
				{
					family = LoadoutFamily_CTAutoPistol;
					strcopy(selectedClass, sizeof(selectedClass), info[15]);
				}
				else if (StrContains(info, "t_auto_pistol:") == 0)
				{
					family = LoadoutFamily_TAutoPistol;
					strcopy(selectedClass, sizeof(selectedClass), info[14]);
				}
				else if (StrContains(info, "heavy_pistol:") == 0)
				{
					family = LoadoutFamily_HeavyPistol;
					strcopy(selectedClass, sizeof(selectedClass), info[13]);
				}
				else if (StrContains(info, "mid_smg:") == 0)
				{
					family = LoadoutFamily_MidSMG;
					strcopy(selectedClass, sizeof(selectedClass), info[8]);
				}
				else
				{
					family = GetLoadoutFamily(info);
				}

				if (family != LoadoutFamily_None)
				{
					int selectedIndex;
					if (g_smWeaponIndex.GetValue(selectedClass, selectedIndex))
					{
						SetLoadoutFamilySelection(client, family, selectedIndex);
						SaveLoadoutSelection(client);
						RefreshWeapon(client, selectedIndex);
					}
				}

				int menuTime = GetRemainingGracePeriodSeconds(client);
				if (menuTime >= 0)
				{
					CreateLoadoutMenu(client).Display(client, menuTime);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if (selection == MenuCancel_ExitBack && IsClientInGame(client))
			{
				int menuTime = GetRemainingGracePeriodSeconds(client);
				if (menuTime >= 0)
				{
					CreateLoadoutMenu(client).Display(client, menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

Menu CreateKnifeMenu(int client)
{
	Menu menu = new Menu(KnifeMenuHandler);
	menu.SetTitle("%T", "KnifeMenuTitle", client);
	
	char buffer[60];
	Format(buffer, sizeof(buffer), "%T", "OwnKnife", client);
	menu.AddItem("0", buffer, g_iKnife[client] != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "RandomKnife", client);
	menu.AddItem("-1", buffer, g_iKnife[client] != -1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_cord", client);
	menu.AddItem("49", buffer, g_iKnife[client] != 49 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_canis", client);
	menu.AddItem("50", buffer, g_iKnife[client] != 50 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_outdoor", client);
	menu.AddItem("51", buffer, g_iKnife[client] != 51 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_skeleton", client);
	menu.AddItem("52", buffer, g_iKnife[client] != 52 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_css", client);
	menu.AddItem("48", buffer, g_iKnife[client] != 48 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_ursus", client);
	menu.AddItem("43", buffer, g_iKnife[client] != 43 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_gypsy_jackknife", client);
	menu.AddItem("44", buffer, g_iKnife[client] != 44 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_stiletto", client);
	menu.AddItem("45", buffer, g_iKnife[client] != 45 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_widowmaker", client);
	menu.AddItem("46", buffer, g_iKnife[client] != 46 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_karambit", client);
	menu.AddItem("33", buffer, g_iKnife[client] != 33 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_m9_bayonet", client);
	menu.AddItem("34", buffer, g_iKnife[client] != 34 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_bayonet", client);
	menu.AddItem("35", buffer, g_iKnife[client] != 35 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_survival_bowie", client);
	menu.AddItem("36", buffer, g_iKnife[client] != 36 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_butterfly", client);
	menu.AddItem("37", buffer, g_iKnife[client] != 37 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_flip", client);
	menu.AddItem("38", buffer, g_iKnife[client] != 38 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_push", client);
	menu.AddItem("39", buffer, g_iKnife[client] != 39 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_tactical", client);
	menu.AddItem("40", buffer, g_iKnife[client] != 40 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_falchion", client);
	menu.AddItem("41", buffer, g_iKnife[client] != 41 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_gut", client);
	menu.AddItem("42", buffer, g_iKnife[client] != 42 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	return menu;
}

public int KnifeMenuHandler(Menu menu, MenuAction menuaction, int client, int selection)
{
	switch(menuaction)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char knifeIdStr[32];
				menu.GetItem(selection, knifeIdStr, sizeof(knifeIdStr));
				int knifeId = StringToInt(knifeIdStr);
				int knifeDB = knifeId;
				if (knifeId == -1)
				{
					knifeId = GetRandomKnife();
				}
				
				Action action = Plugin_Continue;
				Call_StartForward(g_hOnKnifeSelect_Pre);
				Call_PushCell(client);
				Call_PushCell(knifeId);
				if(knifeId == 0)
				{
					Call_PushString("weapon_knife");
				}
				else
				{
					Call_PushString(g_WeaponClasses[knifeId]);
				}
				Call_Finish(action);

				if(action >= Plugin_Handled)
				{
					return 0;
				}
				
				g_iKnife[client] = knifeDB;
				char updateFields[50];
				Format(updateFields, sizeof(updateFields), "knife = %d", knifeDB);
				UpdatePlayerData(client, updateFields);
				
				RefreshWeapon(client, knifeId, knifeId == 0);
				
				Call_StartForward(g_hOnKnifeSelect_Post);
				Call_PushCell(client);
				Call_PushCell(knifeId);
				if(knifeId == 0)
				{
					Call_PushString("weapon_knife");
				}
				else
				{
					Call_PushString(g_WeaponClasses[knifeId]);
				}
				Call_Finish();
				
				int menuTime;
				if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
				{
					CreateKnifeMenu(client).DisplayAt(client, GetMenuSelectionPosition(), menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

Menu CreateLanguageMenu(int client)
{
	Menu menu = new Menu(LanguageMenuHandler);
	menu.SetTitle("%T", "ChooseLanguage", client);
	
	char buffer[4];
	
	for (int i = 0; i < sizeof(g_Language); i++)
	{
		if(strlen(g_Language[i]) == 0)
			break;
		IntToString(i, buffer, sizeof(buffer));
		menu.AddItem(buffer, g_Language[i]);
	}
	
	return menu;
}

public int LanguageMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char langIndexStr[4];
				menu.GetItem(selection, langIndexStr, sizeof(langIndexStr));
				int langIndex = StringToInt(langIndexStr);
				
				g_iClientLanguage[client] = langIndex;
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

Menu CreateInventoryWeaponMenu(int client)
{
	Menu menu = new Menu(InventoryWeaponMenuHandler);
	char mode[16];
	GetCosmeticsModeLabel(mode, sizeof(mode));
	menu.SetTitle("Skins Inventory - %N [%s]", client, mode);
	char info[16];
	bool hasAnyUnlockedWeapon = false;
	for (int i = 0; i < sizeof(g_WeaponClasses); i++)
	{
		bool hasUnlockedSkin = false;
		for (int j = 0; j < g_iUnlockedItemCount[client]; j++)
		{
			if (g_iUnlockedItemWeaponIndex[client][j] == i)
			{
				hasUnlockedSkin = true;
				break;
			}
		}

		if (!hasUnlockedSkin)
		{
			continue;
		}

		char display[64];
		FormatEx(display, sizeof(display), "%T", g_WeaponClasses[i], client);
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, display);
		hasAnyUnlockedWeapon = true;
	}

	if (!hasAnyUnlockedWeapon)
	{
		if (!CosmeticsModeAllowsDrops())
		{
			menu.AddItem("none", "Drops are disabled (inventory mode)", ITEMDRAW_DISABLED);
		}
		else
		{
			menu.AddItem("none", "No drops yet", ITEMDRAW_DISABLED);
		}
	}
	menu.ExitButton = true;
	return menu;
}

public int InventoryWeaponMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char info[16];
				menu.GetItem(selection, info, sizeof(info));
				g_iIndex[client] = StringToInt(info);
				int menuTime = GetRemainingGracePeriodSeconds(client);
				if (menuTime >= 0)
				{
					CreateInventoryItemMenu(client, g_iIndex[client]).Display(client, menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

Menu CreateInventoryItemMenu(int client, int weaponIndex)
{
	Menu menu = new Menu(InventoryItemMenuHandler);
	char title[64];
	FormatEx(title, sizeof(title), "%T inventory", g_WeaponClasses[weaponIndex], client);
	menu.SetTitle(title);
	char info[32];
	char display[128];
	char skinName[64];
	for (int i = 0; i < g_iUnlockedItemCount[client]; i++)
	{
		if (g_iUnlockedItemWeaponIndex[client][i] != weaponIndex)
		{
			continue;
		}

		int skinId = g_iUnlockedItemSkinId[client][i];
		if (!GetSkinDisplayName(client, skinId, skinName, sizeof(skinName)))
		{
			FormatEx(skinName, sizeof(skinName), "Skin %d", skinId);
		}

		FormatEx(info, sizeof(info), "%d|%d", weaponIndex, g_iUnlockedItemId[client][i]);
		FormatEx(display, sizeof(display), "%s | Wear %.4f%s [#%d | Skin %d]", skinName, g_fUnlockedItemWear[client][i], g_iUnlockedItemStatTrakEnabled[client][i] == 1 ? " | StatTrak" : "", g_iUnlockedItemId[client][i], skinId);
		menu.AddItem(info, display);
	}
	if (menu.ItemCount == 0)
	{
		if (!CosmeticsModeAllowsDrops())
		{
			menu.AddItem("none", "Drops are disabled (inventory mode)", ITEMDRAW_DISABLED);
		}
		else
		{
			menu.AddItem("none", "No drops yet", ITEMDRAW_DISABLED);
		}
	}
	menu.ExitBackButton = true;
	return menu;
}

public int InventoryItemMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char info[32];
				menu.GetItem(selection, info, sizeof(info));
				if (!StrEqual(info, "none"))
				{
					char parts[2][16];
					ExplodeString(info, "|", parts, 2, 16);
					int weaponIndex = StringToInt(parts[0]);
					int unlockedId = StringToInt(parts[1]);
					EquipUnlockedItem(client, weaponIndex, unlockedId);
					PrintToChat(client, " %s \x04Equipped item #%d.", g_ChatPrefix, unlockedId);
				}
				int menuTime = GetRemainingGracePeriodSeconds(client);
				if (menuTime >= 0)
				{
					CreateInventoryItemMenu(client, g_iIndex[client]).Display(client, menuTime);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				int menuTime = GetRemainingGracePeriodSeconds(client);
				if (menuTime >= 0)
				{
					CreateInventoryWeaponMenu(client).Display(client, menuTime);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}
