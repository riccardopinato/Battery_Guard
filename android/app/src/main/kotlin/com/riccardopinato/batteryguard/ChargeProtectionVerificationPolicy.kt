package com.riccardopinato.batteryguard

object ChargeProtectionVerificationPolicy {
    private const val TRANSITION_WINDOW_MS = 3 * 60 * 1000L
    private const val DIRECT_COMMAND_WINDOW_MS = 15 * 1000L

    data class PreviousObservation(
        val enabled: Boolean,
        val targetLevel: Int,
        val level: Int,
        val isPlugged: Boolean,
        val isCharging: Boolean,
        val observedAt: Long,
        val verification: String,
    )

    data class CommandEvidence(
        val sentAt: Long,
        val targetLevel: Int,
    )

    fun evaluate(
        enabled: Boolean,
        targetLevel: Int,
        level: Int,
        isPlugged: Boolean,
        isCharging: Boolean,
        capabilityMode: String,
        now: Long,
        previous: PreviousObservation?,
        command: CommandEvidence?,
    ): String {
        val target = targetLevel.coerceIn(70, 100)

        if (!enabled) return "disabled"
        if (target >= 100) return "not_applicable"
        if (!isPlugged) return "unplugged"
        if (level < 0) return "pending"
        if (level < target) return "below_target"
        if (isCharging) return "still_charging"

        val sameTarget =
            previous != null &&
                previous.enabled &&
                previous.targetLevel == target

        if (
            sameTarget &&
            previous!!.verification == "verified_stopped" &&
            previous.isPlugged &&
            !previous.isCharging &&
            previous.level >= target
        ) {
            return "verified_stopped"
        }

        if (capabilityMode == "alert_only") {
            return "unsupported"
        }

        val freshTransition =
            sameTarget &&
                previous!!.isPlugged &&
                previous.isCharging &&
                previous.observedAt > 0L &&
                now >= previous.observedAt &&
                now - previous.observedAt <= TRANSITION_WINDOW_MS

        if (!freshTransition) return "pending"

        if (capabilityMode == "direct_control") {
            val commandFresh =
                command != null &&
                    command.targetLevel == target &&
                    command.sentAt > 0L &&
                    now >= command.sentAt &&
                    now - command.sentAt <= DIRECT_COMMAND_WINDOW_MS
            return if (commandFresh) "verified_stopped" else "pending"
        }

        return if (capabilityMode == "system_setting") {
            "verified_stopped"
        } else {
            "pending"
        }
    }
}
