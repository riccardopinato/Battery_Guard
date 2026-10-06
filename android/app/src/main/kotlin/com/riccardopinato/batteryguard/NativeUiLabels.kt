package com.riccardopinato.batteryguard

import android.content.Context
import java.util.Locale

object NativeUiLabels {
    private val supported = setOf("en", "it", "es", "fr", "de", "pt")

    private fun language(context: Context): String {
        val override = context.getSharedPreferences(
            "battery_guard_app_state",
            Context.MODE_PRIVATE,
        ).getString("localeOverride", null)
        val raw = override?.lowercase(Locale.ROOT)
            ?: Locale.getDefault().language.lowercase(Locale.ROOT)
        return if (raw in supported) raw else "en"
    }

    private fun pick(
        context: Context,
        en: String,
        it: String,
        es: String,
        fr: String,
        de: String,
        pt: String,
    ): String = when (language(context)) {
        "it" -> it
        "es" -> es
        "fr" -> fr
        "de" -> de
        "pt" -> pt
        else -> en
    }

    fun status(context: Context, raw: String): String {
        return when (raw.trim().lowercase(Locale.ROOT)) {
            "in carica", "charging" -> pick(
                context, "Charging", "In carica", "Cargando", "En charge", "Wird geladen", "A carregar",
            )
            "in uso", "discharging" -> pick(
                context, "In use", "In uso", "En uso", "En utilisation", "In Benutzung", "Em utilização",
            )
            "carica completa", "full" -> pick(
                context, "Full", "Carica completa", "Carga completa", "Charge complète", "Voll geladen", "Carga completa",
            )
            "non in carica", "not charging" -> pick(
                context, "Not charging", "Non in carica", "No cargando", "Pas en charge", "Wird nicht geladen", "Não está a carregar",
            )
            else -> pick(
                context, "Unknown", "Sconosciuto", "Desconocido", "Inconnu", "Unbekannt", "Desconhecido",
            )
        }
    }

    fun plugType(context: Context, raw: String): String {
        return when (raw.trim().lowercase(Locale.ROOT)) {
            "caricatore ac", "ac charger", "ac" -> pick(
                context, "AC charger", "Caricatore AC", "Cargador AC", "Chargeur secteur", "Netzladegerät", "Carregador AC",
            )
            "usb" -> "USB"
            "ricarica wireless", "wireless charging" -> pick(
                context, "Wireless charging", "Ricarica wireless", "Carga inalámbrica", "Charge sans fil", "Kabelloses Laden", "Carregamento sem fios",
            )
            "dock" -> "Dock"
            else -> pick(
                context, "None", "Nessuno", "Ninguna", "Aucune", "Keine", "Nenhuma",
            )
        }
    }

    fun protection(context: Context, enabled: Boolean): String {
        return if (enabled) {
            pick(
                context,
                "Protection ON",
                "Protezione ON",
                "Protección ON",
                "Protection ON",
                "Schutz ON",
                "Proteção ON",
            )
        } else {
            pick(
                context,
                "Protection OFF",
                "Protezione OFF",
                "Protección OFF",
                "Protection OFF",
                "Schutz OFF",
                "Proteção OFF",
            )
        }
    }

    fun target(context: Context, level: Int): String = pick(
        context,
        "Target $level%",
        "Target $level%",
        "Objetivo $level%",
        "Cible $level%",
        "Ziel $level%",
        "Meta $level%",
    )

    fun tileDescription(context: Context, enabled: Boolean): String {
        return if (enabled) {
            pick(
                context,
                "Battery Guard active",
                "Battery Guard attivo",
                "Battery Guard activo",
                "Battery Guard actif",
                "Battery Guard aktiv",
                "Battery Guard ativo",
            )
        } else {
            pick(
                context,
                "Battery Guard disabled",
                "Battery Guard disattivato",
                "Battery Guard desactivado",
                "Battery Guard désactivé",
                "Battery Guard deaktiviert",
                "Battery Guard desativado",
            )
        }
    }
}
