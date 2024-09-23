package me.jareddanieljones.shelterpartner.Data

data class Note(
    val id: String? = "",
    val date: Double? = 0.0,
    val note: String? = "",
    val user: String? = ""
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "date" to date,
            "note" to note,
            "user" to user
        )
    }
}
