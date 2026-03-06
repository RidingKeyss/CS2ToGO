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

void GetPlayerData(int client)
{
	char steamid[32];
	if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true))
	{
		char query[512];
		FormatEx(query, sizeof(query), "SELECT * FROM %sweapons WHERE steamid = '%s'", g_TablePrefix, steamid);
		db.Query(T_GetPlayerDataCallback, query, GetClientUserId(client));
	}
}

public void T_GetPlayerDataCallback(Database database, DBResultSet results, const char[] error, int userid)
{
	int clientIndex = GetClientOfUserId(userid);
	if(IsValidClient(clientIndex))
	{
		if (results == null)
		{
			LogError("Query failed! %s", error);
		}
		else if (results.RowCount == 0)
		{
			CreatePlayerData(clientIndex);
		}
		else
		{
			if(results.FetchRow())
			{
				for(int i = 2, j = 0; j < sizeof(g_WeaponClasses); i += 6, j++) 
				{
					g_iSkins[clientIndex][j] = results.FetchInt(i);
					g_fFloatValue[clientIndex][j] = results.FetchFloat(i + 1);
					g_iStatTrak[clientIndex][j] = results.FetchInt(i + 2);
					g_iStatTrakCount[clientIndex][j] = results.FetchInt(i + 3);
					results.FetchString(i + 4, g_NameTag[clientIndex][j], 128);
					g_iWeaponSeed[clientIndex][j] = results.FetchInt(i + 5);
				}
				g_iKnife[clientIndex] = results.FetchInt(1);
			}
			char steamid[32];
			if(GetClientAuthId(clientIndex, AuthId_Steam2, steamid, sizeof(steamid), true))
			{
				char query[512];
				FormatEx(query, sizeof(query), "REPLACE INTO %sweapons_timestamps (steamid, last_seen) VALUES ('%s', %d)", g_TablePrefix, steamid, GetTime());
				DataPack pack = new DataPack();
				pack.WriteString(query);
				db.Query(T_TimestampCallback, query, pack);
			}
		}
	}
}

public void T_InsertCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	char steamid[32];
	pack.ReadString(steamid, 32);
	if (results == null)
	{
		char buffer[1024];
		pack.ReadString(buffer, 1024);
		LogError("Insert Query failed! query: \"%s\" error: \"%s\"", buffer, error);
	}
	else
	{
		char query[255];
		FormatEx(query, sizeof(query), "REPLACE INTO %sweapons_timestamps (steamid, last_seen) VALUES ('%s', %d)", g_TablePrefix, steamid, GetTime());
		DataPack newPack = new DataPack();
		newPack.WriteString(query);
		db.Query(T_TimestampCallback, query, newPack);
	}
	delete pack;
}

public void T_TimestampCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	if (results == null)
	{
		pack.Reset();
		char buffer[1024];
		pack.ReadString(buffer, 1024);
		LogError("Timestamp Query failed! query: \"%s\" error: \"%s\"", buffer, error);
	}
	delete pack;
}

void UpdatePlayerData(int client, char[] updateFields)
{
	char steamid[32];
	if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true))
	{
		char query[1024];
		FormatEx(query, sizeof(query), "UPDATE %sweapons SET %s WHERE steamid = '%s'", g_TablePrefix, updateFields, steamid);
		DataPack pack = new DataPack();
		pack.WriteString(query);
		db.Query(T_UpdatePlayerDataCallback, query, pack);
	}
}

public void T_UpdatePlayerDataCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	if (results == null)
	{
		pack.Reset();
		char buffer[1024];
		pack.ReadString(buffer, 1024);
		LogError("Update Player failed! query: \"%s\" error: \"%s\"", buffer, error);
	}
	delete pack;
}

public void SQLConnectCallback(Database database, const char[] error, any data)
{
	if (database == null)
	{
		LogError("Database failure: %s", error);
	}
	else
	{
		db = database;
		char dbIdentifier[10];
	
		db.Driver.GetIdentifier(dbIdentifier, sizeof(dbIdentifier));
		bool mysql = StrEqual(dbIdentifier, "mysql");
		
		CreateMainTable(mysql);
	}
}

void CreateMainTable(bool mysql, bool recreate = false)
{
	char createQuery[20480];
	
	int index = 0;

	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
		CREATE TABLE IF NOT EXISTS %sweapons (								\
			steamid varchar(32) NOT NULL PRIMARY KEY, 						\
			knife int(4) NOT NULL DEFAULT '0', 								\
			awp int(4) NOT NULL DEFAULT '0', 								\
			awp_float decimal(3,2) NOT NULL DEFAULT '0.0', 					\
			awp_trak int(1) NOT NULL DEFAULT '0', 							\
			awp_trak_count int(10) NOT NULL DEFAULT '0', 					\
			awp_tag varchar(256) NOT NULL DEFAULT '', 						\
			awp_seed int(10) NOT NULL DEFAULT '-1',							\
			ak47 int(4) NOT NULL DEFAULT '0', 								\
			ak47_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ak47_trak int(1) NOT NULL DEFAULT '0', 							\
			ak47_trak_count int(10) NOT NULL DEFAULT '0', 					\
			ak47_tag varchar(256) NOT NULL DEFAULT '', 						\
			ak47_seed int(10) NOT NULL DEFAULT '-1',						\
			m4a1 int(4) NOT NULL DEFAULT '0', 								\
			m4a1_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			m4a1_trak int(1) NOT NULL DEFAULT '0', 							\
			m4a1_trak_count int(10) NOT NULL DEFAULT '0', 					\
			m4a1_tag varchar(256) NOT NULL DEFAULT '',						\
			m4a1_seed int(10) NOT NULL DEFAULT '-1', ", g_TablePrefix);
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			m4a1_silencer int(4) NOT NULL DEFAULT '0', 						\
			m4a1_silencer_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			m4a1_silencer_trak int(1) NOT NULL DEFAULT '0', 				\
			m4a1_silencer_trak_count int(10) NOT NULL DEFAULT '0', 			\
			m4a1_silencer_tag varchar(256) NOT NULL DEFAULT '', 			\
			m4a1_silencer_seed int(10) NOT NULL DEFAULT '-1',				\
			deagle int(4) NOT NULL DEFAULT '0', 							\
			deagle_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			deagle_trak int(1) NOT NULL DEFAULT '0', 						\
			deagle_trak_count int(10) NOT NULL DEFAULT '0', 				\
			deagle_tag varchar(256) NOT NULL DEFAULT '', 					\
			deagle_seed int(10) NOT NULL DEFAULT '-1',						\
			usp_silencer int(4) NOT NULL DEFAULT '0', 						\
			usp_silencer_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			usp_silencer_trak int(1) NOT NULL DEFAULT '0', 					\
			usp_silencer_trak_count int(10) NOT NULL DEFAULT '0', 			\
			usp_silencer_tag varchar(256) NOT NULL DEFAULT '', 				\
			usp_silencer_seed int(10) NOT NULL DEFAULT '-1',				\
			hkp2000 int(4) NOT NULL DEFAULT '0', 							\
			hkp2000_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			hkp2000_trak int(1) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			hkp2000_trak_count int(10) NOT NULL DEFAULT '0', 				\
			hkp2000_tag varchar(256) NOT NULL DEFAULT '', 					\
			hkp2000_seed int(10) NOT NULL DEFAULT '-1',						\
			glock int(4) NOT NULL DEFAULT '0', 								\
			glock_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			glock_trak int(1) NOT NULL DEFAULT '0', 						\
			glock_trak_count int(10) NOT NULL DEFAULT '0', 					\
			glock_tag varchar(256) NOT NULL DEFAULT '', 					\
			glock_seed int(10) NOT NULL DEFAULT '-1',						\
			elite int(4) NOT NULL DEFAULT '0', 								\
			elite_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			elite_trak int(1) NOT NULL DEFAULT '0', 						\
			elite_trak_count int(10) NOT NULL DEFAULT '0', 					\
			elite_tag varchar(256) NOT NULL DEFAULT '', 					\
			elite_seed int(10) NOT NULL DEFAULT '-1',						\
			p250 int(4) NOT NULL DEFAULT '0', 								\
			p250_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			p250_trak int(1) NOT NULL DEFAULT '0', 							\
			p250_trak_count int(10) NOT NULL DEFAULT '0', 					\
			p250_tag varchar(256) NOT NULL DEFAULT '', 						\
			p250_seed int(10) NOT NULL DEFAULT '-1',						\
			cz75a int(4) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			cz75a_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			cz75a_trak int(1) NOT NULL DEFAULT '0', 						\
			cz75a_trak_count int(10) NOT NULL DEFAULT '0', 					\
			cz75a_tag varchar(256) NOT NULL DEFAULT '', 					\
			cz75a_seed int(10) NOT NULL DEFAULT '-1',						\
			fiveseven int(4) NOT NULL DEFAULT '0', 							\
			fiveseven_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			fiveseven_trak int(1) NOT NULL DEFAULT '0', 					\
			fiveseven_trak_count int(10) NOT NULL DEFAULT '0', 				\
			fiveseven_tag varchar(256) NOT NULL DEFAULT '', 				\
			fiveseven_seed int(10) NOT NULL DEFAULT '-1',					\
			tec9 int(4) NOT NULL DEFAULT '0', 								\
			tec9_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			tec9_trak int(1) NOT NULL DEFAULT '0', 							\
			tec9_trak_count int(10) NOT NULL DEFAULT '0', 					\
			tec9_tag varchar(256) NOT NULL DEFAULT '', 						\
			tec9_seed int(10) NOT NULL DEFAULT '-1',						\
			revolver int(4) NOT NULL DEFAULT '0', 							\
			revolver_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			revolver_trak int(1) NOT NULL DEFAULT '0', 						\
			revolver_trak_count int(10) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			revolver_tag varchar(256) NOT NULL DEFAULT '', 					\
			revolver_seed int(10) NOT NULL DEFAULT '-1',					\
			nova int(4) NOT NULL DEFAULT '0', 								\
			nova_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			nova_trak int(1) NOT NULL DEFAULT '0', 							\
			nova_trak_count int(10) NOT NULL DEFAULT '0', 					\
			nova_tag varchar(256) NOT NULL DEFAULT '', 						\
			nova_seed int(10) NOT NULL DEFAULT '-1',						\
			xm1014 int(4) NOT NULL DEFAULT '0', 							\
			xm1014_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			xm1014_trak int(1) NOT NULL DEFAULT '0', 						\
			xm1014_trak_count int(10) NOT NULL DEFAULT '0', 				\
			xm1014_tag varchar(256) NOT NULL DEFAULT '', 					\
			xm1014_seed int(10) NOT NULL DEFAULT '-1',						\
			mag7 int(4) NOT NULL DEFAULT '0', 								\
			mag7_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			mag7_trak int(1) NOT NULL DEFAULT '0', 							\
			mag7_trak_count int(10) NOT NULL DEFAULT '0', 					\
			mag7_tag varchar(256) NOT NULL DEFAULT '', 						\
			mag7_seed int(10) NOT NULL DEFAULT '-1',						\
			sawedoff int(4) NOT NULL DEFAULT '0', 							\
			sawedoff_float decimal(3,2) NOT NULL DEFAULT '0.0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			sawedoff_trak int(1) NOT NULL DEFAULT '0', 						\
			sawedoff_trak_count int(10) NOT NULL DEFAULT '0', 				\
			sawedoff_tag varchar(256) NOT NULL DEFAULT '', 					\
			sawedoff_seed int(10) NOT NULL DEFAULT '-1',					\
			m249 int(4) NOT NULL DEFAULT '0', 								\
			m249_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			m249_trak int(1) NOT NULL DEFAULT '0', 							\
			m249_trak_count int(10) NOT NULL DEFAULT '0', 					\
			m249_tag varchar(256) NOT NULL DEFAULT '', 						\
			m249_seed int(10) NOT NULL DEFAULT '-1',						\
			negev int(4) NOT NULL DEFAULT '0', 								\
			negev_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			negev_trak int(1) NOT NULL DEFAULT '0', 						\
			negev_trak_count int(10) NOT NULL DEFAULT '0', 					\
			negev_tag varchar(256) NOT NULL DEFAULT '', 					\
			negev_seed int(10) NOT NULL DEFAULT '-1',						\
			mp9 int(4) NOT NULL DEFAULT '0', 								\
			mp9_float decimal(3,2) NOT NULL DEFAULT '0.0', 					\
			mp9_trak int(1) NOT NULL DEFAULT '0', 							\
			mp9_trak_count int(10) NOT NULL DEFAULT '0', 					\
			mp9_tag varchar(256) NOT NULL DEFAULT '',						\
			mp9_seed int(10) NOT NULL DEFAULT '-1', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			mac10 int(4) NOT NULL DEFAULT '0', 								\
			mac10_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			mac10_trak int(1) NOT NULL DEFAULT '0', 						\
			mac10_trak_count int(10) NOT NULL DEFAULT '0', 					\
			mac10_tag varchar(256) NOT NULL DEFAULT '', 					\
			mac10_seed int(10) NOT NULL DEFAULT '-1',						\
			mp7 int(4) NOT NULL DEFAULT '0', 								\
			mp7_float decimal(3,2) NOT NULL DEFAULT '0.0', 					\
			mp7_trak int(1) NOT NULL DEFAULT '0', 							\
			mp7_trak_count int(10) NOT NULL DEFAULT '0', 					\
			mp7_tag varchar(256) NOT NULL DEFAULT '', 						\
			mp7_seed int(10) NOT NULL DEFAULT '-1',							\
			ump45 int(4) NOT NULL DEFAULT '0', 								\
			ump45_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ump45_trak int(1) NOT NULL DEFAULT '0', 						\
			ump45_trak_count int(10) NOT NULL DEFAULT '0', 					\
			ump45_tag varchar(256) NOT NULL DEFAULT '', 					\
			ump45_seed int(10) NOT NULL DEFAULT '-1',						\
			p90 int(4) NOT NULL DEFAULT '0', 								\
			p90_float decimal(3,2) NOT NULL DEFAULT '0.0', 					\
			p90_trak int(1) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			p90_trak_count int(10) NOT NULL DEFAULT '0', 					\
			p90_tag varchar(256) NOT NULL DEFAULT '', 						\
			p90_seed int(10) NOT NULL DEFAULT '-1',							\
			bizon int(4) NOT NULL DEFAULT '0', 								\
			bizon_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			bizon_trak int(1) NOT NULL DEFAULT '0', 						\
			bizon_trak_count int(10) NOT NULL DEFAULT '0', 					\
			bizon_tag varchar(256) NOT NULL DEFAULT '', 					\
			bizon_seed int(10) NOT NULL DEFAULT '-1',						\
			famas int(4) NOT NULL DEFAULT '0', 								\
			famas_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			famas_trak int(1) NOT NULL DEFAULT '0', 						\
			famas_trak_count int(10) NOT NULL DEFAULT '0', 					\
			famas_tag varchar(256) NOT NULL DEFAULT '', 					\
			famas_seed int(10) NOT NULL DEFAULT '-1',						\
			galilar int(4) NOT NULL DEFAULT '0', 							\
			galilar_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			galilar_trak int(1) NOT NULL DEFAULT '0', 						\
			galilar_trak_count int(10) NOT NULL DEFAULT '0', 				\
			galilar_tag varchar(256) NOT NULL DEFAULT '', 					\
			galilar_seed int(10) NOT NULL DEFAULT '-1',						\
			ssg08 int(4) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ssg08_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ssg08_trak int(1) NOT NULL DEFAULT '0', 						\
			ssg08_trak_count int(10) NOT NULL DEFAULT '0', 					\
			ssg08_tag varchar(256) NOT NULL DEFAULT '', 					\
			ssg08_seed int(10) NOT NULL DEFAULT '-1',						\
			aug int(4) NOT NULL DEFAULT '0', 								\
			aug_float decimal(3,2) NOT NULL DEFAULT '0.0', 					\
			aug_trak int(1) NOT NULL DEFAULT '0', 							\
			aug_trak_count int(10) NOT NULL DEFAULT '0', 					\
			aug_tag varchar(256) NOT NULL DEFAULT '', 						\
			aug_seed int(10) NOT NULL DEFAULT '-1',							\
			sg556 int(4) NOT NULL DEFAULT '0', 								\
			sg556_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			sg556_trak int(1) NOT NULL DEFAULT '0', 						\
			sg556_trak_count int(10) NOT NULL DEFAULT '0', 					\
			sg556_tag varchar(256) NOT NULL DEFAULT '', 					\
			sg556_seed int(10) NOT NULL DEFAULT '-1',						\
			scar20 int(4) NOT NULL DEFAULT '0', 							\
			scar20_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			scar20_trak int(1) NOT NULL DEFAULT '0', 						\
			scar20_trak_count int(10) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			scar20_tag varchar(256) NOT NULL DEFAULT '', 					\
			scar20_seed int(10) NOT NULL DEFAULT '-1',						\
			g3sg1 int(4) NOT NULL DEFAULT '0', 								\
			g3sg1_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			g3sg1_trak int(1) NOT NULL DEFAULT '0', 						\
			g3sg1_trak_count int(10) NOT NULL DEFAULT '0', 					\
			g3sg1_tag varchar(256) NOT NULL DEFAULT '', 					\
			g3sg1_seed int(10) NOT NULL DEFAULT '-1',						\
			knife_karambit int(4) NOT NULL DEFAULT '0', 					\
			knife_karambit_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			knife_karambit_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_karambit_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_karambit_tag varchar(256) NOT NULL DEFAULT '', 			\
			knife_karambit_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_m9_bayonet int(4) NOT NULL DEFAULT '0', 					\
			knife_m9_bayonet_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			knife_m9_bayonet_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_m9_bayonet_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_m9_bayonet_tag varchar(256) NOT NULL DEFAULT '', 			\
			knife_m9_bayonet_seed int(10) NOT NULL DEFAULT '-1',			\
			bayonet int(4) NOT NULL DEFAULT '0', 							\
			bayonet_float decimal(3,2) NOT NULL DEFAULT '0.0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			bayonet_trak int(1) NOT NULL DEFAULT '0', 						\
			bayonet_trak_count int(10) NOT NULL DEFAULT '0', 				\
			bayonet_tag varchar(256) NOT NULL DEFAULT '', 					\
			bayonet_seed int(10) NOT NULL DEFAULT '-1',						\
			knife_survival_bowie int(4) NOT NULL DEFAULT '0', 				\
			knife_survival_bowie_float decimal(3,2) NOT NULL DEFAULT '0.0', \
			knife_survival_bowie_trak int(1) NOT NULL DEFAULT '0', 			\
			knife_survival_bowie_trak_count int(10) NOT NULL DEFAULT '0', 	\
			knife_survival_bowie_tag varchar(256) NOT NULL DEFAULT '', 		\
			knife_survival_bowie_seed int(10) NOT NULL DEFAULT '-1',		\
			knife_butterfly int(4) NOT NULL DEFAULT '0', 					\
			knife_butterfly_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			knife_butterfly_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_butterfly_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_butterfly_tag varchar(256) NOT NULL DEFAULT '', 			\
			knife_butterfly_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_flip int(4) NOT NULL DEFAULT '0', 						\
			knife_flip_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			knife_flip_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_flip_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_flip_tag varchar(256) NOT NULL DEFAULT '',				\
			knife_flip_seed int(10) NOT NULL DEFAULT '-1', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			knife_push int(4) NOT NULL DEFAULT '0', 						\
			knife_push_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			knife_push_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_push_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_push_tag varchar(256) NOT NULL DEFAULT '', 				\
			knife_push_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_tactical int(4) NOT NULL DEFAULT '0', 					\
			knife_tactical_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			knife_tactical_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_tactical_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_tactical_tag varchar(256) NOT NULL DEFAULT '', 			\
			knife_tactical_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_falchion int(4) NOT NULL DEFAULT '0', 					\
			knife_falchion_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			knife_falchion_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_falchion_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_falchion_tag varchar(256) NOT NULL DEFAULT '', 			\
			knife_falchion_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_gut int(4) NOT NULL DEFAULT '0', 							\
			knife_gut_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			knife_gut_trak int(1) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			knife_gut_trak_count int(10) NOT NULL DEFAULT '0', 				\
			knife_gut_tag varchar(256) NOT NULL DEFAULT '', 				\
			knife_gut_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_ursus int(4) NOT NULL DEFAULT '0', 						\
			knife_ursus_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			knife_ursus_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_ursus_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_ursus_tag varchar(256) NOT NULL DEFAULT '', 				\
			knife_ursus_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_gypsy_jackknife int(4) NOT NULL DEFAULT '0', 				\
			knife_gypsy_jackknife_float decimal(3,2) NOT NULL DEFAULT '0.0',\
			knife_gypsy_jackknife_trak int(1) NOT NULL DEFAULT '0', 		\
			knife_gypsy_jackknife_trak_count int(10) NOT NULL DEFAULT '0', 	\
			knife_gypsy_jackknife_tag varchar(256) NOT NULL DEFAULT '', 	\
			knife_gypsy_jackknife_seed int(10) NOT NULL DEFAULT '-1',		\
			knife_stiletto int(4) NOT NULL DEFAULT '0', 					\
			knife_stiletto_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			knife_stiletto_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_stiletto_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_stiletto_tag varchar(256) NOT NULL DEFAULT '', 			\
			knife_stiletto_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_widowmaker int(4) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			knife_widowmaker_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			knife_widowmaker_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_widowmaker_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_widowmaker_tag varchar(256) NOT NULL DEFAULT '',			\
			knife_widowmaker_seed int(10) NOT NULL DEFAULT '-1',			\
			mp5sd int(4) NOT NULL DEFAULT '0', 								\
			mp5sd_float decimal(3,2) NOT NULL DEFAULT '0.0',				\
			mp5sd_trak int(1) NOT NULL DEFAULT '0', 						\
			mp5sd_trak_count int(10) NOT NULL DEFAULT '0',					\
			mp5sd_tag varchar(256) NOT NULL DEFAULT '',						\
			mp5sd_seed int(10) NOT NULL DEFAULT '-1',						\
			knife_css int(4) NOT NULL DEFAULT '0', 							\
			knife_css_float decimal(3,2) NOT NULL DEFAULT '0.0',			\
			knife_css_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_css_trak_count int(10) NOT NULL DEFAULT '0', 				\
			knife_css_tag varchar(256) NOT NULL DEFAULT '', 				\
			knife_css_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_cord int(4) NOT NULL DEFAULT '0', 						\
			knife_cord_float decimal(3,2) NOT NULL DEFAULT '0.0',			\
			knife_cord_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_cord_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_cord_tag varchar(256) NOT NULL DEFAULT '', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			knife_cord_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_canis int(4) NOT NULL DEFAULT '0', 						\
			knife_canis_float decimal(3,2) NOT NULL DEFAULT '0.0',			\
			knife_canis_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_canis_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_canis_tag varchar(256) NOT NULL DEFAULT '', 				\
			knife_canis_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_outdoor int(4) NOT NULL DEFAULT '0', 						\
			knife_outdoor_float decimal(3,2) NOT NULL DEFAULT '0.0',		\
			knife_outdoor_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_outdoor_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_outdoor_tag varchar(256) NOT NULL DEFAULT '', 			\
			knife_outdoor_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_skeleton int(4) NOT NULL DEFAULT '0', 					\
			knife_skeleton_float decimal(3,2) NOT NULL DEFAULT '0.0',		\
			knife_skeleton_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_skeleton_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_skeleton_tag varchar(256) NOT NULL DEFAULT '', 			\
			knife_skeleton_seed int(10) NOT NULL DEFAULT '-1')");
	
	if (mysql)
	{
		 index += FormatEx(createQuery[index], sizeof(createQuery) - index, " ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
	}
	
	if (recreate)
	{
		db.Query(T_ReCreateMainTableCallback, createQuery, mysql, DBPrio_High);
	}
	else
	{
		db.Query(T_CreateMainTableCallback, createQuery, mysql, DBPrio_High);
	}
}

public void T_ReCreateMainTableCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		LogError("%s Recreating the main table has failed! %s", (mysql ? "MySQL" : "SQLite"), error);
	}
	else
	{
		int index = 0;
		
		char migrateQuery[8192];

		index += FormatEx(migrateQuery[index], sizeof(migrateQuery) - index, "																	\
			INSERT INTO %sweapons (steamid, knife, awp, awp_float, awp_trak, awp_trak_count, awp_tag, ak47, ak47_float, 					\
			ak47_trak, ak47_trak_count, ak47_tag, m4a1, m4a1_float, m4a1_trak, m4a1_trak_count, m4a1_tag, m4a1_silencer, 					\
			m4a1_silencer_float, m4a1_silencer_trak, m4a1_silencer_trak_count, m4a1_silencer_tag, deagle, deagle_float, 					\
			deagle_trak, deagle_trak_count, deagle_tag, usp_silencer, usp_silencer_float, usp_silencer_trak, 								\
			usp_silencer_trak_count, usp_silencer_tag, hkp2000, hkp2000_float, hkp2000_trak, hkp2000_trak_count, 							\
			hkp2000_tag, glock, glock_float, glock_trak, glock_trak_count, glock_tag, elite, elite_float, elite_trak, ", g_TablePrefix);
		index += FormatEx(migrateQuery[index], sizeof(migrateQuery) - index, "																	\
			elite_trak_count, elite_tag, p250, p250_float, p250_trak, p250_trak_count, p250_tag, cz75a, cz75a_float, 						\
			cz75a_trak, cz75a_trak_count, cz75a_tag, fiveseven, fiveseven_float, fiveseven_trak, fiveseven_trak_count, 						\
			fiveseven_tag, tec9, tec9_float, tec9_trak, tec9_trak_count, tec9_tag, revolver, revolver_float, revolver_trak, 				\
			revolver_trak_count, revolver_tag, nova, nova_float, nova_trak, nova_trak_count, nova_tag, xm1014, xm1014_float, 				\
			xm1014_trak, xm1014_trak_count, xm1014_tag, mag7, mag7_float, mag7_trak, mag7_trak_count, mag7_tag, sawedoff, 					\
			sawedoff_float, sawedoff_trak, sawedoff_trak_count, sawedoff_tag, m249, m249_float, m249_trak, m249_trak_count, 				\
			m249_tag, negev, negev_float, negev_trak, negev_trak_count, negev_tag, mp9, mp9_float, mp9_trak, mp9_trak_count, ");
		index += FormatEx(migrateQuery[index], sizeof(migrateQuery) - index, "																	\
			mp9_tag, mac10, mac10_float, mac10_trak, mac10_trak_count, mac10_tag, mp7, mp7_float, mp7_trak, mp7_trak_count, 				\
			mp7_tag, ump45, ump45_float, ump45_trak, ump45_trak_count, ump45_tag, p90, p90_float, p90_trak, p90_trak_count, 				\
			p90_tag, bizon, bizon_float, bizon_trak, bizon_trak_count, bizon_tag, famas, famas_float, famas_trak, 							\
			famas_trak_count, famas_tag, galilar, galilar_float, galilar_trak, galilar_trak_count, galilar_tag, ssg08, 						\
			ssg08_float, ssg08_trak, ssg08_trak_count, ssg08_tag, aug, aug_float, aug_trak, aug_trak_count, aug_tag, sg556, 				\
			sg556_float, sg556_trak, sg556_trak_count, sg556_tag, scar20, scar20_float, scar20_trak, scar20_trak_count, 					\
			scar20_tag, g3sg1, g3sg1_float, g3sg1_trak, g3sg1_trak_count, g3sg1_tag, knife_karambit, knife_karambit_float, 					\
			knife_karambit_trak, knife_karambit_trak_count, knife_karambit_tag, knife_m9_bayonet, knife_m9_bayonet_float, ");
		index += FormatEx(migrateQuery[index], sizeof(migrateQuery) - index, "																	\
			knife_m9_bayonet_trak, knife_m9_bayonet_trak_count, knife_m9_bayonet_tag, bayonet, bayonet_float, bayonet_trak, 				\
			bayonet_trak_count, bayonet_tag, knife_survival_bowie, knife_survival_bowie_float, knife_survival_bowie_trak, 					\
			knife_survival_bowie_trak_count, knife_survival_bowie_tag, knife_butterfly, knife_butterfly_float, knife_butterfly_trak, 		\
			knife_butterfly_trak_count, knife_butterfly_tag, knife_flip, knife_flip_float, knife_flip_trak, knife_flip_trak_count, 			\
			knife_flip_tag, knife_push, knife_push_float, knife_push_trak, knife_push_trak_count, knife_push_tag, knife_tactical, 			\
			knife_tactical_float, knife_tactical_trak, knife_tactical_trak_count, knife_tactical_tag, knife_falchion, 						\
			knife_falchion_float, knife_falchion_trak, knife_falchion_trak_count, knife_falchion_tag, knife_gut, knife_gut_float, ");
		index += FormatEx(migrateQuery[index], sizeof(migrateQuery) - index, "																	\
			knife_gut_trak, knife_gut_trak_count, knife_gut_tag, knife_ursus, knife_ursus_float, knife_ursus_trak, 							\
			knife_ursus_trak_count, knife_ursus_tag, knife_gypsy_jackknife, knife_gypsy_jackknife_float, knife_gypsy_jackknife_trak, 		\
			knife_gypsy_jackknife_trak_count, knife_gypsy_jackknife_tag, knife_stiletto, knife_stiletto_float, knife_stiletto_trak, 		\
			knife_stiletto_trak_count, knife_stiletto_tag, knife_widowmaker, knife_widowmaker_float, knife_widowmaker_trak, 				\
			knife_widowmaker_trak_count, knife_widowmaker_tag, mp5sd, mp5sd_float, mp5sd_trak, mp5sd_trak_count, mp5sd_tag, knife_css, 		\
			knife_css_float, knife_css_trak, knife_css_trak_count, knife_css_tag, knife_css_seed)											\
			SELECT * FROM %sweapons_tmp", g_TablePrefix);
		
		db.Query(T_MigrateOldDataCallback, migrateQuery, mysql, DBPrio_High);
	}
}

public void T_MigrateOldDataCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		LogError("%s Migrating old data has failed! %s", (mysql ? "MySQL" : "SQLite"), error);
	}
	else
	{
		LogMessage("%s Old data has been migrated successfully", (mysql ? "MySQL" : "SQLite"));
		
		char dropTableQuery[512];
		Format(dropTableQuery, sizeof(dropTableQuery), "DROP TABLE %sweapons_tmp", g_TablePrefix);
		db.Query(T_DropOldTableCallback, dropTableQuery, mysql, DBPrio_High);
	}
}

public void T_DropOldTableCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		LogError("%s Dropping old table has failed! %s", (mysql ? "MySQL" : "SQLite"), error);
	}
	else
	{
		LogMessage("%s Old table has been dropped successfully", (mysql ? "MySQL" : "SQLite"));
		if(++g_iDatabaseState > 1)
		{
			LogMessage("%s DB connection successful", (mysql ? "MySQL" : "SQLite"));
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsClientAuthorized(i))
				{
					OnClientPostAdminCheck(i);
				}
			}
			DeleteInactivePlayerData();
		}
	}
}

public void T_CreateMainTableCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		LogError("%s Creating the main table has failed! %s", (mysql ? "MySQL" : "SQLite"), error);
	}
	else
	{
		g_iMigrationStep = 0;
		AddWeaponColumns(mysql, "knife_ursus", false);
		
		char createQuery[512];
		Format(createQuery, sizeof(createQuery), "			\
			CREATE TABLE %sweapons_timestamps ( 			\
				steamid varchar(32) NOT NULL PRIMARY KEY, 	\
				last_seen int(11) NOT NULL)", g_TablePrefix);
		
		if (mysql)
		{
			 Format(createQuery, sizeof(createQuery), "%s ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;", createQuery);
		}
		
		db.Query(T_CreateTimestampTableCallback, createQuery, mysql, DBPrio_High);

		char createLoadoutQuery[512];
		Format(createLoadoutQuery, sizeof(createLoadoutQuery), "\
			CREATE TABLE IF NOT EXISTS %sloadout_slots (\
				steamid64 varchar(32) NOT NULL PRIMARY KEY,\
				ct_default_pistol_variant varchar(32) NOT NULL DEFAULT 'weapon_hkp2000',\
				ct_m4_variant varchar(32) NOT NULL DEFAULT 'weapon_m4a1',\
				ct_auto_pistol_variant varchar(32) NOT NULL DEFAULT 'weapon_fiveseven',\
				t_auto_pistol_variant varchar(32) NOT NULL DEFAULT 'weapon_tec9',\
				heavy_pistol_variant varchar(32) NOT NULL DEFAULT 'weapon_deagle',\
				mid_smg_variant varchar(32) NOT NULL DEFAULT 'weapon_mp7')", g_TablePrefix);
		if (mysql)
		{
			Format(createLoadoutQuery, sizeof(createLoadoutQuery), "%s ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;", createLoadoutQuery);
		}
		db.Query(T_GenericQueryCallback, createLoadoutQuery, 0, DBPrio_High);


		char createUnlockedQuery[1024];
		if (mysql)
		{
			Format(createUnlockedQuery, sizeof(createUnlockedQuery), "CREATE TABLE IF NOT EXISTS %sunlocked_skins (id int(11) NOT NULL AUTO_INCREMENT, steamid64 varchar(32) NOT NULL, weapon_index int(4) NOT NULL, skin_id int(10) NOT NULL, wear float NOT NULL DEFAULT '0.0', seed int(10) NOT NULL DEFAULT '0', stattrak_enabled int(1) NOT NULL DEFAULT '0', stattrak_count int(10) NOT NULL DEFAULT '0', obtained_at int(11) NOT NULL DEFAULT '0', PRIMARY KEY (id)) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;", g_TablePrefix);
		}
		else
		{
			Format(createUnlockedQuery, sizeof(createUnlockedQuery), "CREATE TABLE IF NOT EXISTS %sunlocked_skins (id INTEGER PRIMARY KEY AUTOINCREMENT, steamid64 varchar(32) NOT NULL, weapon_index int(4) NOT NULL, skin_id int(10) NOT NULL, wear float NOT NULL DEFAULT '0.0', seed int(10) NOT NULL DEFAULT '0', stattrak_enabled int(1) NOT NULL DEFAULT '0', stattrak_count int(10) NOT NULL DEFAULT '0', obtained_at int(11) NOT NULL DEFAULT '0')", g_TablePrefix);
		}
		db.Query(T_GenericQueryCallback, createUnlockedQuery, 0, DBPrio_High);

		char unlockedIndexQuery[512];
		Format(unlockedIndexQuery, sizeof(unlockedIndexQuery), "CREATE UNIQUE INDEX IF NOT EXISTS %sunlocked_skin_signature ON %sunlocked_skins (steamid64, weapon_index, skin_id, wear, seed, stattrak_enabled)", g_TablePrefix, g_TablePrefix);
		db.Query(T_GenericQueryCallback, unlockedIndexQuery, 0, DBPrio_High);

		char createImportSourceQuery[1024];
		if (mysql)
		{
			Format(createImportSourceQuery, sizeof(createImportSourceQuery), "CREATE TABLE IF NOT EXISTS %sinventory_import_items (id int(11) NOT NULL AUTO_INCREMENT, external_item_id varchar(64) NOT NULL DEFAULT '', steamid64 varchar(32) NOT NULL, weapon_class varchar(64) NOT NULL DEFAULT '', weapon_defindex int(11) NOT NULL DEFAULT '0', skin_id int(10) NOT NULL DEFAULT '0', paintkit int(10) NOT NULL DEFAULT '0', wear float NOT NULL DEFAULT '0.0', seed int(10) NOT NULL DEFAULT '0', stattrak_enabled int(1) NOT NULL DEFAULT '0', stattrak_count int(10) NOT NULL DEFAULT '0', obtained_at int(11) NOT NULL DEFAULT '0', imported_at int(11) NOT NULL DEFAULT '0', PRIMARY KEY (id), UNIQUE KEY uniq_external_item_id (external_item_id), KEY idx_steamid64 (steamid64)) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;", g_TablePrefix);
		}
		else
		{
			Format(createImportSourceQuery, sizeof(createImportSourceQuery), "CREATE TABLE IF NOT EXISTS %sinventory_import_items (id INTEGER PRIMARY KEY AUTOINCREMENT, external_item_id varchar(64) NOT NULL DEFAULT '', steamid64 varchar(32) NOT NULL, weapon_class varchar(64) NOT NULL DEFAULT '', weapon_defindex int(11) NOT NULL DEFAULT '0', skin_id int(10) NOT NULL DEFAULT '0', paintkit int(10) NOT NULL DEFAULT '0', wear float NOT NULL DEFAULT '0.0', seed int(10) NOT NULL DEFAULT '0', stattrak_enabled int(1) NOT NULL DEFAULT '0', stattrak_count int(10) NOT NULL DEFAULT '0', obtained_at int(11) NOT NULL DEFAULT '0', imported_at int(11) NOT NULL DEFAULT '0')", g_TablePrefix);
		}
		db.Query(T_GenericQueryCallback, createImportSourceQuery, 0, DBPrio_High);

		char createImportSourceIdxQuery[512];
		Format(createImportSourceIdxQuery, sizeof(createImportSourceIdxQuery), "CREATE INDEX IF NOT EXISTS %sinventory_import_items_steamid_idx ON %sinventory_import_items (steamid64)", g_TablePrefix, g_TablePrefix);
		db.Query(T_GenericQueryCallback, createImportSourceIdxQuery, 0, DBPrio_High);

		char alterLoadoutCtAutoPistolQuery[256];
		FormatEx(alterLoadoutCtAutoPistolQuery, sizeof(alterLoadoutCtAutoPistolQuery), "ALTER TABLE %sloadout_slots ADD COLUMN ct_auto_pistol_variant varchar(32) NOT NULL DEFAULT 'weapon_fiveseven'", g_TablePrefix);
		db.Query(T_IgnoreSchemaErrorCallback, alterLoadoutCtAutoPistolQuery, 0, DBPrio_High);

		char alterLoadoutTAutoPistolQuery[256];
		FormatEx(alterLoadoutTAutoPistolQuery, sizeof(alterLoadoutTAutoPistolQuery), "ALTER TABLE %sloadout_slots ADD COLUMN t_auto_pistol_variant varchar(32) NOT NULL DEFAULT 'weapon_tec9'", g_TablePrefix);
		db.Query(T_IgnoreSchemaErrorCallback, alterLoadoutTAutoPistolQuery, 0, DBPrio_High);


		char migrateOldAutoPistolToCtQuery[512];
		FormatEx(migrateOldAutoPistolToCtQuery, sizeof(migrateOldAutoPistolToCtQuery), "UPDATE %sloadout_slots SET ct_auto_pistol_variant = CASE WHEN auto_pistol_variant = 'weapon_cz75a' THEN 'weapon_cz75a' ELSE 'weapon_fiveseven' END WHERE ct_auto_pistol_variant = 'weapon_fiveseven'", g_TablePrefix);
		db.Query(T_IgnoreSchemaErrorCallback, migrateOldAutoPistolToCtQuery, 0, DBPrio_High);

		char migrateOldAutoPistolToTQuery[512];
		FormatEx(migrateOldAutoPistolToTQuery, sizeof(migrateOldAutoPistolToTQuery), "UPDATE %sloadout_slots SET t_auto_pistol_variant = CASE WHEN auto_pistol_variant = 'weapon_cz75a' THEN 'weapon_cz75a' ELSE 'weapon_tec9' END WHERE t_auto_pistol_variant = 'weapon_tec9'", g_TablePrefix);
		db.Query(T_IgnoreSchemaErrorCallback, migrateOldAutoPistolToTQuery, 0, DBPrio_High);

		char alterLoadoutHeavyPistolQuery[256];
		FormatEx(alterLoadoutHeavyPistolQuery, sizeof(alterLoadoutHeavyPistolQuery), "ALTER TABLE %sloadout_slots ADD COLUMN heavy_pistol_variant varchar(32) NOT NULL DEFAULT 'weapon_deagle'", g_TablePrefix);
		db.Query(T_IgnoreSchemaErrorCallback, alterLoadoutHeavyPistolQuery, 0, DBPrio_High);

		char alterLoadoutMidSmgQuery[256];
		FormatEx(alterLoadoutMidSmgQuery, sizeof(alterLoadoutMidSmgQuery), "ALTER TABLE %sloadout_slots ADD COLUMN mid_smg_variant varchar(32) NOT NULL DEFAULT 'weapon_mp7'", g_TablePrefix);
		db.Query(T_IgnoreSchemaErrorCallback, alterLoadoutMidSmgQuery, 0, DBPrio_High);

		char createEquippedQuery[512];
		Format(createEquippedQuery, sizeof(createEquippedQuery), "			CREATE TABLE IF NOT EXISTS %sequipped_skins (				steamid64 varchar(32) NOT NULL,				weapon_index int(4) NOT NULL,				unlocked_id int(11) NOT NULL DEFAULT '0',				PRIMARY KEY (steamid64, weapon_index))", g_TablePrefix);
		if (mysql)
		{
			Format(createEquippedQuery, sizeof(createEquippedQuery), "%s ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;", createEquippedQuery);
		}
		db.Query(T_GenericQueryCallback, createEquippedQuery, 0, DBPrio_High);
		EnsureUnlockedSchemaColumns();
	}
}

void addSeedColumns(bool mysql)
{
	char seedCheckQuery[128];
	FormatEx(seedCheckQuery, sizeof(seedCheckQuery), "SELECT awp_seed FROM %sweapons", g_TablePrefix);

	db.Query(T_SeedColumnCallback, seedCheckQuery, mysql, DBPrio_High);
}

public void T_SeedColumnCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		LogMessage("%s Attempting to create seed columns", (mysql ? "MySQL" : "SQLite"));
		
		char seedColumnsQuery[8192];
		
		int index = 0;
		
		if (mysql)
		{
			index += FormatEx(seedColumnsQuery[index], sizeof(seedColumnsQuery) - index, "										\
				ALTER TABLE %sweapons																						\
					ADD COLUMN awp_seed int(10) NOT NULL DEFAULT '-1' AFTER awp_tag,										\
					ADD COLUMN ak47_seed int(10) NOT NULL DEFAULT '-1' AFTER ak47_tag,										\
					ADD COLUMN m4a1_seed int(10) NOT NULL DEFAULT '-1' AFTER m4a1_tag,										\
					ADD COLUMN m4a1_silencer_seed int(10) NOT NULL DEFAULT '-1' AFTER m4a1_silencer_tag,					\
					ADD COLUMN deagle_seed int(10) NOT NULL DEFAULT '-1' AFTER deagle_tag,									\
					ADD COLUMN usp_silencer_seed int(10) NOT NULL DEFAULT '-1' AFTER usp_silencer_tag,						\
					ADD COLUMN hkp2000_seed int(10) NOT NULL DEFAULT '-1' AFTER hkp2000_tag,								\
					ADD COLUMN glock_seed int(10) NOT NULL DEFAULT '-1' AFTER glock_tag,									\
					ADD COLUMN elite_seed int(10) NOT NULL DEFAULT '-1' AFTER elite_tag,									\
					ADD COLUMN p250_seed int(10) NOT NULL DEFAULT '-1' AFTER p250_tag,										\
					ADD COLUMN cz75a_seed int(10) NOT NULL DEFAULT '-1' AFTER cz75a_tag,									\
					ADD COLUMN fiveseven_seed int(10) NOT NULL DEFAULT '-1' AFTER fiveseven_tag,							\
					ADD COLUMN tec9_seed int(10) NOT NULL DEFAULT '-1' AFTER tec9_tag,										\
					ADD COLUMN revolver_seed int(10) NOT NULL DEFAULT '-1' AFTER revolver_tag,								\
					ADD COLUMN nova_seed int(10) NOT NULL DEFAULT '-1' AFTER nova_tag,										\
					ADD COLUMN xm1014_seed int(10) NOT NULL DEFAULT '-1' AFTER xm1014_tag,									\
					ADD COLUMN mag7_seed int(10) NOT NULL DEFAULT '-1' AFTER mag7_tag,										\
					ADD COLUMN sawedoff_seed int(10) NOT NULL DEFAULT '-1' AFTER sawedoff_tag,								\
					ADD COLUMN m249_seed int(10) NOT NULL DEFAULT '-1' AFTER m249_tag,										\
					ADD COLUMN negev_seed int(10) NOT NULL DEFAULT '-1' AFTER negev_tag,									\
					ADD COLUMN mp9_seed int(10) NOT NULL DEFAULT '-1' AFTER mp9_tag, ", g_TablePrefix);
			index += FormatEx(seedColumnsQuery[index], sizeof(seedColumnsQuery) - index, "										\
					ADD COLUMN mac10_seed int(10) NOT NULL DEFAULT '-1' AFTER mac10_tag,									\
					ADD COLUMN mp7_seed int(10) NOT NULL DEFAULT '-1' AFTER mp7_tag,										\
					ADD COLUMN ump45_seed int(10) NOT NULL DEFAULT '-1' AFTER ump45_tag,									\
					ADD COLUMN p90_seed int(10) NOT NULL DEFAULT '-1' AFTER p90_tag,										\
					ADD COLUMN bizon_seed int(10) NOT NULL DEFAULT '-1' AFTER bizon_tag,									\
					ADD COLUMN famas_seed int(10) NOT NULL DEFAULT '-1' AFTER famas_tag,									\
					ADD COLUMN galilar_seed int(10) NOT NULL DEFAULT '-1' AFTER galilar_tag,								\
					ADD COLUMN ssg08_seed int(10) NOT NULL DEFAULT '-1' AFTER ssg08_tag,									\
					ADD COLUMN aug_seed int(10) NOT NULL DEFAULT '-1' AFTER aug_tag,										\
					ADD COLUMN sg556_seed int(10) NOT NULL DEFAULT '-1' AFTER sg556_tag,									\
					ADD COLUMN scar20_seed int(10) NOT NULL DEFAULT '-1' AFTER scar20_tag,									\
					ADD COLUMN g3sg1_seed int(10) NOT NULL DEFAULT '-1' AFTER g3sg1_tag,									\
					ADD COLUMN knife_karambit_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_karambit_tag,					\
					ADD COLUMN knife_m9_bayonet_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_m9_bayonet_tag,				\
					ADD COLUMN bayonet_seed int(10) NOT NULL DEFAULT '-1' AFTER bayonet_tag,								\
					ADD COLUMN knife_survival_bowie_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_survival_bowie_tag,		\
					ADD COLUMN knife_butterfly_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_butterfly_tag,				\
					ADD COLUMN knife_flip_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_flip_tag,							\
					ADD COLUMN knife_push_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_push_tag,							\
					ADD COLUMN knife_tactical_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_tactical_tag,					\
					ADD COLUMN knife_falchion_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_falchion_tag,					\
					ADD COLUMN knife_gut_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_gut_tag,							\
					ADD COLUMN knife_ursus_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_ursus_tag,						\
					ADD COLUMN knife_gypsy_jackknife_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_gypsy_jackknife_tag,	\
					ADD COLUMN knife_stiletto_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_stiletto_tag,					\
					ADD COLUMN knife_widowmaker_seed int(10) NOT NULL DEFAULT '-1' AFTER knife_widowmaker_tag,				\
					ADD COLUMN mp5sd_seed int(10) NOT NULL DEFAULT '-1' AFTER mp5sd_tag");
			
			db.Query(T_SeedConfirmationCallback, seedColumnsQuery, mysql, DBPrio_High);
		}
		else
		{
			char renameQuery[512];
			Format(renameQuery, sizeof(renameQuery), "ALTER TABLE %sweapons RENAME TO %sweapons_tmp", g_TablePrefix, g_TablePrefix);
			db.Query(T_RenameCallback, renameQuery, mysql, DBPrio_High);
		}
	}
	else
	{
		if(++g_iDatabaseState > 1)
		{
			LogMessage("%s DB connection successful", (mysql ? "MySQL" : "SQLite"));
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsClientAuthorized(i))
				{
					OnClientPostAdminCheck(i);
				}
			}
			DeleteInactivePlayerData();
		}
	}
}

public void T_RenameCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		LogError("%s Renaming old table has failed! %s", (mysql ? "MySQL" : "SQLite"), error);
	}
	else
	{
		CreateMainTable(mysql, true);
	}
}

public void T_SeedConfirmationCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		LogError("%s Seed column creation failed! %s", (mysql ? "MySQL" : "SQLite"), error);
	}
	else
	{
		LogMessage("Successfully created seed columns");
		if(++g_iDatabaseState > 1)
		{
			LogMessage("%s DB connection successful", (mysql ? "MySQL" : "SQLite"));
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsClientAuthorized(i))
				{
					OnClientPostAdminCheck(i);
				}
			}
			DeleteInactivePlayerData();
		}
	}
}

void AddWeaponColumns(bool mysql, const char[] weapon, bool seedColumn = true)
{
	Transaction txn = new Transaction();
	char query[512];
	Format(query, sizeof(query), "ALTER TABLE %sweapons ADD %s int(4) NOT NULL DEFAULT '0'", g_TablePrefix, weapon);
	txn.AddQuery(query);
	Format(query, sizeof(query), "ALTER TABLE %sweapons ADD %s_float decimal(3,2) NOT NULL DEFAULT '0.0'", g_TablePrefix, weapon);
	txn.AddQuery(query);
	Format(query, sizeof(query), "ALTER TABLE %sweapons ADD %s_trak int(1) NOT NULL DEFAULT '0'", g_TablePrefix, weapon);
	txn.AddQuery(query);
	Format(query, sizeof(query), "ALTER TABLE %sweapons ADD %s_trak_count int(10) NOT NULL DEFAULT '0'", g_TablePrefix, weapon);
	txn.AddQuery(query);
	Format(query, sizeof(query), "ALTER TABLE %sweapons ADD %s_tag varchar(256) NOT NULL DEFAULT ''", g_TablePrefix, weapon);
	txn.AddQuery(query);
	if (seedColumn)
	{
		Format(query, sizeof(query), "ALTER TABLE %sweapons ADD %s_seed int(10) NOT NULL DEFAULT '-1'", g_TablePrefix, weapon);
		txn.AddQuery(query);
	}
	db.Execute(txn, Txn_OnSucess, Txn_OnFail, mysql);
}

public void Txn_OnSucess(Database database, bool mysql, int numQueries, DBResultSet[] results, any[] queryData)
{
	if(++g_iMigrationStep >= sizeof(g_MigrationWeapons))
	{
		addSeedColumns(mysql);
	}
	else
	{
		AddWeaponColumns(mysql, g_MigrationWeapons[g_iMigrationStep], g_iMigrationStep > 4);
	}
}

public void Txn_OnFail(Database database, bool mysql, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	if(++g_iMigrationStep >= sizeof(g_MigrationWeapons))
	{
		addSeedColumns(mysql);
	}
	else
	{
		AddWeaponColumns(mysql, g_MigrationWeapons[g_iMigrationStep], g_iMigrationStep > 4);
	}
}

public void T_CreateTimestampTableCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		if(++g_iDatabaseState > 1)
		{
			LogMessage("%s DB connection successful", (mysql ? "MySQL" : "SQLite"));
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsClientAuthorized(i))
				{
					OnClientPostAdminCheck(i);
				}
			}
			DeleteInactivePlayerData();
		}
	}
	else
	{
		char insertQuery[512];
		Format(insertQuery, sizeof(insertQuery), "	\
			INSERT INTO %sweapons_timestamps  		\
				SELECT steamid, %d FROM %sweapons", g_TablePrefix, GetTime(), g_TablePrefix);
		
		db.Query(T_InsertTimestampsCallback, insertQuery, mysql, DBPrio_High);
	}
}

public void T_InsertTimestampsCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		LogError("%s Insert timestamps failed! %s", (mysql ? "MySQL" : "SQLite"), error);
	}
	else
	{
		if(++g_iDatabaseState > 1)
		{
			LogMessage("%s DB connection successful", (mysql ? "MySQL" : "SQLite"));
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsClientAuthorized(i))
				{
					OnClientPostAdminCheck(i);
				}
			}
			DeleteInactivePlayerData();
		}
	}
}

void DeleteInactivePlayerData()
{
	if(g_iGraceInactiveDays > 0)
	{
		char query[255];
		int now = GetTime();
		FormatEx(query, sizeof(query), "DELETE FROM %sweapons WHERE steamid in (SELECT steamid FROM %sweapons_timestamps WHERE last_seen < %d - (%d * 86400))", g_TablePrefix, g_TablePrefix, now, g_iGraceInactiveDays);
		DataPack pack = new DataPack();
		pack.WriteCell(now);
		pack.WriteString(query);
		db.Query(T_DeleteInactivePlayerDataCallback, query, pack);
	}
}

public void T_DeleteInactivePlayerDataCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	int now = pack.ReadCell();
	if (results == null)
	{
		char buffer[1024];
		pack.ReadString(buffer, 1024);
		LogError("Delete Inactive Player Data failed! query: \"%s\" error: \"%s\"", buffer, error);
	}
	else
	{
		if(now > 0)
		{
			char query[255];
			FormatEx(query, sizeof(query), "DELETE FROM %sweapons_timestamps WHERE last_seen < %d - (%d * 86400)", g_TablePrefix, now, g_iGraceInactiveDays);
			DataPack newPack = new DataPack();
			newPack.WriteCell(0);
			newPack.WriteString(query);
			db.Query(T_DeleteInactivePlayerDataCallback, query, newPack);
		}
		else
		{
			LogMessage("Inactive players' data has been deleted");
		}
	}
	delete pack;
}




void EnsureUnlockedSchemaColumns()
{
	char query[256];
	FormatEx(query, sizeof(query), "ALTER TABLE %sunlocked_skins ADD COLUMN wear float NOT NULL DEFAULT '0.0'", g_TablePrefix);
	db.Query(T_IgnoreSchemaErrorCallback, query, 0);
	FormatEx(query, sizeof(query), "ALTER TABLE %sunlocked_skins ADD COLUMN seed int(10) NOT NULL DEFAULT '0'", g_TablePrefix);
	db.Query(T_IgnoreSchemaErrorCallback, query, 0);
	FormatEx(query, sizeof(query), "ALTER TABLE %sunlocked_skins ADD COLUMN stattrak_enabled int(1) NOT NULL DEFAULT '0'", g_TablePrefix);
	db.Query(T_IgnoreSchemaErrorCallback, query, 0);
	FormatEx(query, sizeof(query), "ALTER TABLE %sunlocked_skins ADD COLUMN stattrak_count int(10) NOT NULL DEFAULT '0'", g_TablePrefix);
	db.Query(T_IgnoreSchemaErrorCallback, query, 0);
	FormatEx(query, sizeof(query), "CREATE UNIQUE INDEX IF NOT EXISTS %sunlocked_skin_signature ON %sunlocked_skins (steamid64, weapon_index, skin_id, wear, seed, stattrak_enabled)", g_TablePrefix, g_TablePrefix);
	db.Query(T_IgnoreSchemaErrorCallback, query, 0);
}

public void T_IgnoreSchemaErrorCallback(Database database, DBResultSet results, const char[] error, any data)
{
}
public void T_GenericQueryCallback(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("Generic DB query failed: %s", error);
	}
}

void GetLoadoutSelection(int client)
{
	char steamid64[32];
	if(GetClientSteamID64(client, steamid64, sizeof(steamid64)))
	{
		char query[512];
		FormatEx(query, sizeof(query), "SELECT ct_default_pistol_variant, ct_m4_variant, ct_auto_pistol_variant, t_auto_pistol_variant, heavy_pistol_variant, mid_smg_variant FROM %sloadout_slots WHERE steamid64 = '%s'", g_TablePrefix, steamid64);
		db.Query(T_GetLoadoutSelectionCallback, query, GetClientUserId(client));
	}
}

public void T_GetLoadoutSelectionCallback(Database database, DBResultSet results, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
	{
		return;
	}

	if (results == null)
	{
		LogError("Loadout select query failed! %s", error);
		return;
	}

	if (!results.FetchRow())
	{
		SaveLoadoutSelection(client);
		return;
	}

	char pistolClass[32];
	char m4Class[32];
	char ctAutoPistolClass[32];
	char tAutoPistolClass[32];
	char heavyPistolClass[32];
	char midSmgClass[32];
	results.FetchString(0, pistolClass, sizeof(pistolClass));
	results.FetchString(1, m4Class, sizeof(m4Class));
	results.FetchString(2, ctAutoPistolClass, sizeof(ctAutoPistolClass));
	results.FetchString(3, tAutoPistolClass, sizeof(tAutoPistolClass));
	results.FetchString(4, heavyPistolClass, sizeof(heavyPistolClass));
	results.FetchString(5, midSmgClass, sizeof(midSmgClass));

	int index;
	LoadoutFamily family = GetLoadoutFamily(pistolClass);
	if (family == LoadoutFamily_CTPistol)
	{
		if (g_smWeaponIndex.GetValue(pistolClass, index))
		{
			SetLoadoutFamilySelection(client, LoadoutFamily_CTPistol, index);
		}
	}

	family = GetLoadoutFamily(m4Class);
	if (family == LoadoutFamily_CTM4)
	{
		if (g_smWeaponIndex.GetValue(m4Class, index))
		{
			SetLoadoutFamilySelection(client, LoadoutFamily_CTM4, index);
		}
	}

	if (g_smWeaponIndex.GetValue(ctAutoPistolClass, index))
	{
		SetLoadoutFamilySelection(client, LoadoutFamily_CTAutoPistol, index);
	}

	if (g_smWeaponIndex.GetValue(tAutoPistolClass, index))
	{
		SetLoadoutFamilySelection(client, LoadoutFamily_TAutoPistol, index);
	}

	family = GetLoadoutFamily(heavyPistolClass);
	if (family == LoadoutFamily_HeavyPistol)
	{
		if (g_smWeaponIndex.GetValue(heavyPistolClass, index))
		{
			SetLoadoutFamilySelection(client, LoadoutFamily_HeavyPistol, index);
		}
	}

	family = GetLoadoutFamily(midSmgClass);
	if (family == LoadoutFamily_MidSMG)
	{
		if (g_smWeaponIndex.GetValue(midSmgClass, index))
		{
			SetLoadoutFamilySelection(client, LoadoutFamily_MidSMG, index);
		}
	}
}

void SaveLoadoutSelection(int client)
{
	char steamid64[32];
	if(GetClientSteamID64(client, steamid64, sizeof(steamid64)))
	{
		char pistolClass[32];
		char m4Class[32];
		char ctAutoPistolClass[32];
		char tAutoPistolClass[32];
		char heavyPistolClass[32];
		char midSmgClass[32];
		ResolveLoadoutClassForClient(client, "weapon_hkp2000", pistolClass, sizeof(pistolClass));
		ResolveLoadoutClassForClient(client, "weapon_m4a1", m4Class, sizeof(m4Class));
		ResolveLoadoutClassForClient(client, "weapon_fiveseven", ctAutoPistolClass, sizeof(ctAutoPistolClass));
		ResolveLoadoutClassForClient(client, "weapon_tec9", tAutoPistolClass, sizeof(tAutoPistolClass));
		ResolveLoadoutClassForClient(client, "weapon_deagle", heavyPistolClass, sizeof(heavyPistolClass));
		ResolveLoadoutClassForClient(client, "weapon_mp7", midSmgClass, sizeof(midSmgClass));

		char query[512];
		FormatEx(query, sizeof(query), "REPLACE INTO %sloadout_slots (steamid64, ct_default_pistol_variant, ct_m4_variant, ct_auto_pistol_variant, t_auto_pistol_variant, heavy_pistol_variant, mid_smg_variant) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s')", g_TablePrefix, steamid64, pistolClass, m4Class, ctAutoPistolClass, tAutoPistolClass, heavyPistolClass, midSmgClass);
		db.Query(T_GenericQueryCallback, query, 0);
	}
}




void RefreshInventoryImportTimer()
{
	if (g_hInventoryImportTimer != INVALID_HANDLE)
	{
		delete g_hInventoryImportTimer;
		g_hInventoryImportTimer = INVALID_HANDLE;
	}

	if (g_fInventoryImportSyncInterval > 0.0)
	{
		g_hInventoryImportTimer = CreateTimer(g_fInventoryImportSyncInterval, Timer_InventoryImportSync, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_InventoryImportSync(Handle timer)
{
	if (db == null || g_iDatabaseState <= 1)
	{
		return Plugin_Continue;
	}

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsClientAuthorized(client))
		{
			SyncInventoryFromBackendForClient(client);
		}
	}
	return Plugin_Continue;
}

void InsertImportedSkinRecord(const char[] steamid64, int weaponIndex, int skinId, float wear, int seed, int stattrakEnabled, int stattrakCount, int obtainedAt)
{
	if (wear < 0.0) wear = 0.0;
	if (wear > 1.0) wear = 1.0;
	if (obtainedAt <= 0) obtainedAt = GetTime();

	char escapedSteamId[64];
	db.Escape(steamid64, escapedSteamId, sizeof(escapedSteamId));

	char query[1024];
	FormatEx(query, sizeof(query), "INSERT INTO %sunlocked_skins (steamid64, weapon_index, skin_id, wear, seed, stattrak_enabled, stattrak_count, obtained_at) SELECT '%s', %d, %d, %.6f, %d, %d, %d, %d WHERE NOT EXISTS (SELECT 1 FROM %sunlocked_skins WHERE steamid64 = '%s' AND weapon_index = %d AND skin_id = %d AND wear = %.6f AND seed = %d AND stattrak_enabled = %d)", g_TablePrefix, escapedSteamId, weaponIndex, skinId, wear, seed, stattrakEnabled, stattrakCount, obtainedAt, g_TablePrefix, escapedSteamId, weaponIndex, skinId, wear, seed, stattrakEnabled);
	db.Query(T_GenericQueryCallback, query, 0);
}

bool SyncInventoryFromBackendBySteamID64(const char[] steamid64, int requestedBy = 0, int refreshClientUserId = 0)
{
	if (!IsSteamID64String(steamid64))
	{
		LogError("Backend inventory sync aborted: invalid SteamID64 '%s'", steamid64);
		if (IsValidClient(requestedBy))
		{
			ReplyToCommand(requestedBy, "[SM] Backend inventory sync aborted: invalid SteamID64 (%s)", steamid64);
		}
		return false;
	}

	if (GetFeatureStatus(FeatureType_Native, "SteamWorks_CreateHTTPRequest") != FeatureStatus_Available)
	{
		if (g_bDropDebug)
		{
			LogMessage("[weapons:drop-debug] backend sync skipped for %s: SteamWorks extension is not available", steamid64);
		}
		return false;
	}

	if (g_InventoryBackendUrl[0] == EOS || g_InventoryBackendApiKey[0] == EOS)
	{
		if (g_bDropDebug)
		{
			LogMessage("[weapons:drop-debug] backend sync skipped for %s: backend_url_set=%d backend_key_set=%d", steamid64, g_InventoryBackendUrl[0] != EOS, g_InventoryBackendApiKey[0] != EOS);
		}
		return false;
	}

	char url[512];
	FormatEx(url, sizeof(url), "%s/api/server/inventory/export/%s?sync=1", g_InventoryBackendUrl, steamid64);
	if (g_bDropDebug)
	{
		LogMessage("[weapons:drop-debug] backend sync request created for %s url=%s", steamid64, url);
	}
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
	if (request == INVALID_HANDLE)
	{
		LogError("Backend inventory export request creation failed for %s", steamid64);
		return false;
	}

	SteamWorks_SetHTTPRequestHeaderValue(request, "X-Server-Api-Key", g_InventoryBackendApiKey);
	SteamWorks_SetHTTPRequestHeaderValue(request, "Accept", "text/plain");

	DataPack pack = new DataPack();
	pack.WriteString(steamid64);
	pack.WriteCell(requestedBy > 0 ? GetClientUserId(requestedBy) : 0);
	pack.WriteCell(refreshClientUserId);
	SteamWorks_SetHTTPRequestContextValue(request, pack);
	SteamWorks_SetHTTPCallbacks(request, T_BackendInventoryExportCallback);
	SteamWorks_SendHTTPRequest(request);
	return true;
}

bool ExtractFirstPositiveInt(const char[] input, int &value)
{
	value = 0;
	int len = strlen(input);
	int start = -1;

	for (int i = 0; i < len; i++)
	{
		if (input[i] >= '0' && input[i] <= '9')
		{
			start = i;
			break;
		}
	}

	if (start < 0)
	{
		return false;
	}

	char number[16];
	int out;
	for (int i = start; i < len && out < sizeof(number) - 1; i++)
	{
		if (input[i] < '0' || input[i] > '9')
		{
			break;
		}

		number[out++] = input[i];
	}
	number[out] = EOS;

	if (out <= 0)
	{
		return false;
	}

	value = StringToInt(number);
	return value > 0;
}

void NormalizeImportedWeaponClass(const char[] rawValue, char[] weaponClass, int maxlen)
{
	weaponClass[0] = EOS;
	if (rawValue[0] == EOS)
	{
		return;
	}

	char value[128];
	strcopy(value, sizeof(value), rawValue);
	TrimString(value);

	if (StrContains(value, "Souvenir ", false) == 0)
	{
		strcopy(value, sizeof(value), value[9]);
		TrimString(value);
	}

	if (StrContains(value, "StatTrak", false) == 0)
	{
		int firstSpace = StrContains(value, " ", false);
		if (firstSpace > 0)
		{
			strcopy(value, sizeof(value), value[firstSpace + 1]);
			TrimString(value);
		}
	}

	if (value[0] == '\xE2' || value[0] == '*')
	{
		int offset = 1;
		while (value[offset] != EOS && value[offset] == ' ')
		{
			offset++;
		}
		strcopy(value, sizeof(value), value[offset]);
		TrimString(value);
	}

	int separator = StrContains(value, " | ", false);
	if (separator > 0)
	{
		value[separator] = EOS;
		TrimString(value);
	}

	if (StrEqual(value, "AK-47", false)) strcopy(weaponClass, maxlen, "ak47");
	else if (StrEqual(value, "M4A4", false)) strcopy(weaponClass, maxlen, "m4a1");
	else if (StrEqual(value, "M4A1-S", false)) strcopy(weaponClass, maxlen, "m4a1_silencer");
	else if (StrEqual(value, "USP-S", false)) strcopy(weaponClass, maxlen, "usp_silencer");
	else if (StrEqual(value, "Dual Berettas", false)) strcopy(weaponClass, maxlen, "elite");
	else if (StrEqual(value, "Five-SeveN", false)) strcopy(weaponClass, maxlen, "fiveseven");
	else if (StrEqual(value, "CZ75-Auto", false)) strcopy(weaponClass, maxlen, "cz75a");
	else if (StrEqual(value, "R8 Revolver", false)) strcopy(weaponClass, maxlen, "revolver");
	else if (StrEqual(value, "SSG 08", false)) strcopy(weaponClass, maxlen, "ssg08");
	else if (StrEqual(value, "MAC-10", false)) strcopy(weaponClass, maxlen, "mac10");
	else if (StrEqual(value, "Sawed-Off", false)) strcopy(weaponClass, maxlen, "sawedoff");
	else if (StrEqual(value, "MP5-SD", false)) strcopy(weaponClass, maxlen, "mp5sd");
	else if (StrEqual(value, "Incendiary Grenade", false)) strcopy(weaponClass, maxlen, "incgrenade");
	else if (StrEqual(value, "High Explosive Grenade", false)) strcopy(weaponClass, maxlen, "hegrenade");
	else
	{
		strcopy(weaponClass, maxlen, value);
		ReplaceString(weaponClass, maxlen, "-", "", false);
		ReplaceString(weaponClass, maxlen, " ", "", false);
		for (int i = 0; weaponClass[i] != EOS; i++)
		{
			weaponClass[i] = CharToLower(weaponClass[i]);
		}
	}
}

bool TryGetWeaponClassFromDescription(JSON_Object description, char[] weaponClass, int maxlen)
{
	weaponClass[0] = EOS;
	if (description == null)
	{
		return false;
	}

	char marketHashName[192];
	description.GetString("market_hash_name", marketHashName, sizeof(marketHashName));
	if (marketHashName[0] != EOS)
	{
		NormalizeImportedWeaponClass(marketHashName, weaponClass, maxlen);
		if (weaponClass[0] != EOS)
		{
			return true;
		}
	}

	JSON_Array tags = view_as<JSON_Array>(description.GetObject("tags"));
	if (tags == null)
	{
		return false;
	}

	int tagsLength = tags.Length;
	for (int i = 0; i < tagsLength; i++)
	{
		JSON_Object tag = tags.GetObject(i);
		if (tag == null)
		{
			continue;
		}

		char category[64];
		tag.GetString("category", category, sizeof(category));
		if (!StrEqual(category, "Weapon", false) && !StrEqual(category, "Type", false))
		{
			tag = null;
			continue;
		}

		char internalName[64];
		tag.GetString("internal_name", internalName, sizeof(internalName));
		if (StrContains(internalName, "tag_weapon_", false) == 0)
		{
			strcopy(internalName, sizeof(internalName), internalName[11]);
			NormalizeImportedWeaponClass(internalName, weaponClass, maxlen);
			if (weaponClass[0] != EOS)
			{
				tag = null;
				tags = null;
				return true;
			}
		}

		char localized[64];
		tag.GetString("localized_tag_name", localized, sizeof(localized));
		if (localized[0] != EOS)
		{
			NormalizeImportedWeaponClass(localized, weaponClass, maxlen);
			if (weaponClass[0] != EOS)
			{
				tag = null;
				tags = null;
				return true;
			}
		}

		tag = null;
	}

	tags = null;

	return false;
}

bool TryGetPaintKitFromDescription(JSON_Object description, int &paintKit)
{
	paintKit = 0;
	if (description == null)
	{
		return false;
	}

	if (description.GetType("paintindex") == JSON_Type_Int)
	{
		paintKit = description.GetInt("paintindex");
		return paintKit > 0;
	}

	char paintIndex[32];
	description.GetString("paintindex", paintIndex, sizeof(paintIndex));
	if (ExtractFirstPositiveInt(paintIndex, paintKit))
	{
		return true;
	}

	JSON_Array lines = view_as<JSON_Array>(description.GetObject("descriptions"));
	if (lines == null)
	{
		return false;
	}

	int linesLength = lines.Length;
	for (int i = 0; i < linesLength; i++)
	{
		JSON_Object line = lines.GetObject(i);
		if (line == null)
		{
			continue;
		}

		char value[256];
		line.GetString("value", value, sizeof(value));
		if (StrContains(value, "Paint Index", false) >= 0 && ExtractFirstPositiveInt(value, paintKit))
		{
			line = null;
			lines = null;
			return true;
		}

		line = null;
	}

	lines = null;

	return false;
}

void ParseSkinNameFromMarketHashName(const char[] marketHashName, char[] skinName, int maxlen)
{
	skinName[0] = EOS;
	if (marketHashName[0] == EOS)
	{
		return;
	}

	char value[192];
	strcopy(value, sizeof(value), marketHashName);
	int separator = StrContains(value, "|", false);
	if (separator < 0)
	{
		return;
	}

	strcopy(skinName, maxlen, value[separator + 1]);
	TrimString(skinName);

	int openParen = FindCharInString(skinName, '(', true);
	int closeParen = FindCharInString(skinName, ')', true);
	if (openParen > 0 && closeParen > openParen)
	{
		skinName[openParen] = EOS;
		TrimString(skinName);
	}
}

float ParseWearFromMarketHashName(const char[] marketHashName)
{
	if (StrContains(marketHashName, "(Factory New)", false) > -1) return 0.03;
	if (StrContains(marketHashName, "(Minimal Wear)", false) > -1) return 0.10;
	if (StrContains(marketHashName, "(Field-Tested)", false) > -1) return 0.25;
	if (StrContains(marketHashName, "(Well-Worn)", false) > -1) return 0.40;
	if (StrContains(marketHashName, "(Battle-Scarred)", false) > -1) return 0.60;
	return 0.0;
}

void GetAssetWearSeed(JSON_Array assetProperties, const char[] assetId, float &wear, int &seed)
{
	if (assetProperties == null || assetId[0] == EOS)
	{
		return;
	}

	int rows = assetProperties.Length;
	for (int i = 0; i < rows; i++)
	{
		JSON_Object row = assetProperties.GetObject(i);
		if (row == null)
		{
			continue;
		}

		char rowAssetId[32];
		row.GetString("assetid", rowAssetId, sizeof(rowAssetId));
		if (!StrEqual(rowAssetId, assetId, false))
		{
			row = null;
			continue;
		}

		JSON_Array properties = view_as<JSON_Array>(row.GetObject("asset_properties"));
		if (properties == null)
		{
			row = null;
			break;
		}

		int propLen = properties.Length;
		for (int p = 0; p < propLen; p++)
		{
			JSON_Object prop = properties.GetObject(p);
			if (prop == null)
			{
				continue;
			}

			char propName[64];
			prop.GetString("name", propName, sizeof(propName));
			if (StrEqual(propName, "Pattern Template", false))
			{
				seed = prop.GetInt("int_value");
			}
			else if (StrEqual(propName, "Wear Rating", false))
			{
				wear = prop.GetFloat("float_value");
			}
		}

		properties = null;
		row = null;
		break;
	}
}

bool IsStatTrakDescription(JSON_Object description, const char[] marketHashName)
{
	if (StrContains(marketHashName, "StatTrak", false) > -1)
	{
		return true;
	}

	JSON_Array lines = view_as<JSON_Array>(description.GetObject("descriptions"));
	if (lines == null)
	{
		return false;
	}

	int count = lines.Length;
	for (int i = 0; i < count; i++)
	{
		JSON_Object line = lines.GetObject(i);
		if (line == null)
		{
			continue;
		}

		char name[64];
		line.GetString("name", name, sizeof(name));
		if (StrContains(name, "stattrak", false) > -1)
		{
			lines = null;
			return true;
		}
	}

	lines = null;
	return false;
}

int ResolveSkinIdFromMarketHashName(const char[] weaponClass, const char[] marketHashName)
{
	if (g_smSkinIndexByNameAndWeapon == null || weaponClass[0] == EOS || marketHashName[0] == EOS)
	{
		return 0;
	}

	char skinName[96];
	ParseSkinNameFromMarketHashName(marketHashName, skinName, sizeof(skinName));
	if (skinName[0] == EOS)
	{
		return 0;
	}

	char normalizedSkinName[96];
	NormalizeInventoryLookupToken(skinName, normalizedSkinName, sizeof(normalizedSkinName));
	if (normalizedSkinName[0] == EOS)
	{
		return 0;
	}

	char key[160];
	int skinId;
	FormatEx(key, sizeof(key), "%s::%s", normalizedSkinName, weaponClass);
	if (g_smSkinIndexByNameAndWeapon.GetValue(key, skinId) && skinId > 0)
	{
		return skinId;
	}

	if (StrContains(weaponClass, "weapon_", false) != 0)
	{
		FormatEx(key, sizeof(key), "%s::weapon_%s", normalizedSkinName, weaponClass);
		if (g_smSkinIndexByNameAndWeapon.GetValue(key, skinId) && skinId > 0)
		{
			return skinId;
		}
	}

	int weaponIndex = MapImportedWeaponToIndex(weaponClass, 0);
	if (weaponIndex >= 0 && weaponIndex < sizeof(g_WeaponClasses))
	{
		FormatEx(key, sizeof(key), "%s::%s", normalizedSkinName, g_WeaponClasses[weaponIndex]);
		if (g_smSkinIndexByNameAndWeapon.GetValue(key, skinId) && skinId > 0)
		{
			return skinId;
		}
	}

	return 0;
}

StringMap g_smImportedPaintKitToSkinByWeapon;

int MapImportedPaintKitToSkinId(int weaponIndex, int paintKit)
{
	if (paintKit <= 0)
	{
		return 0;
	}

	if (g_smImportedPaintKitToSkinByWeapon == null)
	{
		g_smImportedPaintKitToSkinByWeapon = new StringMap();
	}

	char key[32];
	FormatEx(key, sizeof(key), "%d:%d", weaponIndex, paintKit);

	int mappedSkinId;
	if (g_smImportedPaintKitToSkinByWeapon.GetValue(key, mappedSkinId) && mappedSkinId > 0)
	{
		return mappedSkinId;
	}

	// Deterministic fallback overrides for known paintkit->skin_id divergences.
	// Format: "<weapon_index>:<paintkit>" => skin_id.
	static const char knownPaintKitMap[][2][24] = {
		{"", ""}
	};

	for (int i = 0; i < sizeof(knownPaintKitMap); i++)
	{
		if (knownPaintKitMap[i][0][0] == EOS)
		{
			continue;
		}

		if (!StrEqual(knownPaintKitMap[i][0], key, false))
		{
			continue;
		}

		mappedSkinId = StringToInt(knownPaintKitMap[i][1]);
		if (mappedSkinId > 0)
		{
			g_smImportedPaintKitToSkinByWeapon.SetValue(key, mappedSkinId);
			return mappedSkinId;
		}
	}

	return 0;
}

void RememberPaintKitSkinMapping(int weaponClassIndex, int paintKit, int skinId)
{
	if (weaponClassIndex < 0 || paintKit <= 0 || skinId <= 0)
	{
		return;
	}

	if (g_smImportedPaintKitToSkinByWeapon == null)
	{
		g_smImportedPaintKitToSkinByWeapon = new StringMap();
	}

	char key[32];
	FormatEx(key, sizeof(key), "%d:%d", weaponClassIndex, paintKit);
	g_smImportedPaintKitToSkinByWeapon.SetValue(key, skinId);
}

bool ProcessImportedInventoryRow(const char[] steamid64, const char[] sourceName, const char[] weaponClass, int weaponDefIndex, int skinId, float wear, int seed, int stattrakEnabled, int stattrakCount, int obtainedAt)
{
	int normalizedStatTrakEnabled = stattrakEnabled > 0 ? 1 : 0;
	int normalizedObtainedAt = obtainedAt > 0 ? obtainedAt : GetTime();
	int weaponIndex = MapImportedWeaponToIndex(weaponClass, weaponDefIndex);

	if (g_bDropDebug)
	{
		LogMessage("[weapons:drop-debug] normalized import row source=%s steamid=%s class=%s defindex=%d skin_id=%d wear=%.6f seed=%d stattrak_enabled=%d stattrak_count=%d obtained_at=%d mapped_weapon_index=%d", sourceName, steamid64, weaponClass, weaponDefIndex, skinId, wear, seed, normalizedStatTrakEnabled, stattrakCount, normalizedObtainedAt, weaponIndex);
	}

	if (weaponIndex < 0)
	{
		return false;
	}

	if (!IsImportedSkinCompatible(weaponIndex, skinId))
	{
		return false;
	}

	InsertImportedSkinRecord(steamid64, weaponIndex, skinId, wear, seed, normalizedStatTrakEnabled, stattrakCount, normalizedObtainedAt);
	return true;
}

bool SyncInventoryFromSteamCommunityBySteamID64(const char[] steamid64, int requestedBy = 0, int refreshClientUserId = 0)
{
	if (!IsSteamID64String(steamid64))
	{
		LogError("SteamCommunity inventory sync aborted: invalid SteamID64 '%s'", steamid64);
		if (IsValidClient(requestedBy))
		{
			ReplyToCommand(requestedBy, "[SM] SteamCommunity inventory sync aborted: invalid SteamID64 (%s)", steamid64);
		}
		return false;
	}

	if (GetFeatureStatus(FeatureType_Native, "SteamWorks_CreateHTTPRequest") != FeatureStatus_Available)
	{
		if (g_bDropDebug)
		{
			LogMessage("[weapons:drop-debug] steamcommunity sync skipped for %s: SteamWorks extension is not available", steamid64);
		}
		return false;
	}

	char url[256];
	FormatEx(url, sizeof(url), "https://steamcommunity.com/inventory/%s/730/2", steamid64);
	if (g_bDropDebug)
	{
		LogMessage("[weapons:drop-debug] steamcommunity sync request created for %s url=%s", steamid64, url);
	}

	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
	if (request == INVALID_HANDLE)
	{
		LogError("SteamCommunity inventory request creation failed for %s", steamid64);
		return false;
	}

	SteamWorks_SetHTTPRequestHeaderValue(request, "Accept", "application/json");

	DataPack pack = new DataPack();
	pack.WriteString(steamid64);
	pack.WriteCell(requestedBy > 0 ? GetClientUserId(requestedBy) : 0);
	pack.WriteCell(refreshClientUserId);
	SteamWorks_SetHTTPRequestContextValue(request, pack);
	SteamWorks_SetHTTPCallbacks(request, T_SteamCommunityInventoryCallback);
	SteamWorks_SendHTTPRequest(request);
	return true;
}

void SyncInventoryFromBackendForClient(int client)
{
	char steamid64[32];
	if (!GetClientSteamID64(client, steamid64, sizeof(steamid64)))
	{
		return;
	}

	if (!IsSteamID64String(steamid64))
	{
		LogError("Inventory sync aborted for client %N: invalid SteamID64 '%s'", client, steamid64);
		PrintToChat(client, " %s Inventory sync aborted: invalid SteamID64 (got: %s)", g_ChatPrefix, steamid64);
		return;
	}

	bool queued;
	if (g_InventoryBackendUrl[0] == EOS)
	{
		queued = SyncInventoryFromSteamCommunityBySteamID64(steamid64, 0, GetClientUserId(client));
	}
	else
	{
		queued = SyncInventoryFromBackendBySteamID64(steamid64, 0, GetClientUserId(client));
	}

	if (!queued)
	{
		ImportInventoryForClient(client);
	}
}

public int T_SteamCommunityInventoryCallback(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, DataPack pack)
{
	pack.Reset();
	char steamid64[32];
	pack.ReadString(steamid64, sizeof(steamid64));
	int requestedByUserId = pack.ReadCell();
	int refreshClientUserId = pack.ReadCell();
	delete pack;

	int requestedBy = GetClientOfUserId(requestedByUserId);
	int refreshClient = GetClientOfUserId(refreshClientUserId);
	if (!IsValidClient(refreshClient))
	{
		refreshClient = FindOnlineClientBySteamID64(steamid64);
	}

	if (failure || !requestSuccessful || statusCode != k_EHTTPStatusCode200OK)
	{
		LogError("SteamCommunity inventory sync failed for %s (failure=%d request=%d status=%d)", steamid64, failure, requestSuccessful, statusCode);
		if (IsValidClient(requestedBy))
		{
			ReplyToCommand(requestedBy, "[SM] SteamCommunity inventory sync failed for %s (status: %d)", steamid64, statusCode);
		}
		return 0;
	}

	int bodySize;
	if (!SteamWorks_GetHTTPResponseBodySize(request, bodySize) || bodySize <= 0)
	{
		LogError("SteamCommunity inventory response body empty for %s", steamid64);
		return 0;
	}

	char[] body = new char[bodySize + 1];
	if (!SteamWorks_GetHTTPResponseBodyData(request, body, bodySize))
	{
		LogError("SteamCommunity inventory response body read failed for %s", steamid64);
		return 0;
	}
	body[bodySize] = EOS;

	int imported;
	int skippedUnmapped;
	int skippedMalformed;

	JSON_Object root = json_decode(body);
	if (root == null)
	{
		LogError("SteamCommunity inventory json_decode failed for %s", steamid64);
		return 0;
	}

	JSON_Array assets = view_as<JSON_Array>(root.GetObject("assets"));
	JSON_Array descriptions = view_as<JSON_Array>(root.GetObject("descriptions"));
	JSON_Array assetProperties = view_as<JSON_Array>(root.GetObject("asset_properties"));
	if (assets == null || descriptions == null)
	{
		LogError("SteamCommunity inventory malformed payload for %s (missing assets/descriptions)", steamid64);
		json_cleanup_and_delete(root);
		return 0;
	}

	StringMap descriptionLookup = new StringMap();
	for (int i = 0; i < descriptions.Length; i++)
	{
		JSON_Object description = descriptions.GetObject(i);
		if (description == null)
		{
			skippedMalformed++;
			continue;
		}

		char classid[32], instanceid[32], lookupKey[96];
		description.GetString("classid", classid, sizeof(classid));
		description.GetString("instanceid", instanceid, sizeof(instanceid));
		if (classid[0] == EOS || instanceid[0] == EOS)
		{
			skippedMalformed++;
			if (g_bDropDebug)
			{
				LogMessage("[weapons:drop-debug] steamcommunity description skipped for %s: missing classid/instanceid", steamid64);
			}
			continue;
		}

		FormatEx(lookupKey, sizeof(lookupKey), "%s_%s", classid, instanceid);
		descriptionLookup.SetValue(lookupKey, i);
	}

	for (int i = 0; i < assets.Length; i++)
	{
		JSON_Object asset = assets.GetObject(i);
		if (asset == null)
		{
			skippedMalformed++;
			continue;
		}

		char classid[32], instanceid[32], lookupKey[96];
		asset.GetString("classid", classid, sizeof(classid));
		asset.GetString("instanceid", instanceid, sizeof(instanceid));
		if (classid[0] == EOS || instanceid[0] == EOS)
		{
			skippedMalformed++;
			if (g_bDropDebug)
			{
				LogMessage("[weapons:drop-debug] steamcommunity asset skipped for %s: missing classid/instanceid", steamid64);
			}
			continue;
		}

		FormatEx(lookupKey, sizeof(lookupKey), "%s_%s", classid, instanceid);
		int descriptionIndex;
		if (!descriptionLookup.GetValue(lookupKey, descriptionIndex))
		{
			skippedMalformed++;
			if (g_bDropDebug)
			{
				LogMessage("[weapons:drop-debug] steamcommunity asset skipped for %s: description lookup missing key=%s", steamid64, lookupKey);
			}
			continue;
		}

		JSON_Object description = descriptions.GetObject(descriptionIndex);
		if (description == null)
		{
			skippedMalformed++;
			continue;
		}

		int weaponDefIndex = description.GetInt("defindex");

		float wear = description.GetFloat("paintwear");
		int seed = description.GetInt("paintseed");

		char assetId[32];
		asset.GetString("assetid", assetId, sizeof(assetId));
		GetAssetWearSeed(assetProperties, assetId, wear, seed);

		char marketHashName[192];
		description.GetString("market_hash_name", marketHashName, sizeof(marketHashName));
		if (wear <= 0.0)
		{
			wear = ParseWearFromMarketHashName(marketHashName);
		}
		if (wear < 0.0) wear = 0.0;
		if (wear > 1.0) wear = 1.0;
		if (seed < 0) seed = 0;

		int stattrakCount = description.GetInt("stattrak_score");
		if (stattrakCount <= 0)
		{
			// Fallback for older payload shapes.
			stattrakCount = description.GetInt("killeatervalue");
		}
		if (stattrakCount < 0)
		{
			stattrakCount = 0;
		}
		int stattrakEnabled = IsStatTrakDescription(description, marketHashName) ? 1 : 0;

		char weaponClass[64];
		weaponClass[0] = EOS;
		TryGetWeaponClassFromDescription(description, weaponClass, sizeof(weaponClass));

		int provisionalWeaponIndex = MapImportedWeaponToIndex(weaponClass, weaponDefIndex);
		int skinId = ResolveSkinIdFromMarketHashName(weaponClass, marketHashName);

		if (skinId <= 0)
		{
			int paintKit;
			if (TryGetPaintKitFromDescription(description, paintKit))
			{
				skinId = MapImportedPaintKitToSkinId(provisionalWeaponIndex, paintKit);
				if (skinId > 0 && provisionalWeaponIndex >= 0)
				{
					RememberPaintKitSkinMapping(provisionalWeaponIndex, paintKit, skinId);
				}
			}
		}

		if (skinId <= 0)
		{
			skippedUnmapped++;
			if (g_bDropDebug)
			{
				LogMessage("[weapons:drop-debug] steamcommunity asset unresolved skin for %s: class=%s defindex=%d market_hash_name=%s", steamid64, weaponClass, weaponDefIndex, marketHashName);
			}
			continue;
		}

		if (!ProcessImportedInventoryRow(steamid64, "steamcommunity", weaponClass, weaponDefIndex, skinId, wear, seed, stattrakEnabled, stattrakCount, GetTime()))
		{
			skippedUnmapped++;
			continue;
		}

		imported++;
	}

	delete descriptionLookup;
	assets = null;
	descriptions = null;
	json_cleanup_and_delete(root);

	if (IsValidClient(refreshClient))
	{
		LoadClientUnlockedItems(refreshClient);
	}

	if (g_bDropDebug)
	{
		LogMessage("[weapons:drop-debug] steamcommunity inventory parse result for %s: imported=%d malformed=%d unmapped=%d", steamid64, imported, skippedMalformed, skippedUnmapped);
	}

	if (IsValidClient(requestedBy))
	{
		ReplyToCommand(requestedBy, "[SM] SteamCommunity inventory sync finished for %s: imported=%d malformed=%d unmapped=%d", steamid64, imported, skippedMalformed, skippedUnmapped);
	}

	return 0;
}

public int T_BackendInventoryExportCallback(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, DataPack pack)
{
	pack.Reset();
	char steamid64[32];
	pack.ReadString(steamid64, sizeof(steamid64));
	int requestedByUserId = pack.ReadCell();
	int refreshClientUserId = pack.ReadCell();
	delete pack;

	int requestedBy = GetClientOfUserId(requestedByUserId);
	int refreshClient = GetClientOfUserId(refreshClientUserId);
	if (!IsValidClient(refreshClient))
	{
		refreshClient = FindOnlineClientBySteamID64(steamid64);
	}

	if (failure || !requestSuccessful || statusCode != k_EHTTPStatusCode200OK)
	{
		LogError("Backend inventory export failed for %s (failure=%d request=%d status=%d)", steamid64, failure, requestSuccessful, statusCode);
		if (IsValidClient(requestedBy))
		{
			ReplyToCommand(requestedBy, "[SM] Backend inventory sync failed for %s (status: %d)", steamid64, statusCode);
		}
		return 0;
	}

	int bodySize;
	if (!SteamWorks_GetHTTPResponseBodySize(request, bodySize) || bodySize <= 0)
	{
		LogError("Backend inventory export response body empty for %s", steamid64);
		return 0;
	}

	int bodyBufferSize = bodySize + 1;
	if (bodyBufferSize < 2)
	{
		bodyBufferSize = 2;
	}

	char[] body = new char[bodyBufferSize];
	if (!SteamWorks_GetHTTPResponseBodyData(request, body, bodySize))
	{
		bool timedOut;
		bool hasTimeoutInfo = SteamWorks_GetHTTPRequestWasTimedOut(request, timedOut);

		int contentTypeSize;
		char contentType[128];
		bool hasContentType = SteamWorks_GetHTTPResponseHeaderSize(request, "Content-Type", contentTypeSize)
			&& contentTypeSize > 0
			&& SteamWorks_GetHTTPResponseHeaderValue(request, "Content-Type", contentType, sizeof(contentType));

		int contentLengthSize;
		char contentLength[64];
		bool hasContentLength = SteamWorks_GetHTTPResponseHeaderSize(request, "Content-Length", contentLengthSize)
			&& contentLengthSize > 0
			&& SteamWorks_GetHTTPResponseHeaderValue(request, "Content-Length", contentLength, sizeof(contentLength));

		char timeoutDisplay[16];
		if (hasTimeoutInfo)
		{
			strcopy(timeoutDisplay, sizeof(timeoutDisplay), timedOut ? "1" : "0");
		}
		else
		{
			strcopy(timeoutDisplay, sizeof(timeoutDisplay), "unknown");
		}

		LogError("Backend inventory export body read failed for %s (body_size=%d read_length=%d buffer_size=%d status=%d timed_out=%s content_type=%s content_length=%s)", steamid64, bodySize, bodySize, bodyBufferSize, statusCode, timeoutDisplay, hasContentType ? contentType : "<missing>", hasContentLength ? contentLength : "<missing>");
		return 0;
	}
	body[bodySize] = EOS;

	int imported;
	int skippedMalformed;
	int skippedUnmapped;
	int lineCount;

	int bodyLength = strlen(body);
	int lineStart = 0;
	for (int i = 0; i <= bodyLength; i++)
	{
		if (body[i] != '\n' && body[i] != EOS)
		{
			continue;
		}

		body[i] = EOS;
		lineCount++;

		if (lineCount > 1)
		{
			TrimString(body[lineStart]);
			if (body[lineStart] != EOS)
			{
				char fields[9][64];
				int fieldCount = ExplodeString(body[lineStart], "\t", fields, sizeof(fields), sizeof(fields[]));
				if (fieldCount < 9)
				{
					skippedMalformed++;
				}
				else
				{
					int weaponDefIndex = StringToInt(fields[2]);
					int skinId = StringToInt(fields[3]);
					float wear = StringToFloat(fields[4]);
					int seed = StringToInt(fields[5]);
					int stattrakEnabled = StringToInt(fields[6]) > 0 ? 1 : 0;
					int stattrakCount = StringToInt(fields[7]);
					int obtainedAt = StringToInt(fields[8]);

					if (!ProcessImportedInventoryRow(steamid64, "backend", fields[1], weaponDefIndex, skinId, wear, seed, stattrakEnabled, stattrakCount, obtainedAt))
					{
						skippedUnmapped++;
					}
					else
					{
						imported++;
					}
				}
			}
		}

		if (i == bodyLength)
		{
			break;
		}

		lineStart = i + 1;
	}

	if (IsValidClient(refreshClient))
	{
		LoadClientUnlockedItems(refreshClient);
	}

	if (g_bDropDebug)
	{
		LogMessage("[weapons:drop-debug] backend inventory parse result for %s: lines=%d imported=%d malformed=%d unmapped=%d", steamid64, lineCount, imported, skippedMalformed, skippedUnmapped);
	}

	if (IsValidClient(requestedBy))
	{
		ReplyToCommand(requestedBy, "[SM] Backend inventory sync finished for %s: imported=%d malformed=%d unmapped=%d", steamid64, imported, skippedMalformed, skippedUnmapped);
	}

	return 0;
}

void ImportInventoryForClient(int client)
{
	char steamid64[32];
	if (!GetClientSteamID64(client, steamid64, sizeof(steamid64)))
	{
		return;
	}

	ImportInventoryForSteamID64(steamid64, 0, GetClientUserId(client));
}

void ImportInventoryForSteamID64(const char[] steamid64, int requestedByUserId = 0, int refreshClientUserId = 0)
{
	if (db == null || g_iDatabaseState <= 1)
	{
		return;
	}

	char sourceTable[128];
	FormatEx(sourceTable, sizeof(sourceTable), "%s%s", g_TablePrefix, g_InventoryImportSourceTable);

	char escapedSteamId[64];
	db.Escape(steamid64, escapedSteamId, sizeof(escapedSteamId));

	char query[1024];
	FormatEx(query, sizeof(query), "SELECT id, external_item_id, weapon_class, weapon_defindex, skin_id, paintkit, wear, seed, stattrak_enabled, stattrak_count, obtained_at FROM %s WHERE steamid64 = '%s'", sourceTable, escapedSteamId);
	if (g_bDropDebug)
	{
		LogMessage("[weapons:drop-debug] local inventory import query queued for steamid=%s source_table=%s", steamid64, sourceTable);
	}

	DataPack pack = new DataPack();
	pack.WriteCell(requestedByUserId);
	pack.WriteCell(refreshClientUserId);
	pack.WriteString(steamid64);
	db.Query(T_ImportInventoryLoadSourceCallback, query, pack);
}

bool IsImportedSkinCompatible(int weaponIndex, int skinId)
{
	if (weaponIndex < 0 || weaponIndex >= sizeof(g_WeaponClasses) || skinId <= 0 || g_smWeaponSkinIndex == null)
	{
		return false;
	}

	char key[32];
	FormatEx(key, sizeof(key), "%d:%s", skinId, g_WeaponClasses[weaponIndex]);
	int value;
	return g_smWeaponSkinIndex.GetValue(key, value);
}

int MapImportedWeaponToIndex(const char[] weaponClass, int weaponDefIndex)
{
	if (weaponClass[0] != EOS)
	{
		int directIndex;
		if (g_smWeaponIndex.GetValue(weaponClass, directIndex))
		{
			return directIndex;
		}

		if (StrContains(weaponClass, "weapon_", false) != 0)
		{
			char prefixedClass[64];
			FormatEx(prefixedClass, sizeof(prefixedClass), "weapon_%s", weaponClass);
			if (g_smWeaponIndex.GetValue(prefixedClass, directIndex))
			{
				return directIndex;
			}
		}
	}

	if (weaponDefIndex > 0)
	{
		for (int i = 0; i < sizeof(g_iWeaponDefIndex); i++)
		{
			if (g_iWeaponDefIndex[i] == weaponDefIndex)
			{
				return i;
			}
		}
	}

	return -1;
}

int FindOnlineClientBySteamID64(const char[] steamid64)
{
	char currentSteamId[32];
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || !IsClientAuthorized(client))
		{
			continue;
		}

		if (!GetClientSteamID64(client, currentSteamId, sizeof(currentSteamId)))
		{
			continue;
		}

		if (StrEqual(currentSteamId, steamid64))
		{
			return client;
		}
	}

	return 0;
}

public void T_ImportInventoryLoadSourceCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	int requestedByUserId = pack.ReadCell();
	int refreshClientUserId = pack.ReadCell();
	char steamid64[32];
	pack.ReadString(steamid64, sizeof(steamid64));
	delete pack;

	int requestedBy = GetClientOfUserId(requestedByUserId);
	int refreshClient = GetClientOfUserId(refreshClientUserId);
	if (!IsValidClient(refreshClient))
	{
		refreshClient = FindOnlineClientBySteamID64(steamid64);
	}

	if (results == null)
	{
		LogError("Inventory import source query failed for %s: %s", steamid64, error);
		if (IsValidClient(requestedBy))
		{
			ReplyToCommand(requestedBy, "[SM] Inventory import failed for %s (%s)", steamid64, error);
		}
		return;
	}

	int processed;
	int imported;
	int skippedInvalid;
	while (results.FetchRow())
	{
		processed++;
		int sourceRowId = results.FetchInt(0);
		char externalItemId[64];
		results.FetchString(1, externalItemId, sizeof(externalItemId));
		if (externalItemId[0] == '\0')
		{
			// Signature dedupe still keeps import idempotent when no external item id is available.
		}

		char weaponClass[64];
		results.FetchString(2, weaponClass, sizeof(weaponClass));
		int weaponDefIndex = results.FetchInt(3);
		int skinId = results.FetchInt(4);
		int paintKit = results.FetchInt(5);
		if (skinId <= 0)
		{
			skinId = paintKit;
		}
		float wear = results.FetchFloat(6);
		int seed = results.FetchInt(7);
		int stattrakEnabled = results.FetchInt(8) > 0 ? 1 : 0;
		int stattrakCount = results.FetchInt(9);
		int obtainedAt = results.FetchInt(10);
		if (obtainedAt <= 0)
		{
			obtainedAt = GetTime();
		}

		if (!ProcessImportedInventoryRow(steamid64, "local", weaponClass, weaponDefIndex, skinId, wear, seed, stattrakEnabled, stattrakCount, obtainedAt))
		{
			skippedInvalid++;
			continue;
		}

		if (paintKit > 0 && skinId > 0)
		{
			int weaponClassIndex = MapImportedWeaponToIndex(weaponClass, weaponDefIndex);
			RememberPaintKitSkinMapping(weaponClassIndex, paintKit, skinId);
		}
		imported++;

		char query[256];

		FormatEx(query, sizeof(query), "UPDATE %s%s SET imported_at = %d WHERE id = %d", g_TablePrefix, g_InventoryImportSourceTable, GetTime(), sourceRowId);
		db.Query(T_GenericQueryCallback, query, 0);
	}

	if (IsValidClient(refreshClient))
	{
		LoadClientUnlockedItems(refreshClient);
	}

	if (g_bDropDebug)
	{
		LogMessage("[weapons:drop-debug] local inventory import result for %s: processed=%d imported=%d skipped_invalid=%d", steamid64, processed, imported, skippedInvalid);
	}

	if (IsValidClient(requestedBy))
	{
		ReplyToCommand(requestedBy, "[SM] Inventory import finished for %s: processed=%d imported=%d skipped_invalid=%d", steamid64, processed, imported, skippedInvalid);
	}
}


void LoadClientUnlockedItems(int client)
{
	char steamid64[32];
	if (!GetClientSteamID64(client, steamid64, sizeof(steamid64)))
	{
		DebugDropLog(client, "LoadClientUnlockedItems aborted: no auth id available");
		return;
	}

	char query[512];
	FormatEx(query, sizeof(query), "SELECT id, weapon_index, skin_id, wear, seed, stattrak_enabled, stattrak_count FROM %sunlocked_skins WHERE steamid64 = '%s' ORDER BY id ASC", g_TablePrefix, steamid64);
	db.Query(T_LoadClientUnlockedItemsCallback, query, GetClientUserId(client));

	char equippedQuery[512];
	FormatEx(equippedQuery, sizeof(equippedQuery), "SELECT weapon_index, unlocked_id FROM %sequipped_skins WHERE steamid64 = '%s'", g_TablePrefix, steamid64);
	db.Query(T_LoadClientEquippedItemsCallback, equippedQuery, GetClientUserId(client));

	char equippedStateQuery[1024];
	FormatEx(equippedStateQuery, sizeof(equippedStateQuery), "SELECT e.weapon_index, u.skin_id, u.wear, u.seed, u.stattrak_enabled, u.stattrak_count FROM %sequipped_skins e JOIN %sunlocked_skins u ON e.unlocked_id = u.id WHERE e.steamid64 = '%s'", g_TablePrefix, g_TablePrefix, steamid64);
	db.Query(T_LoadEquippedStateCallback, equippedStateQuery, GetClientUserId(client));
	DebugDropLog(client, "LoadClientUnlockedItems queued for auth=%s", steamid64);
}

public void T_LoadClientUnlockedItemsCallback(Database database, DBResultSet results, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
	{
		return;
	}

	g_iUnlockedItemCount[client] = 0;
	if (results == null)
	{
		LogError("Load unlocked skins failed: %s", error);
		return;
	}

	while (results.FetchRow() && g_iUnlockedItemCount[client] < MAX_UNLOCKED_ITEMS)
	{
		int i = g_iUnlockedItemCount[client];
		g_iUnlockedItemId[client][i] = results.FetchInt(0);
		g_iUnlockedItemWeaponIndex[client][i] = results.FetchInt(1);
		g_iUnlockedItemSkinId[client][i] = results.FetchInt(2);
		g_fUnlockedItemWear[client][i] = results.FetchFloat(3);
		g_iUnlockedItemSeed[client][i] = results.FetchInt(4);
		g_iUnlockedItemStatTrakEnabled[client][i] = results.FetchInt(5);
		g_iUnlockedItemStatTrakCount[client][i] = results.FetchInt(6);
		g_iUnlockedItemCount[client]++;
	}

	DebugDropLog(client, "LoadClientUnlockedItems completed: unlocked_count=%d", g_iUnlockedItemCount[client]);
}

public void T_LoadClientEquippedItemsCallback(Database database, DBResultSet results, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
	{
		return;
	}

	for (int i = 0; i < sizeof(g_WeaponClasses); i++)
	{
		g_iEquippedItemId[client][i] = 0;
	}

	if (results == null)
	{
		LogError("Load equipped skins failed: %s", error);
		return;
	}

	while (results.FetchRow())
	{
		int weaponIndex = results.FetchInt(0);
		if (weaponIndex >= 0 && weaponIndex < sizeof(g_WeaponClasses))
		{
			g_iEquippedItemId[client][weaponIndex] = results.FetchInt(1);
		}
	}
}

public void T_LoadEquippedStateCallback(Database database, DBResultSet results, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
	{
		return;
	}

	if (results == null)
	{
		LogError("Load equipped state failed: %s", error);
		return;
	}

	while (results.FetchRow())
	{
		int weaponIndex = results.FetchInt(0);
		if (weaponIndex < 0 || weaponIndex >= sizeof(g_WeaponClasses))
		{
			continue;
		}
		g_iSkins[client][weaponIndex] = results.FetchInt(1);
		g_fFloatValue[client][weaponIndex] = results.FetchFloat(2);
		g_iWeaponSeed[client][weaponIndex] = results.FetchInt(3);
		g_iStatTrak[client][weaponIndex] = results.FetchInt(4);
		g_iStatTrakCount[client][weaponIndex] = results.FetchInt(5);
	}
}

void SaveUnlockedDropAndEquip(int client, int weaponIndex, int skinId, float wear, int seed, int stattrakEnabled, int stattrakCount)
{
	char steamid64[32];
	if (!GetClientSteamID64(client, steamid64, sizeof(steamid64)))
	{
		DebugDropLog(client, "SaveUnlockedDropAndEquip aborted: no auth id available");
		return;
	}

	char query[512];
	FormatEx(query, sizeof(query), "INSERT INTO %sunlocked_skins (steamid64, weapon_index, skin_id, wear, seed, stattrak_enabled, stattrak_count, obtained_at) VALUES ('%s', %d, %d, %.6f, %d, %d, %d, %d)", g_TablePrefix, steamid64, weaponIndex, skinId, wear, seed, stattrakEnabled, stattrakCount, GetTime());
	db.Query(T_GenericQueryCallback, query, 0);

	char selectQuery[512];
	FormatEx(selectQuery, sizeof(selectQuery), "SELECT MAX(id) FROM %sunlocked_skins WHERE steamid64 = '%s'", g_TablePrefix, steamid64);
	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(weaponIndex);
	pack.WriteCell(skinId);
	pack.WriteFloat(wear);
	pack.WriteCell(seed);
	pack.WriteCell(stattrakEnabled);
	pack.WriteCell(stattrakCount);
	db.Query(T_SaveUnlockedDropSelectIdCallback, selectQuery, pack);
	DebugDropLog(client, "SaveUnlockedDropAndEquip queued: auth=%s weaponIndex=%d skinId=%d wear=%.4f seed=%d stattrak=%d", steamid64, weaponIndex, skinId, wear, seed, stattrakEnabled);
}

public void T_SaveUnlockedDropSelectIdCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int weaponIndex = pack.ReadCell();
	int skinId = pack.ReadCell();
	float wear = pack.ReadFloat();
	int seed = pack.ReadCell();
	int stattrakEnabled = pack.ReadCell();
	int stattrakCount = pack.ReadCell();
	delete pack;
	if (!IsValidClient(client))
	{
		return;
	}
	if (results == null || !results.FetchRow())
	{
		LogError("Fetch new unlocked id failed: %s", error);
		DebugDropLog(client, "T_SaveUnlockedDropSelectIdCallback failed: %s", error);
		return;
	}

	int unlockedId = results.FetchInt(0);
	DebugDropLog(client, "T_SaveUnlockedDropSelectIdCallback fetched unlockedId=%d", unlockedId);
	if (g_iUnlockedItemCount[client] < MAX_UNLOCKED_ITEMS)
	{
		int cacheIndex = g_iUnlockedItemCount[client];
		g_iUnlockedItemId[client][cacheIndex] = unlockedId;
		g_iUnlockedItemWeaponIndex[client][cacheIndex] = weaponIndex;
		g_iUnlockedItemSkinId[client][cacheIndex] = skinId;
		g_fUnlockedItemWear[client][cacheIndex] = wear;
		g_iUnlockedItemSeed[client][cacheIndex] = seed;
		g_iUnlockedItemStatTrakEnabled[client][cacheIndex] = stattrakEnabled;
		g_iUnlockedItemStatTrakCount[client][cacheIndex] = stattrakCount;
		g_iUnlockedItemCount[client]++;
	}

	// Keep inventory cache aligned with DB even if the in-memory append above misses
	// (for example when cache limits are reached or callback order shifts).
	LoadClientUnlockedItems(client);

	EquipUnlockedItem(client, weaponIndex, unlockedId);
	PrintToChat(client, " %s \x04Drop received:\x01 %s | Skin %d | Wear %.4f%s", g_ChatPrefix, g_WeaponClasses[weaponIndex], skinId, wear, stattrakEnabled == 1 ? " | StatTrak" : "");
	PrintToChatAll(" %s \x04%N\x01 unlocked a skin drop: \x04#%d\x01 for \x04%s\x01.", g_ChatPrefix, client, unlockedId, g_WeaponClasses[weaponIndex]);
}

void EquipUnlockedItem(int client, int weaponIndex, int unlockedId)
{
	bool equipped;
	for (int i = 0; i < g_iUnlockedItemCount[client]; i++)
	{
		if (g_iUnlockedItemId[client][i] != unlockedId || g_iUnlockedItemWeaponIndex[client][i] != weaponIndex)
		{
			continue;
		}

		g_iEquippedItemId[client][weaponIndex] = unlockedId;
		g_iSkins[client][weaponIndex] = g_iUnlockedItemSkinId[client][i];
		g_fFloatValue[client][weaponIndex] = g_fUnlockedItemWear[client][i];
		g_iWeaponSeed[client][weaponIndex] = g_iUnlockedItemSeed[client][i];
		g_iStatTrak[client][weaponIndex] = g_iUnlockedItemStatTrakEnabled[client][i];
		g_iStatTrakCount[client][weaponIndex] = g_iUnlockedItemStatTrakCount[client][i];
		RefreshWeapon(client, weaponIndex);

		char steamid64[32];
		if (GetClientSteamID64(client, steamid64, sizeof(steamid64)))
		{
			char query[512];
			FormatEx(query, sizeof(query), "REPLACE INTO %sequipped_skins (steamid64, weapon_index, unlocked_id) VALUES ('%s', %d, %d)", g_TablePrefix, steamid64, weaponIndex, unlockedId);
			db.Query(T_GenericQueryCallback, query, 0);
		}

		char updateFields[512];
		char weaponName[32];
		RemoveWeaponPrefix(g_WeaponClasses[weaponIndex], weaponName, sizeof(weaponName));
		FormatEx(updateFields, sizeof(updateFields), "%s = %d, %s_float = %.2f, %s_seed = %d, %s_trak = %d, %s_trak_count = %d", weaponName, g_iSkins[client][weaponIndex], weaponName, g_fFloatValue[client][weaponIndex], weaponName, g_iWeaponSeed[client][weaponIndex], weaponName, g_iStatTrak[client][weaponIndex], weaponName, g_iStatTrakCount[client][weaponIndex]);
		UpdatePlayerData(client, updateFields);
		equipped = true;
		break;
	}

	if (!equipped)
	{
		DebugDropLog(client, "EquipUnlockedItem missing cache row: weaponIndex=%d unlockedId=%d unlocked_count=%d", weaponIndex, unlockedId, g_iUnlockedItemCount[client]);
	}
}

void UpdateUnlockedItemStatTrakCount(int client, int weaponIndex)
{
	int equippedId = g_iEquippedItemId[client][weaponIndex];
	if (equippedId <= 0)
	{
		return;
	}
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE %sunlocked_skins SET stattrak_count = %d WHERE id = %d", g_TablePrefix, g_iStatTrakCount[client][weaponIndex], equippedId);
	db.Query(T_GenericQueryCallback, query, 0);
}

void CreatePlayerData(int client)
{
	char steamid[32];
	if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true))
	{
		char query[255];
		FormatEx(query, sizeof(query), "INSERT INTO %sweapons (steamid) VALUES ('%s')", g_TablePrefix, steamid);
		DataPack pack = new DataPack();
		pack.WriteString(steamid);
		pack.WriteString(query);
		db.Query(T_InsertCallback, query, pack);
	}
}

void ResetPlayerData(int client)
{
	char steamid[32];
	if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true))
	{
		char query[255];
		FormatEx(query, sizeof(query), "DELETE FROM %sweapons WHERE steamid = '%s'", g_TablePrefix, steamid);
		DataPack pack = new DataPack();
		pack.WriteCell(GetClientUserId(client));
		pack.WriteString(query);
		db.Query(T_DeletePlayerDataCallback, query, pack);
	}

	char steamid64[32];
	if (GetClientSteamID64(client, steamid64, sizeof(steamid64)))
	{
		char inventoryQuery[256];
		FormatEx(inventoryQuery, sizeof(inventoryQuery), "DELETE FROM %sunlocked_skins WHERE steamid64 = '%s'", g_TablePrefix, steamid64);
		db.Query(T_GenericQueryCallback, inventoryQuery, 0);
		char equippedQuery[256];
		FormatEx(equippedQuery, sizeof(equippedQuery), "DELETE FROM %sequipped_skins WHERE steamid64 = '%s'", g_TablePrefix, steamid64);
		db.Query(T_GenericQueryCallback, equippedQuery, 0);
	}
}

public void T_DeletePlayerDataCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (results == null)
	{
		char buffer[255];
		pack.ReadString(buffer, 255);
		LogError("Delete Query failed! query: \"%s\" error: \"%s\"", buffer, error);
	}
	else if (client > 0)
	{
		CreatePlayerData(client);
	}
	delete pack;
}
