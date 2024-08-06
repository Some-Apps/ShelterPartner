package me.jareddanieljones.shelterpartner

import android.app.Application
import com.google.firebase.FirebaseApp

class ShelterPartnerApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
    }
}
