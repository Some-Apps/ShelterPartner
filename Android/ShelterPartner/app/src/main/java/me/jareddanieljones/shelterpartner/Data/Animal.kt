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
    val startTime: Double = 0.0, // Epoch time in seconds as Double
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
            val currentTimeSeconds = System.currentTimeMillis() / 1000.0 // Current time in seconds

            if (!inCage) {
                // Animal is out; calculate duration since `startTime`
                val startTimeSeconds = startTime / 1000.0 // Convert to seconds if necessary
                if (startTimeSeconds > 0) {
                    val timeDifferenceSeconds = currentTimeSeconds - startTimeSeconds
                    return formatTimeDifference(timeDifferenceSeconds)
                } else {
                    return "No start time"
                }
            } else if (logs.isNotEmpty()) {
                // Animal is in cage; find the most recent log
                val validLogs = logs.filter { log ->
                    log.startTime != null && log.endTime != null &&
                            log.startTime > 0 && log.endTime >= log.startTime
                }

                if (validLogs.isNotEmpty()) {
                    val lastLog = validLogs.maxByOrNull { it.endTime!! }
                    if (lastLog != null) {
                        val endTimeSeconds = lastLog.endTime!! / 1000.0 // Convert to seconds if necessary
                        val timeDifferenceSeconds = currentTimeSeconds - endTimeSeconds
                        return formatTimeDifference(timeDifferenceSeconds) + " ago"
                    }
                }
                return "No valid logs"
            } else {
                return "No records"
            }
        }

    private fun formatTimeDifference(timeDifferenceSeconds: Double): String {
        val days = (timeDifferenceSeconds / 86400).toInt() // 86400 seconds in a day
        val hours = ((timeDifferenceSeconds % 86400) / 3600).toInt() // 3600 seconds in an hour
        val minutes = ((timeDifferenceSeconds % 3600) / 60).toInt() // 60 seconds in a minute

        return when {
            days >= 1 -> {
                val dayLabel = if (days == 1) "day" else "days"
                "$days $dayLabel"
            }
            hours >= 1 -> {
                val hourLabel = if (hours == 1) "hour" else "hours"
                "$hours $hourLabel"
            }
            minutes >= 1 -> {
                val minuteLabel = if (minutes == 1) "minute" else "minutes"
                "$minutes $minuteLabel"
            }
            else -> "0 minutes"
        }
    }



//    // Function to display the largest applicable time unit, with minutes being the smallest.
//    private fun formatTimeDifference(timeDifferenceSeconds: Double): String {
//        val days = (timeDifferenceSeconds / 86400).toInt() // 86400 seconds in a day
//        val hours = ((timeDifferenceSeconds % 86400) / 3600).toInt() // 3600 seconds in an hour
//        val minutes = ((timeDifferenceSeconds % 3600) / 60).toInt() // 60 seconds in a minute
//
//        return when {
//            days >= 1 -> {
//                val dayLabel = if (days == 1) "day" else "days"
//                "$days $dayLabel"
//            }
//            hours >= 1 -> {
//                val hourLabel = if (hours == 1) "hour" else "hours"
//                "$hours $hourLabel"
//            }
//            minutes >= 1 -> {
//                val minuteLabel = if (minutes == 1) "minute" else "minutes"
//                "$minutes $minuteLabel"
//            }
//            else -> "0 minutes" // If less than a minute, default to "0 minutes"
//        }
//    }
}




enum class AnimalType {
    Cat, Dog
}

data class Photo(
    val url: String = "",
    val privateURL: String = "",
    val timestamp: Double = 0.0
)
