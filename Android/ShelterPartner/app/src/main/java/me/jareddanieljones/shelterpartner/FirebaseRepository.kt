package me.jareddanieljones.shelterpartner

import com.google.firebase.auth.FirebaseAuth

class FirebaseRepository {
    fun signOut() {
        FirebaseAuth.getInstance().signOut()
    }
}