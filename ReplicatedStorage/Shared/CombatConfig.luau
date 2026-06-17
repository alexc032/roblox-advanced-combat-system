local CombatConfig = {
    StunDuration = 0.8, 

    Attacks = {
        ["Punch"] = {
            Damage       = 2,
            Cooldown     = 0.5,
            ActiveTime   = 0.3,
            HitboxSize   = Vector3.new(2, 2, 2),
            HitboxOffset = CFrame.new(0, 0, -3),
        },
    },

    Block = {
        Stun = 1,
		Key  = "F",
		ParryWindow = 0.25,
    },
}

return CombatConfig