package me.jareddanieljones.shelterpartner.ViewModels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.launch

class LoginViewModel : ViewModel() {

    private val db = FirebaseFirestore.getInstance()

    fun fetchSocietyID(userID: String, callback: (Result<String>) -> Unit) {
        db.collection("Users").document(userID).get().addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val document = task.result
                if (document != null && document.exists()) {
                    val societyID = document.getString("societyID")
                    if (societyID != null) {
                        callback(Result.success(societyID))
                    } else {
                        callback(Result.failure(Exception("SocietyID not found")))
                    }
                } else {
                    callback(Result.failure(Exception("No such document")))
                }
            } else {
                callback(Result.failure(task.exception ?: Exception("Failed to fetch societyID")))
            }
        }
    }

    fun fetchSignUpForm(callback: (String, String) -> Unit) {
        db.collection("Stats").document("AppInformation").addSnapshotListener { documentSnapshot, error ->
            if (error != null) {
                Log.e("LoginViewModel", "Error fetching sign up form", error)
                return@addSnapshotListener
            }
            if (documentSnapshot != null && documentSnapshot.exists()) {
                val signUpForm = documentSnapshot.getString("signUpForm").orEmpty()
                val tutorialsURL = documentSnapshot.getString("tutorialsURL").orEmpty()
                callback(signUpForm, tutorialsURL)
            }
        }
    }
}
