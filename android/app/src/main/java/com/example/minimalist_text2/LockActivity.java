package com.example.minimalist_text2;

import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.WindowManager;
import androidx.annotation.NonNull;

import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import com.google.firebase.FirebaseException;

import androidx.appcompat.app.AppCompatActivity;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.PhoneAuthCredential;
import com.google.firebase.auth.PhoneAuthOptions;
import com.google.firebase.auth.PhoneAuthProvider;

public class LockActivity extends AppCompatActivity {

    public static final String EXTRA_PASSWORD = "password";   // legacy, not used
    public static final String EXTRA_PACKAGE_NAME = "packageName";
    public static final String EXTRA_MODE = "mode";           // NEW: "unlock_app" | "stop_session"

    public static final String ACTION_FOCUS_MODE_UNLOCKED = "com.example.minimalist_text2.FOCUS_MODE_UNLOCKED";
    public static final String ACTION_FOCUS_MODE_STOP = "com.example.minimalist_text2.FOCUS_MODE_STOP";

    public static volatile boolean isShowing = false;

    // Track permanently unlocked apps
    public static final Set<String> permanentlyUnlockedApps = new HashSet<>();

    private String targetPackage;
    private String actionMode = "unlock_app"; // default

    // Firebase phone auth
    private FirebaseAuth mAuth;
    private String verificationId;
    private PhoneAuthProvider.ForceResendingToken resendToken;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d("LockActivity", "onCreate() called");

        if (isShowing) {
            finish();
            return;
        }
        isShowing = true;

        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN
                | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                | WindowManager.LayoutParams.FLAG_SECURE);

        setContentView(R.layout.activity_lock);

        try {
            FirebaseApp.initializeApp(this);
        } catch (Exception ignore) {}
        mAuth = FirebaseAuth.getInstance();

        targetPackage = getIntent().getStringExtra(EXTRA_PACKAGE_NAME);
        actionMode = getIntent().getStringExtra(EXTRA_MODE);
        if (TextUtils.isEmpty(actionMode)) {
            actionMode = "unlock_app"; // fallback
        }

        ImageView appIcon = findViewById(R.id.appIcon);
        TextView appName = findViewById(R.id.appName);
        TextView subtitle = findViewById(R.id.subtitle);

        EditText phoneInput = findViewById(R.id.phoneInput);
        EditText otpInput   = findViewById(R.id.otpInput);
        Button sendOtpBtn   = findViewById(R.id.sendOtpButton);
        Button verifyBtn    = findViewById(R.id.verifyOtpButton);

        if ("unlock_app".equals(actionMode) && !TextUtils.isEmpty(targetPackage)) {
            try {
                PackageManager pm = getPackageManager();
                ApplicationInfo ai = pm.getApplicationInfo(targetPackage, 0);
                Drawable icon = pm.getApplicationIcon(ai);
                String label = pm.getApplicationLabel(ai).toString();
                appIcon.setImageDrawable(icon);
                appName.setText(label);
            } catch (PackageManager.NameNotFoundException e) {
                appName.setText("Blocked App");
            }
            subtitle.setText("Verify OTP to unlock this app");
        } else {
            appName.setText("Focus Mode");
            subtitle.setText("Verify OTP to stop session");
        }

        // Send OTP
        sendOtpBtn.setOnClickListener(v -> {
            String phone = phoneInput.getText().toString().trim();
            if (TextUtils.isEmpty(phone)) {
                Toast.makeText(this, "Enter phone number (+91...)", Toast.LENGTH_SHORT).show();
                return;
            }
            startPhoneVerification(phone);
        });

        // Verify OTP
        verifyBtn.setOnClickListener(v -> {
            String code = otpInput.getText().toString().trim();
            if (TextUtils.isEmpty(code)) {
                Toast.makeText(this, "Enter the OTP", Toast.LENGTH_SHORT).show();
                return;
            }
            if (verificationId == null) {
                Toast.makeText(this, "Send OTP first", Toast.LENGTH_SHORT).show();
                return;
            }
            verifyCode(code);
        });
    }

    private final PhoneAuthProvider.OnVerificationStateChangedCallbacks callbacks =
            new PhoneAuthProvider.OnVerificationStateChangedCallbacks() {
                @Override
                public void onVerificationCompleted(PhoneAuthCredential credential) {
                    signInWithPhoneAuthCredential(credential);
                }

                @Override
                public void onVerificationFailed(@NonNull FirebaseException e) {
                    Toast.makeText(LockActivity.this, "Verification failed: " + e.getMessage(), Toast.LENGTH_LONG).show();
                }

                @Override
                public void onCodeSent(String verId, PhoneAuthProvider.ForceResendingToken token) {
                    verificationId = verId;
                    resendToken = token;
                    Toast.makeText(LockActivity.this, "OTP sent!", Toast.LENGTH_SHORT).show();
                }
            };

    private void startPhoneVerification(String phoneNumber) {
        PhoneAuthOptions options =
                PhoneAuthOptions.newBuilder(mAuth)
                        .setPhoneNumber(phoneNumber)
                        .setTimeout(60L, TimeUnit.SECONDS)
                        .setActivity(this)
                        .setCallbacks(callbacks)
                        .build();
        PhoneAuthProvider.verifyPhoneNumber(options);
    }

    private void verifyCode(String code) {
        PhoneAuthCredential credential = PhoneAuthProvider.getCredential(verificationId, code);
        signInWithPhoneAuthCredential(credential);
    }

    private void signInWithPhoneAuthCredential(PhoneAuthCredential credential) {
        mAuth.signInWithCredential(credential)
                .addOnCompleteListener(this, task -> {
                    if (task.isSuccessful()) {
                        if ("unlock_app".equals(actionMode)) {
                            if (!TextUtils.isEmpty(targetPackage)) {
                                permanentlyUnlockedApps.add(targetPackage);
                            }
                            Intent unlocked = new Intent(ACTION_FOCUS_MODE_UNLOCKED);
                            unlocked.putExtra("packageName", targetPackage);
                            sendBroadcast(unlocked);
                            Toast.makeText(this, "App Unlocked!", Toast.LENGTH_SHORT).show();
                            finish();
                        } else if ("stop_session".equals(actionMode)) {
                            Intent serviceIntent = new Intent(this, ForegroundMonitorService.class);
                            stopService(serviceIntent);

                            // Notify service that focus mode has stopped
                            Intent stopIntent = new Intent(ACTION_FOCUS_MODE_STOP);
                            sendBroadcast(stopIntent);

                            // 🔥 Tell Flutter side that focus mode is stopped
                            // 🔥 Tell Flutter side that focus mode is stopped
                            MainActivity.notifyFlutterStop();

                            Toast.makeText(this, "Focus Mode stopped!", Toast.LENGTH_SHORT).show();
                            finish();
                        }
                    } else {
                        Toast.makeText(this, "Invalid OTP", Toast.LENGTH_SHORT).show();
                    }
                });
    }



    @Override
    protected void onDestroy() {
        super.onDestroy();
        isShowing = false;
    }

    @Override
    public void onBackPressed() {
        // Disable back
    }

    public static void resetUnlockedApps() {
        permanentlyUnlockedApps.clear();
    }
}
