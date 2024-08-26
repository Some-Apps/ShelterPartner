package me.jareddanieljones.shelterpartner.Views.MainViews

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.sp
import me.jareddanieljones.shelterpartner.Data.FirestoreRepository
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerSettingsViewModel

@Composable
fun VolunteerSettingsView() {
    val firebaseRepository = FirestoreRepository()
    val viewModel = VolunteerSettingsViewModel(firebaseRepository)

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
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