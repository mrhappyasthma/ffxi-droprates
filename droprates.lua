addon.author   = 'mrhappyasthma';
addon.name     = 'droprates';
addon.version  = '1.0.0';

require 'common'
local http = require("socket.http")
local text = require("lin/text")

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local mobdrops_url = 'https://raw.githubusercontent.com/LandSandBoat/server/refs/heads/base/sql/mob_droplist.sql'
local zones_url = 'https://raw.githubusercontent.com/LandSandBoat/server/refs/heads/base/sql/zone_settings.sql'
local mobgroups_url = 'https://raw.githubusercontent.com/LandSandBoat/server/e884dd53a7c0587cb97986e5f326edb0215af553/sql/mob_groups.sql'
local era_corrections = 'https://github.com/LandSandBoat/server/blob/e884dd53a7c0587cb97986e5f326edb0215af553/modules/era/sql/pre_rmt_drops.sql'

local STEAL = "2"
local DESPOIL = "4"

local droprates = {}

-- ZONE ID: local zone_name = AshitaCore:GetResourceManager():GetString("zones.names", zone_id)
-- local item = AshitaCore:GetResourceManager():GetItemById(itemid);
-- local item = AshitaCore:GetResourceManager():GetItemByName()
--    if (CheckResource(resource) == false) then
--        return;
--    end
-- local resourceName = encoding:ShiftJIS_To_UTF8(resource.Name[1]);
----------------------------------------------------------------------------------------------------
-- func: fetch_url
-- desc: Returns the data from a URL.
----------------------------------------------------------------------------------------------------
local function fetch_url(url)
    local response, code, headers, status = http.request(url)
    if response then
      return response
  else
    print("Error fetching URL, status code:", code)
    return ''
  end
end

local function print_str(str)
   print(string.format('\31\200[\31\05' .. addon.name .. '\31\200]\30\01 ' .. tostring(str)))
end

local function lookup_item_by_name(name)
  translated_name = AshitaCore:GetChatManager():ParseAutoTranslate(name, false);
  local item = AshitaCore:GetResourceManager():GetItemByName(translated_name, 0)
    if (item == nil) then
      return nil
    end
   return item
end

local function lookup_zone_by_name(zone)
  translated_zone = AshitaCore:GetChatManager():ParseAutoTranslate(zone, false);
  local item = AshitaCore:GetResourceManager():GetString("zones.names", zone_id)
    if (item == nil) then
      return nil
    end
   return item
end


----------------------------------------------------------------------------------------------------
-- func: extract_fields_from_sql
-- desc: Downloads a SQL file from the given URL, extracts specific fields from
--       the INSERT INTO statements, and returns them as a JSON array.
-- args:
--   url (string): The URL of the SQL file.
--   fields_to_extract (table): Table with field names as keys and indices as values 
--                              (e.g., {zoneid = 0, name = 4}).
-- returns:
--   string: JSON array of dictionaries with the specified fields, or an error message.
----------------------------------------------------------------------------------------------------
local function extract_fields_from_sql(url, fields_to_extract)
  local data = fetch_url(url)
end


----------------------------------------------------------------------------------------------------
-- func: print_help
-- desc: Displays a help block for proper command usage.
----------------------------------------------------------------------------------------------------
local function print_help(cmd, help)
    -- Print the invalid format header..
    print('\31\200[\31\05' .. addon.name .. '\31\200]\30\01 ' .. '\30\68Invalid format for command:\30\02 ' .. cmd .. '\30\01'); 

    -- Loop and print the help commands..
    for k, v in pairs(help) do
        print('\31\200[\31\05' .. addon.name .. '\31\200]\30\01 ' .. '\30\68Syntax:\30\02 ' .. v[1] .. '\30\71 ' .. v[2]);
    end
end

local function convertRateToPercentage(str)
  local num = tonumber(str)  -- Convert the string to a number

  if num then
    return string.format("%.1f", num / 10) .. "%%"  -- Divide by 10 and return the result
  else
    return str  -- Return the original string if it's not a valid number. (e.g. "Steal")
  end
end

-- Function to extract values from the INSERT INTO statement based on field mappings
local function extract_fields(statement, fields_to_extract)
    -- Match the part inside the parentheses after the "VALUES" keyword

    local values_part = statement:match("VALUES%s*%((.-)%)") -- Extract values inside parentheses
    local values = ashita.regex.split(values_part, ",")  -- Split the values by commas

    -- Create a table to hold the extracted fields
    local extracted_fields = {}

    -- Iterate over the fields_to_extract and extract the corresponding values
    for field_name, index in pairs(fields_to_extract) do
        if values[index] then
            extracted_fields[field_name] = values[index]:gsub("'", ""):gsub("_", " ")
        end
    end

    return extracted_fields
end

local function extract_statement_types(sql_data)
  local sql_statements = ashita.regex.split(sql_data, "\n") 
  local insert_statements = {}
  local set_statements = {}
  for _, statement in pairs(sql_statements) do
    if statement:sub(1, 11) == "INSERT INTO" then
      table.insert(insert_statements, statement)
    end
    if statement:sub(1, 5) == "SET @" then
      table.insert(set_statements, statement)
    end
  end
  return insert_statements, set_statements
end

-- Extracts specific fields from the SQL-formatted string and returns an array of dictionary entries.
local function extract_fields_from_insert_statements(insert_statements, fields_to_extract, key_name)
  local extracted_data = {}
  for _, insert_statement in pairs(insert_statements) do
    local fields = extract_fields(insert_statement, fields_to_extract)
    local key = fields[key_name]
    if not extracted_data[key] then
      extracted_data[key] = {}
    end
    table.insert(extracted_data[key], fields)
  end
  return extracted_data
end

local function extract_rate_variables(set_statements)
  local rates_table = {}
  for _, set_statement in pairs(set_statements) do
    local variable, value = set_statement:match("SET (%S+) = (%d+);")
    rates_table[variable] = value
  end
  return rates_table
end

local function create_table_grouped_by_key(original_table, key)
    local new_table = {}

    for _, entries in pairs(original_table) do
        for _, entry in pairs(entries) do
            local new_key = entry[key]

            if not new_table[new_key] then
                new_table[new_key] = {}
            end

            -- Insert the entry into the appropriate zone_id group
            table.insert(new_table[new_key], entry)
        end
    end

    return new_table
end

-------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()
  print(string.format('\31\200[\31\05' .. addon.name .. '\31\200]\30\01 ' .. '\30\07Fetching databse info...:'));
   
  local sql_data = fetch_url(mobdrops_url)
  local fields_to_extract = {["dropid"] = 1, ["droptype"] = 2, ["itemid"] = 5, ["itemrate"] = 6}
  local insert_statements, set_statements = extract_statement_types(sql_data)
  local rates_table = extract_rate_variables(set_statements)
  local key = "itemid"
  droprates.mobdrops_itemid = extract_fields_from_insert_statements(insert_statements, fields_to_extract, key)
  for i, mobdrop in pairs(droprates.mobdrops_itemid) do
    for _, droprate in ipairs(mobdrop) do
      rate = rates_table[droprate["itemrate"]]
      if rate ~= nil then
        droprate["itemrate"] = rate
      end
      local droptype = droprate["droptype"]
      if droptype == STEAL then
        droprate["itemrate"] = "Steal"
      elseif droptype == DESPOIL then
        droprate["itemrate"] = "Despoil"
      end
    end
  end
  droprates.mobdrops_dropid = create_table_grouped_by_key(droprates.mobdrops_itemid, "dropid")
  
  sql_data = fetch_url(mobgroups_url)
  insert_statements = extract_statement_types(sql_data)
  fields_to_extract = {["zoneid"] = 3, ["mobname"] = 4, ["dropid"] = 7}
  key = "dropid"
  droprates.mobgroups_dropid = extract_fields_from_insert_statements(insert_statements, fields_to_extract, key)
  droprates.mobgroups_mobname = create_table_grouped_by_key(droprates.mobgroups_dropid, "mobname")
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unload.
----------------------------------------------------------------------------------------------------
ashita.events.register('unload', 'unload_cb', function()

end);

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.events.register('command', 'command_cb', function(event)
	-- Parse the command arguments
	local command_args = event.command:args();
  if not table.contains({'/droprates', '/dr'}, string.lower(command_args[1])) then
    return false;
  end
  
  local command = table.concat(command_args, " ", 2, #command_args)

  local item = lookup_item_by_name(command)
  local mob_entries = droprates.mobgroups_mobname[command]
  if item then
    local item_name = item.Name[1]
    local mobdrops = droprates.mobdrops_itemid[tostring(item.Id)]
    print_str("Drops for '" .. item_name .. "':")
    local last_mobname = ""
    for _, mobdrop in ipairs(mobdrops) do
      if mobdrop then
        local item_rate = convertRateToPercentage(mobdrop["itemrate"])
        local drop_id = mobdrop["dropid"]
        local mobgroups = droprates.mobgroups_dropid[drop_id]
        for _, mobgroup in pairs(mobgroups) do
          local mobname = mobgroup["mobname"]
          if mobname ~= last_mobname then
            print_str("---------------------------------:")
            last_mobname = mobname
          end
          
          local zone_id = tonumber(mobgroup["zoneid"])
          local zone_name = AshitaCore:GetResourceManager():GetString('zones.names', zone_id)
          print_str(mobname .. ' - ' .. zone_name .. ' (' .. item_rate .. ')')
        end
      end
    end
  elseif mob_entries then
    local mob_name = mob_entries[1]["mobname"]
    print_str("Drops for '" .. mob_name .. "':")
    local last_zonename
    for _, entry in pairs(mob_entries) do
      local drop_id = entry["dropid"]
      local item_entries = droprates.mobdrops_dropid[drop_id]
      for _, item_entry in pairs(item_entries) do
        local item_id = tonumber(item_entry["itemid"])
        local item = AshitaCore:GetResourceManager():GetItemById(item_id)
        local zone_id = tonumber(entry["zoneid"])
        local zone_name = AshitaCore:GetResourceManager():GetString('zones.names', zone_id)
        local item_rate = convertRateToPercentage(item_entry["itemrate"]) or ''
        if zone_name ~= last_zonename then
            print_str("---------------------------------:")
            last_zonename = zone_name
        end
        print_str(zone_name .. ' - ' .. item.Name[1] .. ' (' .. item_rate .. ')')
      end
    end
  else
    print('Entry not found: ' .. command)
    -- TODO: try zone search
  end
  return true
end);
