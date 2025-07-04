package com.example.minimalist_text2;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class ScreenUnlockReceiver extends BroadcastReceiver {
    private static final String PREFS_NAME = "PickupPrefs";
    private static final String PICKUP_COUNT_KEY = "pickup_count";
    private static final String LAST_DATE_KEY = "last_recorded_date";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_USER_PRESENT.equals(intent.getAction())) {
            SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);

            String todayDate = getCurrentDate();
            String lastRecordedDate = prefs.getString(LAST_DATE_KEY, "");

            if (!todayDate.equals(lastRecordedDate)) {
                // Reset count for new day
                prefs.edit()
                        .putInt(PICKUP_COUNT_KEY, 1)
                        .putString(LAST_DATE_KEY, todayDate)
                        .apply();
                Log.d("PICKUP_TRACKING", "New day started. Pickup count reset to 1");
            } else {
                int count = prefs.getInt(PICKUP_COUNT_KEY, 0);
                prefs.edit().putInt(PICKUP_COUNT_KEY, count + 1).apply();
                Log.d("PICKUP_TRACKING", "Pickup count incremented to: " + (count + 1));
            }
        }
    }

    private String getCurrentDate() {
        return new SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(new Date());
    }
}
