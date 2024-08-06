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
import me.jareddanieljones.shelterpartner.ui.theme.ShelterPartnerTheme
import androidx.compose.material3.Scaffold
import com.google.firebase.FirebaseApp
import android.util.Log
import me.jareddanieljones.shelterpartner.Views.MainViews.LoginView
import androidx.compose.runtime.*
import com.google.firebase.auth.FirebaseAuth
import me.jareddanieljones.shelterpartner.Views.MainViews.VolunteerSettingsView
import me.jareddanieljones.shelterpartner.Views.MainViews.VolunteerView

class AuthenticationView : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            FirebaseApp.initializeApp(this)
            Log.d("AuthenticationView", "Firebase initialized successfully")
        } catch (e: Exception) {
            Log.e("AuthenticationView", "Error initializing Firebase", e)
        }
        WindowCompat.setDecorFitsSystemWindows(window, false)
        enableEdgeToEdge()
        setContent {
            ShelterPartnerTheme {
                val auth = FirebaseAuth.getInstance()
                var isAuthenticated by remember { mutableStateOf(auth.currentUser != null) }

                DisposableEffect(auth) {
                    val authStateListener = FirebaseAuth.AuthStateListener { firebaseAuth ->
                        isAuthenticated = firebaseAuth.currentUser != null
                    }
                    auth.addAuthStateListener(authStateListener)
                    onDispose {
                        auth.removeAuthStateListener(authStateListener)
                    }
                }

                if (isAuthenticated) {
                    val navController = rememberNavController()
                    Scaffold(
                        bottomBar = { NavigationBarElement(navController) },
                        modifier = Modifier.fillMaxSize()
                    ) { innerPadding ->
                        NavHost(
                            navController = navController,
                            startDestination = "volunteer",
                            modifier = Modifier.padding(innerPadding)
                        ) {
                            composable("volunteer") { VolunteerView() }
                            composable("visitor") { VisitorView() }
                            composable("settings") { VolunteerSettingsView() }
                        }
                    }
                } else {
                    LoginView()
                }
            }
        }
    }
}


