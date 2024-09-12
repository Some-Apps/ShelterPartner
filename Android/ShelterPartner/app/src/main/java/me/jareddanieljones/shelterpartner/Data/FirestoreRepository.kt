package me.jareddanieljones.shelterpartner.Data

import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first
import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "shelter_preferences")


class FirestoreRepository(private val context: Context) {

    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()

    private val SHELTER_ID_KEY = stringPreferencesKey("shelter_id")

    // Function to save shelterID in DataStore
    suspend fun saveShelterID(shelterID: String) {
        context.dataStore.edit { preferences ->
            preferences[SHELTER_ID_KEY] = shelterID
        }
    }

    // Function to get shelterID from DataStore
    suspend fun getStoredShelterID(): String? {
        val preferences = context.dataStore.data.first()
        return preferences[SHELTER_ID_KEY]
    }

    suspend fun getShelterID(): String? {
        val storedShelterID = getStoredShelterID()
        if (storedShelterID != null) {
            return storedShelterID
        }

        val uid = auth.currentUser?.uid
        if (uid == null) {
            Log.e("FirestoreRepository", "UID is null. User might not be logged in.")
            return null
        }

        val userDoc = db.collection("Users").document(uid).get().await()
        if (!userDoc.exists()) {
            Log.e("FirestoreRepository", "User document does not exist.")
            return null
        }

        val shelterID = userDoc.getString("societyID")
        if (shelterID != null) {
            // Save the shelterID to DataStore for future use
            saveShelterID(shelterID)
        } else {
            Log.e("FirestoreRepository", "shelterID is null in the document.")
        }
        return shelterID
    }

    fun signOut() {
        FirebaseAuth.getInstance().signOut()
    }

    fun getSettingsStream(shelterID: String): Flow<ShelterSettings?> {
        return callbackFlow {
            val listener = db.collection("Societies")
                .document(shelterID)
                .addSnapshotListener { snapshot, error ->
                    if (error != null) {
                        close(error)
                        return@addSnapshotListener
                    }

                    if (snapshot != null && snapshot.exists()) {
                        // Extract the "Volunteer Settings" field as a Map
                        val volunteerSettingsMap = snapshot.get("VolunteerSettings") as? Map<String, Any>

                        // Map it to ShelterSettings if it's not null
                        val shelterSettings = volunteerSettingsMap?.let {
                            ShelterSettings(
                                QRMode = it["QRMode"] as? Boolean ?: false,
                                adminMode = it["adminMode"] as? Boolean ?: false,
                                allowPhotoUploads = it["allowPhotoUploads"] as? Boolean ?: false,
                                appendAnimalData = it["appendAnimalData"] as? Boolean ?: false,
                                automaticPutBackHours = (it["automaticPutBackHours"] as? Long)?.toInt() ?: 3, // Handle Long to Int
                                automaticPutBackIgnoreVisit = it["automaticPutBackIgnoreVisit"] as? Boolean ?: true,
                                cardsPerPage = (it["cardsPerPage"] as? Long)?.toInt() ?: 30, // Handle Long to Int
                                createLogsAlways = it["createLogsAlways"] as? Boolean ?: true,
                                customFormURL = it["customFormURL"] as? String ?: "",
                                enableAutomaticPutBack = it["enableAutomaticPutBack"] as? Boolean ?: true,
                                groupOption = it["groupOption"] as? String ?: "",
                                isCustomFormOn = it["isCustomFormOn"] as? Boolean ?: false,
                                linkType = it["linkType"] as? String ?: "QR Code",
                                minimumDuration = (it["minimumDuration"] as? Long)?.toInt() ?: 10, // Handle Long to Int
                                requireLetOutType = it["requireLetOutType"] as? Boolean ?: false,
                                requireName = it["requireName"] as? Boolean ?: false,
                                requireReason = it["requireReason"] as? Boolean ?: false,
                                secondarySortOption = it["secondarySortOption"] as? String ?: "",
                                showAllAnimals = it["showAllAnimals"] as? Boolean ?: false,
                                showBulkTakeOut = it["showBulkTakeOut"] as? Boolean ?: false,
                                showFilterOptions = it["showFilterOptions"] as? Boolean ?: false,
                                showNoteDates = it["showNoteDates"] as? Boolean ?: true,
                                showSearchBar = it["showSearchBar"] as? Boolean ?: false,
                                sortBy = it["sortBy"] as? String ?: "Last Let Out"
                            )
                        }

                        println("[LOG] Firestore listener received updated shelter settings")
                        trySend(shelterSettings).isSuccess
                    } else {
                        trySend(null).isSuccess // Send null if the document or field doesn't exist
                    }
                }

            awaitClose { listener.remove() }
        }
    }





    fun getAnimalsStream(shelterID: String, animalType: String): Flow<List<Animal>> {
        return callbackFlow {
            val listener = db.collection("Societies")
                .document(shelterID)
                .collection(animalType)
                .addSnapshotListener { snapshot, error ->
                    if (error != null) {
                        close(error)
                        return@addSnapshotListener
                    }

                    if (snapshot != null) {
                        val animalsList = snapshot.documents.mapNotNull { it.toObject(Animal::class.java) }
                        println("[LOG] Firestore listener received updated animal list")
                        trySend(animalsList).isSuccess
                    }
                }

            awaitClose { listener.remove() }
        }
    }


    suspend fun getAnimalById(animalId: String, shelterID: String, animalType: String): Animal? {
        return try {
            val document = db.collection("Societies")
                .document(shelterID)
                .collection(animalType)
                .document(animalId)
                .get()
                .await()

            document.toObject(Animal::class.java)
        } catch (e: Exception) {
            println("[LOG] Error fetching animal by ID: ${e.message}")
            null
        }
    }


    suspend fun toggleInCage(animalId: String, newInCageValue: Boolean) {
        try {
            getStoredShelterID()?.let {
                db.collection("Societies")
                    .document(it) // Replace with actual shelter ID
                    .collection("Dogs")
                    .document(animalId)
                    .update("inCage", newInCageValue)
                    .await()
            }
        } catch (e: Exception) {
            println("[LOG] Error toggling inCage: ${e.message}")
        }
    }

}