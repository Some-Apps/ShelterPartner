package me.jareddanieljones.shelterpartner.Views.MainViews

import android.app.Application
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import me.jareddanieljones.shelterpartner.Data.FirestoreRepository
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerSettingsViewModel
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerSettingsViewModelFactory
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerViewModel
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerViewModelFactory

@Composable
fun VolunteerSettingsView() {

    // Get the Application Context and cast it to Application
    val application = LocalContext.current.applicationContext as Application

    // Create the ViewModel with Application Context
    val viewModel: VolunteerSettingsViewModel = viewModel(
        factory = VolunteerSettingsViewModelFactory(application)
    )

    val settings by viewModel.shelterSettings.collectAsStateWithLifecycle()


    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column {
            Text(settings.toString())
            TextButton(
                onClick = { viewModel.signOut() },
            ) {
                Text(
                    text = "Sign Out",
                    fontSize = 17.sp
                )
            }
        }
        
    }
}
