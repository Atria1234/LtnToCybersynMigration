require('init')

data:extend({
    {
        name = LtnToCybersynMigration.mod_setting_names.same_depot,
        type = 'bool-setting',
        setting_type = 'runtime-global',
        default_value = false
    },
    {
        name = LtnToCybersynMigration.mod_setting_names.bypass_depot,
        type = 'bool-setting',
        setting_type = 'runtime-global',
        default_value = true
    },
    {
        name = LtnToCybersynMigration.mod_setting_names.inactivity_condition,
        type = 'bool-setting',
        setting_type = 'runtime-global',
        default_value = true
    },
})