package com.resq.app.ui.settings;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.slider.Slider;
import com.resq.app.R;
import com.resq.app.ui.devices.NearbyDevicesActivity;
import com.resq.app.ui.home.HomeActivity;
import com.resq.app.ui.inbox.InboxActivity;
import com.resq.app.ui.message.EmergencyMessageActivity;

/**
 * Screen 7: Settings Screen
 * Manages power conservation bands, rendezvous point, fall calibration, and security keys.
 */
public class SettingsActivity extends AppCompatActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);

        Slider sliderBattery = findViewById(R.id.sliderBattery);
        TextView tvPowerBandTag = findViewById(R.id.tvPowerBandTag);

        if (sliderBattery != null && tvPowerBandTag != null) {
            sliderBattery.addOnChangeListener((slider, value, fromUser) -> {
                int val = (int) value;
                if (val >= 25) {
                    tvPowerBandTag.setText("NORMAL (" + val + "%)");
                    tvPowerBandTag.setTextColor(getColor(R.color.safe_green));
                } else if (val >= 15) {
                    tvPowerBandTag.setText("OPTIMIZATION (" + val + "%)");
                    tvPowerBandTag.setTextColor(getColor(R.color.p1_orange));
                } else if (val >= 5) {
                    tvPowerBandTag.setText("LOW POWER ALERT (<15%)");
                    tvPowerBandTag.setTextColor(getColor(R.color.sos_red));
                } else {
                    tvPowerBandTag.setText("CRITICAL (<5%)");
                    tvPowerBandTag.setTextColor(getColor(R.color.sos_red));
                }
            });
        }

        EditText etMeetingPoint = findViewById(R.id.etMeetingPoint);
        Button btnUpdateMeeting = findViewById(R.id.btnUpdateMeeting);
        if (btnUpdateMeeting != null && etMeetingPoint != null) {
            btnUpdateMeeting.setOnClickListener(v -> {
                String val = etMeetingPoint.getText().toString().trim();
                if (!val.isEmpty()) {
                    Toast.makeText(this, "📍 Rendezvous point updated to: \"" + val + "\"", Toast.LENGTH_SHORT).show();
                }
            });
        }

        Button btnTestFall = findViewById(R.id.btnTestFallAlert);
        if (btnTestFall != null) {
            btnTestFall.setOnClickListener(v -> {
                Toast.makeText(this, "⚠️ Simulated 2.6g drop impact detected. 15s timer active.", Toast.LENGTH_LONG).show();
            });
        }

        setupBottomNav();
    }

    private void setupBottomNav() {
        BottomNavigationView bottomNav = findViewById(R.id.bottomNav);
        if (bottomNav != null) {
            bottomNav.setSelectedItemId(R.id.action_settings);
            bottomNav.setOnItemSelectedListener(item -> {
                int id = item.getItemId();
                if (id == R.id.action_home) {
                    startActivity(new Intent(this, HomeActivity.class));
                    finish();
                    return true;
                } else if (id == R.id.action_sos_message) {
                    startActivity(new Intent(this, EmergencyMessageActivity.class));
                    finish();
                    return true;
                } else if (id == R.id.action_devices) {
                    startActivity(new Intent(this, NearbyDevicesActivity.class));
                    finish();
                    return true;
                } else if (id == R.id.action_inbox) {
                    startActivity(new Intent(this, InboxActivity.class));
                    finish();
                    return true;
                }
                return true;
            });
        }
    }
}
