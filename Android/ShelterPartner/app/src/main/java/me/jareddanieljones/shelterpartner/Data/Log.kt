package me.jareddanieljones.shelterpartner.Data

import java.util.UUID

data class Log(
    val id: String = UUID.randomUUID().toString(),
    val startTime: Double = 0.0,
    val endTime: Double = 0.0,
    val user: String? = "",
    val shortReason: String = "",
    val letOutType: String? = ""
)
