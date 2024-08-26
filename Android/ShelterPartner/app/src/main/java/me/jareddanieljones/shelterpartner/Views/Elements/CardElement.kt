package me.jareddanieljones.shelterpartner.Views.Elements

import me.jareddanieljones.shelterpartner.Data.Animal

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp

@Composable
fun CardElement(animal: Animal) {
    val backgroundColor = when {
        animal.canPlay && animal.inCage -> Color(0xFF89CFE0)
        animal.canPlay -> Color(0xFFEBCA96)
        else -> Color(0xFFC8C8C8)
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp)
            .background(backgroundColor, RoundedCornerShape(20.dp))
            .padding(16.dp)
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
}