package me.jareddanieljones.shelterpartner.ViewModels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import me.jareddanieljones.shelterpartner.Data.FirestoreRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import me.jareddanieljones.shelterpartner.Data.Animal

class VolunteerViewModel(
    private val repository: FirestoreRepository = FirestoreRepository()
) : ViewModel() {

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
            val shelterID = repository.getShelterID()
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