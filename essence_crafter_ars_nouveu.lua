local pretty = require "cc.pretty"

----- initialize required variables / devices
local is_listening = true
local listening_delay = 5

local pedestals = {}
local chamber = nil
local raw_item = 'ars_nouveau:source_gem'
local bridge = peripheral.find("meBridge")
local args = {...}
local auto_start = true

----- craftable items recipies
local craft_items = {
    {
        item = 'ars_nouveau:abjuration_essence',
        display_name = 'Abjuration Essence',
        items_required = {
            'minecraft:milk_bucket',
            'minecraft:fermented_spider_eye',
            'minecraft:sugar'    
        }
    }, {
        item = 'ars_nouveau:conjuration_essence',
        display_name = 'Conjuration essence',
        items_required = {
            'ars_nouveau:wilden_horn',
            'minecraft:book',
            'ars_nouveau:starbuncle_shards'
        }
    },
    {
        item = 'ars_nouveau:air_essence',
        display_name = 'Air Essence',
        items_required = {
            'ars_nouveau:wilden_wing',
            'minecraft:feather',
            'minecraft:arrow'
        }
    },
    {
        item = 'ars_nouveau:earth_essence',
        display_name = 'Earth Essence',
        items_required = {
            'minecraft:wheat_seeds',
            'minecraft:iron_ingot',
            'minecraft:dirt'
        }
    },
    {
        item = 'ars_nouveau:fire_essence',
        display_name = 'Fire Essence',
        items_required = {
            'minecraft:torch',
            'minecraft:flint_and_steel',
            'minecraft:gunpowder'
        }
    },
    {
        item = 'ars_nouveau:manipulation_essence',
        display_name = 'Manipulation Essence',
        items_required = {
            'minecraft:stone_button',
            'minecraft:clock',
            'minecraft:redstone'
        }
    },
    {
        item = 'ars_nouveau:water_essence',
        display_name = 'Water Essence',
        items_required = {
            'minecraft:water_bucket',
            'minecraft:kelp',
            'minecraft:snow_block'
        }
    }
}

local function find_chamber()
    for indx, name in pairs(peripheral.getNames()) do
        if string.find(name, 'ars_nouveau:imbuement_chamber') then
            return name
        end
    end

    return nil
end

local function find_pedestals()
    for indx, name in pairs(peripheral.getNames()) do
        if string.find(name, 'ars_nouveau:arcane_pedestal') then
            table.insert(pedestals, name)
        end
    end
end

local function is_craftable_item(item_name)
    for indx, item_entry in pairs(craft_items) do
        if(item_name == item_entry.item) then
            return item_entry
        end
    end

    return nil
end

local function can_craft_item(craft)
    can_craft = true

    write('> ' .. craft.display_name)

    for indx, item_required in pairs(craft.items_required) do
        item = bridge.getItem({name = item_required})
        
        if(type(item) == 'table' and item.amount ~= nil and item.amount >= 1) then
            --print('- item ok: ' .. item.displayName)
        elseif(type(item) == 'table' and item.amount == 0 and item.isCraftable)  then
            if(can_craft) then
                print(' - ERR!')
            end
            print('\t- craft this item!! ' .. item.displayName .. '\n')
            can_craft = false
        else
            if(can_craft) then
                print(' - ERR!')
            end
            print('\t- item not found in ae2 system: ' .. item_required .. '\n')
            can_craft = false
        end
    end

    if(can_craft) then
        print(' - OK\n')
    end

    return can_craft
end

local function push_items(craft)
    for indx, item_required in pairs(craft.items_required) do
        -- print(item_required)
        -- print(pedestals[indx])
        bridge.exportItemToPeripheral({name = item_required, count = 1}, pedestals[indx])
    end
end

local function push_raw()
    w = peripheral.wrap(chamber)
    
    if(w.getItemDetail(1) ~= nil) then
        bridge.importItemFromPeripheral({name = w.getItemDetail(1).name, count = 1}, chamber)
    end

    bridge.exportItemToPeripheral({name = raw_item, count = 1}, chamber)
end

local function pull_items()
    for indx, pedestal in pairs(pedestals) do
        w = peripheral.wrap(pedestal)
        if(w.getItemDetail(1) ~= nil) then
            bridge.importItemFromPeripheral({name = w.getItemDetail(1).name, count = 1}, pedestal)
        end
    end
end

-- wait of imbuiment and take item of chamber
local function wait_for_imbuiment()
    w = peripheral.wrap(chamber)
    waiting = true

    while(waiting) do 
        if(w.getItemDetail(1) == nil) then
            waiting = false
        elseif(w.getItemDetail(1).name ~= raw_item) then
            bridge.importItemFromPeripheral({name = w.getItemDetail(1).name, count = 1}, chamber)
            waiting = false
        end

        os.sleep(3)
    end
end

local function  to_imbuiment(craft, count)
    print('craft ' .. craft.display_name .. ' x' .. count)
    push_items(craft)
    
    for i = 1, count do
        push_raw()
        wait_for_imbuiment()
        print('crafted ' .. i .. ' of ' .. count)
    end

    pull_items()
end

local function listen_crafter_cpu()
    while(is_listening) do
        for indx, item_entry in pairs(craft_items) do
            if(bridge.isItemCrafting({name = item_entry.item})) then
                for _, cpu in pairs(bridge.getCraftingCPUs()) do
                    if(cpu.isBusy and item_entry.item == cpu.craftingJob.storage.name) then
                        to_imbuiment(item_entry, cpu.craftingJob.totalItem)
                    end
                end
            end
        end

        os.sleep(listening_delay)
        --is_listening = false
    end
end

-- start here!
local init_err = false

find_pedestals()
chamber = find_chamber()

if #pedestals ~= 3 then
    print('pedestals missing... needed 3, identified ' .. #pedestals)
    init_err = true
end

if chamber == nil then
    print('chamber missing...')
    init_err = true
end

if(init_err) then
    return
end

local can_craft_all_items = true
for indx, item_entry in pairs(craft_items) do
    if(not can_craft_item(item_entry) and not auto_start) then
        write('press enter to continue...')
        read()
        can_craft_all_items = false
    end
end

if(not can_craft_all_items) then
    while true do
        if(not auto_start) then
            write('missing raw items... ¿continue? [y/n]: ')

            local r = read()
            if(r:find('^n') == 1) then
                print('bye!')
                return
            elseif(r:find('^y') == 1) then
                do break end
            end
        else
            print('missing raw items....')
        end
    end
end

print('enabling listener ae2 CPUs')
listen_crafter_cpu()