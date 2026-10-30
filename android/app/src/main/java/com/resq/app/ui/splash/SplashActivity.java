package com.resq.app.ui.splash;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.animation.AlphaAnimation;
import android.widget.LinearLayout;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.resq.app.R;
import com.resq.app.ui.home.HomeActivity;
import com.resq.app.ui.onboarding.OnboardingActivity;

/**
 * Screen 1: Splash Screen
 * Displays ResQ brand identity and transitions to Onboarding or Home.
 */
public class SplashActivity extends AppCompatActivity {

    private static final long SPLASH_DURATION_MS = 1800;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);

        LinearLayout brandGroup = findViewById(R.id.brandGroup);
        if (brandGroup != null) {
            AlphaAnimation fadeIn = new AlphaAnimation(0.0f, 1.0f);
            fadeIn.setDuration(1000);
            brandGroup.startAnimation(fadeIn);
        }

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            Intent intent = new Intent(SplashActivity.this, OnboardingActivity.class);
            startActivity(intent);
            finish();
        }, SPLASH_DURATION_MS);
    }
}
