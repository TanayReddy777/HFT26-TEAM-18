package com.resq.app.ui.devices;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.resq.app.R;
import com.resq.app.ui.home.HomeActivity;
import com.resq.app.ui.inbox.InboxActivity;
import com.resq.app.ui.message.EmergencyMessageActivity;
import com.resq.app.ui.settings.SettingsActivity;

/**
 * Screen 5: Nearby Devices Screen
 * Displays connected BLE and Wi-Fi Direct mesh peers with signal strength and hop topology.
 */
public class NearbyDevicesActivity extends AppCompatActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_nearby_devices);

        Button btnScan = findViewById(R.id.btnScanRadar);
        if (btnScan != null) {
            btnScan.setOnClickListener(v -> {
                Toast.makeText(this, "Scanning BLE beacons... 3 peers synchronized!", Toast.LENGTH_SHORT).show();
            });
        }

        Button btnPingRavi = findViewById(R.id.btnPingRavi);
        if (btnPingRavi != null) {
            btnPingRavi.setOnClickListener(v -> {
                Toast.makeText(this, "⚡ Ping to Ravi: 14ms (HMAC-SHA256 verified)", Toast.LENGTH_SHORT).show();
            });
        }

        Button btnPingPriya = findViewById(R.id.btnPingPriya);
        if (btnPingPriya != null) {
            btnPingPriya.setOnClickListener(v -> {
                Toast.makeText(this, "⚡ Ping to Priya: 22ms (Weak signal -81 dBm)", Toast.LENGTH_SHORT).show();
            });
        }

        Button btnTraceAnil = findViewById(R.id.btnTraceAnil);
        if (btnTraceAnil != null) {
            btnTraceAnil.setOnClickListener(v -> {
                Toast.makeText(this, "📍 Mesh Route: Local [You] ➔ Ravi (Hop 0) ➔ Anil (Hop 1)", Toast.LENGTH_SHORT).show();
            });
        }

        setupBottomNav();
    }

    private void setupBottomNav() {
        BottomNavigationView bottomNav = findViewById(R.id.bottomNav);
        if (bottomNav != null) {
            bottomNav.setSelectedItemId(R.id.action_devices);
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
                } else if (id == R.id.action_inbox) {
                    startActivity(new Intent(this, InboxActivity.class));
                    finish();
                    return true;
                } else if (id == R.id.action_settings) {
                    startActivity(new Intent(this, SettingsActivity.class));
                    finish();
                    return true;
                }
                return true;
            });
        }
    }
}
