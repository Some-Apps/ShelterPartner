package app.pawparnter

// AppDelegate equivalent in Kotlin
import android.app.Application
import com.google.firebase.FirebaseApp
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.lifecycle.viewmodel.compose.viewModel
// AuthenticationViewModel.kt
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow


// PawPartnerApp.kt
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.tooling.preview.Preview

class PawPartnerApp : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
    }
}



class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val authViewModel: AuthenticationViewModel = viewModel()
            PawPartnerApp(authViewModel)
        }
    }
}



@Composable
fun PawPartnerApp(authViewModel: AuthenticationViewModel) {
    MaterialTheme {
        if (authViewModel.isSignedIn.collectAsState().value) {
            when (authViewModel.accountType.collectAsState().value) {
                "admin" -> {
                    AdminView()
                }
                "volunteer" -> {
                    VolunteerView()
                }
                else -> {
                    DefaultView()
                }
            }
        } else {
            LoginView(authViewModel)
        }
    }
}

@Composable
fun AdminView() {
    // Implement the Admin View here
}

@Composable
fun VolunteerView() {
    // Implement the Volunteer View here
}

@Composable
fun DefaultView() {
    // Implement the Default View here
}

@Composable
fun LoginView(authViewModel: AuthenticationViewModel) {
    // Implement the Login View here
}

@Preview
@Composable
fun PreviewPawPartnerApp() {
    val authViewModel = AuthenticationViewModel()
    PawPartnerApp(authViewModel)
}



class AuthenticationViewModel : ViewModel() {
    private val auth: FirebaseAuth = FirebaseAuth.getInstance()

    private val _isSignedIn = MutableStateFlow(auth.currentUser != null)
    val isSignedIn: StateFlow<Boolean> = _isSignedIn

    private val _accountType = MutableStateFlow("volunteer")
    val accountType: StateFlow<String> = _accountType

    init {
        auth.addAuthStateListener { firebaseAuth ->
            _isSignedIn.value = firebaseAuth.currentUser != null
            if (firebaseAuth.currentUser != null) {
                fetchAccountType()
            }
        }
    }

    private fun fetchAccountType() {
        // Fetch account type from Firestore and update _accountType
    }

    fun signOut() {
        auth.signOut()
    }
}
