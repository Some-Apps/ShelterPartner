package me.jareddanieljones.shelterpartner.Views.MainViews

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.runtime.Composable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.launch
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerViewModel
import me.jareddanieljones.shelterpartner.Views.Elements.CardElement

@Composable
fun VolunteerView(viewModel: VolunteerViewModel = viewModel()) {
    val animals = viewModel.animals.collectAsState()
    val selectedAnimalType = viewModel.selectedAnimalType.collectAsState()

    Column(modifier = Modifier.fillMaxSize()) {
        SegmentedControl(
            options = listOf("Dogs", "Cats"),
            selectedOption = selectedAnimalType.value,
            onOptionSelected = { viewModel.onAnimalTypeChange(it) }
        )
        LazyColumn {
            items(animals.value) { animal ->
                CardElement(animal = animal)
            }
        }
    }
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