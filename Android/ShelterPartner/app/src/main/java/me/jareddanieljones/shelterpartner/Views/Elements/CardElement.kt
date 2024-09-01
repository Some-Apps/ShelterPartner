package me.jareddanieljones.shelterpartner.Views.Elements

import me.jareddanieljones.shelterpartner.Data.Animal

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
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

@Composable
fun CardElement(animal: Animal) {
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
            Text(
                text = animal.name,
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Bold,
                    textDecoration = TextDecoration.Underline
                )
            )
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

        // Load the first image from animal.photos using AsyncImage
        if (animal.photos.isNotEmpty()) {
            Box(
                modifier = Modifier
                    .padding(10.dp)  // Apply padding here
            ) {
                TakeOutButtonElement(
                    animal = animal
                ) {
                    println("button pressed")
                }
            }




        } else {
            // Fallback or placeholder if no photo is available
            Image(
                painter = painterResource(id = R.drawable.ic_launcher_background), // Replace with your placeholder resource
                contentDescription = null,
                modifier = Modifier.size(90.dp),
                contentScale = ContentScale.FillBounds
            )
        }
    }
}
