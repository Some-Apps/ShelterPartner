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
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import me.jareddanieljones.shelterpartner.Data.ShelterSettings


class VolunteerViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = FirestoreRepository(application)

    private val _animals = MutableStateFlow<List<Animal>>(emptyList())
    val animals: StateFlow<List<Animal>> get() = _animals

    private val _selectedAnimalType = MutableStateFlow("Dogs")
    val selectedAnimalType: StateFlow<String> get() = _selectedAnimalType

    private val _shelterSettings = MutableStateFlow<ShelterSettings?>(null)
    val shelterSettings = _shelterSettings.asStateFlow()

    // State variables for dialogs and user inputs
    private val _showNameDialog = MutableStateFlow(false)
    val showNameDialog: StateFlow<Boolean> get() = _showNameDialog

    private val _showLetOutTypeDialog = MutableStateFlow(false)
    val showLetOutTypeDialog: StateFlow<Boolean> get() = _showLetOutTypeDialog

    var name: String = ""

    private val _volunteerName = MutableStateFlow("")
    val volunteerName: StateFlow<String> get() = _volunteerName

    private val _selectedLetOutType = MutableStateFlow("")
    val selectedLetOutType: StateFlow<String> get() = _selectedLetOutType

    private var currentAnimalId: String? = null


    init {
        fetchAnimals()
        fetchShelterSettings()
        fetchVolunteerName()
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
//                    val success = repository.toggleInCage(animalId, newInCageValue)
                    if (!newInCageValue) {
                        takeOutAnimal(animalId = animalId)
                    } else {
                        putBackAnimal(animalId = animalId)
                    }
                }
            }
        }
    }

    fun takeOutAnimal(animalId: String) {
        currentAnimalId = animalId
        viewModelScope.launch {
            val requireName = shelterSettings.value?.requireName == true
            val requireLetOutType = shelterSettings.value?.requireLetOutType == true

            if (requireName && requireLetOutType) {
                if (name.isBlank()) {
                    _showNameDialog.value = true
                } else {
                    _showLetOutTypeDialog.value = true
                }
            } else if (requireName) {
                println("[LOG]: should require name")
                if (_volunteerName.value.isBlank()) {
                    _showNameDialog.value = true
                } else {
                    toggleAnimalOut()
                }
            } else if (requireLetOutType) {
                _showLetOutTypeDialog.value = true
            } else {
                toggleAnimalOut()
            }
        }
    }

    private fun toggleAnimalOut() {
        currentAnimalId?.let { animalId ->
            viewModelScope.launch {
                repository.toggleInCage(animalId = animalId, newInCageValue = false)
            }
        }
    }


    fun putBackAnimal(animalId: String) {
        viewModelScope.launch {
            repository.toggleInCage(animalId = animalId, newInCageValue = true)

        }
    }

    private fun fetchShelterSettings() {
        viewModelScope.launch {
            repository.getStoredShelterID()?.let {
                repository.getSettingsStream(it)
                    .onEach { settings ->
                        _shelterSettings.value = settings
                    }
                    .launchIn(this)
            }
        }
    }

    private fun fetchVolunteerName() {
        viewModelScope.launch {
            val tempName = repository.getUserName()
            if (tempName != null) {
                name = tempName
                _volunteerName.value = tempName
            }
        }
    }


    fun onVolunteerNameSubmit(name: String) {
        viewModelScope.launch {
            _volunteerName.value = name
            _showNameDialog.value = false
            val requireLetOutType = shelterSettings.value?.requireLetOutType == true
            if (requireLetOutType) {
                _showLetOutTypeDialog.value = true
            } else {
                updateAnimalWithVolunteerName()
                currentAnimalId?.let { repository.toggleInCage(animalId = it, newInCageValue = false) }
            }
        }
    }

    fun onLetOutTypeSubmit(letOutType: String) {
        viewModelScope.launch {
            _selectedLetOutType.value = letOutType
            _showLetOutTypeDialog.value = false
            updateAnimalWithLetOutType()
            if (shelterSettings.value?.requireName == true && _volunteerName.value.isNotBlank()) {
                updateAnimalWithVolunteerName()
            }
            currentAnimalId?.let { repository.toggleInCage(animalId = it, newInCageValue = false) }
        }
    }

    fun onNameDialogDismiss() {
        _showNameDialog.value = false
    }

    fun onLetOutTypeDialogDismiss() {
        _showLetOutTypeDialog.value = false
    }

    private suspend fun updateAnimalWithVolunteerName() {
        currentAnimalId?.let { animalId ->
            val shelterID = repository.getStoredShelterID()
            val animalType = _selectedAnimalType.value
            if (shelterID != null) {
                repository.updateAnimalField(
                    shelterID,
                    animalType,
                    animalId,
                    "lastVolunteer",
                    _volunteerName.value
                )
            }
        }
    }

    private suspend fun updateAnimalWithLetOutType() {
        currentAnimalId?.let { animalId ->
            val shelterID = repository.getStoredShelterID()
            val animalType = _selectedAnimalType.value
            if (shelterID != null) {
                repository.updateAnimalField(
                    shelterID,
                    animalType,
                    animalId,
                    "lastLetOutType",
                    _selectedLetOutType.value
                )
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