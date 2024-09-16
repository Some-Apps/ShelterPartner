package me.jareddanieljones.shelterpartner.Views.MainViews

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.runtime.Composable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import kotlinx.coroutines.launch
import me.jareddanieljones.shelterpartner.Data.Animal
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerViewModel
import me.jareddanieljones.shelterpartner.Views.Elements.CardElement

@Composable
fun VolunteerView(viewModel: VolunteerViewModel = viewModel()) {
    val animals by viewModel.animals.collectAsStateWithLifecycle()
    val selectedAnimalType by viewModel.selectedAnimalType.collectAsStateWithLifecycle()
    val showNameDialog by viewModel.showNameDialog.collectAsStateWithLifecycle()
    val showLetOutTypeDialog by viewModel.showLetOutTypeDialog.collectAsStateWithLifecycle()
    val shelterSettings by viewModel.shelterSettings.collectAsStateWithLifecycle()
    val showThankYouDialog by viewModel.showThankYouDialog.collectAsStateWithLifecycle()
    val showAddNoteDialog by viewModel.showAddNoteDialog.collectAsStateWithLifecycle()
    val currentAnimalId by viewModel.currentAnimalId.collectAsStateWithLifecycle()
    val currentAnimal = animals.find { it.id == currentAnimalId }

    Column(modifier = Modifier.fillMaxSize()) {
        SegmentedControl(
            options = listOf("Dogs", "Cats"),
            selectedOption = selectedAnimalType,
            onOptionSelected = { viewModel.onAnimalTypeChange(it) }
        )

        LazyColumn {
            items(animals, key = { it.id }) { animal ->
                CardElement(
                    animal = animal,
                    viewModel = viewModel,
                )
            }
        }

        if (showNameDialog) {
            NameInputDialog(
                onDismissRequest = { viewModel.onNameDialogDismiss() },
                onSubmit = { name ->
                    viewModel.onVolunteerNameSubmit(name)
                }
            )
        }

        if (showLetOutTypeDialog) {
            shelterSettings?.let { settings ->
                LetOutTypePickerDialog(
                    letOutTypes = settings.letOutTypes,
                    onDismissRequest = { viewModel.onLetOutTypeDialogDismiss() },
                    onSubmit = { letOutType ->
                        viewModel.onLetOutTypeSubmit(letOutType)
                    }
                )
            }
        }

        if (showThankYouDialog && currentAnimal != null) {
            ThankYouDialog(
                animal = currentAnimal,
                onDismiss = { viewModel.onThankYouDialogDismiss() },
                onAddNote = { viewModel.onAddNoteSelected() }
            )
        }

        if (showAddNoteDialog) {
            AddNoteDialog(
                onDismiss = { viewModel.onAddNoteDismiss() },
                onSubmit = { noteText -> viewModel.onAddNoteSubmit(noteText) }
            )
        }
    }
}

@Composable
fun ThankYouDialog(
    animal: Animal,
    onDismiss: () -> Unit,
    onAddNote: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                // Display the animal's first photo clipped in a circle
                val imageURL = animal.photos.firstOrNull()?.url
                if (imageURL != null) {
                    AsyncImage(
                        model = imageURL,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .size(100.dp)
                            .clip(CircleShape)
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
                Text("Thank You!", style = MaterialTheme.typography.titleLarge)
            }
        },
        text = {},
        confirmButton = {
            Row {
                TextButton(onClick = onDismiss) {
                    Text("Dismiss")
                }
                Spacer(modifier = Modifier.width(8.dp))
                TextButton(onClick = onAddNote) {
                    Text("Add Note")
                }
            }
        },
        dismissButton = {}
    )
}

@Composable
fun AddNoteDialog(
    onDismiss: () -> Unit,
    onSubmit: (String) -> Unit
) {
    var noteText by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Note") },
        text = {
            TextField(
                value = noteText,
                onValueChange = { noteText = it },
                label = { Text("Note") }
            )
        },
        confirmButton = {
            TextButton(onClick = { onSubmit(noteText) }) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}


@Composable
fun NameInputDialog(
    onDismissRequest: () -> Unit,
    onSubmit: (String) -> Unit
) {
    var name by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismissRequest,
        title = { Text("Enter your name") },
        text = {
            TextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Name") }
            )
        },
        confirmButton = {
            TextButton(onClick = { onSubmit(name) }) {
                Text("Submit")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismissRequest) {
                Text("Nevermind")
            }
        }
    )
}

@Composable
fun LetOutTypePickerDialog(
    letOutTypes: List<String>,
    onDismissRequest: () -> Unit,
    onSubmit: (String) -> Unit
) {
    var selectedLetOutType by remember { mutableStateOf(letOutTypes.firstOrNull() ?: "") }

    AlertDialog(
        onDismissRequest = onDismissRequest,
        title = { Text("Select Let Out Type") },
        text = {
            Column {
                letOutTypes.forEach { type ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        RadioButton(
                            selected = selectedLetOutType == type,
                            onClick = { selectedLetOutType = type }
                        )
                        Text(text = type)
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = { onSubmit(selectedLetOutType) }) {
                Text("Submit")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismissRequest) {
                Text("Nevermind")
            }
        }
    )
}


@Composable
fun SegmentedControl(
    options: List<String>,
    selectedOption: String,
    onOptionSelected: (String) -> Unit
) {
    val scope = rememberCoroutineScope()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp),
        horizontalArrangement = Arrangement.Center
    ) {
        options.forEach { option ->
            Button(
                onClick = {
                    scope.launch {
                        onOptionSelected(option)
                    }
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (selectedOption == option) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surface,
                    contentColor = if (selectedOption == option) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface
                ),
                modifier = Modifier.weight(1f)
            ) {
                Text(text = option)
            }
        }
    }
}