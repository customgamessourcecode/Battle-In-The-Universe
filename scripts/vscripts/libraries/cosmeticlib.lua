--[[
	Author: kritth
	Date: 12.03.2015
	TODO:
	- Particle on swap
	- Courier swap
	- Ward swap
]]

--[[
====================================================================================================================
============================================Init Functions==========================================================
====================================================================================================================
]]

local m = {}
m.__index = m;


-- Initialize the library, should be called only once
function m.Init()
	if not m.bHasInitialized then
		-- Set flag so it cannot initialize twice
		m.bHasInitialized = true
		
		-- Disable combine models
		SendToServerConsole( "dota_combine_models 0" )
		SendToConsole( "dota_combine_models 0" )
		
		-- Create the tables
		m._CreateTables()
		
		-- Custom console command
		Convars:RegisterCommand( "print_available_players", function( cmd )
				return m.PrintPlayers()
			end, "Print all available players", FCVAR_CHEAT
		)
		Convars:RegisterCommand( "print_item_sets_for_player", function( cmd, player_id ) 
				return m.PrintSetsForHero( PlayerResource:GetPlayer( tonumber( player_id ) ) )
			end, "Print set item for hero", FCVAR_CHEAT
		)
		Convars:RegisterCommand( "print_items_from_player", function( cmd, player_id )
				return m.PrintItemsFromPlayer( PlayerResource:GetPlayer( tonumber( player_id ) ) )
			end, "Print items currently equipped to assigned hero", FCVAR_CHEAT
		)
		Convars:RegisterCommand( "print_items_for_slot_from_player", function( cmd, player_id, slot_name )
				return m.PrintItemsForSlotFromPlayer( PlayerResource:GetPlayer( tonumber( player_id ) ), slot_name )
			end, "Print items available for certain slot in hero", FCVAR_CHEAT
		)
		Convars:RegisterCommand( "equip_item_set_for_player", function( cmd, player_id, set_id ) 
				local hero = PlayerResource:GetPlayer( tonumber( player_id ) ):GetAssignedHero()
				return m.EquipHeroSet( hero, set_id )
			end, "Equip set item for hero", FCVAR_CHEAT
		)
		Convars:RegisterCommand( "replace_item_by_slot", function( cmd, player_id, slot_name, item_id )
				local hero = PlayerResource:GetPlayer( tonumber( player_id ) ):GetAssignedHero()
				return m.ReplaceWithSlotName( hero, slot_name, item_id )
			end, "Replace item by slot name", FCVAR_CHEAT
		)
		Convars:RegisterCommand( "replace_item_by_id", function( cmd, player_id, old_item_id, new_item_id )
				local hero = PlayerResource:GetPlayer( tonumber( player_id ) ):GetAssignedHero()
				return m.ReplaceWithItemID( hero, old_item_id, new_item_id )
			end, "Replace item by id", FCVAR_CHEAT
		)
		Convars:RegisterCommand( "replace_default", function( cmd, player_id )
				local hero = PlayerResource:GetPlayer( tonumber( player_id ) ):GetAssignedHero()
				return m.ReplaceDefault( hero, hero:GetName() )
			end, "Replace items with default items", FCVAR_CHEAT
		)
		Convars:RegisterCommand( "remove_from_slot", function( cmd, player_id, slot_name )
				local hero = PlayerResource:GetPlayer( tonumber( player_id ) ):GetAssignedHero()
				return m.RemoveFromSlot( hero, slot_name )
			end, "Remove cosmetic in certain slot", FCVAR_CHEAT
		)
		Convars:RegisterCommand( "remove_all", function( cmd, player_id )
				local hero = PlayerResource:GetPlayer( tonumber( player_id ) ):GetAssignedHero()
				return m.RemoveAll( hero )
			end, "Remove all cosmetics from hero", FCVAR_CHEAT
		)
	end
end

-- Create table in the structure specified above
function m._CreateTables()
	-- Load in values
	local kvLoadedTable = LoadKeyValues( "scripts/items/items_game.txt" )
	m._AllItemsByID = kvLoadedTable[ "items" ]
	m._NameToID = m._NameToID or {}										-- Structure table[ "item_name" ] = item_id
	
	-- Create these tables for faster lookup time
	for CosmeticID, CosmeticTable in pairs( m._AllItemsByID ) do					-- Extract only from items block
		if CosmeticTable[ "prefab" ] then	
			if CosmeticTable[ "prefab" ] == "default_item" and CosmeticTable[ "used_by_heroes" ]
					and type( CosmeticTable[ "used_by_heroes" ] ) == "table" then			-- Insert default items
				m._InsertIntoDefaultTable( CosmeticID )
				m._NameToID[ CosmeticTable[ "name" ] ] = CosmeticID
			elseif CosmeticTable[ "prefab" ] == "wearable" and CosmeticTable[ "used_by_heroes" ]
					and type( CosmeticTable[ "used_by_heroes" ] ) == "table" then			-- Insert wearable items
				m._InsertIntoWearableTable( CosmeticID )
				m._NameToID[ CosmeticTable[ "name" ] ] = CosmeticID
			elseif CosmeticTable[ "prefab" ] == "courier" then								-- Insert couriers
				m._InsertIntoCourierTable( CosmeticID )
				m._NameToID[ CosmeticTable[ "name" ] ] = CosmeticID
			elseif CosmeticTable[ "prefab" ] == "ward" then
				m._InsertIntoWardTable( CosmeticID )
				m._NameToID[ CosmeticTable[ "name" ] ] = CosmeticID
			end
		end
	end
	
	-- Run second time for bundle
	for CosmeticID, CosmeticTable in pairs( m._AllItemsByID ) do					-- Extract only from items block
		if CosmeticTable[ "prefab" ] and CosmeticTable[ "prefab" ] == "bundle"
				and CosmeticTable[ "used_by_heroes" ] ~= nil and type( CosmeticTable[ "used_by_heroes" ] ) == "table" then
			m._InsertIntoBundleTable( CosmeticID )
			m._NameToID[ CosmeticTable[ "name" ] ] = CosmeticID
		end
	end
	
	m._AllItemsByID[ "-1" ] = {}
	m._AllItemsByID[ "-1" ][ "model_player" ] = "models/development/invisiblebox.vmdl"
end

--[[
====================================================================================================================
=========================================Direct Commands============================================================
====================================================================================================================
]]

-- Print available players for replace
function m.PrintPlayers()
	local players = {}
	for i = 0, 9 do
		local player = PlayerResource:GetPlayer( i )
		if player and player:GetAssignedHero() then
			table.insert( players, i )
		end
	end
	
	DebugPrint( "[m] Available players are" )
	for k, v in pairs( players ) do
		DebugPrint( "[m] Player " .. v )
	end
end

-- Print available set_id for player with id player_id to console
function m.PrintSetsForHero( player )
	local hero = player:GetAssignedHero()
	local hero_sets = m.GetAllSetsForHero( hero:GetName() )
	DebugPrint( "[m] Available set for " .. hero:GetName() .. " are" )
	for _, item_id in pairs( hero_sets ) do
		DebugPrint( "[m] Set ID: " .. item_id .. "\tName: " .. m._AllItemsByID[ item_id ][ "name" ] )
	end
end

-- Print all item slots and its associated item id from player_id to console
function m.PrintItemsFromPlayer( player )
	local hero = player:GetAssignedHero()
	if hero and hero:IsRealHero() then
		if m._Identify( hero )then
			DebugPrint( "[m] Current cosmetics: " )
			for item_slot, handle_table in pairs( hero._cosmeticlib_wearables_slots ) do
				DebugPrint( "[m] Item ID: " .. handle_table[ "item_id" ] .. "\tSlot: " .. item_slot )
			end
		end
	end
end

-- Print all items for certain slot from player
function m.PrintItemsForSlotFromPlayer( player, slot_name )
	local hero = player:GetAssignedHero()
	if hero and hero:IsRealHero() then
		if m._WearableForHero[ hero:GetName() ] and m._WearableForHero[ hero:GetName() ][ slot_name ] then
			for item_name, item_id in pairs( m._WearableForHero[ hero:GetName() ][ slot_name ] ) do
				DebugPrint( "[m] Item ID: " .. item_id .. "\tItem Name: " .. item_name )
			end
		else
			DebugPrint( "[m] Invalid input. Please try again." )
		end
	end
end

--[[
====================================================================================================================
========================================Create Table Functions======================================================
====================================================================================================================
]]

-- Create sub table with new key value, return true if it existed or is able to create one
function m._CheckSubTable( new_key, table_to_insert )
	if new_key and table_to_insert and type( table_to_insert ) == "table" then
		if table_to_insert[ new_key ] == nil then
			table_to_insert[ new_key ] = {}
		end
		return 1
	else
		return nil
	end
end

-- Insert element into the default wearable table
function m._InsertIntoDefaultTable( CosmeticID )
	m._DefaultForHero = m._DefaultForHero or {}
	m._InsertIntoCosmeticTable( CosmeticID, m._DefaultForHero )
end

-- Insert element into the non-default wearable table
function m._InsertIntoWearableTable( CosmeticID )
	m._WearableForHero = m._WearableForHero or {}
	m._InsertIntoCosmeticTable( CosmeticID, m._WearableForHero )
end

--[[
	This function will put cosmetics into table
	Structure is
	m._TypeForHero[ "hero_name" ][ "item_slot" ][ "item_name" ] = item_id
]]
function m._InsertIntoCosmeticTable( CosmeticID, table_to_insert )
	-- All cosmetic will be store in this two tables
	m._SlotToName = m._SlotToName or {}							-- Structure table[ "slot_name" ][ "item_name" ] = item_id
	m._ModelNameToID = m._ModelNameToID or {}					-- Structure table[ "model_name" ] = item_id

	-- Check if it can be used by heroes
	local selected_item = m._AllItemsByID[ "" .. CosmeticID ]
	if not selected_item[ "used_by_heroes" ] or not selected_item[ "model_player" ] then return end
	local usable_by_heroes = selected_item[ "used_by_heroes" ]
	
	for hero_name, _ in pairs( usable_by_heroes ) do
		if m._CheckSubTable( hero_name, table_to_insert ) then						-- Check on hero name
			local item_slot = selected_item[ "item_slot" ] or "weapon"
			if m._CheckSubTable( item_slot, table_to_insert[ hero_name ] ) then		-- Check on item slot
				local item_name = selected_item[ "name" ]
				if item_name then																-- Check on item name
					table_to_insert[ hero_name ][ item_slot ][ item_name ] = CosmeticID
					m._ModelNameToID[ selected_item[ "model_player" ] ] = CosmeticID
					
					if m._CheckSubTable( item_slot, m._SlotToName ) then	-- Check to add into _SlotToName
						m._SlotToName[ item_slot ][ item_name ] = CosmeticID
					end
				end
			end
		end
	end
end

-- Insert new data into courier table
function m._InsertIntoCourierTable( CosmeticID )
	m._Couriers = m._Couriers or {}
	
	local selected_item = m._AllItemsByID[ "" .. CosmeticID ]
	
	if m._CheckSubTable( selected_item[ "name" ], m._Couriers ) then
		m._Couriers[ selected_item[ "name" ] ] = CosmeticID 
	end
end

-- Insert new data into ward table
function m._InsertIntoWardTable( CosmeticID )
	m._Wards = m._Wards or {}
	
	local selected_item = m._AllItemsByID[ "" .. CosmeticID ]
	
	if m._CheckSubTable( selected_item[ "name" ], m._Wards ) then
		m._Wards[ selected_item[ "name" ] ] = CosmeticID
	end
end

-- Insert new data into bundle/set table
function m._InsertIntoBundleTable( CosmeticID )
	m._Sets = m._Sets or {}
	m._SetByHeroes = m._SetByHeroes or {}
	
	local selected_item = m._AllItemsByID[ "" .. CosmeticID ]
	
	if m._CheckSubTable( selected_item[ "name" ], m._Sets ) then
		-- For hero name lookup
		for hero_name, enabled in pairs( selected_item[ "used_by_heroes" ] ) do
			if m._CheckSubTable( hero_name, m._SetByHeroes ) then
				m._SetByHeroes[ hero_name ][ selected_item[ "name" ] ] = CosmeticID
			end
		end
		-- For set name lookup
		for cosmetic_name, enabled in pairs( selected_item[ "bundle" ] ) do
			local item_set_id = m.GetIDByName( cosmetic_name )
			if item_set_id then
				local item = m._AllItemsByID[ item_set_id ]
				if item then
					if item[ "item_slot" ] then
						m._Sets[ selected_item[ "name" ] ][ item[ "item_slot" ] ] = item_set_id
					elseif item[ "prefab" ] == "wearable" or item[ "prefab" ] == "default_item" then
						m._Sets[ selected_item[ "name" ] ][ "weapon" ] = item_set_id
					end
				end
			end
		end
	end
end

--[[
====================================================================================================================
===========================================Getter Functions=========================================================
====================================================================================================================
]]

--[[
	Get available cosmetic slots for given hero name
]]
function m.GetAvailableSlotForHero( hero_name )
	if hero_name then
		if m._WearableForHero[ hero_name ] ~= nil then
			local toReturn = {}
			for item_slot, _ in pairs( m._WearableForHero[ hero_name ] ) do
				table.insert( toReturn, item_slot )
			end
			table.sort( toReturn )
			return toReturn
		end
	else
		DebugPrint( '[m:Getter] Error: Given hero_name does not exist.' )
	end
end

--[[
	Get available cosmetics for hero in given slot
]]
function m.GetAllAvailableForHeroInSlot( hero_name, slot_name )
	if hero_name then
		if m._WearableForHero[ hero_name ][ slot_name ] ~= nil then
			local toReturn = {}
			for item_name, _ in pairs( m._WearableForHero[ hero_name ][ slot_name ] ) do
				table.insert( toReturn, item_name )
			end
			table.sort( toReturn )
			return toReturn
		end
	else
		DebugPrint( '[m:Getter] Error: Given hero_name does not exist.' )
	end
end


-- Get all available cosmetics name
function m.GetAllAvailableWearablesName()
	if m._NameToID then
		local toReturn = {}
		for k, v in pairs( m._NameToID ) do
			table.insert( toReturn, k )
		end
		table.sort( toReturn )
		return toReturn
	else
		DebugPrint( '[m:Getter] Error: No cosmetic table found. Please verify that you have item_games.txt in your vpk' )
		return nil
	end
end

-- Get all available cosmetics id
function m.GetAllAvailableWearablesID()
	if m._NameToID then
		local toReturn = {}
		for k, v in pairs( m._NameToID ) do
			table.insert( toReturn, v )
		end
		table.sort( toReturn )
		return toReturn
	else
		DebugPrint( '[m:Getter] Error: No cosmetic table found. Please verify that you have item_games.txt in your vpk' )
		return nil
	end
end

-- Get all sets
function m.GetSetByName( set_name )
	return m._Sets[ set_name ]
end

-- Get all set for hero
function m.GetAllSetsForHero( hero_name )
	return m._SetByHeroes[ hero_name ]
end

-- Get ID by item name
function m.GetIDByName( item_name )
	if m._NameToID[ item_name ] ~= nil then
		return "" .. m._NameToID[ item_name ]
	end
end

-- Get ID by model name
function m.GetIDByModelName( model_name )
	if m._ModelNameToID[ model_name ] ~= nil then
		return "" .. m._ModelNameToID[ model_name ]
	end
end

--[[
====================================================================================================================
==========================================Replace Functions=========================================================
====================================================================================================================
]]

-- Check if the table existed
function m._Identify( unit )
	if unit:entindex() then
		if unit._cosmeticlib_wearables_slots == nil then
			unit._cosmeticlib_wearables_slots = {}
			-- Fill the table
			local wearable = unit:FirstMoveChild()
			while wearable do
				if wearable:GetClassname() == "dota_item_wearable" then
					local id = m.GetIDByModelName( wearable:GetModelName() )
					local item = m._AllItemsByID[ id ]
					if item then
						-- Structure table[ item_slot ] = { handle entindex, item_id }
						local item_slot = item[ "item_slot" ] or "weapon"
						unit._cosmeticlib_wearables_slots[ item_slot ] = { handle = wearable, item_id = id }
					end
				end
				wearable = wearable:NextMovePeer()
			end
		end
		return 1
	else
		DebugPrint( '[m:Replace] Error: Input is not entity' )
		return nil
	end
end

-- Equip set for hero
function m.EquipHeroSet( hero, set_id )
	m.EquipSet( hero, hero:GetName(), set_id )
end

-- Equip set
function m.EquipSet( unit, hero_name, set_id )
	if unit and hero_name and set_id and m._Identify( unit ) then
		local selected_item = m._AllItemsByID[ "" .. set_id ]
		if selected_item and m._SetByHeroes[ hero_name ]
				and m._SetByHeroes[ hero_name ][ selected_item[ "name" ] ] then
			for slot_name, item_id in pairs ( m._Sets[ selected_item[ "name" ] ] ) do
				m.ReplaceWithSlotName( unit, slot_name, item_id )
			end
			return
		end
	end
	
	DebugPrint( "[m.EquipSet] Error: Invalid input." )
end

-- Replace any unit back to default based on hero_name
function m.ReplaceDefault( unit, hero_name )
	if unit and hero_name and m._Identify( unit ) then
		if m._DefaultForHero[ hero_name ] then
			local hero_items = m._DefaultForHero[ hero_name ]
			for slot_name, item_table in pairs( hero_items ) do
				for item_name, item_id in pairs( item_table ) do
					m.ReplaceWithSlotName( unit, slot_name, item_id )
				end
			end
			return
		end
	end
	
	DebugPrint( "[m:Replace] Error: Invalid input." )
end

-- Remove from slot
function m.RemoveFromSlot( unit, slot_name )
	if unit and slot_name and m._Identify( unit ) then
		if unit._cosmeticlib_wearables_slots[ slot_name ] then
			m._Replace( unit._cosmeticlib_wearables_slots[ slot_name ], "-1" )
		end
		return
	end
	
	DebugPrint( "[m:Remove] Error: Invalid input." )
end

-- Remove all
function m.RemoveAll( unit )
	if unit and m._Identify( unit ) then
		-- Start force replacing
		for slot_name, handle_table in pairs( unit._cosmeticlib_wearables_slots ) do
			m._Replace( handle_table, "-1" )
		end
		return
	end
	
	DebugPrint( "[m:Remove] Error: Invalid input." )
end

-- Replace with check respect to slot name
function m.ReplaceWithSlotName( unit, slot_name, new_item_id )
	if unit and slot_name and new_item_id and m._Identify( unit ) then
		local handle_table = unit._cosmeticlib_wearables_slots[ slot_name ]
		if handle_table then
			return m._Replace( handle_table, new_item_id )
		end
	end
	DebugPrint("[m:Replace] Error: Invalid input.")
end

-- Replace with check respect to old item_id
function m.ReplaceWithItemID( unit, old_item_id, new_item_id )
	if unit and old_item_id and new_item_id and m._Identify( unit ) then
		for slot_name, handle_table in pairs( unit._cosmeticlib_wearables_slots ) do
			if "" .. handle_table[ "item_id" ] == "" .. old_item_id then
				return m._Replace( handle_table, new_item_id )
			end
		end
	end

	DebugPrint( "[m:Replace] Error: Invalid input." )
end

-- Replace cosmetic
-- This should never be called alone
function m._Replace( handle_table, new_item_id )
	local item = m._AllItemsByID[ "" .. new_item_id ]
	handle_table[ "handle" ]:SetModel( item[ "model_player" ] )
	handle_table[ "item_id" ] = new_item_id
	
	-- Attach particle
	-- Still cannot attach it properly
	if item[ "visual" ] and item[ "visual" ][ "attached_particlesystem0" ] then
		local wearable = handle_table[ "handle" ]
		local counter = 0
		local particle_name = item[ "visual" ][ "attached_particlesystem0" ]
	end
end

--[[
====================================================================================================================
====================================================================================================================
====================================================================================================================
]]

m.Init()