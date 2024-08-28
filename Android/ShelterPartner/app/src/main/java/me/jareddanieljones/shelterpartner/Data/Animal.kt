package me.jareddanieljones.shelterpartner.Data

data class Animal(
    val id: String = "",
    val name: String = "",
    val animalType: AnimalType = AnimalType.Dog,
    val location: String = "",
    val alert: String = "",
    val canPlay: Boolean = true,
    val inCage: Boolean = true,
    val startTime: Double = 0.0,
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
    val photos: List<Photo> = emptyList()
)

enum class AnimalType {
    Cat, Dog
}

data class Photo(
    val url: String = "",
    val privateURL: String = "",
    val timestamp: Double = 0.0
)
