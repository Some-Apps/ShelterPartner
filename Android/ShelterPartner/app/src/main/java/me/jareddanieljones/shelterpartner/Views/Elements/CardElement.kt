package me.jareddanieljones.shelterpartner.Views.Elements

import me.jareddanieljones.shelterpartner.Data.Animal

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import me.jareddanieljones.shelterpartner.R
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerViewModel

@Composable
fun CardElement(
    animal: Animal,
    viewModel: VolunteerViewModel
) {
    val backgroundColor = when {
        animal.canPlay && animal.inCage -> Color(0xFF89CFE0)
        animal.canPlay -> Color(0xFFEBCA96)
        else -> Color(0xFFC8C8C8)
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp)
            .background(backgroundColor, RoundedCornerShape(20.dp))
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .align(Alignment.Top)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically, // Align content vertically
            ) {
                Text(
                    text = animal.name,
                    style = MaterialTheme.typography.titleLarge.copy(
                        fontWeight = FontWeight.ExtraBold,
                        textDecoration = TextDecoration.Underline
                    ),
                    modifier = Modifier.padding(end = 8.dp) // Optional padding to add space between name and icon
                )

                Box(
                    modifier = Modifier
                        .size(25.dp) // Adjust size of the circle
                        .background(
                            color = Color.Gray.copy(alpha = 0.2f), // Gray circle with transparency
                            shape = CircleShape
                        ),
                    contentAlignment = Alignment.Center // Center the icon inside the circle
                ) {
                    IconButton(onClick = {
                        // Navigate to AnimalDetailView with animal as a parameter
                        // navController.navigate("animal_detail/${animal.id}")
                    }) {
                        Icon(
                            imageVector = Icons.Default.MoreVert, // 3-dot ellipses icon
                            contentDescription = "More options"
                        )
                    }
                }
            }



            Text(
                text = animal.location,
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Normal)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Some additional info here",
                style = MaterialTheme.typography.bodyMedium
            )
        }

        if (animal.photos.isNotEmpty()) {
            Box(
                modifier = Modifier.padding(10.dp)
            ) {
                TakeOutButtonElement(
                    animalId = animal.id
                ) {
                    println("[LOG]: the button pressed")
                    viewModel.toggleInCage(animalId = animal.id)
                }
            }
        }
    }
}

