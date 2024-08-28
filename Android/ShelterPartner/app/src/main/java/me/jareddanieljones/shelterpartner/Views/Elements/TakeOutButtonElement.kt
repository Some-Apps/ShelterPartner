package me.jareddanieljones.shelterpartner.Views.Elements

import android.media.Image
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import coil.request.ImageRequest
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import me.jareddanieljones.shelterpartner.R

@Composable
fun TakeOutButtonElement(photo: String, onComplete: () -> Unit) {
    var isPressed by remember { mutableStateOf(false) }
    var progress by remember { mutableStateOf(0f) }

    val coroutineScope = rememberCoroutineScope()

    Surface(
        modifier = Modifier
            .size(100.dp)
            .border(
                width = 8.dp,  // Thicker border
                color = if (isPressed) Color.Cyan else Color.Gray,
                shape = CircleShape
            )
            .background(MaterialTheme.colorScheme.background, CircleShape)
            .pointerInput(Unit) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        progress = 0f
                        coroutineScope.launch {
                            while (progress < 1f) {
                                delay(40)  // Slower progress
                                progress += 0.01f
                            }
                            onComplete()
                        }
                        awaitRelease()
                        isPressed = false
                        coroutineScope.launch {
                            while (progress > 0f) {
                                delay(10)  // Slightly faster reset
                                progress -= 0.05f
                            }
                            progress = 0f  // Ensure it goes back to 0
                        }
                    }
                )
            },
        shape = CircleShape,
        color = MaterialTheme.colorScheme.background,
    ) {
        Box(contentAlignment = androidx.compose.ui.Alignment.Center) {
            CircularProgressIndicator(
                progress = progress,
                strokeWidth = 8.dp,
                modifier = Modifier.size(100.dp),
                color = if (isPressed) Color.Cyan else Color.Gray
            )
            AsyncImage(
                model = ImageRequest.Builder(LocalContext.current)
                    .data(photo)
                    .crossfade(true)
                    .build(),
                contentDescription = null,
                modifier = Modifier.size(90.dp),
                contentScale = ContentScale.Crop
            )
        }
    }
}
