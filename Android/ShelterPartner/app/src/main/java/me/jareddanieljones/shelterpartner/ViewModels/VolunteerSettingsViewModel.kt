package me.jareddanieljones.shelterpartner.ViewModels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import me.jareddanieljones.shelterpartner.Data.FirestoreRepository
import me.jareddanieljones.shelterpartner.Data.ShelterSettings


class VolunteerSettingsViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = FirestoreRepository(application)

    // StateFlow to hold the latest shelter settings
    private val _shelterSettings = MutableStateFlow<ShelterSettings?>(null)
    val shelterSettings = _shelterSettings.asStateFlow()

    private val _catTags = MutableStateFlow<List<String>>(emptyList())
    val catTags = _catTags.asStateFlow()

    private val _dogTags = MutableStateFlow<List<String>>(emptyList())
    val dogTags = _dogTags.asStateFlow()

    // State to hold selected tags
    private val _selectedTags = MutableStateFlow<Set<String>>(emptySet())
    val selectedTags = _selectedTags.asStateFlow()

    init {
//        fetchShelterSettings()
        viewModelScope.launch {
            val shelterID = repository.getShelterID()
            if (shelterID != null) {
                // Fetch shelter settings
                repository.getSettingsStream(shelterID)
                    .collect { settings ->
                        _shelterSettings.value = settings
                    }

                // Fetch tags
                repository.getTagsStream(shelterID)
                    .collect { (catTags, dogTags) ->
                        _catTags.value = catTags
                        _dogTags.value = dogTags
                    }
            }
        }
    }


    fun onTagSelected(tag: String) {
        val currentTags = _selectedTags.value.toMutableSet()
        if (currentTags.contains(tag)) {
            currentTags.remove(tag)
        } else {
            currentTags.add(tag)
        }
        _selectedTags.value = currentTags
    }

    // Function to clear selected tags (e.g., when dialog is dismissed)
    fun clearSelectedTags() {
        _selectedTags.value = emptySet()
    }
    // Function to fetch settings stream from Firestore
    private fun fetchShelterSettings() {
        println("[LOG]: fetching shelter settings")
        viewModelScope.launch {
            println("[LOG]: fetching settings")

            repository.getShelterID()?.let {

                repository.getSettingsStream(it) // Replace with actual shelter ID

                    .onEach { settings ->
                        println("[LOG]: $settings")
                        _shelterSettings.value = settings // Update the state with new settings
                    }
                    .launchIn(this)
            } // Launch it in the ViewModel's scope
        }
    }

    // Sign out function
    fun signOut() {
        repository.signOut()
    }


}
class VolunteerSettingsViewModelFactory(private val application: Application) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(VolunteerSettingsViewModel::class.java)) {
            return VolunteerSettingsViewModel(application) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}