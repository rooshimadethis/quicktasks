package me.rooshi.quicktasks

import android.content.Context
import android.content.Intent
import android.text.Html
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.lang.Exception

class TaskListWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        Log.d("TaskListWidget", "onGetViewFactory called")
        return TaskListWidgetFactory(applicationContext)
    }
}

class TaskListWidgetFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private var tasksArray = JSONArray()

    override fun onCreate() {
        Log.d("TaskListWidget", "onCreate called")
        loadData()
    }

    override fun onDataSetChanged() {
        Log.d("TaskListWidget", "onDataSetChanged called")
        loadData()
    }

    override fun onDestroy() {
        Log.d("TaskListWidget", "onDestroy called")
        tasksArray = JSONArray()
    }

    private fun loadData() {
        try {
            val prefs = HomeWidgetPlugin.getData(context)
            val jsonStr = prefs.getString("tasks_json", "[]") ?: "[]"
            Log.d("TaskListWidget", "loadData: tasks_json string = $jsonStr")
            tasksArray = JSONArray(jsonStr)
            Log.d("TaskListWidget", "loadData parsed array length = ${tasksArray.length()}")
        } catch (e: Exception) {
            Log.e("TaskListWidget", "loadData error loading data", e)
            tasksArray = JSONArray()
        }
    }

    override fun getCount(): Int {
        val count = tasksArray.length()
        Log.d("TaskListWidget", "getCount called, returning $count")
        return count
    }

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= count) return null

        val task = tasksArray.optJSONObject(position) ?: return null
        val localId = task.optString("localId", "")
        val title = task.optString("title", "")
        val isComplete = task.optBoolean("isComplete", false)
        val category = task.optString("category", "none")
        val timeString = task.optString("timeString", "")

        val views = RemoteViews(context.packageName, R.layout.task_list_widget_item)

        // 1. Checkbox state
        val checkboxSymbol = if (isComplete) "☑" else "☐"
        views.setTextViewText(R.id.item_status, checkboxSymbol)

        // 2. Styled title (Strikethrough if completed)
        if (isComplete) {
            val styledTitle = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                Html.fromHtml("<s>$title</s>", Html.FROM_HTML_MODE_LEGACY)
            } else {
                @Suppress("DEPRECATION")
                Html.fromHtml("<s>$title</s>")
            }
            views.setTextViewText(R.id.item_title, styledTitle)
        } else {
            views.setTextViewText(R.id.item_title, title)
        }

        // 3. Category shape & Time String
        val shape = when (category.lowercase()) {
            "work" -> "■"
            "personal" -> "●"
            "errand" -> "▲"
            else -> ""
        }

        val metaText = StringBuilder()
        if (shape.isNotEmpty()) {
            metaText.append(shape).append(" ")
        }
        if (timeString.isNotEmpty()) {
            metaText.append(timeString)
        }
        views.setTextViewText(R.id.item_meta, metaText.toString())

        // 4. Fill-in intent for tapping row
        val fillInIntent = Intent().apply {
            data = android.net.Uri.parse("quicktasks://task?id=$localId")
        }
        views.setOnClickFillInIntent(R.id.widget_item_container, fillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? {
        return null
    }

    override fun getViewTypeCount(): Int {
        return 1
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }
}
