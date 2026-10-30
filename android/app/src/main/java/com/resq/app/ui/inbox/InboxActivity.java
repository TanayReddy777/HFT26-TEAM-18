package com.resq.app.ui.inbox;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.resq.app.R;
import com.resq.app.ui.devices.NearbyDevicesActivity;
import com.resq.app.ui.home.HomeActivity;
import com.resq.app.ui.message.EmergencyMessageActivity;
import com.resq.app.ui.settings.SettingsActivity;

/**
 * Screen 6: Inbox Screen
 * Offline decentralized store-and-forward message thread with bilingual translation.
 */
public class InboxActivity extends AppCompatActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_inbox);

        EditText etMsg = findViewById(R.id.etInboxMessage);
        Button btnSend = findViewById(R.id.btnSendMsg);

        if (btnSend != null && etMsg != null) {
            btnSend.setOnClickListener(v -> {
                String text = etMsg.getText().toString().trim();
                if (!text.isEmpty()) {
                    Toast.makeText(this, "Delivered to nearby mesh: \"" + text + "\"", Toast.LENGTH_SHORT).show();
                    etMsg.setText("");
                }
            });
        }

        setupBottomNav();
    }

    private void setupBottomNav() {
        BottomNavigationView bottomNav = findViewById(R.id.bottomNav);
        if (bottomNav != null) {
            bottomNav.setSelectedItemId(R.id.action_inbox);
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
