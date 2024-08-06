package me.jareddanieljones.shelterpartner.Views.MainViews

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.ListenerRegistration
import kotlinx.coroutines.launch
import me.jareddanieljones.shelterpartner.R
import me.jareddanieljones.shelterpartner.ViewModels.LoginViewModel
import java.text.DateFormat
import java.util.Date

@Composable
fun SafariView(url: String) {
    val context = LocalContext.current
    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult(),
        onResult = { /* Handle result if needed */ }
    )

    LaunchedEffect(Unit) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        launcher.launch(intent)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoginView(loginViewModel: LoginViewModel = viewModel()) {
    var showNewShelterForm by remember { mutableStateOf(false) }
    var showTutorials by remember { mutableStateOf(false) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var showLoginError by remember { mutableStateOf(false) }
    var loginError by remember { mutableStateOf("") }
    var isLoginInProgress by remember { mutableStateOf(false) }
    var newShelterForm by remember { mutableStateOf("") }
    var tutorialsURL by remember { mutableStateOf("") }
    var lastSync by remember { mutableStateOf("") }
    val dateFormatter = DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT)
    var showVideo by remember { mutableStateOf(false) }
    var loginListener: ListenerRegistration? = null
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        lastSync = dateFormatter.format(Date())
        loginViewModel.fetchSignUpForm { signUpForm, tutorials ->
            newShelterForm = signUpForm
            tutorialsURL = tutorials
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            loginListener?.remove()
        }
    }

    Scaffold { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(Color.White)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Spacer(modifier = Modifier.weight(.1f))
                Image(
                    painter = painterResource(id = R.drawable.login_image),
                    contentDescription = null,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp)
                        .align(Alignment.CenterHorizontally)
                )
                Spacer(modifier = Modifier.height(16.dp))
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Email") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text("Password") },
                    visualTransformation = PasswordVisualTransformation(),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(50.dp))
                Row {
                    Spacer(modifier = Modifier.weight(.1f))
                    Button(
                        onClick = {
                            if (email.isBlank() || password.isBlank()) {
                                // Display error message or handle empty fields
                                loginError = "Email and password cannot be empty"
                                showLoginError = true
                            } else {
                                isLoginInProgress = true
                                FirebaseAuth.getInstance().signInWithEmailAndPassword(email, password)
                                    .addOnCompleteListener { task ->
                                        isLoginInProgress = false
                                        if (task.isSuccessful) {
                                            val user = task.result?.user
                                            if (user != null) {
                                                coroutineScope.launch {
                                                    loginViewModel.fetchSocietyID(user.uid) { result ->
                                                        result.onSuccess { societyID ->
                                                            // Handle success
                                                        }.onFailure { error ->
                                                            Log.e("LoginView", "Error fetching society ID", error)
                                                        }
                                                    }
                                                }
                                            }
                                        } else {
                                            loginError = task.exception?.message.orEmpty()
                                            showLoginError = true
                                            Log.e("LoginView", "Login failed", task.exception)
                                        }
                                    }
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = colorResource(id = R.color.customLightBlue), // Change this to your desired color
                            contentColor = colorResource(id = R.color.customBlue) // Change this to your desired text color
                        ),
                        shape = RoundedCornerShape(8.dp), // Less rounded corners
                        modifier = Modifier
                    ) {
                        Text(
                            text = "Login",
                            fontWeight = FontWeight.Bold, // Bold text
                            fontSize = 30.sp // Larger text size
                        )
                    }

                    Spacer(modifier = Modifier.weight(.1f))
                }


                Spacer(modifier = Modifier.height(50.dp))
                Text(
                    text = "Please do not share your login with anybody. You can request an additional admin account by emailing me or create volunteer accounts from within the app.",
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceAround
                ) {
                    if (newShelterForm.isNotEmpty()) {
                        TextButton(
                            onClick = { showNewShelterForm = true },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = colorResource(id = R.color.customGrayBackground), // Change this to your desired color
                                contentColor = colorResource(id = R.color.customGrayText) // Change this to your desired text color
                            ),
                            shape = RoundedCornerShape(8.dp), // Less rounded corners
                        ) {
                            Text(
                                text = "Create New Shelter",
                                fontSize = 17.sp
                            )
                        }
                        if (showNewShelterForm) {
                            SafariView(newShelterForm)
                        }
                    }
                    if (tutorialsURL.isNotEmpty()) {
                        TextButton(
                            onClick = { showTutorials = true },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = colorResource(id = R.color.customGrayBackground), // Change this to your desired color
                                contentColor = colorResource(id = R.color.customGrayText) // Change this to your desired text color
                            ),
                            shape = RoundedCornerShape(8.dp), // Less rounded corners
                        ) {
                            Text(
                                text = "Tutorials/Documentation",
                                fontSize = 17.sp
                            )
                        }
                        if (showTutorials) {
                            SafariView(tutorialsURL)
                        }
                    }
                }
                Spacer(modifier = Modifier.weight(.1f))
            }
        }
    }

    if (showLoginError) {
        AlertDialog(
            onDismissRequest = { showLoginError = false },
            confirmButton = {
                TextButton(onClick = { showLoginError = false }) {
                    Text("OK")
                }
            },
            text = { Text("Your username or password is incorrect.") }
        )
    }

    if (isLoginInProgress) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator()
        }
    }
}

