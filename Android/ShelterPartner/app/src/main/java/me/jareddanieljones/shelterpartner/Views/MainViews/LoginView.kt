package me.jareddanieljones.shelterpartner.Views.MainViews

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import me.jareddanieljones.shelterpartner.R
import java.text.DateFormat
import java.util.Date
import android.util.Log
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch

@Composable
fun SafariView(url: String) {
    LocalContext.current
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
fun LoginView() {
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
    val loginListener: ListenerRegistration? = null
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        lastSync = dateFormatter.format(Date())
        fetchSignUpForm { signUpForm, tutorials ->
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
                Spacer(modifier = Modifier.height(16.dp))
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
                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = {
                        isLoginInProgress = true
                        FirebaseAuth.getInstance().signInWithEmailAndPassword(email, password)
                            .addOnCompleteListener { task ->
                                isLoginInProgress = false
                                if (task.isSuccessful) {
                                    val user = task.result?.user
                                    if (user != null) {
                                        coroutineScope.launch {
                                            fetchSocietyID(user.uid) { result ->
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
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Login")
                }
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    if (newShelterForm.isNotEmpty()) {
                        TextButton(onClick = { showNewShelterForm = true }) {
                            Text("Create New Shelter")
                        }
                        if (showNewShelterForm) {
                            SafariView(newShelterForm)
                        }
                    }
                    if (tutorialsURL.isNotEmpty()) {
                        TextButton(onClick = { showTutorials = true }) {
                            Text("Tutorials/Documentation")
                        }
                        if (showTutorials) {
                            SafariView(tutorialsURL)
                        }
                    }
                }
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Please do not share your login with anybody. You can request an additional admin account by emailing me or create volunteer accounts from within the app.",
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
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

fun fetchSocietyID(userID: String, callback: (Result<String>) -> Unit) {
//    val db = FirebaseFirestore.getInstance()
//    db.collection("Users").document(userID).get().addOnCompleteListener { task ->
//        if (task.isSuccessful) {
//            val document = task.result
//            if (document != null && document.exists()) {
//                val societyID = document.getString("societyID")
//                if (societyID != null) {
//                    callback(Result.success(societyID))
//                } else {
//                    callback(Result.failure(Exception("SocietyID not found")))
//                }
//            } else {
//                callback(Result.failure(Exception("No such document")))
//            }
//        } else {
//            callback(Result.failure(task.exception ?: Exception("Failed to fetch societyID")))
//        }
//    }
}

fun fetchSignUpForm(callback: (String, String) -> Unit) {
//    val db = FirebaseFirestore.getInstance()
//    db.collection("Stats").document("AppInformation").addSnapshotListener { documentSnapshot, error ->
//        if (error != null) {
//            Log.e("LoginView", "Error fetching sign up form", error)
//            return@addSnapshotListener
//        }
//        if (documentSnapshot != null && documentSnapshot.exists()) {
//            val signUpForm = documentSnapshot.getString("signUpForm").orEmpty()
//            val tutorialsURL = documentSnapshot.getString("tutorialsURL").orEmpty()
//            callback(signUpForm, tutorialsURL)
//        }
//    }
}
