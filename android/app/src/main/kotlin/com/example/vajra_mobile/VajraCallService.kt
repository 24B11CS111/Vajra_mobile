package com.example.vajra_mobile

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.ContactsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class VajraCallService(private val activity: Activity) {
    private val CHANNEL = "com.vajra.app/call_assistant"
    private var methodChannel: MethodChannel? = null

    fun register(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "searchContacts" -> {
                        val query = call.argument<String>("query") ?: ""
                        try {
                            val contacts = searchContacts(query)
                            result.success(contacts)
                        } catch (e: Exception) {
                            result.success(emptyList<Map<String, Any?>>())
                        }
                    }
                    "makeCall" -> {
                        val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                        val contactName = call.argument<String>("contactName")
                        val directCall = call.argument<Boolean>("directCall") ?: false

                        if (phoneNumber.isEmpty()) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "message" to "No phone number provided.",
                                    "error" to "EMPTY_NUMBER"
                                )
                            )
                            return@setMethodCallHandler
                        }

                        try {
                            if (directCall && activity.checkSelfPermission(android.Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
                                val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$phoneNumber")).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                activity.startActivity(intent)
                                result.success(
                                    mapOf(
                                        "success" to true,
                                        "message" to "Calling ${contactName ?: phoneNumber}...",
                                        "openedDialer" to false
                                    )
                                )
                            } else {
                                val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phoneNumber")).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                activity.startActivity(intent)
                                result.success(
                                    mapOf(
                                        "success" to true,
                                        "message" to "Opened dialer for ${contactName ?: phoneNumber}.",
                                        "openedDialer" to true
                                    )
                                )
                            }
                        } catch (e: Exception) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "message" to "Failed to start phone action: ${e.message}",
                                    "error" to "INTENT_FAILED"
                                )
                            )
                        }
                    }
                    "openDialer" -> {
                        val phoneNumber = call.argument<String>("phoneNumber")
                        try {
                            val intent = if (!phoneNumber.isNullOrEmpty()) {
                                Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phoneNumber"))
                            } else {
                                Intent(Intent.ACTION_DIAL)
                            }.apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            activity.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("DIALER_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun searchContacts(query: String): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()
        if (activity.checkSelfPermission(android.Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            return list
        }

        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER,
            ContactsContract.CommonDataKinds.Phone.PHOTO_URI
        )
        val selection = "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} LIKE ? OR ${ContactsContract.CommonDataKinds.Phone.NUMBER} LIKE ?"
        val selectionArgs = arrayOf("%$query%", "%$query%")

        var cursor: Cursor? = null
        try {
            cursor = activity.contentResolver.query(uri, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val idIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)
                val nameIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                val numIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                val photoIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.PHOTO_URI)

                var count = 0
                do {
                    val id = if (idIdx >= 0) cursor.getString(idIdx) else ""
                    val name = if (nameIdx >= 0) cursor.getString(nameIdx) else ""
                    val num = if (numIdx >= 0) cursor.getString(numIdx) else ""
                    val photo = if (photoIdx >= 0) cursor.getString(photoIdx) else null

                    list.add(
                        mapOf(
                            "id" to id,
                            "displayName" to name,
                            "phoneNumber" to num,
                            "photoUri" to photo
                        )
                    )
                    count++
                } while (cursor.moveToNext() && count < 10)
            }
        } catch (e: Exception) {
            // Return whatever found
        } finally {
            cursor?.close()
        }
        return list
    }
}
