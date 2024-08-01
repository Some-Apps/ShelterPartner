package me.jareddanieljones.shelterpartner.Views.Elements

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.navigation.NavController
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Settings

@Composable
fun NavigationBarElement(navController: NavController) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination?.route ?: "volunteer"

    NavigationBar {
        NavigationBarItem(
            selected = currentDestination == "volunteer",
            onClick = { navController.navigate("volunteer") },
            icon = {
                if (currentDestination == "volunteer") {
                    Icon(Icons.Filled.Person, contentDescription = "Volunteer")
                } else {
                    Icon(Icons.Outlined.Person, contentDescription = "Volunteer")
                }
            },
            label = { Text("Volunteer") }
        )
        NavigationBarItem(
            selected = currentDestination == "visitor",
            onClick = { navController.navigate("visitor") },
            icon = {
                if (currentDestination == "visitor") {
                    Icon(Icons.Filled.People, contentDescription = "Visitor")
                } else {
                    Icon(Icons.Outlined.People, contentDescription = "Visitor")
                }
            },
            label = { Text("Visitor") }
        )
        NavigationBarItem(
            selected = currentDestination == "settings",
            onClick = { navController.navigate("settings") },
            icon = {
                if (currentDestination == "settings") {
                    Icon(Icons.Filled.Settings, contentDescription = "Settings")
                } else {
                    Icon(Icons.Outlined.Settings, contentDescription = "Settings")
                }
            },
            label = { Text("Settings") }
        )
    }
}
