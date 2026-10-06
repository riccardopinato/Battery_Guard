package com.riccardopinato.batteryguard

import android.content.Context
import java.util.Locale

object NativeStrings {
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

    fun monitorChannelName(context: Context) = pick(
        context,
        "Battery Guard monitoring",
        "Monitoraggio Battery Guard",
        "Monitorización Battery Guard",
        "Surveillance Battery Guard",
        "Battery Guard Überwachung",
        "Monitorização Battery Guard",
    )

    fun monitorChannelDescription(context: Context) = pick(
        context,
        "Persistent notification while Battery Guard monitors the battery",
        "Notifica persistente mentre Battery Guard controlla la batteria",
        "Notificación persistente mientras Battery Guard controla la batería",
        "Notification persistante pendant la surveillance de la batterie",
        "Dauerhafte Benachrichtigung während der Batterieüberwachung",
        "Notificação persistente durante a monitorização da bateria",
    )

    fun alertChannelName(context: Context) = pick(
        context,
        "Battery alerts",
        "Avvisi batteria",
        "Avisos de batería",
        "Alertes batterie",
        "Batteriewarnungen",
        "Alertas de bateria",
    )

    fun alertChannelDescription(context: Context) = pick(
        context,
        "Temperature and charging alerts",
        "Avvisi generali di temperatura e ricarica",
        "Avisos generales de temperatura y carga",
        "Alertes générales de température et de charge",
        "Allgemeine Temperatur- und Ladewarnungen",
        "Alertas gerais de temperatura e carregamento",
    )

    fun highChannelName(context: Context) = pick(
        context,
        "Upper charging limit",
        "Limite superiore di ricarica",
        "Límite superior de carga",
        "Limite haute de charge",
        "Obere Ladegrenze",
        "Limite superior de carregamento",
    )

    fun highChannelDescription(context: Context) = pick(
        context,
        "Dedicated sound when it is time to unplug the charger",
        "Suono dedicato quando puoi scollegare il caricatore",
        "Sonido dedicado cuando es hora de desconectar el cargador",
        "Son dédié lorsqu'il est temps de débrancher le chargeur",
        "Eigener Ton, wenn das Ladegerät abgezogen werden sollte",
        "Som dedicado quando é hora de desligar o carregador",
    )

    fun lowChannelName(context: Context) = pick(
        context,
        "Lower battery limit",
        "Limite inferiore batteria",
        "Límite inferior de batería",
        "Limite basse de batterie",
        "Untere Batteriegrenze",
        "Limite inferior da bateria",
    )

    fun lowChannelDescription(context: Context) = pick(
        context,
        "Dedicated sound when it is time to charge",
        "Suono dedicato quando è il momento di mettere in carica",
        "Sonido dedicado cuando es hora de cargar",
        "Son dédié lorsqu'il est temps de recharger",
        "Eigener Ton, wenn geladen werden sollte",
        "Som dedicado quando é hora de carregar",
    )

    fun quietChannelName(context: Context) = pick(
        context,
        "Silent night alerts",
        "Avvisi silenziosi notturni",
        "Avisos nocturnos silenciosos",
        "Alertes nocturnes silencieuses",
        "Stille Nachtwarnungen",
        "Alertas noturnos silenciosos",
    )

    fun quietChannelDescription(context: Context) = pick(
        context,
        "Visible alerts without sound or vibration during night mode",
        "Avvisi visibili ma silenziosi durante la modalità notte",
        "Avisos visibles sin sonido ni vibración durante el modo nocturno",
        "Alertes visibles sans son ni vibration pendant le mode nuit",
        "Sichtbare Warnungen ohne Ton oder Vibration im Nachtmodus",
        "Alertas visíveis sem som ou vibração durante o modo noturno",
    )

    fun monitorTitle(context: Context) = pick(
        context,
        "Battery Guard active",
        "Battery Guard attivo",
        "Battery Guard activo",
        "Battery Guard actif",
        "Battery Guard aktiv",
        "Battery Guard ativo",
    )

    fun monitoring(context: Context) = pick(
        context,
        "Monitoring",
        "Monitoraggio",
        "Monitorización",
        "Surveillance",
        "Überwachung",
        "Monitorização",
    )

    fun disable(context: Context) = pick(
        context, "Disable", "Disattiva", "Desactivar", "Désactiver", "Deaktivieren", "Desativar",
    )

    fun target80(context: Context) = pick(
        context, "Target 80%", "Target 80%", "Objetivo 80%", "Cible 80%", "Ziel 80%", "Meta 80%",
    )

    fun adaptiveTemperatureTitle(context: Context) = pick(
        context,
        "Temperature above your usual level",
        "Temperatura sopra la tua media",
        "Temperatura por encima de tu media",
        "Température au-dessus de votre moyenne",
        "Temperatur über deinem Durchschnitt",
        "Temperatura acima da sua média",
    )

    fun adaptiveTemperatureMessage(
        context: Context,
        temperature: Double,
        baseline: Double,
    ) = pick(
        context,
        "This charge is at ${"%.1f".format(temperature)} °C, about 4 °C or more above your usual maximum (${"%.1f".format(baseline)} °C).",
        "Questa ricarica è a ${"%.1f".format(temperature)} °C, circa 4 °C o più sopra la tua massima abituale (${"%.1f".format(baseline)} °C).",
        "Esta carga está a ${"%.1f".format(temperature)} °C, unos 4 °C o más por encima de tu máximo habitual (${"%.1f".format(baseline)} °C).",
        "Cette charge est à ${"%.1f".format(temperature)} °C, environ 4 °C ou plus au-dessus de votre maximum habituel (${"%.1f".format(baseline)} °C).",
        "Dieser Ladevorgang liegt bei ${"%.1f".format(temperature)} °C, etwa 4 °C oder mehr über deinem üblichen Maximum (${"%.1f".format(baseline)} °C).",
        "Este carregamento está a ${"%.1f".format(temperature)} °C, cerca de 4 °C ou mais acima do máximo habitual (${"%.1f".format(baseline)} °C).",
    )

    fun adaptiveSlowTitle(context: Context) = pick(
        context,
        "Charging slower than usual",
        "Ricarica più lenta del solito",
        "Carga más lenta de lo habitual",
        "Charge plus lente que d'habitude",
        "Laden langsamer als üblich",
        "Carregamento mais lento do que o habitual",
    )

    fun adaptiveSlowMessage(context: Context, rate: Double, baseline: Double) = pick(
        context,
        "Current speed about ${"%.1f".format(rate)} %/h versus your ${"%.1f".format(baseline)} %/h average with this source.",
        "Velocità attuale circa ${"%.1f".format(rate)} %/h contro una media personale di ${"%.1f".format(baseline)} %/h con questa sorgente.",
        "Velocidad actual de ${"%.1f".format(rate)} %/h frente a tu media de ${"%.1f".format(baseline)} %/h con esta fuente.",
        "Vitesse actuelle d'environ ${"%.1f".format(rate)} %/h contre une moyenne de ${"%.1f".format(baseline)} %/h avec cette source.",
        "Aktuell etwa ${"%.1f".format(rate)} %/h gegenüber durchschnittlich ${"%.1f".format(baseline)} %/h mit dieser Quelle.",
        "Velocidade atual de cerca de ${"%.1f".format(rate)} %/h contra uma média de ${"%.1f".format(baseline)} %/h com esta fonte.",
    )

    fun rapidTemperatureTitle(context: Context) = pick(
        context,
        "Temperature rising quickly",
        "Temperatura in rapido aumento",
        "Temperatura subiendo rápidamente",
        "Température en hausse rapide",
        "Temperatur steigt schnell",
        "Temperatura a subir rapidamente",
    )

    fun rapidTemperatureMessage(context: Context, temperature: Double) = pick(
        context,
        "Battery temperature quickly reached ${"%.1f".format(temperature)} °C during this charge.",
        "La batteria è salita rapidamente fino a ${"%.1f".format(temperature)} °C durante questa ricarica.",
        "La batería alcanzó rápidamente ${"%.1f".format(temperature)} °C durante esta carga.",
        "La batterie a rapidement atteint ${"%.1f".format(temperature)} °C pendant cette charge.",
        "Die Batterie erreichte während dieses Ladevorgangs schnell ${"%.1f".format(temperature)} °C.",
        "A bateria atingiu rapidamente ${"%.1f".format(temperature)} °C durante este carregamento.",
    )

    fun slowChargingTitle(context: Context) = pick(
        context,
        "Unusually slow charging",
        "Ricarica insolitamente lenta",
        "Carga inusualmente lenta",
        "Charge anormalement lente",
        "Ungewöhnlich langsames Laden",
        "Carregamento invulgarmente lento",
    )

    fun slowChargingMessage(context: Context, rate: Double) = pick(
        context,
        "Average speed is about ${"%.1f".format(rate)} %/h. Check cable and charger.",
        "Velocità media circa ${"%.1f".format(rate)} %/h. Verifica cavo e alimentatore.",
        "Velocidad media de ${"%.1f".format(rate)} %/h. Comprueba cable y cargador.",
        "Vitesse moyenne d'environ ${"%.1f".format(rate)} %/h. Vérifiez le câble et le chargeur.",
        "Durchschnittlich etwa ${"%.1f".format(rate)} %/h. Kabel und Ladegerät prüfen.",
        "Velocidade média de cerca de ${"%.1f".format(rate)} %/h. Verifique cabo e carregador.",
    )

    fun lowTitle(context: Context, level: Int) = pick(
        context, "Battery at $level%", "Batteria al $level%", "Batería al $level%", "Batterie à $level%", "Batterie bei $level%", "Bateria a $level%",
    )

    fun lowMessage(context: Context, limit: Int) = pick(
        context,
        "You reached your $limit% lower limit. This is a good time to charge.",
        "Hai raggiunto il limite inferiore del $limit%. È un buon momento per mettere il telefono in carica.",
        "Has alcanzado el límite inferior del $limit%. Es un buen momento para cargar.",
        "Vous avez atteint la limite basse de $limit%. C'est un bon moment pour recharger.",
        "Du hast die untere Grenze von $limit% erreicht. Jetzt ist ein guter Zeitpunkt zum Laden.",
        "Atingiu o limite inferior de $limit%. É uma boa altura para carregar.",
    )

    fun highTitle(context: Context, level: Int) = pick(
        context, "Charge limit reached: $level%", "Soglia raggiunta: $level%", "Límite alcanzado: $level%", "Limite atteinte : $level%", "Ladegrenze erreicht: $level%", "Limite atingido: $level%",
    )

    fun highMessage(context: Context, target: Int) = if (target < 100) {
        pick(
            context,
            "Battery reached $target%. You can unplug the charger.",
            "La batteria ha raggiunto il $target%. Puoi scollegare il caricatore.",
            "La batería ha alcanzado el $target%. Puedes desconectar el cargador.",
            "La batterie a atteint $target%. Vous pouvez débrancher le chargeur.",
            "Die Batterie hat $target% erreicht. Du kannst das Ladegerät abziehen.",
            "A bateria atingiu $target%. Pode desligar o carregador.",
        )
    } else {
        pick(
            context,
            "Battery reached 100%.",
            "La batteria ha raggiunto il 100%.",
            "La batería ha alcanzado el 100%.",
            "La batterie a atteint 100%.",
            "Die Batterie hat 100% erreicht.",
            "A bateria atingiu 100%.",
        )
    }

    fun fullTitle(context: Context) = pick(
        context, "Charge complete", "Carica completa", "Carga completa", "Charge complète", "Vollständig geladen", "Carga completa",
    )

    fun fullMessage(context: Context) = pick(
        context,
        "Battery is at 100%. You can unplug the charger.",
        "La batteria è al 100%. Puoi scollegare il caricatore.",
        "La batería está al 100%. Puedes desconectar el cargador.",
        "La batterie est à 100%. Vous pouvez débrancher le chargeur.",
        "Die Batterie ist bei 100%. Du kannst das Ladegerät abziehen.",
        "A bateria está a 100%. Pode desligar o carregador.",
    )

    fun temperatureTitle(context: Context) = pick(
        context, "High battery temperature", "Temperatura batteria elevata", "Temperatura de batería alta", "Température batterie élevée", "Hohe Batterietemperatur", "Temperatura da bateria elevada",
    )

    fun temperatureMessage(context: Context, temperature: Double) = pick(
        context,
        "Battery is at ${"%.1f".format(temperature)} °C. Check the phone and charging conditions.",
        "La batteria è a ${"%.1f".format(temperature)} °C. Controlla il telefono e la ricarica.",
        "La batería está a ${"%.1f".format(temperature)} °C. Revisa el teléfono y la carga.",
        "La batterie est à ${"%.1f".format(temperature)} °C. Vérifiez le téléphone et la charge.",
        "Die Batterie ist bei ${"%.1f".format(temperature)} °C. Telefon und Ladevorgang prüfen.",
        "A bateria está a ${"%.1f".format(temperature)} °C. Verifique o telefone e o carregamento.",
    )

    fun unplugTitle(context: Context) = pick(
        context, "Charger disconnected", "Cavo scollegato", "Cargador desconectado", "Chargeur débranché", "Ladegerät getrennt", "Carregador desligado",
    )

    fun unplugMessage(context: Context, level: Int) = pick(
        context,
        "Charging stopped at $level%.",
        "Ricarica interrotta con batteria al $level%.",
        "Carga interrumpida con la batería al $level%.",
        "Charge interrompue avec la batterie à $level%.",
        "Ladevorgang bei $level% beendet.",
        "Carregamento interrompido com a bateria a $level%.",
    )

    fun testGeneralTitle(context: Context) = pick(
        context, "Battery Guard works", "Battery Guard funziona", "Battery Guard funciona", "Battery Guard fonctionne", "Battery Guard funktioniert", "Battery Guard funciona",
    )

    fun testGeneralMessage(context: Context) = pick(
        context, "This is a test alert.", "Questo è un avviso di prova.", "Este es un aviso de prueba.", "Ceci est une alerte de test.", "Dies ist eine Testwarnung.", "Este é um alerta de teste.",
    )

    fun testHighTitle(context: Context) = pick(
        context, "Upper-limit sound", "Suono limite superiore", "Sonido del límite superior", "Son de limite haute", "Ton der oberen Grenze", "Som do limite superior",
    )

    fun testHighMessage(context: Context) = pick(
        context,
        "This is the sound used when it is time to unplug.",
        "Questo è il suono usato quando puoi scollegare il caricatore.",
        "Este es el sonido usado cuando puedes desconectar el cargador.",
        "C'est le son utilisé lorsqu'il est temps de débrancher.",
        "Dieser Ton wird verwendet, wenn das Ladegerät abgezogen werden sollte.",
        "Este é o som usado quando é hora de desligar.",
    )

    fun testLowTitle(context: Context) = pick(
        context, "Lower-limit sound", "Suono limite inferiore", "Sonido del límite inferior", "Son de limite basse", "Ton der unteren Grenze", "Som do limite inferior",
    )

    fun testLowMessage(context: Context) = pick(
        context,
        "This is the sound used when it is time to charge.",
        "Questo è il suono usato quando è il momento di mettere in carica.",
        "Este es el sonido usado cuando es hora de cargar.",
        "C'est le son utilisé lorsqu'il est temps de recharger.",
        "Dieser Ton wird verwendet, wenn geladen werden sollte.",
        "Este é o som usado quando é hora de carregar.",
    )
}
