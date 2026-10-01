package de.kopten.gymfy

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.WeightRecord
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.ZoneId

/**
 * Every call into connect-client, in one class.
 *
 * Kept apart from [HealthConnectBridge] so the library's classes are only
 * loaded once the bridge has checked the Android version — see the note on
 * `tools:overrideLibrary` in AndroidManifest.xml.
 */
@RequiresApi(Build.VERSION_CODES.O)
internal class HealthConnectOps(private val context: Context) {
    private val client by lazy { HealthConnectClient.getOrCreate(context) }

    suspend fun grantedPermissions(): Set<String> =
        client.permissionController.getGrantedPermissions().intersect(PERMISSIONS)

    fun permissionIntent(permissions: Set<String>): Intent =
        PermissionController.createRequestPermissionResultContract()
            .createIntent(context, permissions)

    /**
     * Writes finished workouts as exercise sessions.
     *
     * Each one carries a client record id that Dart derives from the session,
     * which is what makes a second write of the same workout replace the first
     * rather than add a twin. The version is the time of writing, so the
     * newest write always wins.
     *
     * Recorded as a manual entry: the session's span comes from tapping start
     * and finish in a logging app, not from a sensor, and other apps treat
     * "actively recorded" data as measured.
     */
    suspend fun writeSessions(sessions: List<Map<*, *>>) {
        if (sessions.isEmpty()) return
        val version = System.currentTimeMillis()
        val zone = ZoneId.systemDefault()
        val records = sessions.map { fields ->
            val start = Instant.ofEpochMilli((fields["startMs"] as Number).toLong())
            val end = Instant.ofEpochMilli((fields["endMs"] as Number).toLong())
            ExerciseSessionRecord(
                startTime = start,
                startZoneOffset = zone.rules.getOffset(start),
                endTime = end,
                endZoneOffset = zone.rules.getOffset(end),
                metadata = Metadata.manualEntry(
                    clientRecordId = fields["clientRecordId"] as String,
                    clientRecordVersion = version,
                ),
                exerciseType = ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING,
                title = fields["title"] as? String,
            )
        }
        client.insertRecords(records)
    }

    /**
     * Deletes sessions by the client record ids they were written with.
     *
     * Only ever records this app wrote: Health Connect does not let one app
     * delete another's data, and the ids are Gymfy's own.
     */
    suspend fun deleteSessions(clientRecordIds: List<String>) {
        if (clientRecordIds.isEmpty()) return
        client.deleteRecords(
            ExerciseSessionRecord::class,
            recordIdsList = emptyList(),
            clientRecordIdsList = clientRecordIds,
        )
    }

    /**
     * Weight records between two instants, every page of them.
     *
     * Plain values only — id, time, the offset it was taken in, kilograms.
     * Which of them become a bodyweight in Gymfy is Dart's decision.
     */
    suspend fun readWeights(startMs: Long, endMs: Long): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        var page: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = WeightRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(
                        Instant.ofEpochMilli(startMs),
                        Instant.ofEpochMilli(endMs),
                    ),
                    pageToken = page,
                ),
            )
            for (record in response.records) {
                out += mapOf(
                    "id" to record.metadata.id,
                    "timeMs" to record.time.toEpochMilli(),
                    "offsetSeconds" to record.zoneOffset?.totalSeconds,
                    "kg" to record.weight.inKilograms,
                )
            }
            page = response.pageToken
        } while (!page.isNullOrEmpty())
        return out
    }

    /**
     * Health Connect's screen for this app's data and permissions — where
     * the user revokes access or deletes what Gymfy wrote.
     */
    fun manageDataIntent(): Intent = HealthConnectClient.getHealthConnectManageDataIntent(context)

    companion object {
        /**
         * The permissions Gymfy uses, and the only ones it will ask for.
         * Must match the `android.permission.health.*` entries in
         * AndroidManifest.xml — pinned by health_connect_test.dart.
         */
        val PERMISSIONS = setOf(
            HealthPermission.getWritePermission(ExerciseSessionRecord::class),
            HealthPermission.getReadPermission(WeightRecord::class),
        )

        /**
         * One of "available", "needsUpdate", "notInstalled", "unsupported".
         *
         * "notInstalled" only where installing would help: Android 9 to 13,
         * where Health Connect is an app from the Play Store. From 14 it is
         * part of the system, so "unavailable" there (a work profile, say)
         * cannot be fixed by installing anything.
         */
        fun availability(context: Context): String =
            when (HealthConnectClient.getSdkStatus(context, HealthConnectBridge.PROVIDER_PACKAGE)) {
                HealthConnectClient.SDK_AVAILABLE -> "available"
                HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> "needsUpdate"
                else -> if (Build.VERSION.SDK_INT in Build.VERSION_CODES.P until Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    "notInstalled"
                } else {
                    "unsupported"
                }
            }
    }
}
