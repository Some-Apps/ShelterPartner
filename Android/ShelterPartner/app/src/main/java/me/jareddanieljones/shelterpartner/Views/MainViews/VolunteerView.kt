package me.jareddanieljones.shelterpartner.Views.MainViews

import android.app.Application
import android.net.Uri
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
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
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.ModalBottomSheetValue
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import coil.compose.rememberAsyncImagePainter
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import android.os.Build

import com.google.accompanist.permissions.rememberPermissionState


import kotlinx.coroutines.launch
import me.jareddanieljones.shelterpartner.Data.Animal
import me.jareddanieljones.shelterpartner.Data.ShelterSettings
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerViewModel
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerViewModelFactory
import me.jareddanieljones.shelterpartner.Views.Elements.CardElement

@Composable
fun VolunteerView(
    viewModel: VolunteerViewModel = viewModel(
        factory = VolunteerViewModelFactory(LocalContext.current.applicationContext as Application)
    )
) {
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
            println("[LOG]: $animals")
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
//            ThankYouDialog(
//                animal = currentAnimal,
//                onDismiss = { viewModel.onThankYouDialogDismiss() },
//                onAddNote = { viewModel.onAddNoteSelected() }
//            )
            shelterSettings?.let {
                ThankYouDialog(
                    animal = currentAnimal,
                    onDismiss = { viewModel.onThankYouDialogDismiss() },
                    onAddNote = { viewModel.onAddNoteSelected() },
                    shelterSettings = it
                )
            }
        }

        if (showAddNoteDialog) {
            AddNoteDialog(
                onDismiss = { viewModel.onAddNoteDismiss() },
                onSubmit = { noteText, imageUri -> viewModel.onAddNoteSubmit(noteText, imageUri) }
            )
        }

    }
}

@Composable
fun ThankYouDialog(
    animal: Animal,
    onDismiss: () -> Unit,
    onAddNote: () -> Unit,
    shelterSettings: ShelterSettings
) {
    var showQRCodeDialog by remember { mutableStateOf(false) }
    var showOpenLink by remember { mutableStateOf(false) }
    var showDialog by remember { mutableStateOf(true) } // State to control whether to show the dialog

    if (showDialog) {
        AlertDialog(
            onDismissRequest = {
                showDialog = false
                onDismiss()
            },
            title = {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
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
                    TextButton(onClick = {
                        showDialog = false
                        onDismiss()
                    }) {
                        Text("Dismiss")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    TextButton(onClick = onAddNote) {
                        Text("Add Note")
                    }

                    // Conditionally display "Custom Form" button based on isCustomFormOn setting
                    if (shelterSettings.isCustomFormOn) {
                        Spacer(modifier = Modifier.width(8.dp))
                        TextButton(onClick = {
                            showDialog = false // Hide the dialog before showing the sheet
                            if (shelterSettings.linkType == "QR Code") {
                                showQRCodeDialog = true // Trigger QR Code dialog
                            } else {
                                showOpenLink = true // Show WebView sheet
                            }
                        }) {
                            Text("Custom Form")
                        }
                    }
                }
            },
            dismissButton = {}
        )
    }

    // Show QR Code dialog if the state is true
    if (showQRCodeDialog) {
        showQRCodeDialog(shelterSettings.customFormURL, onDismiss = { showQRCodeDialog = false })
    }

    // Show WebView sheet if the state is true
    if (showOpenLink) {
        WebViewSheet(url = shelterSettings.customFormURL) {
            showOpenLink = false // Hide WebView when dismissed
        }
    }
}

@Composable
fun showQRCodeDialog(url: String, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Scan QR Code") },
        text = {
            // Load the QR Code image from a URL or a generated image
            // Here we are using a third-party service to generate the QR code
            val qrCodeUrl = "https://api.qrserver.com/v1/create-qr-code/?data=$url&size=200x200"
            Image(
                painter = rememberAsyncImagePainter(model = qrCodeUrl),
                contentDescription = "QR Code",
                modifier = Modifier.fillMaxWidth()
            )
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Done")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterialApi::class)
@Composable
fun WebViewSheet(url: String, onDismiss: () -> Unit) {
    // Correctly handle ModalBottomSheetState
    val sheetState = rememberModalBottomSheetState(
        skipPartiallyExpanded = true // Whether to allow a partially expanded state
    )
    val coroutineScope = rememberCoroutineScope()

    // Launch the bottom sheet automatically on the first composition
    LaunchedEffect(Unit) {
        coroutineScope.launch {
            sheetState.show()
        }
    }

    ModalBottomSheet(
        onDismissRequest = {
            coroutineScope.launch { sheetState.hide() }
            onDismiss()
        }, // Handle dismiss by hiding the sheet
        sheetState = sheetState // Use sheetState to control the modal bottom sheet
    ) {
        // Back handler or close button to exit the webview
        var canGoBack by remember { mutableStateOf(false) }

        AndroidView(
            factory = { context ->
                WebView(context).apply {
                    webViewClient = WebViewClient() // Ensures the URL loads within WebView and not an external browser
                    settings.javaScriptEnabled = true // Enable JavaScript if needed
                    loadUrl(url)

                    setOnKeyListener { _, keyCode, _ ->
                        if (keyCode == android.view.KeyEvent.KEYCODE_BACK && canGoBack) {
                            goBack()
                            true
                        } else {
                            onDismiss()
                            false
                        }
                    }
                }
            },
            update = { webView ->
                canGoBack = webView.canGoBack()
            },
            modifier = Modifier.fillMaxWidth()
        )
    }
}


@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun AddNoteDialog(
    onDismiss: () -> Unit,
    onSubmit: (String, Uri?) -> Unit
) {
    var noteText by remember { mutableStateOf("") }
    var selectedImageUri by remember { mutableStateOf<Uri?>(null) }

    // Permissions
    val storagePermissionState = rememberPermissionState(
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            android.Manifest.permission.READ_MEDIA_IMAGES
        } else {
            android.Manifest.permission.READ_EXTERNAL_STORAGE
        }
    )

    // Declare the launcher outside of the onClick lambda
    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent(),
        onResult = { uri: Uri? ->
            uri?.let { selectedImageUri = it }
        }
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Note") },
        text = {
            Column {
                TextField(
                    value = noteText,
                    onValueChange = { noteText = it },
                    label = { Text("Note") },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))

                // Image selection
                Button(onClick = {
                    if (storagePermissionState.status.isGranted) {
                        // Open image picker directly
                        launcher.launch("image/*")
                    } else {
                        storagePermissionState.launchPermissionRequest()
                    }
                }) {
                    Text("Select Image")
                }

                // Show selected image preview
                selectedImageUri?.let { uri ->
                    Spacer(modifier = Modifier.height(8.dp))
                    Image(
                        painter = rememberAsyncImagePainter(uri),
                        contentDescription = null,
                        modifier = Modifier
                            .size(100.dp)
                            .clip(CircleShape)
                            .background(Color.Gray)
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = {
                onSubmit(noteText, selectedImageUri)
            }) {
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


// Helper function to open image picker
@Composable
fun selectImage(onImageSelected: (Uri) -> Unit) {
    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent(),
        onResult = { uri: Uri? ->
            uri?.let { onImageSelected(it) }
        }
    )
    SideEffect {
        launcher.launch("image/*")
    }
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