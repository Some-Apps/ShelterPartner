package me.jareddanieljones.shelterpartner.Data

import android.util.Log
import android.net.Uri
import android.app.Application
import com.google.firebase.storage.FirebaseStorage
import com.google.firebase.storage.StorageMetadata
import kotlinx.coroutines.tasks.await

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
import com.google.firebase.firestore.FieldValue

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

    private suspend fun uploadImageToFirebaseStorage(
        imageUri: Uri,
        shelterID: String,
        animalId: String,
        noteId: String
    ): Map<String, Any>? {
        return try {
            val storage = FirebaseStorage.getInstance()
            val storageRef = storage.reference

            val storagePath = "$shelterID/$animalId/$noteId.jpeg"
            val imageRef = storageRef.child(storagePath)

            // Get the application context
//            val context = getApplication<Application>().applicationContext

            // Open the input stream from the URI
            val inputStream = context.contentResolver.openInputStream(imageUri)

            if (inputStream != null) {
                val metadata = StorageMetadata.Builder()
                    .setContentType("image/jpeg")
                    .build()

                // Upload the image data
                imageRef.putStream(inputStream, metadata).await()

                // Get the download URL
                val downloadUrl = imageRef.downloadUrl.await()

                // Create the photoDict
                val photoDict = mapOf(
                    "url" to downloadUrl.toString(),
                    "privateURL" to storagePath,
                    "timestamp" to System.currentTimeMillis().toDouble() / 1000.0
                )
                photoDict
            } else {
                null
            }
        } catch (e: Exception) {
            // Handle any errors
            Log.e("VolunteerViewModel", "Error uploading image", e)
            null
        }
    }


    suspend fun getUserName(): String? {
        val uid = auth.currentUser?.uid
        if (uid != null) {
            try {
                val userDoc = db.collection("Users").document(uid).get().await()
                if (userDoc.exists()) {
                    return userDoc.getString("name")
                }
            } catch (e: Exception) {
                println("[LOG] Error fetching user name: ${e.message}")
            }
        } else {
            println("[LOG] User is not logged in.")
        }
        return null
    }

    suspend fun addLog(
        shelterID: String,
        animalType: String,
        animalId: String,
        log: me.jareddanieljones.shelterpartner.Data.Log
    ) {
        val animalDocRef = db.collection("Societies")
            .document(shelterID)
            .collection(animalType)
            .document(animalId)

        animalDocRef.update("logs", FieldValue.arrayUnion(log))
            .await()
    }

    suspend fun addNote(
        shelterID: String,
        animalType: String,
        animalId: String,
        note: Note,
        selectedTags: List<String>,
        photoDict: Map<String, Any>? = null
    ) {
        val animalDocRef = db.collection("Societies")
            .document(shelterID)
            .collection(animalType)
            .document(animalId)

        db.runTransaction { transaction ->
            val snapshot = transaction.get(animalDocRef)
            val currentNotes = snapshot.get("notes") as? List<Map<String, Any>> ?: emptyList()
            val updatedNotes = currentNotes + note.toMap()

            val updates = mutableMapOf<String, Any>(
                "notes" to updatedNotes
            )

            if (photoDict != null) {
                val currentPhotos = snapshot.get("photos") as? List<Map<String, Any>> ?: emptyList()
                val updatedPhotos = currentPhotos + photoDict
                updates["photos"] = updatedPhotos
            }

            // Update the tags map
            val currentTagsMap = snapshot.get("tags") as? Map<String, Long> ?: emptyMap()
            val newTagsMap = currentTagsMap.toMutableMap()

            for (tag in selectedTags) {
                val currentCount = newTagsMap[tag] ?: 0
                newTagsMap[tag] = currentCount + 1
            }

            updates["tags"] = newTagsMap

            transaction.update(animalDocRef, updates)
        }.await()
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
                        // Extract the "VolunteerSettings" field as a Map
                        val volunteerSettingsMap = snapshot.get("VolunteerSettings") as? Map<String, Any>

                        // Extract the "letOutTypes" attribute as a List of Strings
                        val letOutTypes = snapshot.get("letOutTypes") as? List<String> ?: emptyList()
                        val earlyReasons = snapshot.get("earlyReasons") as? List<String> ?: emptyList()
                        // Map it to ShelterSettings if it's not null
                        val shelterSettings = volunteerSettingsMap?.let {
                            ShelterSettings(
                                QRMode = it["QRMode"] as? Boolean ?: false,
                                adminMode = it["adminMode"] as? Boolean ?: false,
                                allowPhotoUploads = it["allowPhotoUploads"] as? Boolean ?: false,
                                appendAnimalData = it["appendAnimalData"] as? Boolean ?: false,
                                automaticPutBackHours = (it["automaticPutBackHours"] as? Long)?.toInt() ?: 3,
                                automaticPutBackIgnoreVisit = it["automaticPutBackIgnoreVisit"] as? Boolean ?: true,
                                cardsPerPage = (it["cardsPerPage"] as? Long)?.toInt() ?: 30,
                                createLogsAlways = it["createLogsAlways"] as? Boolean ?: true,
                                customFormURL = it["customFormURL"] as? String ?: "",
                                enableAutomaticPutBack = it["enableAutomaticPutBack"] as? Boolean ?: true,
                                groupOption = it["groupOption"] as? String ?: "",
                                isCustomFormOn = it["isCustomFormOn"] as? Boolean ?: false,
                                linkType = it["linkType"] as? String ?: "QR Code",
                                minimumDuration = (it["minimumDuration"] as? Long)?.toInt() ?: 10,
                                requireLetOutType = it["showLetOutTypePrompt"] as? Boolean ?: false,
                                requireName = it["requireName"] as? Boolean ?: false,
                                requireReason = it["requireReason"] as? Boolean ?: false,
                                secondarySortOption = it["secondarySortOption"] as? String ?: "",
                                showAllAnimals = it["showAllAnimals"] as? Boolean ?: false,
                                showBulkTakeOut = it["showBulkTakeOut"] as? Boolean ?: false,
                                showFilterOptions = it["showFilterOptions"] as? Boolean ?: false,
                                showNoteDates = it["showNoteDates"] as? Boolean ?: true,
                                showSearchBar = it["showSearchBar"] as? Boolean ?: false,
                                sortBy = it["sortBy"] as? String ?: "Last Let Out",
                                letOutTypes = letOutTypes,
                                earlyReasons = earlyReasons
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

    suspend fun updateAnimalField(
        shelterID: String,
        animalType: String,
        animalId: String,
        fieldName: String,
        value: Any
    ) {
        val animalDocRef = db.collection("Societies")
            .document(shelterID)
            .collection(animalType)
            .document(animalId)

        try {
            Log.d("FirestoreRepository", "Attempting to update field '$fieldName' with value '$value' for animalId '$animalId'")
            animalDocRef.update(fieldName, value).await()
            Log.d("FirestoreRepository", "Successfully updated field '$fieldName'")
        } catch (e: Exception) {
            Log.e("FirestoreRepository", "Error updating field '$fieldName'", e)
        }
    }


    suspend fun toggleInCage(animalId: String, animalType: String, newInCageValue: Boolean) {
        try {
            getStoredShelterID()?.let {
                db.collection("Societies")
                    .document(it) // Replace with actual shelter ID
                    .collection(animalType)
                    .document(animalId)
                    .update("inCage", newInCageValue)
                    .await()
                updateAnimalField(
                    it,
                    animalType,
                    animalId,
                    "startTime",
                    System.currentTimeMillis().toDouble() / 1000.0
                )
            }

        } catch (e: Exception) {
            println("[LOG] Error toggling inCage: ${e.message}")
        }
    }

    fun getTagsStream(shelterID: String): Flow<Pair<List<String>, List<String>>> {
        return callbackFlow {
            val listener = db.collection("Societies")
                .document(shelterID)
                .addSnapshotListener { snapshot, error ->
                    if (error != null) {
                        close(error)
                        return@addSnapshotListener
                    }

                    if (snapshot != null && snapshot.exists()) {
                        val catTags = snapshot.get("catTags") as? List<String> ?: emptyList()
                        val dogTags = snapshot.get("dogTags") as? List<String> ?: emptyList()
                        trySend(Pair(catTags, dogTags)).isSuccess
                    } else {
                        trySend(Pair(emptyList(), emptyList())).isSuccess
                    }
                }

            awaitClose { listener.remove() }
        }
    }

}