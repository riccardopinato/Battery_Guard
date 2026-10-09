package com.riccardopinato.batteryguard

import org.junit.Assert.assertEquals
import org.junit.Test

class ChargeProtectionVerificationPolicyTest {
    private val now = 1_000_000L

    private fun previous(
        charging: Boolean,
        plugged: Boolean = true,
        level: Int = 79,
        target: Int = 80,
        observedAt: Long = now - 60_000L,
        verification: String = "below_target",
    ) = ChargeProtectionVerificationPolicy.PreviousObservation(
        enabled = true,
        targetLevel = target,
        level = level,
        isPlugged = plugged,
        isCharging = charging,
        observedAt = observedAt,
        verification = verification,
    )

    @Test
    fun staticNotChargingSnapshotDoesNotVerify() {
        val result = ChargeProtectionVerificationPolicy.evaluate(
            enabled = true,
            targetLevel = 80,
            level = 80,
            isPlugged = true,
            isCharging = false,
            capabilityMode = "system_setting",
            now = now,
            previous = null,
            command = null,
        )
        assertEquals("pending", result)
    }

    @Test
    fun systemSettingRequiresObservedChargingToNotChargingTransition() {
        val result = ChargeProtectionVerificationPolicy.evaluate(
            enabled = true,
            targetLevel = 80,
            level = 80,
            isPlugged = true,
            isCharging = false,
            capabilityMode = "system_setting",
            now = now,
            previous = previous(charging = true),
            command = null,
        )
        assertEquals("verified_stopped", result)
    }

    @Test
    fun staleTransitionDoesNotVerify() {
        val result = ChargeProtectionVerificationPolicy.evaluate(
            enabled = true,
            targetLevel = 80,
            level = 80,
            isPlugged = true,
            isCharging = false,
            capabilityMode = "system_setting",
            now = now,
            previous = previous(
                charging = true,
                observedAt = now - 10 * 60_000L,
            ),
            command = null,
        )
        assertEquals("pending", result)
    }

    @Test
    fun alertOnlyNeverVerifiesAChargeStop() {
        val result = ChargeProtectionVerificationPolicy.evaluate(
            enabled = true,
            targetLevel = 80,
            level = 80,
            isPlugged = true,
            isCharging = false,
            capabilityMode = "alert_only",
            now = now,
            previous = previous(charging = true),
            command = null,
        )
        assertEquals("unsupported", result)
    }

    @Test
    fun directControlNeedsFreshCommandAndFreshReadbackTransition() {
        val noCommand = ChargeProtectionVerificationPolicy.evaluate(
            enabled = true,
            targetLevel = 80,
            level = 80,
            isPlugged = true,
            isCharging = false,
            capabilityMode = "direct_control",
            now = now,
            previous = previous(charging = true),
            command = null,
        )
        assertEquals("pending", noCommand)

        val withCommand = ChargeProtectionVerificationPolicy.evaluate(
            enabled = true,
            targetLevel = 80,
            level = 80,
            isPlugged = true,
            isCharging = false,
            capabilityMode = "direct_control",
            now = now,
            previous = previous(charging = true),
            command = ChargeProtectionVerificationPolicy.CommandEvidence(
                sentAt = now - 2_000L,
                targetLevel = 80,
            ),
        )
        assertEquals("verified_stopped", withCommand)
    }

    @Test
    fun verifiedStatePersistsOnlyWhileStoppedOnSameTargetAndPlugSession() {
        val result = ChargeProtectionVerificationPolicy.evaluate(
            enabled = true,
            targetLevel = 80,
            level = 80,
            isPlugged = true,
            isCharging = false,
            capabilityMode = "system_setting",
            now = now,
            previous = previous(
                charging = false,
                level = 80,
                verification = "verified_stopped",
            ),
            command = null,
        )
        assertEquals("verified_stopped", result)
    }
}
