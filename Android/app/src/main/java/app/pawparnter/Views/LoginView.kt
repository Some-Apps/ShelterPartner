package app.pawparnter.Views

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.tooling.preview.Preview
import app.pawparnter.R

@Composable
fun LoginView() {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Add Image composable
        Image(
            painter = painterResource(id = R.drawable.logo),
            contentDescription = "Dog Image",
            modifier = Modifier
                .size(150.dp)
                .clip(RoundedCornerShape(25.dp)) // Add rounded corners

        )

        // Add spacing
        Spacer(modifier = Modifier.height(16.dp))

        // Add Text composable
        Text(
            text = "Login",
            fontWeight = FontWeight.Bold,
            fontSize = 35.sp
        )
    }
}

@Preview(showBackground = true)
@Composable
fun DefaultPreview() {
    LoginView()
}
