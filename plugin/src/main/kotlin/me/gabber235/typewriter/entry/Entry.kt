package me.gabber235.typewriter.entry

import com.google.gson.annotations.SerializedName
import me.gabber235.typewriter.adapters.Tags
import me.gabber235.typewriter.adapters.modifiers.*
import me.gabber235.typewriter.entry.entries.*
import me.gabber235.typewriter.facts.Fact

interface Entry {
	val id: String
	val name: String
}

@Tags("static")
interface StaticEntry : Entry

@Tags("trigger")
interface TriggerEntry : Entry {
	@Triggers
	@EntryIdentifier(TriggerableEntry::class)
	@Help("The entries that will be fired after this entry.")
	val triggers: List<String>
}

@Tags("triggerable")
interface TriggerableEntry : TriggerEntry {
	@Help("The criteria that must be met before this entry is triggered")
	val criteria: List<Criteria>

	@Help("The modifiers that will be applied when this entry is triggered")
	val modifiers: List<Modifier>
}

enum class CriteriaOperator {
	@SerializedName("==")
	EQUALS,

	@SerializedName("<")
	LESS_THAN,

	@SerializedName(">")
	GREATER_THAN,

	@SerializedName("<=")
	LESS_THAN_OR_EQUALS,

	@SerializedName(">=")
	GREATER_THAN_OR_EQUAL,
}

data class Criteria(
	@Help("The fact to check before triggering the entry")
	@EntryIdentifier(ReadableFactEntry::class)
	val fact: String,
	@Help("The operator to use when comparing the fact value to the criteria value")
	val operator: CriteriaOperator,
	@Help("The value to compare the fact value to")
	val value: Int,
) {
	fun isValid(fact: Fact?): Boolean {
		val value = fact?.value ?: 0
		return when (operator) {
			CriteriaOperator.EQUALS                -> value == this.value
			CriteriaOperator.LESS_THAN             -> value < this.value
			CriteriaOperator.GREATER_THAN          -> value > this.value
			CriteriaOperator.LESS_THAN_OR_EQUALS   -> value <= this.value
			CriteriaOperator.GREATER_THAN_OR_EQUAL -> value >= this.value
		}
	}
}

enum class ModifierOperator {
	@SerializedName("=")
	SET,

	@SerializedName("+")
	ADD;
}

data class Modifier(
	@Help("The fact to modify when the entry is triggered")
	@EntryIdentifier(WritableFactEntry::class)
	val fact: String,
	@Help("The operator to use when modifying the fact value")
	val operator: ModifierOperator,
	@Help("The value to modify the fact value by")
	val value: Int,
)
