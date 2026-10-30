package com.resq.app.ui.onboarding;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.resq.app.R;
import com.resq.app.ui.home.HomeActivity;

/**
 * Screen 2: Onboarding Screen
 * Explains offline mesh communication, Bluetooth permissions, and multi-hop forwarding.
 */
public class OnboardingActivity extends AppCompatActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_onboarding);

        Button btnGetStarted = findViewById(R.id.btnGetStarted);
        if (btnGetStarted != null) {
            btnGetStarted.setOnClickListener(v -> {
                Intent intent = new Intent(OnboardingActivity.this, HomeActivity.class);
                startActivity(intent);
                finish();
            });
        }
    }
}
