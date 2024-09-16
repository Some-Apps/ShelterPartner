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
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
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

    val cornerRadius = 20.dp
    val shadowColor = Color.Black.copy(alpha = 0.5f)
    val shadowElevation = 2.dp  // This corresponds to the blur radius in SwiftUI
    val shadowOffsetX = 1.dp
    val shadowOffsetY = 2.dp

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp)
    ) {
        // Shadow Layer
        Box(
            modifier = Modifier
                .matchParentSize()
                .offset(
                    x = shadowOffsetX,
                    y = shadowOffsetY
                )
                .background(
                    color = shadowColor,
                    shape = RoundedCornerShape(cornerRadius)
                )
                .blur(radius = shadowElevation)
        )

        // Content Layer
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    color = backgroundColor,
                    shape = RoundedCornerShape(cornerRadius)
                )
                .clip(RoundedCornerShape(cornerRadius))
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .align(Alignment.Top)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = animal.name,
                        style = MaterialTheme.typography.titleLarge.copy(
                            fontWeight = FontWeight.ExtraBold,
                            textDecoration = TextDecoration.Underline
                        ),
                        modifier = Modifier.padding(end = 8.dp)
                    )

                    Box(
                        modifier = Modifier
                            .size(25.dp)
                            .background(
                                color = Color.Gray.copy(alpha = 0.2f),
                                shape = CircleShape
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        IconButton(onClick = {
                            // Navigate to AnimalDetailView with animal as a parameter
                        }) {
                            Icon(
                                imageVector = Icons.Default.MoreVert,
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
                Text(text = animal.timeSinceLastLetOut)
                // add a for each or list that displays all the logs for this animal
            }

            if (animal.photos.isNotEmpty()) {
                Box(
                    modifier = Modifier.padding(10.dp)
                ) {
                    TakeOutButtonElement(
                        animalId = animal.id,
                        enabled = animal.canPlay
                    ) {
                        println("[LOG]: the button pressed")
                        viewModel.toggleInCage(animalId = animal.id)
                    }
                }
            }
        }
    }
}
