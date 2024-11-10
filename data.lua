require('init')

local ltn_stop = table.deepcopy(data.raw["train-stop"]["train-stop"])
ltn_stop.name = "logistic-train-stop"

local ltn_input = table.deepcopy(data.raw["lamp"]["small-lamp"])
ltn_input.name = "logistic-train-stop-input"
local ltn_output = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
ltn_output.name = "logistic-train-stop-output"
local ltn_combinator = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
ltn_combinator.name = "ltn-combinator"

data:extend({
    ltn_stop,
    ltn_input,
    ltn_output,
    ltn_combinator,
    {
        type = "virtual-signal",
        name = "ltn-depot",
        icon = "__base__/graphics/icons/signal/signal_D.png"
    },
    {
        type = "virtual-signal",
        name = "ltn-depot-priority",
        icon = "__base__/graphics/icons/signal/signal_D.png"
    },
    {
        type = "virtual-signal",
        name = "ltn-network-id",
        icon = "__base__/graphics/icons/signal/signal_N.png"
    },
    {
        type = "virtual-signal",
        name = "ltn-max-trains",
        icon = "__base__/graphics/icons/signal/signal_T.png"
    },
    {
        type = "virtual-signal",
        name = "ltn-provider-threshold",
        icon = "__base__/graphics/icons/signal/signal_P.png"
    },
    {
        type = "virtual-signal",
        name = "ltn-provider-stack-threshold",
        icon = "__base__/graphics/icons/signal/signal_P.png"
    },
    {
        type = "virtual-signal",
        name = "ltn-provider-priority",
        icon = "__base__/graphics/icons/signal/signal_P.png"
    },
    {
        type = "virtual-signal",
        name = "ltn-locked-slots",
        icon = "__base__/graphics/icons/signal/signal_L.png"
    },
    {
        type = "virtual-signal",
        name = "ltn-requester-threshold",
        icon = "__base__/graphics/icons/signal/signal_R.png"
    },
    {
        type = "virtual-signal",
        name = "ltn-requester-stack-threshold",
        icon = "__base__/graphics/icons/signal/signal_R.png"
    },
    {
        type = "virtual-signal",
        name = "ltn-requester-priority",
        icon = "__base__/graphics/icons/signal/signal_R.png"
    },

    {
        type = "shortcut",
        name = LtnToCybersynMigration.shortcut_names.migrate_station,
        action = "lua",
        icon = "__base__/graphics/icons/signal/signal_M.png",
        icon_size = 64,
        small_icon = "__base__/graphics/icons/signal/signal_M.png",
        small_icon_size = 64
    },
    {
        type = "shortcut",
        name = LtnToCybersynMigration.shortcut_names.toggle_trains,
        action = "lua",
        icon = "__base__/graphics/icons/signal/signal_T.png",
        icon_size = 64,
        small_icon = "__base__/graphics/icons/signal/signal_T.png",
        small_icon_size = 64
    }
})
