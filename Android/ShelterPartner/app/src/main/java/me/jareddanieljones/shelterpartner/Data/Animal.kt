package me.jareddanieljones.shelterpartner.Data

import java.util.concurrent.TimeUnit


data class Animal(
    val id: String = "",
    val name: String = "",
    val animalType: AnimalType = AnimalType.Dog,
    val location: String = "",
    val alert: String = "",
    val canPlay: Boolean = true,
    val inCage: Boolean = true,
    val startTime: Double = 0.0, // Epoch time in milliseconds as Double
    val sex: String? = null,
    val age: String? = null,
    val breed: String? = null,
    val intakeDate: String? = null,
    val lastVolunteer: String? = null,
    val lastLetOutType: String? = null,
    val extraInfo: String? = null,
    val fullLocation: String? = null,
    val secondarySort: Int? = null,
    val behaviorSort: Int? = null,
    val buildingSort: Int? = null,
    val adoptionGroup: String? = null,
    val colorGroup: String? = null,
    val medicalGroup: String? = null,
    val behaviorGroup: String? = null,
    val buildingGroup: String = "",

    val photos: List<Photo> = emptyList(),
    val notes: List<Note> = emptyList(),
    val logs: List<Log> = emptyList()
) {
    val timeSinceLastLetOut: String
        get() {
            val currentTimeMillis = System.currentTimeMillis()

            when {
                !inCage -> {
                    // Animal is currently out; calculate how long they've been out using startTime
                    val startTimeMillis = startTime.toLong() ?: return "No start time"
                    val timeDifferenceMillis = currentTimeMillis - startTimeMillis

                    // Convert time difference to appropriate units
                    val minutes = TimeUnit.MILLISECONDS.toMinutes(timeDifferenceMillis)
                    val hours = TimeUnit.MILLISECONDS.toHours(timeDifferenceMillis)
                    val days = TimeUnit.MILLISECONDS.toDays(timeDifferenceMillis)

                    return when {
                        days >= 1 -> {
                            val remainingHours = hours % 24
                            val dayLabel = if (days == 1L) "day" else "days"
                            val hourLabel = if (remainingHours == 1L) "hour" else "hours"

                            if (remainingHours > 0) {
                                "$days $dayLabel $remainingHours $hourLabel"
                            } else {
                                "$days $dayLabel"
                            }
                        }
                        hours >= 1 -> {
                            val remainingMinutes = minutes % 60
                            val hourLabel = if (hours == 1L) "hour" else "hours"
                            val minuteLabel = if (remainingMinutes == 1L) "minute" else "minutes"

                            if (remainingMinutes > 0) {
                                "$hours $hourLabel $remainingMinutes $minuteLabel"
                            } else {
                                "$hours $hourLabel"
                            }
                        }
                        minutes >= 1 -> {
                            val minuteLabel = if (minutes == 1L) "minute" else "minutes"
                            "$minutes $minuteLabel"
                        }
                        else -> "0 minutes"
                    }
                }
                logs.isNotEmpty() -> {
                    // Animal is in cage; calculate time since last let out using last log's endTime

                    // Filter logs to include only those with valid startTime and endTime, and where endTime > startTime
                    val validLogs = logs.filter {
                        it.endTime > it.startTime
                    }

                    if (validLogs.isNotEmpty()) {
                        val lastLog = validLogs.maxByOrNull { it.endTime }!!

                        val lastEndTimeMillis = lastLog.endTime.toLong()
                        val timeDifferenceMillis = currentTimeMillis - lastEndTimeMillis

                        // Convert time difference to appropriate units
                        val minutes = TimeUnit.MILLISECONDS.toMinutes(timeDifferenceMillis)
                        val hours = TimeUnit.MILLISECONDS.toHours(timeDifferenceMillis)
                        val days = TimeUnit.MILLISECONDS.toDays(timeDifferenceMillis)

                        return when {
                            days >= 1 -> {
                                val remainingHours = hours % 24
                                val dayLabel = if (days == 1L) "day" else "days"
                                val hourLabel = if (remainingHours == 1L) "hour" else "hours"

                                if (remainingHours > 0) {
                                    "$days $dayLabel $remainingHours $hourLabel ago"
                                } else {
                                    "$days $dayLabel ago"
                                }
                            }
                            hours >= 1 -> {
                                val remainingMinutes = minutes % 60
                                val hourLabel = if (hours == 1L) "hour" else "hours"
                                val minuteLabel = if (remainingMinutes == 1L) "minute" else "minutes"

                                if (remainingMinutes > 0) {
                                    "$hours $hourLabel $remainingMinutes $minuteLabel ago"
                                } else {
                                    "$hours $hourLabel ago"
                                }
                            }
                            minutes >= 1 -> {
                                val minuteLabel = if (minutes == 1L) "minute" else "minutes"
                                "$minutes $minuteLabel ago"
                            }
                            else -> "0 minutes ago"
                        }
                    } else {
                        // No valid logs available
                        return "No Logs"
                    }
                }
                else -> {
                    // No logs available
                    return "No records"
                }
            }
        }
}



enum class AnimalType {
    Cat, Dog
}

data class Photo(
    val url: String = "",
    val privateURL: String = "",
    val timestamp: Double = 0.0
)
