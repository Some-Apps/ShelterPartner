package me.jareddanieljones.shelterpartner.Data

import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await



class FirestoreRepository {

    private val firestore = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()

    suspend fun getShelterID(): String? {
        val uid = auth.currentUser?.uid
        if (uid == null) {
            Log.e("FirestoreRepository", "UID is null. User might not be logged in.")
            return null
        }

        val userDoc = firestore.collection("Users").document(uid).get().await()
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

    fun getAnimalsStream(shelterID: String, animalType: String): Flow<List<Animal>> = callbackFlow {
        val listenerRegistration = firestore.collection("Societies")
            .document(shelterID)
            .collection(animalType)
            .addSnapshotListener { snapshot, e ->
                if (e != null || snapshot == null) {
                    close(e) // Close the flow in case of an error
                    return@addSnapshotListener
                }

                val animalList = snapshot.documents.mapNotNull { document ->
                    document.toObject(Animal::class.java)
                }
                trySend(animalList).isSuccess
            }

        awaitClose { listenerRegistration.remove() }
    }
}