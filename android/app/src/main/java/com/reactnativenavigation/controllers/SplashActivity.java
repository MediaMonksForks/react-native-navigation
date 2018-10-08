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

    // This receiver receives the Intent to launch a new NavigationActivity.
    // Since this starts an Activity, it is only registered when the current Activity is visible.
    private BroadcastReceiver navigationIntentReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final ComponentName component = intent.getComponent();
            if (component == null) {
                return;
            }

            unregisterToNavigationActivityLaunch();

            final String className = component.getClassName();
            if (!NavigationActivity.class.getName().equals(className)) {
                return;
            }

            continueToStartAppIntent();
        }
    };


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

    private void unregisterToNavigationActivityLaunch() {
        LocalBroadcastManager.getInstance(NavigationApplication.instance).unregisterReceiver(navigationIntentReceiver);
    }


    @Override
    protected void onResume() {
        super.onResume();
        registerToNavigationActivityLaunch();

        if (ReactDevPermission.shouldAskPermission()) {
            ReactDevPermission.askPermission(this);
            return;
        }

        /*
         * Previously JS contexts were destroyed when a NavigationActivity was destroyed.
         * I found this not unsatisfactory, because when the app is in the background and the app launcher is used,
         * SplashActivity will cause other Activity instances to be destroyed,
         * but that destruction may occur AFTER SplashActivity.onResume() determined that we DO have a JS context.
         * This miscommunication caused SplashActivity to launch a new NavigationActivity with no JS context,
         * which in turn caused it to start JS context initialization and to launch yet another NavigationActivity.
         *
         * By destroying and re-creating the JS context here instead of waiting for the old Activity to do it,
         * we save the user from staring at a blank screen for a couple of seconds.
         *
         */
        if (NavigationApplication.instance.getReactGateway().hasStartedCreatingContext()) {
            if (NavigationApplication.instance.isReactContextInitialized()) {
                NavigationApplication.instance.getReactGateway().onDestroyApp();
            }
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
    }

    @Override
    protected void onPause() {
        super.onPause();
        unregisterToNavigationActivityLaunch();
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
        if (startAppIntent != null) {
            NavigationApplication.instance.startActivity(startAppIntent);
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
