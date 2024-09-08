package me.jareddanieljones.shelterpartner.Data

import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await



class FirestoreRepository {

    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()

    suspend fun getShelterID(): String? {
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
        if (shelterID == null) {
            Log.e("FirestoreRepository", "shelterID is null in the document.")
        }
        return shelterID
    }

    fun signOut() {
        FirebaseAuth.getInstance().signOut()
    }

    fun getAnimalsStream(shelterID: String, animalType: String): Flow<List<Animal>> {
        return callbackFlow {
            val listener = db.collection("Societies").document(shelterID).collection(animalType)
                .addSnapshotListener { snapshot, error ->
                    if (error != null) {
                        close(error)
                        return@addSnapshotListener
                    }

                    if (snapshot != null) {
                        val animalsList = snapshot.documents.mapNotNull { it.toObject(Animal::class.java) }
                        trySend(animalsList).isSuccess
                    }
                }

            awaitClose { listener.remove() }
        }
    }

    suspend fun toggleInCage(animalId: String, newInCageValue: Boolean): Boolean {
        return try {
            println("[LOG] inKennel = $newInCageValue")
            db.collection("Societies")
                .document("demo1")
                .collection("Dogs")
                .document(animalId)
                .update("inCage", newInCageValue)
                .await() // Ensure this is awaited to complete the operation
            true  // Return true if update succeeds
        } catch (e: Exception) {
            println("[LOG] inKennel = $newInCageValue")
            false // Return false if update fails
        }
    }
}