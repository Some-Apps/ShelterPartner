package me.jareddanieljones.shelterpartner

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.Modifier
import androidx.core.view.WindowCompat
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import me.jareddanieljones.shelterpartner.Views.Elements.NavigationBarElement
import me.jareddanieljones.shelterpartner.Views.MainViews.SettingsView
import me.jareddanieljones.shelterpartner.Views.MainViews.VisitorView
import me.jareddanieljones.shelterpartner.Views.MainViews.VolunteerView
import me.jareddanieljones.shelterpartner.ui.theme.ShelterPartnerTheme
import androidx.compose.material3.Scaffold
import me.jareddanieljones.shelterpartner.Views.MainViews.LoginView


class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        enableEdgeToEdge()
        setContent {
            ShelterPartnerTheme {
                val navController = rememberNavController()
                Scaffold(
                    bottomBar = { NavigationBarElement(navController) },
                    modifier = Modifier
                        .fillMaxSize()
                ) { innerPadding ->
                    NavHost(
                        navController = navController,
                        startDestination = "volunteer",
                        modifier = Modifier
                            .padding(innerPadding)
                    ) {
                        composable("volunteer") {
                            LoginView()
//                            VolunteerView()
                        }
                        composable("visitor") { VisitorView() }
                        composable("settings") { SettingsView() }
                    }
                }
            }
        }
    }
}






