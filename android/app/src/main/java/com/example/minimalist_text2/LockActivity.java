package com.example.minimalist_text2;

import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.util.HashSet;
import java.util.Set;

public class LockActivity extends AppCompatActivity {

    public static final String EXTRA_PASSWORD = "password";
    public static final String EXTRA_PACKAGE_NAME = "packageName";
    public static final String ACTION_FOCUS_MODE_UNLOCKED = "com.example.minimalist_text2.FOCUS_MODE_UNLOCKED";

    public static volatile boolean isShowing = false;

    // ✅ Track permanently unlocked apps for this session
    public static final Set<String> permanentlyUnlockedApps = new HashSet<>();

    private String correctPassword;
    private String targetPackage;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d("LockActivity", "onCreate() called");

        // Avoid multiple lock screens
        if (isShowing) {
            Log.d("LockActivity", "Lock screen already showing. Finishing activity.");
            finish();
            return;
        }
        isShowing = true;

        // Secure the window
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN
                | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                | WindowManager.LayoutParams.FLAG_SECURE);

        setContentView(R.layout.activity_lock);
        Log.d("LockActivity", "UI set with lock screen layout");

        correctPassword = getIntent().getStringExtra(EXTRA_PASSWORD);
        targetPackage = getIntent().getStringExtra(EXTRA_PACKAGE_NAME);

        Log.d("LockActivity", "Received correctPassword: " + correctPassword);
        Log.d("LockActivity", "Received targetPackage: " + targetPackage);

        ImageView appIcon = findViewById(R.id.appIcon);
        TextView appName = findViewById(R.id.appName);
        TextView subtitle = findViewById(R.id.subtitle);
        EditText passwordInput = findViewById(R.id.passwordInput);
        Button unlockBtn = findViewById(R.id.unlockButton);

        if (!TextUtils.isEmpty(targetPackage)) {
            try {
                PackageManager pm = getPackageManager();
                ApplicationInfo ai = pm.getApplicationInfo(targetPackage, 0);
                Drawable icon = pm.getApplicationIcon(ai);
                String label = pm.getApplicationLabel(ai).toString();
                appIcon.setImageDrawable(icon);
                appName.setText(label);
                Log.d("LockActivity", "Loaded app info for: " + label);
            } catch (PackageManager.NameNotFoundException e) {
                Log.e("LockActivity", "Package not found: " + targetPackage);
                appName.setText("Blocked App");
            }
        } else {
            Log.d("LockActivity", "No target package found. Showing default text.");
            appName.setText("App Locked");
        }

        subtitle.setText("Enter your Focus Mode password to continue");

        unlockBtn.setOnClickListener(v -> {
            String entered = passwordInput.getText().toString();
            Log.d("LockActivity", "Unlock button clicked. Entered password: " + entered);

            if (TextUtils.isEmpty(entered)) {
                Log.d("LockActivity", "Password field empty.");
                Toast.makeText(this, "Please enter password", Toast.LENGTH_SHORT).show();
                return;
            }
            if (correctPassword == null) {
                Log.e("LockActivity", "correctPassword is null. Session not initialized.");
                Toast.makeText(this, "Focus session not initialized", Toast.LENGTH_SHORT).show();
                return;
            }
            if (entered.equals(correctPassword)) {
                Log.d("LockActivity", "Password correct. Unlocking app permanently for this session.");

                // ✅ Add this app to permanently unlocked list
                if (!TextUtils.isEmpty(targetPackage)) {
                    permanentlyUnlockedApps.add(targetPackage);
                }

                // Notify service (optional, for consistency)
                Intent unlocked = new Intent(ACTION_FOCUS_MODE_UNLOCKED);
                unlocked.putExtra("packageName", targetPackage);
                sendBroadcast(unlocked);

                Toast.makeText(this, "Unlocked permanently for this session", Toast.LENGTH_SHORT).show();
                finish();
            } else {
                Log.d("LockActivity", "Incorrect password entered.");
                Toast.makeText(this, "Incorrect password", Toast.LENGTH_SHORT).show();
                passwordInput.setText("");
            }
        });
    }

    @Override
    protected void onDestroy() {
        Log.d("LockActivity", "onDestroy() called. Resetting isShowing flag.");
        super.onDestroy();
        isShowing = false;
    }

    @Override
    public void onBackPressed() {
    }


    // ✅ Helper to reset when session ends
    public static void resetUnlockedApps() {
        permanentlyUnlockedApps.clear();
    }
}
