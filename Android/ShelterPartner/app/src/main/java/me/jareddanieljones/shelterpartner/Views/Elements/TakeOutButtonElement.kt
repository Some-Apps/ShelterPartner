package me.jareddanieljones.shelterpartner.Views.Elements

import android.app.Application
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import kotlinx.coroutines.Job
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import me.jareddanieljones.shelterpartner.Data.Animal
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerViewModel
import me.jareddanieljones.shelterpartner.ViewModels.VolunteerViewModelFactory
import kotlin.math.pow

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TakeOutButtonElement(
    animalId: String,
    enabled: Boolean = true, // Added enabled parameter
    function: () -> Unit
) {
    // Get the Application Context and cast it to Application
    val application = LocalContext.current.applicationContext as Application

    // Create the ViewModel with Application Context
    val viewModel: VolunteerViewModel = viewModel(
        factory = VolunteerViewModelFactory(application)
    )

    // Observe the animal list from the ViewModel and find the animal by ID
    val animals by viewModel.animals.collectAsStateWithLifecycle()
    val animal = animals.find { it.id == animalId }

    animal?.let { currentAnimal ->  // Ensure animal is not null
        var progress by remember { mutableStateOf(0f) }
        var isPressed by remember { mutableStateOf(false) }

        val imageURL = currentAnimal.photos.first().url

        val width = 100.dp
        val height = 100.dp
        val lineWidth = 25.dp

        var tickCountPressing by remember { mutableStateOf(0f) }
        var tickCountNotPressing by remember { mutableStateOf(75f) }
        var lastEaseValue by remember { mutableStateOf(0f) }
        val scope = rememberCoroutineScope()

        var currentJob by remember { mutableStateOf<Job?>(null) }

        val primaryColor = Color(0xFF6200EE)
        val transparentGray = Color.Gray.copy(alpha = 0.5f)

        // Reset progress and cancel animations when enabled changes to false
        LaunchedEffect(enabled) {
            if (!enabled) {
                progress = 0f
                isPressed = false
                currentJob?.cancel()
            }
        }

        Box(
            modifier = Modifier
                .size(width, height)
                .let { baseModifier ->
                    if (enabled) {
                        baseModifier.pointerInput(Unit) {
                            awaitPointerEventScope {
                                while (true) {
                                    val event = awaitPointerEvent(PointerEventPass.Initial)
                                    if (event.changes.any { it.pressed }) {
                                        isPressed = true
                                        tickCountPressing = 0f
                                        lastEaseValue = easeIn(0f)

                                        currentJob?.cancel()

                                        currentJob = scope.launch {
                                            while (isPressed && isActive) {
                                                val t = tickCountPressing / 75f
                                                val currentEaseValue = easeIn(t)
                                                val increment = currentEaseValue - lastEaseValue
                                                progress += increment
                                                lastEaseValue = currentEaseValue
                                                tickCountPressing += 1

                                                if (progress >= 1f) {
                                                    progress = 0f
                                                    onCompleteHold(function)
                                                    break
                                                } else if (progress > 0.97f) {
                                                    progress = 1f
                                                }

                                                kotlinx.coroutines.delay(20L)
                                            }
                                        }
                                    } else {
                                        isPressed = false
                                        tickCountNotPressing = 75f
                                        lastEaseValue = easeIn(1f)

                                        currentJob?.cancel()

                                        currentJob = scope.launch {
                                            while (progress > 0f && isActive) {
                                                val t = tickCountNotPressing / 75f
                                                val currentEaseValue = easeIn(t)
                                                val decrement = lastEaseValue - currentEaseValue
                                                progress -= decrement
                                                lastEaseValue = currentEaseValue
                                                tickCountNotPressing -= 1

                                                if (progress <= 0f) {
                                                    progress = 0f
                                                    break
                                                }

                                                kotlinx.coroutines.delay(20L)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        baseModifier // Do not apply pointerInput when disabled
                    }
                },
            contentAlignment = Alignment.Center
        ) {
            Canvas(modifier = Modifier.size(width)) {
                drawCircle(
                    color = transparentGray,
                    style = androidx.compose.ui.graphics.drawscope.Stroke(width = lineWidth.toPx())
                )
                drawArc(
                    color = if (currentAnimal.inCage) Color(0xFFFF9800) else Color(0xFF00BCD4),
                    startAngle = -90f,
                    sweepAngle = progress * 360f,
                    useCenter = false,
                    style = androidx.compose.ui.graphics.drawscope.Stroke(width = lineWidth.toPx())
                )
            }

            AsyncImage(
                model = imageURL,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(width, height)
                    .clip(CircleShape)
                    .graphicsLayer {
                        scaleX = if (isPressed) 1f else 1.025f
                        scaleY = if (isPressed) 1f else 1.025f
                        shadowElevation = if (isPressed) 0.075.dp.toPx() else 2.dp.toPx()
                    }
                    .background(Color.White.copy(alpha = if (isPressed) 0.95f else 1f))
//                    .let { baseModifier ->
//                        if (!enabled) {
//                            baseModifier.alpha(0.5f) // Adjust alpha when disabled
//                        } else {
//                            baseModifier
//                        }
//                    }
            )
        }
    }
}

private fun onCompleteHold(
    function: () -> Unit
) {
    function()
}

private fun easeIn(t: Float): Float {
    return t.pow(2)
}
