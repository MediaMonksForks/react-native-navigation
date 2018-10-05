package com.reactnativenavigation.controllers;

import android.graphics.Color;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.support.annotation.LayoutRes;
import android.support.annotation.Nullable;
import android.support.v4.content.LocalBroadcastManager;
import android.support.v7.app.AppCompatActivity;
import android.view.View;

import com.reactnativenavigation.NavigationApplication;
import com.reactnativenavigation.react.ReactDevPermission;

public abstract class SplashActivity extends AppCompatActivity {
    private BroadcastReceiver navigationIntentReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final ComponentName component = intent.getComponent();
            if (component == null) {
                return;
            }

            LocalBroadcastManager.getInstance(getApplicationContext()).unregisterReceiver(this);

            final String className = component.getClassName();
            if (!NavigationActivity.class.getName().equals(className)) {
                return;
            }

            continueToStartAppIntent();
        }
    };

    boolean screenIsVisible = false;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setSplashLayout();
        IntentDataHandler.saveIntentData(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
    }

    private void registerToNavigationActivityLaunch() {
        LocalBroadcastManager.getInstance(NavigationApplication.instance).registerReceiver(navigationIntentReceiver, new IntentFilter(Intent.ACTION_VIEW));
    }

    @Override
    protected void onResume() {
        super.onResume();
        screenIsVisible = true;
        registerToNavigationActivityLaunch();

        if (ReactDevPermission.shouldAskPermission()) {
            ReactDevPermission.askPermission(this);
            return;
        }

        if (NavigationApplication.instance.getReactGateway().hasStartedCreatingContext()) {
            if (NavigationApplication.instance.isReactContextInitialized() && NavigationApplication.instance.getLastActivityIntent() != null) {
                continueToStartAppIntent();
            }
            return;
        }

        NavigationApplication.instance.startReactContextOnceInBackgroundAndExecuteJS();
    }

    private void setSplashLayout() {
        final int splashLayout = getSplashLayout();
        if (splashLayout > 0) {
            setContentView(splashLayout);
        } else {
            setContentView(createSplashLayout());
        }
    @Override
    protected void onPause() {
        super.onPause();
        screenIsVisible = false;
    }

    /**
     * @return xml layout res id
     */
    @LayoutRes
    public int getSplashLayout() {
        return 0;
    }
    private void continueToStartAppIntent() {
        final Intent startAppIntent = NavigationApplication.instance.getLastActivityIntent();
        if (startAppIntent != null && screenIsVisible) {
            NavigationApplication.instance.startActivity(startAppIntent);
            finish();
        }
    }


    /**
     * @return the layout you would like to show while react's js context loads
     */
    public View createSplashLayout() {
        View view = new View(this);
        view.setBackgroundColor(Color.WHITE);
        return view;
    }
}
