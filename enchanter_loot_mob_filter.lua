
local pretty = require "cc.pretty"

local args = {...}

local inventory_map = {
    trash = 'trashcans:item_trash_can_0',
    items = 'sophisticatedstorage:diamond_chest_0'
}

local delayTime = 30 -- in seconds

local filter_logic = {
    items_filter = {
        'minecraft:bow',
        'minecraft:.*_helmet',
        'minecraft:.*_boots',
        'minecraft:.*_chestplate',
        'minecraft:.*_leggings',
        'minecraft:.*_sword',
        'minecraft:rotten_flesh',
        'minecraft:shield'
    },
    delete_filter = {
        '^rftoolsdim',
        'supplementaries:quiver'
    }
}

local function invExists(name)
    for indx, side in pairs(peripheral.getNames()) do
        if(peripheral.getName(peripheral.wrap(side)) == name) then
            return true
        end
    end

    return false
end

local function showInvs(map)
    for indx, side in pairs(peripheral.getNames()) do
        print('- ' .. peripheral.getName(peripheral.wrap(side)))
        -- print(peripheral.getType(peripheral.wrap(side)))
    end
end

local function isFiltrable(item)
    items_filter = filter_logic["items_filter"]

    for k, v in pairs(items_filter) do
        if v == item['name'] or item['name']:match(v) then 
            return true
        end
    end

    return false
end

local function isDeletable(item)
    delete_filter = filter_logic['delete_filter']

    for k, v in pairs(delete_filter) do
        if v == item['name'] or item['name']:match(v) then
            return true
        end
    end

end

local function start()
    while(true) do
        local itemsDropped = 0
        local itemsIgnored = 0
        local itemsEnchanted = 0
        local trash = peripheral.wrap(inventory_map['trash'])
        local chest = peripheral.wrap(inventory_map['items'])

        -- iteración de slots en el inventario
        for i = 1, chest.size(), 1 do repeat
            item = chest.getItemDetail(i)

            -- ¿el slot se encuentra vacio?
            if(item == nil) then
                do break end
            end

            -- pretty.pretty_print(item)

            -- ¿el item se encuentra en la lista para ser filtrada
            if(not isFiltrable(item) and not isDeletable(item)) then
                -- print('no filtrable item! ' .. item['name'])
                itemsIgnored = itemsIgnored + 1
                do break end
            end

            print('item #' .. i)
            if(item['enchantments'] == nil or isDeletable(item)) then
                -- print('no enchantments available... drop it')
                local trash_name = peripheral.getName(trash)
                local ok = pcall(chest.pushItems, trash_name, i)

                if(not ok) then
                    print('error on pcall push items!')
                    do break end
                end

                itemsDropped = itemsDropped + 1

                do break end
            end

            print(item['name'])
            itemsEnchanted = itemsEnchanted + 1

            -- todo: filter enchantments
            -- for k, v in pairs(item['enchantments']) do
            --     print(v['displayName'])
            -- end
        until true end

        print('---------')
        print('Items encantados: ' .. itemsEnchanted)
        print('Items dropeados: ' .. itemsDropped)
        print('Items ignorados: ' .. itemsIgnored)

        os.sleep(delayTime)
    end
end

local autoStart = true
local runIt = nil

for k, v in pairs(args) do
    if(v == '--help' or v == '-h') then
        print(
[[
Enchanter router help
    -h --help   Mostrar esta información
    -li --inventories    Listar los nombres de inventarios disponibles para configurar el ruteo
    -i --items  Especifica el nombre del inventario que contiene todos los items
    -t --trash Especifica el nombre del invnetario en donde se tiraran los items
    -y Confirma la configuración inicial sin preguntar
]])
        return
    end

    if(v == '-li' or v == '--inventories') then
        print('Inventarios disponibles: ')
        showInvs()
        return
    end

    if(v == '-y') then
        autoStart = true
    end

    if(v == '-i' or v == '--items') then
        invName = args[k + 1]

        if(not invExists(args[k + 1])) then
            print('Inventario de items no encontrado, revisa la siguiente lista:')
            showInvs()
        else
            inventory_map['items'] = invName
        end
    end

    if(v == '-t' or v == '--trash') then
        invName = args[k + 1]

        if(not invExists(args[k + 1])) then
            print('Inventario de basura no encontrado, revisa la siguiente lista:')
            showInvs()
        else
            inventory_map['trash'] = invName
        end
    end
end

print('Configuración:\n' ..
'- items = ' .. inventory_map['items'] .. '\n' ..
'- trash = ' .. inventory_map['trash'] .. '\n')

if(not autoStart) then
    while(runIt == nil) do
        print('Continuar? (y/n)')
    
        r = read()
    
        if(r == 'y' or r == 'yes' or r == 's' or r == 'si') then
            runIt = true
            
        elseif(r == 'n' or r == 'no') then
            runIt = false
            
        else
            print('Opción no válida')
        end
    end
else
    runIt = true
end

if(runIt) then
    start()
end
