package com.ktso7.ledgerify

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.NumberFormat
import java.util.Locale

/**
 * Ledgerify Home Screen Widget Provider
 *
 * Displays:
 * - Budget progress (spent / total)
 * - Safe to spend amount
 * - Quick-add category buttons
 * - Contextual alerts (upcoming bills, overspending warnings)
 *
 * Syncs data from Flutter via home_widget SharedPreferences.
 */
class LedgerifyWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val ACTION_QUICK_ADD = "com.ktso7.ledgerify.QUICK_ADD"
        private const val EXTRA_CATEGORY = "category"
        private const val PREFS_NAME = "HomeWidgetPreferences"

        // Category icon mappings (Material Icons codepoints)
        private val CATEGORY_ICONS = mapOf(
            0 to android.R.drawable.ic_menu_today,        // food - restaurant
            1 to android.R.drawable.ic_menu_directions,   // transport - car
            2 to android.R.drawable.ic_menu_agenda,       // shopping - bag
            3 to android.R.drawable.ic_menu_gallery,      // entertainment - movie
            4 to android.R.drawable.ic_menu_recent_history, // bills - receipt
            5 to android.R.drawable.ic_menu_help,         // health - medical
            6 to android.R.drawable.ic_menu_info_details, // education - school
            7 to android.R.drawable.ic_menu_more          // other - more
        )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_QUICK_ADD) {
            val category = intent.getIntExtra(EXTRA_CATEGORY, -1)
            openAppWithCategory(context, category)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_ledgerify)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Read data from SharedPreferences (synced from Flutter)
        val budgetText = prefs.getString("budget_text", "₹0") ?: "₹0"
        val safeSpendText = prefs.getString("safe_to_spend_text", "₹0 safe") ?: "₹0 safe"
        val daysLeftText = prefs.getString("days_left_text", "") ?: ""
        val percentageText = prefs.getString("budget_percentage_text", "0%") ?: "0%"
        val percentage = (prefs.getFloat("budget_percentage", 0f) * 100).toInt()
        val alertText = prefs.getString("context_alert", "Tap + to add expense") ?: "Tap + to add expense"
        val showAlerts = prefs.getBoolean("show_alerts", true)
        val showBudget = prefs.getBoolean("show_budget", true)

        // Update text views
        views.setTextViewText(R.id.budget_text, budgetText)
        views.setTextViewText(R.id.safe_spend_text, if (daysLeftText.isNotEmpty()) "$safeSpendText ($daysLeftText)" else safeSpendText)
        views.setTextViewText(R.id.percentage_text, percentageText)
        views.setProgressBar(R.id.budget_progress, 100, percentage.coerceIn(0, 100), false)
        views.setTextViewText(R.id.alert_text, alertText)

        // Update visibility
        views.setViewVisibility(R.id.status_row, if (showBudget) android.view.View.VISIBLE else android.view.View.GONE)
        views.setViewVisibility(R.id.budget_progress, if (showBudget) android.view.View.VISIBLE else android.view.View.GONE)
        views.setViewVisibility(R.id.alert_row, if (showAlerts) android.view.View.VISIBLE else android.view.View.GONE)

        // Update category buttons
        updateCategoryButton(views, prefs, R.id.cat_1_container, R.id.cat_1_text, "cat_0", context, appWidgetId)
        updateCategoryButton(views, prefs, R.id.cat_2_container, R.id.cat_2_text, "cat_1", context, appWidgetId)
        updateCategoryButton(views, prefs, R.id.cat_3_container, R.id.cat_3_text, "cat_2", context, appWidgetId)
        updateCategoryButton(views, prefs, R.id.cat_4_container, R.id.cat_4_text, "cat_3", context, appWidgetId)

        // Set up add button click
        val addIntent = createQuickAddIntent(context, appWidgetId, -1)
        views.setOnClickPendingIntent(R.id.add_container, addIntent)

        // Set up widget container click (opens app)
        val openAppIntent = createOpenAppIntent(context)
        views.setOnClickPendingIntent(R.id.widget_container, openAppIntent)

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun updateCategoryButton(
        views: RemoteViews,
        prefs: SharedPreferences,
        containerId: Int,
        textId: Int,
        prefKey: String,
        context: Context,
        appWidgetId: Int
    ) {
        val categoryIndex = prefs.getInt("${prefKey}_index", -1)
        val categoryName = prefs.getString("${prefKey}_name", "") ?: ""

        if (categoryIndex >= 0 && categoryName.isNotEmpty()) {
            views.setTextViewText(textId, categoryName)
            views.setViewVisibility(containerId, android.view.View.VISIBLE)

            // Set click listener
            val intent = createQuickAddIntent(context, appWidgetId, categoryIndex)
            views.setOnClickPendingIntent(containerId, intent)
        } else {
            views.setViewVisibility(containerId, android.view.View.GONE)
        }
    }

    private fun createQuickAddIntent(context: Context, appWidgetId: Int, category: Int): PendingIntent {
        val intent = Intent(context, LedgerifyWidgetProvider::class.java).apply {
            action = ACTION_QUICK_ADD
            putExtra(EXTRA_CATEGORY, category)
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        return PendingIntent.getBroadcast(
            context,
            category + 100, // Unique request code for each category
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun createOpenAppIntent(context: Context): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun openAppWithCategory(context: Context, category: Int) {
        val uri = if (category >= 0) {
            Uri.parse("ledgerify://quick-add?category=$category")
        } else {
            Uri.parse("ledgerify://quick-add")
        }

        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            setPackage(context.packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        // Fall back to launching the main activity if deep link fails
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            val fallbackIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("category", category)
            }
            fallbackIntent?.let { context.startActivity(it) }
        }
    }
}
