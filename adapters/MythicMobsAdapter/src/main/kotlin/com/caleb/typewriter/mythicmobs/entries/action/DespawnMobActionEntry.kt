package com.caleb.typewriter.mythicmobs.entries.action

import io.lumine.mythic.bukkit.BukkitAdapter
import io.lumine.mythic.bukkit.MythicBukkit
import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.entry.Criteria
import me.gabber235.typewriter.entry.Modifier
import me.gabber235.typewriter.entry.entries.ActionEntry
import me.gabber235.typewriter.utils.Icons
import org.bukkit.entity.Player
import java.util.*


@Entry("despawn_mythicmobs_mob", "Despawn a mob from mythicmobs", Colors.ORANGE, Icons.HANDSHAKE)
class DespawnMobActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<String> = emptyList(),
    @Help("The mob's name")
    private val mob: String = "",
) : ActionEntry {
    override fun execute(player: Player) {
        super.execute(player)

        val mob = MythicBukkit.inst().mobManager.getMythicMob(mob) ?: return
        for (activeMob in MythicBukkit.inst().mobManager.activeMobs) {
            if (activeMob.name.equals(mob)) activeMob.despawn();
        }
    }
}