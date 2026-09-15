# VAJRA API INTEGRATION STATUS

## Summary
All core subsystem contracts between the Flutter mobile client and the FastAPI backend are now mapped, typed, and persistently integrated with database backing and offline-first local caching.

## Endpoint Architecture

| Subsystem | HTTP Method | Endpoint | Request Payload | Response Schema | Local Cache / Sync Layer |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Authentication** | `POST` | `/api/v1/auth/login` | `{"email": str, "password": str}` | `TokenResponse(access_token, token_type)` | `FlutterSecureStorage` |
| **Authentication** | `POST` | `/api/v1/auth/social` | `{"provider": str, "id_token": str}` | `TokenResponse(access_token, token_type)` | `FlutterSecureStorage` |
| **Authentication** | `POST` | `/api/v1/auth/refresh` | `{"refresh_token": str}` | `TokenResponse(access_token, token_type)` | `FlutterSecureStorage` |
| **Authentication** | `POST` | `/api/v1/auth/logout` | None (Bearer Token) | `{"status": "ok"}` | Secure deletion of token & state reset |
| **User Profile** | `GET` | `/api/v1/me` | None (Bearer Token) | `UserResponse(id, email, full_name, etc.)` | `SharedPreferences` cached profile |
| **User Profile** | `PUT` | `/api/v1/me` | `UserUpdate(full_name, bio, theme, personality)` | `UserResponse(...)` | Deterministic local sync |
| **Companion Chat** | `GET` | `/api/v1/chat/conversations` | None | `List[ConversationResponse]` | Local conversation cache |
| **Companion Chat** | `POST` | `/api/v1/chat/conversations` | `ConversationCreate(title)` | `ConversationResponse(id, title)` | Session ID mapping |
| **Companion Chat** | `POST` | `/api/v1/chat/conversations/{id}/messages/stream` | `MessageCreate(role, content)` | SSE Stream (`text/event-stream`) | Live UI streaming & DB message persistence |
| **Memory Engine** | `GET` | `/api/v1/memory/` | Query params: `query`, `memory_type` | `List[Memory]` | `cached_memories_<category>` |
| **Memory Engine** | `POST` | `/api/v1/memory/` | `MemoryCreate(content, type, importance)` | `Memory(...)` | Safe deduplication sync |
| **Memory Engine** | `POST` | `/api/v1/memory/{id}/favorite` | None | `Memory(...)` | Local pin state sync |
| **Memory Engine** | `POST` | `/api/v1/memory/{id}/archive` | None | `Memory(...)` | Local archive sync |
| **Memory Engine** | `DELETE` | `/api/v1/memory/{id}` | None | `Memory(...)` | Local cache invalidation |
| **Planner** | `GET` | `/api/v1/planner/tasks` | None | `List[TaskResponse]` | `cached_tasks_<date>` |
| **Planner** | `POST` | `/api/v1/planner/tasks` | `TaskCreate(title, category, priority, due_date)`| `TaskResponse(...)` | Optimistic update + persistent save |
| **Planner** | `POST` | `/api/v1/planner/tasks/{id}/toggle` | None | `TaskResponse(...)` | Offline toggle queue |
| **Planner** | `POST` | `/api/v1/planner/tasks/reorder` | `TaskReorder(task_ids)` | `{"status": "ok"}` | Local reorder list |
| **Planner** | `DELETE` | `/api/v1/planner/tasks/{id}` | None | 204 No Content | Local delete |
| **Notifications** | `GET` | `/api/v1/notifications/` | None | `List[NotificationResponse]` | `cached_notifications` |
| **Notifications** | `POST` | `/api/v1/notifications/` | `NotificationCreate(title, message, type)` | `NotificationResponse(...)` | Proactive alert storage |
| **Notifications** | `POST` | `/api/v1/notifications/{id}/read` | None | `NotificationResponse(...)` | Read status sync |
| **Notifications** | `POST` | `/api/v1/notifications/read-all` | None | `{"status": "ok"}` | Batch mark read |

## Network Safety & Robustness
1. **Host-to-Emulator Resolution**: Dynamic base URL using `http://10.0.2.2:8000/api/v1`.
2. **Interceptors**:
   - `TraceInterceptor`: Generates unique `X-Request-ID` for end-to-end tracing.
   - `AuthInterceptor`: Attaches `Authorization: Bearer <token>` from encrypted storage.
   - `RetryInterceptor`: Transparent retry with exponential backoff on transient network drops.
   - `ConnectivityInterceptor`: Immediate offline detection before socket timeouts.
   - `LoggingInterceptor`: Sanitized header and request logging without token leakage.
