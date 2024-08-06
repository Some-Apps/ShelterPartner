package me.jareddanieljones.shelterpartner.Views.MainViews

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.Text
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import me.jareddanieljones.shelterpartner.FirebaseRepository
import me.jareddanieljones.shelterpartner.R
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerSettingsViewModel

@Composable
fun VolunteerSettingsView() {
    val firebaseRepository = FirebaseRepository()
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