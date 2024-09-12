package me.jareddanieljones.shelterpartner.ViewModels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import me.jareddanieljones.shelterpartner.Data.FirestoreRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import me.jareddanieljones.shelterpartner.Data.Animal
import android.content.Context


class VolunteerViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = FirestoreRepository(application)

    private val _animals = MutableStateFlow<List<Animal>>(emptyList())
    val animals: StateFlow<List<Animal>> get() = _animals

    private val _selectedAnimalType = MutableStateFlow("Dogs")
    val selectedAnimalType: StateFlow<String> get() = _selectedAnimalType

    init {
        fetchAnimals()
    }

    fun onAnimalTypeChange(type: String) {
        _selectedAnimalType.value = type
        fetchAnimals()
    }

    private fun fetchAnimals() {
        viewModelScope.launch {
            val shelterID = repository.getStoredShelterID()
            if (shelterID != null) {
                repository.getAnimalsStream(shelterID, _selectedAnimalType.value).collect { animalList ->
                    _animals.value = animalList
                }
            }
        }
    }



    fun toggleInCage(animalId: String) {
        viewModelScope.launch {
            // Fetch the shelter ID first (you might want to cache this)
            val shelterID = repository.getShelterID()
            val animalType = _selectedAnimalType.value

            if (shelterID != null) {
                // Fetch the latest state from Firestore before toggling
                val currentAnimal = repository.getAnimalById(animalId, shelterID, animalType)
                if (currentAnimal != null) {
                    val newInCageValue = !currentAnimal.inCage
                    val success = repository.toggleInCage(animalId, newInCageValue)

                    // Let Firestore handle updating the UI through the real-time listener
                }
            }
        }
    }
}

class VolunteerViewModelFactory(private val application: Application) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(VolunteerViewModel::class.java)) {
            return VolunteerViewModel(application) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}