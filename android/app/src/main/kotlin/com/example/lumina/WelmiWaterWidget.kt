package com.example.lumina

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Виджет «Вода» на рабочий стол.
 *
 * Данные пишет Flutter-код через HomeWidget.saveWidgetData(...)
 * (см. lib/core/services/widget_service.dart) и читаются здесь
 * через widgetData (SharedPreferences плагина home_widget).
 *
 * Кнопка «Выпил стакан» открывает приложение с URI welmi://add_water?ml=250,
 * Flutter добавляет воду и обновляет виджет.
 */
class WelmiWaterWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.welmi_water_widget)

            // Если данные за вчера — показываем 0 (вода «сгорает» в полночь)
            val storedDate = widgetData.getString("widget_date", "")
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val isToday = storedDate == today

            val waterMl = if (isToday) widgetData.getInt("widget_water_ml", 0) else 0
            val waterGoal = widgetData.getInt("widget_water_goal", 1).coerceAtLeast(1)
            val calories = if (isToday) widgetData.getInt("widget_calories", 0) else 0
            val caloriesGoal = widgetData.getInt("widget_calories_goal", 1).coerceAtLeast(1)

            views.setTextViewText(
                R.id.water_value,
                "$waterMl / $waterGoal мл",
            )
            views.setProgressBar(R.id.water_progress, waterGoal, waterMl, false)

            views.setTextViewText(
                R.id.calories_value,
                "$calories / $caloriesGoal ккал",
            )
            views.setProgressBar(R.id.calories_progress, caloriesGoal, calories, false)

            // Клик по виджету — открыть приложение
            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("welmi://home"),
            )
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)

            // Кнопка «Выпил стакан» — открыть приложение и добавить воду
            val waterIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("welmi://add_water?ml=250"),
            )
            views.setOnClickPendingIntent(R.id.btn_add_water, waterIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
