package com.resq.app.ui.message;

import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.card.MaterialCardView;
import com.resq.app.R;
import com.resq.app.ui.devices.NearbyDevicesActivity;
import com.resq.app.ui.home.HomeActivity;
import com.resq.app.ui.inbox.InboxActivity;
import com.resq.app.ui.settings.SettingsActivity;

import java.nio.charset.StandardCharsets;

/**
 * Screen 4: Emergency Message Screen
 * Allows fast selection of P0/P1/P2 priorities, templates, and mesh packet broadcast.
 */
public class EmergencyMessageActivity extends AppCompatActivity {

    private String selectedPriority = "P0";
    private EditText etMessage;
    private TextView tvByteCounter;
    private Button btnPriorityP0, btnPriorityP1, btnPriorityP2;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_emergency_message);

        ImageView btnBack = findViewById(R.id.btnBack);
        if (btnBack != null) {
            btnBack.setOnClickListener(v -> finish());
        }

        etMessage = findViewById(R.id.etMessage);
        tvByteCounter = findViewById(R.id.tvByteCounter);

        btnPriorityP0 = findViewById(R.id.btnPriorityP0);
        btnPriorityP1 = findViewById(R.id.btnPriorityP1);
        btnPriorityP2 = findViewById(R.id.btnPriorityP2);

        setupPriorityButtons();
        setupTemplates();
        setupByteCounter();
        setupBroadcastButton();
        setupBottomNav();
    }

    private void setupPriorityButtons() {
        if (btnPriorityP0 != null) {
            btnPriorityP0.setOnClickListener(v -> {
                selectedPriority = "P0";
                btnPriorityP0.setBackgroundColor(getColor(R.color.sos_red));
                btnPriorityP0.setTextColor(getColor(R.color.text_white));
                btnPriorityP1.setBackgroundColor(getColor(R.color.bg_card_slate));
                btnPriorityP2.setBackgroundColor(getColor(R.color.bg_card_slate));
            });
        }

        if (btnPriorityP1 != null) {
            btnPriorityP1.setOnClickListener(v -> {
                selectedPriority = "P1";
                btnPriorityP1.setBackgroundColor(getColor(R.color.p1_orange));
                btnPriorityP1.setTextColor(getColor(R.color.text_white));
                btnPriorityP0.setBackgroundColor(getColor(R.color.bg_card_slate));
                btnPriorityP2.setBackgroundColor(getColor(R.color.bg_card_slate));
            });
        }

        if (btnPriorityP2 != null) {
            btnPriorityP2.setOnClickListener(v -> {
                selectedPriority = "P2";
                btnPriorityP2.setBackgroundColor(getColor(R.color.cyan_accent));
                btnPriorityP2.setTextColor(getColor(R.color.bg_navy_deep));
                btnPriorityP0.setBackgroundColor(getColor(R.color.bg_card_slate));
                btnPriorityP1.setBackgroundColor(getColor(R.color.bg_card_slate));
            });
        }
    }

    private void setupTemplates() {
        MaterialCardView tmplTrapped = findViewById(R.id.tmplTrapped);
        if (tmplTrapped != null) {
            tmplTrapped.setOnClickListener(v -> etMessage.setText("🚨 Trapped under debris, need immediate extrication"));
        }

        MaterialCardView tmplInjury = findViewById(R.id.tmplInjury);
        if (tmplInjury != null) {
            tmplInjury.setOnClickListener(v -> etMessage.setText("🩸 Severe injury / bleeding, need first aid kit"));
        }

        MaterialCardView tmplSeparated = findViewById(R.id.tmplSeparated);
        if (tmplSeparated != null) {
            tmplSeparated.setOnClickListener(v -> etMessage.setText("⚠️ Separated from group, battery < 10%, staying in place"));
        }

        MaterialCardView tmplFlood = findViewById(R.id.tmplFlood);
        if (tmplFlood != null) {
            tmplFlood.setOnClickListener(v -> etMessage.setText("🌊 Flash flood warning, heading to high ground"));
        }
    }

    private void setupByteCounter() {
        if (etMessage != null) {
            etMessage.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {
                    int bytes = s.toString().getBytes(StandardCharsets.UTF_8).length;
                    if (tvByteCounter != null) {
                        tvByteCounter.setText(bytes + " / 140 bytes");
                    }
                }

                @Override
                public void afterTextChanged(Editable s) {}
            });
        }
    }

    private void setupBroadcastButton() {
        Button btnBroadcast = findViewById(R.id.btnBroadcastSos);
        if (btnBroadcast != null) {
            btnBroadcast.setOnClickListener(v -> {
                String text = etMessage != null ? etMessage.getText().toString().trim() : "";
                if (text.isEmpty()) {
                    Toast.makeText(this, "Please select a template or enter details", Toast.LENGTH_SHORT).show();
                    return;
                }
                Toast.makeText(this, "🚨 [" + selectedPriority + "] Alert broadcasted across offline mesh!", Toast.LENGTH_LONG).show();
                finish();
            });
        }
    }

    private void setupBottomNav() {
        BottomNavigationView bottomNav = findViewById(R.id.bottomNav);
        if (bottomNav != null) {
            bottomNav.setSelectedItemId(R.id.action_sos_message);
            bottomNav.setOnItemSelectedListener(item -> {
                int id = item.getItemId();
                if (id == R.id.action_home) {
                    startActivity(new Intent(this, HomeActivity.class));
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
