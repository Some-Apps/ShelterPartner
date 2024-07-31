package me.jareddanieljones.shelterpartner

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Pets
import androidx.compose.material.icons.filled.Settings
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import me.jareddanieljones.shelterpartner.ui.theme.ShelterPartnerTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ShelterPartnerTheme {
                val navController = rememberNavController()
                Scaffold(
                    bottomBar = { NavigationBarElement(navController) },
                    modifier = Modifier.fillMaxSize()
                ) { innerPadding ->
                    NavHost(
                        navController = navController,
                        startDestination = "volunteer",
                        modifier = Modifier
                            .padding(innerPadding)
                    ) {
                        composable("volunteer") { Greeting("Volunteer") }
                        composable("visitor") { Greeting("Visitor") }
                        composable("settings") { Greeting("Settings") }
                    }
                }
            }
        }
    }
}

@Composable
fun NavigationBarElement(navController: NavController) {
    BottomNavigation(
        backgroundColor = MaterialTheme.colors.primary, // Set the background color
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colors.primary)
//            .windowInsetsPadding(WindowInsets.navigationBars)
    ) {
        BottomNavigationItem(
            icon = { Icon(Icons.Filled.Pets, contentDescription = "Volunteer") },
            label = { Text("Volunteer") },
            selected = false,
            onClick = { navController.navigate("volunteer") }
        )
        BottomNavigationItem(
            icon = { Icon(Icons.Filled.People, contentDescription = "Visitor") },
            label = { Text("Visitor") },
            selected = false,
            onClick = { navController.navigate("visitor") }
        )
        BottomNavigationItem(
            icon = { Icon(Icons.Filled.Settings, contentDescription = "Settings") },
            label = { Text("Settings") },
            selected = false,
            onClick = { navController.navigate("settings") }
        )
    }
}

@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "Hello $name!",
        modifier = modifier.padding(16.dp) // Add padding around the text
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    ShelterPartnerTheme {
        Greeting("Android")
    }
}




