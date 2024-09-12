package me.jareddanieljones.shelterpartner.Data

data class ShelterSettings(
    val QRMode: Boolean = false,
    val adminMode: Boolean = false,
    val allowPhotoUploads: Boolean = false,
    val appendAnimalData: Boolean = false,
    val automaticPutBackHours: Int = 3,
    val automaticPutBackIgnoreVisit: Boolean = true,
    val cardsPerPage: Int = 30,
    val createLogsAlways: Boolean = true,
    val customFormURL: String = "",
    val enableAutomaticPutBack: Boolean = true,
    val groupOption: String = "",
    val isCustomFormOn: Boolean = false,
    val linkType: String = "QR Code",
    val minimumDuration: Int = 10,
    val requireLetOutType: Boolean = false,
    val requireName: Boolean = false,
    val requireReason: Boolean = false,
    val secondarySortOption: String = "",
    val showAllAnimals: Boolean = false,
    val showBulkTakeOut: Boolean = false,
    val showFilterOptions: Boolean = false,
    val showNoteDates: Boolean = true,
    val showSearchBar: Boolean = false,
    val sortBy: String = "Last Let Out"
)
