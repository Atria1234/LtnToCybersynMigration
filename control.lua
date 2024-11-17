require('init')

local depot_operation = '+'
local depot_default_value = 0x5
local depot_not_same_depo_value = 0x20
local depot_not_bypass_depo_value = 0x40

local station_operation = '/'
local station_not_requester_value = 0x1
local station_not_provider_value = 0x2
local station_not_whitelist_value = 0x4
local station_stack_threshold_value = 0x8
local station_inactivity_condition_value = 0x10

local function reconnect_wires(source_connector, target_conector)
    if source_connector then
        for _, connection in ipairs(source_connector.connections) do
            target_conector.connect_to(connection.target, false)
        end
    end
end

---@return data.MapPosition.struct[]
---@return data.MapPosition.struct[]
local function generate_possible_positions()
    local vertical_positions = {}
    local horizontal_positions = {}
    for x = -1.5, 1.5 do
        for y = -2, 2 do
            if math.abs(x) > 1 or math.abs(y) > 1 then
                table.insert(vertical_positions, {x = x, y = y})
            end
        end
    end
    for x = -2, 2 do
        for y = -1.5, 1.5 do
            if math.abs(x) > 1 or math.abs(y) > 1 then
                table.insert(horizontal_positions, {x = x, y = y})
            end
        end
    end
    local function compare(a, b)
        local min_a = math.min(math.abs(a.x), math.abs(a.y))
        local min_b = math.min(math.abs(b.x), math.abs(b.y))
        if min_a == min_b then
            local euclid_a = a.x * a.x + a.y * a.y
            local euclid_b = b.x * b.x + b.y * b.y
            return euclid_a < euclid_b
        end
        return min_a < min_b
    end
    table.sort(vertical_positions, compare)
    table.sort(horizontal_positions, compare)
    return vertical_positions, horizontal_positions
end

local vertical_positions, horizontal_positions = generate_possible_positions()
local positions = {
    [defines.direction.north] = vertical_positions,
    [defines.direction.east] = horizontal_positions,
}

---@param position data.MapPosition
---@param surface LuaSurface
---@param force LuaForce
---@return data.MapPosition | nil
---@return defines.direction | nil
local function find_non_colliding_position_in_box(position, surface, force)
    for direction, direction_positions in pairs(positions) do
        for _, diff in ipairs(direction_positions) do
            local cybersyn_position = { x = position.x + diff.x, y = position.y + diff.y }
            if surface.can_place_entity({ name = 'cybersyn-combinator', position = cybersyn_position, direction = direction, force = force }) then
                return cybersyn_position, direction
            end
        end
    end

    return nil, nil
end

local function migrate_stations_and_combinators()
    local same_depot = settings.global[LtnToCybersynMigration.mod_setting_names.same_depot].value
    local bypass_depot = settings.global[LtnToCybersynMigration.mod_setting_names.bypass_depot].value
    local inactivity_condition = settings.global[LtnToCybersynMigration.mod_setting_names.inactivity_condition].value

    for _, surface in pairs(game.surfaces) do
        for _, station in ipairs(surface.find_entities_filtered({ name = 'logistic-train-stop' })) do
            local station_inputs = surface.find_entities_filtered({ name = 'logistic-train-stop-input', area = {{station.position.x - 1, station.position.y - 1}, {station.position.x + 1, station.position.y + 1}} })
            if #station_inputs ~= 1 then
                game.print("Couldn't find exactly one logistic-train-stop-input near station [gps="..station.position.x..","..station.position.y.."]")
                goto continue
            end
            local station_outputs = surface.find_entities_filtered({ name = 'logistic-train-stop-output', area = {{station.position.x - 1, station.position.y - 1}, {station.position.x + 1, station.position.y + 1}} })
            if #station_outputs ~= 1 then
                game.print("Couldn't find exactly one logistic-train-stop-output near station [gps="..station.position.x..","..station.position.y.."]")
                goto continue
            end

            local combinator_position, combinator_direction = find_non_colliding_position_in_box(station.position, surface, station.force)
            if combinator_position == nil or combinator_position == nil then
                game.print("Can't find place for Cybersyn combinator near station [gps="..station.position.x..","..station.position.y.."]")
                goto continue
            end

            local ltn_combinator = nil
            for _, connection in ipairs(station_inputs[1].get_wire_connector(defines.wire_connector_id.circuit_red).connections) do
                if connection.target.owner.name == 'ltn-combinator' then
                    ltn_combinator = connection.target.owner
                end
            end
            for _, connection in ipairs(station_inputs[1].get_wire_connector(defines.wire_connector_id.circuit_green).connections) do
                if connection.target.owner.name == 'ltn-combinator' then
                    ltn_combinator = connection.target.owner
                end
            end

            if ltn_combinator == nil then
                game.print("Couldn't find ltn-combinator connected to input of station [gps="..station.position.x..","..station.position.y.."]")
                goto continue
            end

            station = surface.create_entity({
                name = 'train-stop',
                direction = station.direction,
                position = station.position,
                force = station.force,
                player = station.last_user,
                fast_replace = true,
                raise_built = true
            })
            local cybersyn_combinator = surface.create_entity({
                name = 'cybersyn-combinator',
                direction = combinator_direction,
                position = combinator_position,
                force = station.force,
                player = station.last_user,
                raise_built = true
            })

            local train_limit = station_inputs[1].get_signal({ type = 'virtual', name = 'ltn-max-trains' }, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
            if station.trains_limit == 4294967295 and train_limit > 0 then
                station.trains_limit = train_limit
            end

            local parameters = {
                first_signal = {
                    type = 'virtual',
                    name = 'signal-A'
                }
            }

            local network_id = station_inputs[1].get_signal({ type = 'virtual', name = 'ltn-network-id' }, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)

            local is_depot = station_inputs[1].get_signal({ type = 'virtual', name = 'ltn-depot' }, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green) > 0
            if is_depot then
                parameters.operation = depot_operation
                parameters.second_constant = depot_default_value
                if not same_depot then
                    parameters.second_constant = parameters.second_constant + depot_not_same_depo_value
                end
                if not bypass_depot then
                    parameters.second_constant = parameters.second_constant + depot_not_bypass_depo_value
                end
            else
                parameters.operation = station_operation
                parameters.second_constant = station_not_whitelist_value
            end

            local requester_threshold = station_inputs[1].get_signal({ type = 'virtual', name = 'ltn-requester-threshold' }, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
            local requester_stack_threshold = station_inputs[1].get_signal({ type = 'virtual', name = 'ltn-requester-stack-threshold' }, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
            local is_requester = requester_threshold > 0 and requester_threshold < 2147483647 or requester_stack_threshold > 0
            if not is_requester then
                parameters.second_constant = parameters.second_constant + station_not_requester_value
            end

            local provider_threshold = station_inputs[1].get_signal({ type = 'virtual', name = 'ltn-provider-threshold' }, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
            local provider_stack_threshold = station_inputs[1].get_signal({ type = 'virtual', name = 'ltn-provider-stack-threshold' }, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
            local is_provider = provider_threshold > 0 and provider_threshold < 2147483647 or provider_stack_threshold > 0
            if not is_provider then
                parameters.second_constant = parameters.second_constant + station_not_provider_value
            elseif inactivity_condition then
                parameters.second_constant = parameters.second_constant + station_inactivity_condition_value
            end

            local requester_priority = station_inputs[1].get_signal({ type = 'virtual', name = 'ltn-requester-priority' }, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
            local provider_priority = station_inputs[1].get_signal({ type = 'virtual', name = 'ltn-provider-priority' }, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
            local locked_slots = station_inputs[1].get_signal({ type = 'virtual', name = 'ltn-locked-slots' }, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)

            local control_signals = {}
            if is_requester then
                table.insert(control_signals, {
                    value = {
                        type = 'virtual',
                        name = 'cybersyn-request-threshold',
                        quality = 'normal'
                    },
                    min = (requester_threshold > 0 and requester_threshold < 2147483647) and requester_threshold or requester_stack_threshold
                })
                if requester_stack_threshold > 0 then
                    parameters.second_constant = parameters.second_constant + station_stack_threshold_value
                end
            end

            if locked_slots > 0 then
                table.insert(control_signals, {
                    value = {
                        type = 'virtual',
                        name = 'cybersyn-locked-slots',
                        quality = 'normal'
                    },
                    min = locked_slots
                })
            end

            if is_requester and requester_priority ~= 0 then
                table.insert(control_signals, {
                    value = {
                        type = 'virtual',
                        name = 'cybersyn-priority',
                        quality = 'normal'
                    },
                    min = requester_priority
                })
            elseif is_provider and provider_priority ~= 0 then
                table.insert(control_signals, {
                    value = {
                        type = 'virtual',
                        name = 'cybersyn-priority',
                        quality = 'normal'
                    },
                    min = provider_priority
                })
            end

            local ltn_combinator_behaviour = ltn_combinator.get_control_behavior()
            local control_section = ltn_combinator_behaviour.get_section(1)
            local request_signals = {}
            for _, filter in ipairs(control_section.filters) do
                if filter.value.type ~= 'virtual' then
                    table.insert(request_signals, filter)
                end
            end

            for i = ltn_combinator_behaviour.sections_count, 1, -1 do
                ltn_combinator_behaviour.remove_section(i)
            end
            -- control section
            ltn_combinator_behaviour.add_section().filters = control_signals
            -- request section
            ltn_combinator_behaviour.add_section().filters = request_signals
            -- network section
            ltn_combinator_behaviour.add_section().filters = {
                {
                    value = {
                        type = 'virtual',
                        name = 'signal-A',
                        quality = 'normal'
                    },
                    min = network_id
                }
            }

            surface.create_entity({
                name = script.active_mods['cybersyn-combinator'] and 'cybersyn-constant-combinator' or 'constant-combinator',
                position = ltn_combinator.position,
                direction = ltn_combinator.direction,
                force = ltn_combinator.force,
                player = ltn_combinator.last_user,
                fast_replace = true,
                raise_built = true
            })

            cybersyn_combinator.get_control_behavior().parameters = parameters

            reconnect_wires(
                station_inputs[1].get_wire_connector(defines.wire_connector_id.circuit_red),
                cybersyn_combinator.get_wire_connector(defines.wire_connector_id.combinator_input_red, true)
            )
            reconnect_wires(
                station_inputs[1].get_wire_connector(defines.wire_connector_id.circuit_green),
                cybersyn_combinator.get_wire_connector(defines.wire_connector_id.combinator_input_green, true)
            )
            station_inputs[1].destroy()

            reconnect_wires(
                station_outputs[1].get_wire_connector(defines.wire_connector_id.circuit_red),
                cybersyn_combinator.get_wire_connector(defines.wire_connector_id.combinator_output_red, true)
            )
            reconnect_wires(
                station_outputs[1].get_wire_connector(defines.wire_connector_id.circuit_green),
                cybersyn_combinator.get_wire_connector(defines.wire_connector_id.combinator_output_green, true)
            )
            station_outputs[1].destroy()

            ::continue::
        end
    end
end

local function toggle_trains()
    for _, train in ipairs(game.train_manager.get_trains({ is_manual = false })) do
        train.manual_mode = true
        train.manual_mode = false
    end
end

--- @param event EventData.on_lua_shortcut
local function on_shortcut(event)
    if event.prototype_name == LtnToCybersynMigration.shortcut_names.migrate_station then
        migrate_stations_and_combinators()
    elseif event.prototype_name == LtnToCybersynMigration.shortcut_names.toggle_trains then
        toggle_trains()
    end
end

script.on_event('on_lua_shortcut', on_shortcut)
