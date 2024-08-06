package me.jareddanieljones.shelterpartner.ViewModels

import me.jareddanieljones.shelterpartner.FirebaseRepository

class VolunteerSettingsViewModel(private val firebaseRepository: FirebaseRepository) {
    fun signOut() {
        firebaseRepository.signOut()
    }
}
