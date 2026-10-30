package com.resq.app.ui.home;

import android.os.Bundle;
import android.os.Vibrator;
import android.view.MenuItem;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.ScaleAnimation;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.card.MaterialCardView;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.resq.app.R;

/**
 * HomeActivity - Primary Home Dashboard UI for ResQ Offline Emergency Messaging & Safety System.
 * Adheres to Material Design 3 guidelines with dark navy background, radiant Red SOS primary action,
 * and subtle cyan accents.
 */
public class HomeActivity extends AppCompatActivity {

    // Views
    private FrameLayout btnEmergencySos;
    private View viewSosGlow;
    private TextView tvNetworkStatus;
    private TextView tvNearbyDevicesCount;
    private TextView tvActivityType;
    private TextView tvActivitySub;
    private TextView tvActivityTime;
    private ImageView ivActivityIcon;
    private MaterialCardView cardLastActivity;
    private MaterialCardView cardMeetingPoint;
    private BottomNavigationView bottomNavigation;

    // State Variables (Sample data for preview)
    private boolean isSosActive = false;
    private int nearbyDeviceCount = 3;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_home);

        initViews();
        setupSosButton();
        setupCards();
        setupBottomNavigation();
        loadSampleDashboardData();
    }

    private void initViews() {
        btnEmergencySos = findViewById(R.id.btn_emergency_sos);
        viewSosGlow = findViewById(R.id.view_sos_glow);
        tvNetworkStatus = findViewById(R.id.tv_network_status);
        tvNearbyDevicesCount = findViewById(R.id.tv_nearby_devices_count);
        tvActivityType = findViewById(R.id.tv_activity_type);
        tvActivitySub = findViewById(R.id.tv_activity_sub);
        tvActivityTime = findViewById(R.id.tv_activity_time);
        ivActivityIcon = findViewById(R.id.iv_activity_icon);
        cardLastActivity = findViewById(R.id.card_last_activity);
        cardMeetingPoint = findViewById(R.id.card_meeting_point);
        bottomNavigation = findViewById(R.id.bottom_navigation);
    }

    /**
     * Sets up the interactive large circular SOS button with scale animation and confirmation.
     */
    private void setupSosButton() {
        btnEmergencySos.setOnClickListener(v -> {
            // Haptic vibration feedback
            Vibrator vibrator = (Vibrator) getSystemService(VIBRATOR_SERVICE);
            if (vibrator != null) {
                vibrator.vibrate(100);
            }

            // Click scale bounce animation
            animateSosClick(v);

            // Confirm and broadcast emergency alert
            showEmergencyConfirmationDialog();
        });
    }

    private void animateSosClick(View view) {
        ScaleAnimation scale = new ScaleAnimation(
                1.0f, 0.94f, 1.0f, 0.94f,
                Animation.RELATIVE_TO_SELF, 0.5f,
                Animation.RELATIVE_TO_SELF, 0.5f);
        scale.setDuration(120);
        scale.setRepeatMode(Animation.REVERSE);
        scale.setRepeatCount(1);
        view.startAnimation(scale);
    }

    private void showEmergencyConfirmationDialog() {
        new MaterialAlertDialogBuilder(this)
                .setTitle("Broadcast Emergency SOS?")
                .setMessage("This will immediately transmit a P0 priority emergency alert across the offline mesh to all " + nearbyDeviceCount + " nearby devices.")
                .setIcon(R.drawable.ic_sos)
                .setPositiveButton("SEND SOS NOW", (dialog, which) -> {
                    triggerEmergencySos();
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    private void triggerEmergencySos() {
        isSosActive = true;
        tvActivityType.setText("CRITICAL SOS: Broadcasted by You");
        tvActivityType.setTextColor(getResources().getColor(R.color.sos_red));
        tvActivitySub.setText("Direct BLE & Nearby relay • Stored locally in Outbox");
        tvActivityTime.setText("Just now");
        ivActivityIcon.setImageResource(R.drawable.ic_activity);

        Toast.makeText(this, getString(R.string.sos_broadcasted_toast), Toast.LENGTH_LONG).show();
    }

    private void setupCards() {
        // Meeting Point Guidance Card Click
        cardMeetingPoint.setOnClickListener(v -> {
            Toast.makeText(this, "Straight-line compass direction to Camp Alpha active (140m NE).", Toast.LENGTH_SHORT).show();
        });

        // Last Activity Card Click
        cardLastActivity.setOnClickListener(v -> {
            String status = isSosActive ? "Active P0 Incident" : "No ongoing emergency incidents";
            Toast.makeText(this, status + " • Showing recent mesh timeline", Toast.LENGTH_SHORT).show();
        });
    }

    /**
     * Sets up the Material 3 BottomNavigationView.
     */
    private void setupBottomNavigation() {
        bottomNavigation.setSelectedItemId(R.id.action_home);
        bottomNavigation.setOnItemSelectedListener(new BottomNavigationView.OnItemSelectedListener() {
            @Override
            public boolean onNavigationItemSelected(@NonNull MenuItem item) {
                int itemId = item.getItemId();
                if (itemId == R.id.action_home) {
                    return true;
                } else if (itemId == R.id.action_sos_message) {
                    Toast.makeText(HomeActivity.this, "Emergency Message Screen (Screen 4)", Toast.LENGTH_SHORT).show();
                    return true;
                } else if (itemId == R.id.action_devices) {
                    Toast.makeText(HomeActivity.this, "Nearby Devices Screen (Screen 5)", Toast.LENGTH_SHORT).show();
                    return true;
                } else if (itemId == R.id.action_inbox) {
                    Toast.makeText(HomeActivity.this, "Emergency Inbox Screen (Screen 6)", Toast.LENGTH_SHORT).show();
                    return true;
                } else if (itemId == R.id.action_settings) {
                    Toast.makeText(HomeActivity.this, "Settings Screen (Screen 7)", Toast.LENGTH_SHORT).show();
                    return true;
                }
                return false;
            }
        });
    }

    private void loadSampleDashboardData() {
        tvNetworkStatus.setText(R.string.network_status_active);
        tvNearbyDevicesCount.setText(nearbyDeviceCount + " Devices");
        tvActivityType.setText(R.string.activity_type_none);
        tvActivitySub.setText(R.string.activity_sub_none);
        tvActivityTime.setText(R.string.activity_time_recent);
    }
}
