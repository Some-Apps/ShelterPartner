package me.jareddanieljones.shelterpartner.ViewModels

import me.jareddanieljones.shelterpartner.Data.FirestoreRepository


class VolunteerSettingsViewModel(private val firebaseRepository: FirestoreRepository) {
    fun signOut() {
        firebaseRepository.signOut()
    }
}
