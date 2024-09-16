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
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import me.jareddanieljones.shelterpartner.Data.Log
import me.jareddanieljones.shelterpartner.Data.Note
import me.jareddanieljones.shelterpartner.Data.ShelterSettings
import java.util.UUID


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

    private val _showThankYouDialog = MutableStateFlow(false)
    val showThankYouDialog: StateFlow<Boolean> get() = _showThankYouDialog

    private val _showAddNoteDialog = MutableStateFlow(false)
    val showAddNoteDialog: StateFlow<Boolean> get() = _showAddNoteDialog

    private val _volunteerName = MutableStateFlow("")
    val volunteerName: StateFlow<String> get() = _volunteerName

    private val _selectedLetOutType = MutableStateFlow("")
    val selectedLetOutType: StateFlow<String> get() = _selectedLetOutType

    private val _currentAnimalId = MutableStateFlow<String?>(null)
    val currentAnimalId: StateFlow<String?> get() = _currentAnimalId

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
            val shelterID = repository.getShelterID()
            val animalType = _selectedAnimalType.value

            if (shelterID != null) {
                val currentAnimal = repository.getAnimalById(animalId, shelterID, animalType)
                if (currentAnimal != null) {
                    val newInCageValue = !currentAnimal.inCage
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
        _currentAnimalId.value = animalId
        viewModelScope.launch {
            val requireName = shelterSettings.value?.requireName == true
            val requireLetOutType = shelterSettings.value?.requireLetOutType == true

            if (requireName && requireLetOutType) {
                if (_volunteerName.value.isBlank()) {
                    _showNameDialog.value = true
                } else {
                    _showLetOutTypeDialog.value = true
                }
            } else if (requireName) {
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
        _currentAnimalId.value?.let { animalId ->
            viewModelScope.launch {
                repository.toggleInCage(animalId = animalId, animalType = selectedAnimalType.value, newInCageValue = false)
                // Update startTime in Firestore
                val shelterID = repository.getStoredShelterID()
                val animalType = _selectedAnimalType.value
                if (shelterID != null) {
                    repository.updateAnimalField(
                        shelterID,
                        animalType,
                        animalId,
                        "startTime",
                        System.currentTimeMillis().toDouble() / 1000.0
                    )
                }
            }
        }
    }

    fun putBackAnimal(animalId: String) {
        /*
        - The animal should be put back in their cage
        - The createLog function should be called
        - Show a popup with the animal's first photo clipped in a circle. Below that it says "Thank You!" and below that are two buttons; "Dismiss" and "Add Note"
        - If the user selected "Add Note" the popup will be dismissed and a new popup will be displayed.
        - The new popup will have a text field allowing the user to add notes and a "Save" button.
        - Tapping the save adds the note to firestore and then dismisses the view
        - Firestore Path for note: Societies/$shelterID/$animalType/$animalID/ (this is an array of map)
         */
        _currentAnimalId.value = animalId
        viewModelScope.launch {
            val shelterID = repository.getStoredShelterID()
            val animalType = _selectedAnimalType.value
            if (shelterID != null) {
                // Update the animal's inCage status to true
                repository.updateAnimalField(
                    shelterID,
                    animalType,
                    animalId,
                    "inCage",
                    true
                )
                // Call createLog function
                createLog(animalId)
                // Show the Thank You popup
                _showThankYouDialog.value = true
            }
        }
    }

    fun createLog(animalId: String) {
        /*
        - A log should be created for the animal and appended to logs in firestore
        - Log.startTime is the startTime attribute in the animal's document
        - Log.endTime is now
        - Log.user is the lastVolunteer attribute in the animal's document
        - Log.shortReason should just be an empty string for now
        - Log.letOutType is the lastLetOutType attribute in the animal's document
        - Firestore Path for logs: Societies/$shelterID/$animalType/$animalID/ (this is an array of Map)
        - The lastVolunteer and lastLetOutType attributes in the animal's document should be reset to an empty string
         */
        viewModelScope.launch {
            val shelterID = repository.getStoredShelterID()
            val animalType = _selectedAnimalType.value
            if (shelterID != null) {
                val animal = repository.getAnimalById(animalId, shelterID, animalType)
                if (animal != null) {
                    val log = Log(
                        id = UUID.randomUUID().toString(),
                        startTime = animal.startTime,
                        endTime = System.currentTimeMillis().toDouble() / 1000.0,
                        user = animal.lastVolunteer,
                        shortReason = "",  // Empty string for now
                        letOutType = animal.lastLetOutType
                    )
                    // Append the log to the logs collection in Firestore
                    repository.addLog(
                        shelterID = shelterID,
                        animalType = animalType,
                        animalId = animalId,
                        log = log
                    )
                    // Reset lastVolunteer and lastLetOutType in the animal's document
                    repository.updateAnimalField(
                        shelterID = shelterID,
                        animalType = animalType,
                        animalId,
                        "lastVolunteer",
                        ""
                    )
                    repository.updateAnimalField(
                        shelterID = shelterID,
                        animalType = animalType,
                        animalId,
                        "lastLetOutType",
                        ""
                    )
                }
            }
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
                _currentAnimalId.value?.let { repository.toggleInCage(animalId = it, animalType = selectedAnimalType.value, newInCageValue = false) }
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
            _currentAnimalId.value?.let { repository.toggleInCage(animalId = it, animalType = selectedAnimalType.value, newInCageValue = false) }
        }
    }

    fun onNameDialogDismiss() {
        _showNameDialog.value = false
    }

    fun onLetOutTypeDialogDismiss() {
        _showLetOutTypeDialog.value = false
    }

    fun onThankYouDialogDismiss() {
        _showThankYouDialog.value = false
        _currentAnimalId.value = null
    }

    fun onAddNoteSelected() {
        _showThankYouDialog.value = false
        _showAddNoteDialog.value = true
    }

    fun onAddNoteDismiss() {
        _showAddNoteDialog.value = false
        _currentAnimalId.value = null
    }

    fun onAddNoteSubmit(noteText: String) {
        viewModelScope.launch {
            val shelterID = repository.getStoredShelterID()
            val animalType = _selectedAnimalType.value
            val animalId = _currentAnimalId.value
            if (shelterID != null && animalId != null) {
                val note = Note(
                    id = UUID.randomUUID().toString(),
                    date = System.currentTimeMillis().toDouble() / 1000.0,
                    note = noteText,
                    user = _volunteerName.value
                )
                repository.addNote(
                    shelterID = shelterID,
                    animalType = animalType,
                    animalId = animalId,
                    note = note
                )
            }
            _showAddNoteDialog.value = false
            _currentAnimalId.value = null
        }
    }

    private suspend fun updateAnimalWithVolunteerName() {
        _currentAnimalId.value?.let { animalId ->
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
        _currentAnimalId.value?.let { animalId ->
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