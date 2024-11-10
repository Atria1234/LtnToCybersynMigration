LtnToCybersynMigration = {}

LtnToCybersynMigration.mod_name = 'LtnToCybersynMigration'

function LtnToCybersynMigration.prefix_with_mod_name(value)
    return LtnToCybersynMigration.mod_name..'__'..value
end

LtnToCybersynMigration.mod_setting_names = {
    same_depot = LtnToCybersynMigration.prefix_with_mod_name('same-depot'),
    bypass_depot = LtnToCybersynMigration.prefix_with_mod_name('bypass-depot'),
    inactivity_condition = LtnToCybersynMigration.prefix_with_mod_name('inactivity-condition')
}

LtnToCybersynMigration.shortcut_names = {
    migrate_station = LtnToCybersynMigration.prefix_with_mod_name('migrate-stations'),
    toggle_trains = LtnToCybersynMigration.prefix_with_mod_name('toggle-trains')
}
