package me.gabber235.typewriter.snippets

import kotlin.properties.ReadOnlyProperty
import kotlin.reflect.KClass
import kotlin.reflect.KProperty


inline fun <reified T : Any> snippet(path: String, defaultValue: T): ReadOnlyProperty<Nothing?, T> {
	return snippet(path, T::class, defaultValue)
}

fun <T : Any> snippet(path: String, klass: KClass<T>, defaultValue: T): ReadOnlyProperty<Nothing?, T> {
	return Snippet(path, klass, defaultValue)
}

class Snippet<T : Any>(private val path: String, private val klass: KClass<T>, private val defaultValue: T) :
	ReadOnlyProperty<Nothing?, T> {

	init {
		SnippetDatabase.registerSnippet(path, defaultValue)
	}

	override fun getValue(thisRef: Nothing?, property: KProperty<*>): T {
		return SnippetDatabase.getSnippet(path, klass, defaultValue)
	}
}