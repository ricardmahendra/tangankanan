# PRD — TanganKanan
## Product Requirements Document
**Version:** 1.0.0  
**Last Updated:** Juli 2025  
**Team:** Kelompok 1 — UNISNU Jepara  
**Status:** In Development

---

## 1. OVERVIEW

### 1.1 Product Summary
TanganKanan adalah aplikasi mobile on-demand berbasis jasa rumah tangga yang menghubungkan pengguna (pencari jasa) dengan mitra (penyedia jasa) melalui satu platform terintegrasi. Platform ini menetapkan tarif secara terpusat, memproses pembayaran secara digital, dan mengambil komisi 12% dari setiap transaksi yang berhasil.

### 1.2 Tagline
> **"Asisten Jasa Rumah Tangga"**

### 1.3 Target Market
- **Pencari Jasa (User):** Masyarakat 17+ tahun di kota menengah (Jepara dan sekitarnya) yang membutuhkan bantuan jasa rumah tangga
- **Penyedia Jasa (Mitra):** Pekerja informal 17+ tahun yang ingin mendapatkan pelanggan lebih luas secara digital
- **Pasar Utama:** Jepara, Jawa Tengah — kota menengah yang belum terlayani platform nasional secara optimal

### 1.4 Team
| Nama | NIM | Role |
|---|---|---|
| Ricard Mahendra | 231240001457 | Tech Lead / Backend |
| Danil Faizul Ahadi | 231240001366 | Flutter Dev — User App |
| Kaysha Alvy Nurul Ainiyah | 231240001359 | Flutter Dev — Mitra App |
| Nafisah Rizqy Aulia | 231240001403 | UI/UX + Admin Panel |

### 1.5 Repository
- **GitHub:** https://github.com/ricardmahendra/tangan_kanan
- **Backend:** PocketBase (self-hosted)

---

## 2. TECH STACK

| Layer | Technology | Notes |
|---|---|---|
| Frontend | Flutter (Dart) | Android-first MVP, iOS fase 2 |
| Backend | PocketBase v0.38+ | Self-hosted, REST API + Realtime |
| State Management | flutter_bloc + equatable | BLoC pattern |
| Navigation | go_router | Auth guard via ChangeNotifier |
| Token Storage | shared_preferences | Web-compatible (NOT flutter_secure_storage) |
| HTTP | pocketbase SDK + dio | |
| Image | image_picker | Handle kIsWeb separately |
| Maps | geolocator + flutter_map + OpenStreetMap | Free, no quota |
| Payment | midtrans_sdk | QRIS / Transfer / E-wallet |
| Notification | firebase_messaging + firebase_core | Push notification |
| UI Extras | shimmer, lottie, cached_network_image, intl, timeago | |

---

## 3. DESIGN SYSTEM

### 3.1 Color Palette
```
Primary:        #1A5FA8  (dark blue — buttons, headers, accents)
Primary Mid:    #2E75B6  (section headings)
Primary Light:  #EBF3FB  (card backgrounds, highlights)
Success:        #2ECC71  (confirmed, completed, verified)
Warning:        #F39C12  (pending, ratings)
Danger:         #E74C3C  (error, cancel, suspend)
Background:     #F5F6FA  (scaffold background)
Surface:        #FFFFFF  (cards, modals, forms)
Text Primary:   #1A1A2E  (headings, main text)
Text Secondary: #6C757D  (subtitles, hints, placeholders)
Border:         #E0E0E0  (dividers, input borders)
```

### 3.2 Typography
- **Font Family:** Poppins (Google Fonts)
- **Heading Large:** Poppins Bold, 24–28px
- **Heading Section:** Poppins SemiBold, 18–20px
- **Body:** Poppins Regular, 14–16px
- **Caption:** Poppins Regular, 11–12px

### 3.3 Components
- **Border Radius:** 16px for cards, 12px for inputs and buttons
- **Card Shadow:** `BoxShadow(color: black.withOpacity(0.06), blurRadius: 8, offset: Offset(0,2))`
- **Primary Button:** Full-width, height 52px, rounded 12px, color #1A5FA8
- **Status Badge Colors:**

| Status | Color |
|---|---|
| pending | #F39C12 (orange) |
| confirmed | #2E75B6 (blue) |
| on_the_way | #9B59B6 (purple) |
| arrived | #1ABC9C (teal) |
| in_progress | #3498DB (indigo) |
| completed | #2ECC71 (green) |
| cancelled | #E74C3C (red) |

---

## 4. USER ROLES

### 4.1 Role Types
| Role | Collection | Description |
|---|---|---|
| `user` | users | Pencari jasa, dapat memesan layanan |
| `mitra` | partners | Penyedia jasa, menerima dan mengerjakan pesanan |
| `admin` | _superusers | Pengelola platform, verifikasi mitra, kelola withdraw |

### 4.2 Role-Based Redirect After Login
```
role == "user"  → /main
role == "mitra" → /mitra
role == "admin" → /admin
```

---

## 5. DATABASE SCHEMA

### 5.1 Collection: `users` (Auth)
| Field | Type | Rules |
|---|---|---|
| name | Text | Required |
| phone | Text | Required |
| nik | Text | 16 digits |
| ktp_photo | File | Max 5MB, image only |
| address | Text | |
| avatar | File | Max 2MB |
| is_active | Bool | Default: true |
| role | Text | Default: "user" |

### 5.2 Collection: `partners` (Auth)
| Field | Type | Rules |
|---|---|---|
| name | Text | Required |
| phone | Text | Required |
| nik | Text | Required |
| ktp_photo | File | Required |
| selfie_photo | File | Required |
| avatar | File | |
| bio | Text | |
| is_online | Bool | Default: false |
| is_verified | Bool | Default: false |
| is_active | Bool | Default: true |
| rating | Number | Default: 0, range 0–5 |
| total_jobs | Number | Default: 0 |
| balance | Number | Default: 0 (Rupiah) |
| bank_name | Text | |
| bank_account | Text | |
| work_agreement_signed | Bool | Default: false |
| role | Text | Default: "mitra" |

### 5.3 Collection: `categories` (Base)
| Field | Type | Notes |
|---|---|---|
| name | Text | Required |
| is_active | Bool | Default: true |
| order | Number | Sort order |

**Seed Data (6 records):**
| name | order |
|---|---|
| Home Cleaning | 1 |
| Laundry Assistance | 2 |
| Caregiver | 3 |
| Household Helper | 4 |
| Outdoor House Care | 5 |
| Home Maintenance | 6 |

### 5.4 Collection: `subcategories` (Base)
| Field | Type | Notes |
|---|---|---|
| category_id | Relation → categories | Required |
| name | Text | Required |
| description | Text | |
| price | Number | Required, in Rupiah |
| price_unit | Text | per sesi / per kg / per jam / per item / per unit / per m² / per pekerjaan / per titik |
| is_active | Bool | Default: true |
| order | Number | |

**Seed Data (27 records):**

| Category | Name | Price | Unit |
|---|---|---|---|
| Home Cleaning | Menyapu | 25.000 | per sesi |
| Home Cleaning | Mengepel | 25.000 | per sesi |
| Home Cleaning | Membersihkan debu | 20.000 | per sesi |
| Home Cleaning | Membersihkan kamar mandi | 35.000 | per unit |
| Home Cleaning | Membersihkan dapur | 40.000 | per sesi |
| Home Cleaning | Deep cleaning rumah | 150.000 | per sesi |
| Home Cleaning | Bersih rumah setelah acara | 120.000 | per sesi |
| Laundry Assistance | Cuci pakaian | 8.000 | per kg |
| Laundry Assistance | Setrika | 5.000 | per item |
| Laundry Assistance | Melipat pakaian | 3.000 | per item |
| Laundry Assistance | Menata lemari | 30.000 | per sesi |
| Caregiver | Pendampingan anak | 20.000 | per jam |
| Caregiver | Pendampingan lansia | 25.000 | per jam |
| Household Helper | Belanja kebutuhan rumah | 30.000 | per sesi |
| Household Helper | Membantu angkat barang | 40.000 | per sesi |
| Household Helper | Merapikan rumah | 50.000 | per sesi |
| Household Helper | Membantu pindahan kecil | 100.000 | per sesi |
| Outdoor House Care | Membersihkan halaman | 40.000 | per sesi |
| Outdoor House Care | Potong rumput | 50.000 | per sesi |
| Outdoor House Care | Menyiram tanaman | 15.000 | per sesi |
| Outdoor House Care | Membersihkan garasi | 45.000 | per sesi |
| Outdoor House Care | Bersih saluran air / got | 60.000 | per titik |
| Home Maintenance | Perbaikan lampu / listrik ringan | 75.000 | per pekerjaan |
| Home Maintenance | Perbaikan keran / pipa bocor | 70.000 | per pekerjaan |
| Home Maintenance | Pengecatan dinding area kecil | 100.000 | per m² |
| Home Maintenance | Perbaikan pintu / jendela | 60.000 | per unit |
| Home Maintenance | Pemasangan rak / furnitur | 55.000 | per item |

### 5.5 Collection: `partner_skills` (Base)
| Field | Type |
|---|---|
| partner_id | Relation → partners |
| subcategory_id | Relation → subcategories |

### 5.6 Collection: `orders` (Base)
| Field | Type | Notes |
|---|---|---|
| order_code | Text | Format: TK-XXXXXX (unique) |
| user_id | Relation → users | Required |
| partner_id | Relation → partners | Assigned after confirmation |
| category_id | Relation → categories | Required |
| address | Text | Required |
| latitude | Number | GPS coordinate |
| longitude | Number | GPS coordinate |
| scheduled_at | Date | Required |
| notes | Text | Optional from user |
| total_price | Number | SUM of order_items subtotals |
| platform_fee | Number | total_price × 0.12 |
| partner_income | Number | total_price × 0.88 |
| status | Select | pending / confirmed / on_the_way / arrived / in_progress / completed / cancelled |
| payment_status | Select | unpaid / paid / refunded |
| payment_method | Text | QRIS / transfer / e-wallet |
| midtrans_token | Text | Snap token from Midtrans |
| cancelled_by | Select | user / partner / admin |
| cancel_reason | Text | |
| completed_at | Date | Timestamp when completed |

**Status Flow (one-directional):**
```
pending → confirmed → on_the_way → arrived → in_progress → completed
       ↘ cancelled (only from pending or confirmed)
```

### 5.7 Collection: `order_items` (Base)
| Field | Type | Notes |
|---|---|---|
| order_id | Relation → orders | Required |
| subcategory_id | Relation → subcategories | |
| name | Text | Snapshot at time of order |
| price | Number | Snapshot at time of order |
| quantity | Number | Default: 1 |
| subtotal | Number | price × quantity |

> **Important:** name and price are snapshots — future price changes do NOT affect historical orders.

### 5.8 Collection: `reviews` (Base)
| Field | Type | Notes |
|---|---|---|
| order_id | Relation → orders | Unique (1 review per order) |
| user_id | Relation → users | |
| partner_id | Relation → partners | |
| rating | Number | 1–5 stars |
| comment | Text | Optional |

### 5.9 Collection: `chats` (Base)
| Field | Type | Notes |
|---|---|---|
| order_id | Relation → orders | |
| sender_id | Text | user_id or partner_id |
| sender_type | Select | user / partner |
| message | Text | Required |
| is_read | Bool | Default: false |

### 5.10 Collection: `withdrawals` (Base)
| Field | Type | Notes |
|---|---|---|
| partner_id | Relation → partners | Required |
| amount | Number | Min: 50.000 |
| bank_name | Text | Required |
| bank_account | Text | Required |
| status | Select | pending / approved / rejected / transferred |
| admin_note | Text | |
| transferred_at | Date | |

### 5.11 Collection: `notifications` (Base)
| Field | Type | Notes |
|---|---|---|
| recipient_id | Text | user_id or partner_id |
| recipient_type | Select | user / partner |
| title | Text | |
| body | Text | |
| type | Select | order / payment / system |
| is_read | Bool | Default: false |

---

## 6. FOLDER STRUCTURE

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_constants.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── pocketbase/
│   │   └── pb.dart
│   └── routes/
│       └── app_router.dart
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── partner_model.dart
│   │   ├── category_model.dart
│   │   ├── subcategory_model.dart
│   │   ├── order_model.dart
│   │   ├── order_item_model.dart
│   │   ├── review_model.dart
│   │   ├── chat_model.dart
│   │   └── withdrawal_model.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── category_repository.dart
│       ├── order_repository.dart
│       ├── partner_repository.dart
│       ├── chat_repository.dart
│       └── withdrawal_repository.dart
└── features/
    ├── auth/
    │   ├── login/login_page.dart
    │   └── register/register_page.dart
    ├── home/
    │   └── home_page.dart
    ├── order/
    │   ├── subcategory_page.dart
    │   ├── order_detail_page.dart
    │   ├── partner_select_page.dart
    │   ├── order_confirm_page.dart
    │   ├── order_tracking_page.dart
    │   └── order_review_page.dart
    ├── chat/
    │   └── chat_page.dart
    ├── history/
    │   └── history_page.dart
    ├── profile/
    │   ├── profile_page.dart
    │   └── mitra_registration_page.dart
    ├── main/
    │   └── main_page.dart
    ├── mitra/
    │   ├── mitra_page.dart
    │   ├── mitra_job_page.dart
    │   └── mitra_finance_page.dart
    └── admin/
        ├── admin_page.dart
        ├── admin_mitra_verify_page.dart
        └── admin_withdraw_page.dart

assets/
├── images/
└── icons/
```

---

## 7. ROUTING

```
/                     → LoginPage (default, unauthenticated)
/register             → RegisterPage
/main                 → MainPage (User — bottom nav: Beranda/Pesanan/Chat/Profil)
/order/:categoryId    → SubcategoryPage
/order/:categoryId/detail    → OrderDetailPage
/order/:categoryId/partners  → PartnerSelectPage
/order/confirm               → OrderConfirmPage
/order/tracking/:orderId     → OrderTrackingPage
/order/review/:orderId       → OrderReviewPage
/chat/:orderId               → ChatPage
/history                     → HistoryPage
/profile                     → ProfilePage
/mitra                       → MitraPage (Mitra — bottom nav: Beranda/Pekerjaan/Keuangan/Profil)
/mitra/job/:orderId          → MitraJobPage
/mitra/finance               → MitraFinancePage
/admin                       → AdminPage (Admin — dashboard)
/admin/mitra                 → AdminMitraVerifyPage
/admin/withdraw              → AdminWithdrawPage
```

**Auth Guard Logic:**
```dart
if (!isLoggedIn && !isAuthPage) → redirect to /
if (isLoggedIn && isAuthPage)   → redirect based on role
  role == "mitra" → /mitra
  role == "admin" → /admin
  else            → /main
```

---

## 8. FEATURE SPECIFICATIONS

### 8.1 Authentication

#### Login
- Input: email or phone number + password
- Validate: non-empty fields
- Call: `pb.collection('users').authWithPassword(emailOrPhone, password)`
- On success: token saved to shared_preferences, GoRouter auto-redirects via authNotifier
- On error: show SnackBar with error message
- Link to Register page

#### Register (User)
- Fields: name, phone, email, password, NIK, address, KTP photo upload
- Validate all required fields before submit
- Upload KTP photo to PocketBase file storage
- Call: `pb.collection('users').create(body: {...})`
- On success: auto-login, GoRouter redirects to /main

---

### 8.2 User Features

#### 8.2.1 HomePage (Beranda)
- Greeting: "Halo, [name] 👋"
- Location: "Jepara, Jawa Tengah" (static for MVP)
- Notification bell icon
- Search bar (UI only, no backend for MVP)
- Promo banner: gradient blue, "Gratis Biaya Layanan untuk 50 pesanan pertama"
- Category grid (3 columns): fetch from `categories` (filter: `is_active=true`, sort: `order`)
- Category icon mapping:
  - Home Cleaning → `Icons.cleaning_services`
  - Laundry Assistance → `Icons.local_laundry_service`
  - Caregiver → `Icons.favorite`
  - Household Helper → `Icons.handyman`
  - Outdoor House Care → `Icons.grass`
  - Home Maintenance → `Icons.build`
- "Mengapa TanganKanan?" section: 4 feature cards (Mitra Terverifikasi, Tarif Transparan, Tepat Waktu, Berbasis Rating)
- Loading state: shimmer grid (6 placeholder cards)
- Empty state: icon + "Belum ada kategori" + retry button
- Pull to refresh

#### 8.2.2 Order Flow

**Step 1 — SubcategoryPage**
- Header: category name
- List subcategories (filter: `category_id = selectedId AND is_active = true`, sort: `order`)
- Each item: checkbox + name + price + price_unit
- For `per kg`, `per jam`, `per item`: show quantity stepper (min: 1)
- Running total at bottom: "Total: Rp X"
- "Lanjut" button (disabled if nothing selected)
- Passes selected items to next page

**Step 2 — OrderDetailPage**
- Show selected items summary with subtotals
- Address input (text field, required)
- Date-time picker: scheduled_at (must be future time)
- Notes input (optional)
- "Lanjut Pilih Mitra" button

**Step 3 — PartnerSelectPage**
- Fetch available partners: `is_online=true AND is_verified=true AND is_active=true`
- Filter: partners who have skills matching any selected subcategory (via partner_skills)
- Each partner card: avatar, name, rating stars, total_jobs, distance (if GPS available)
- Tap to select, show checkmark
- "Pilih Mitra Ini" button → proceed to confirm

**Step 4 — OrderConfirmPage**
- Full summary:
  - Selected partner (name, avatar, rating)
  - Service items list with quantity and subtotal
  - Scheduled time
  - Address
  - Tariff breakdown: Subtotal, Platform fee (12%), Total
- "Bayar Sekarang" button → trigger Midtrans payment
- On payment success: create order in PocketBase, create order_items, navigate to tracking

**Financial Calculation:**
```
total_price    = SUM(subcategory.price × quantity) for all items
platform_fee   = total_price × 0.12
partner_income = total_price × 0.88
```

**Step 5 — OrderTrackingPage**
- Real-time status via PocketBase realtime: `pb.collection('orders').subscribe(orderId, callback)`
- Status stepper UI showing all steps
- Current status highlighted
- Order details (partner info, address, items)
- Chat button → navigate to /chat/:orderId
- Cancel button (only if status is pending or confirmed)
- Always unsubscribe in dispose()

**Step 6 — OrderReviewPage**
- Show partner info
- Star rating widget (1–5, interactive)
- Comment text field (optional)
- Submit → create record in reviews collection
- After submit → navigate to /history

#### 8.2.3 HistoryPage (Pesanan)
- Fetch all orders where `user_id = currentUserId`, sort by `created DESC`
- Tab filter: Semua / Aktif / Selesai / Dibatalkan
- Order card: order_code, category name, status badge, scheduled_at (formatted), total_price
- Tap active order → OrderTrackingPage
- Tap completed/cancelled order → order detail view
- Loading: shimmer list
- Empty: illustration + "Belum ada pesanan"

#### 8.2.4 ChatPage
- Fetch messages: `pb.collection('chats').getFullList(filter: 'order_id = orderId', sort: 'created')`
- Subscribe realtime for new messages
- Message bubbles: current user right (blue), other user left (grey)
- Show sender name and timestamp
- Input field + send button
- Mark messages as read on open
- Always unsubscribe in dispose()

#### 8.2.5 ProfilePage
- Show: avatar, name, email, phone, address
- Edit profile button
- Mitra status section:
  - No partner record → "Daftar sebagai Mitra" button → navigate to MitraRegistrationPage
  - Partner exists but `is_verified=false` → "Pendaftaran Sedang Diproses" badge
  - Partner exists and `is_verified=true` → "Anda adalah Mitra Aktif" badge
- Logout button → call `logout()`, GoRouter auto-redirects

#### 8.2.6 MitraRegistrationPage
- Fields: name, phone, NIK, bio
- Upload: KTP photo + selfie with KTP
- Select skills: multi-select from all subcategories (grouped by category)
- Work agreement: scrollable full SOP text, checkbox "Saya telah membaca dan menyetujui"
- Submit: create record in `partners` collection (is_verified=false), create partner_skills records
- Success: show confirmation message, return to profile

---

### 8.3 Mitra Features

#### 8.3.1 MitraPage (Beranda Mitra)
- Toggle online/offline switch → updates `is_online` field in partners
- Balance card: "Saldo Aktif: Rp X"
- Stats row: rating average + total_jobs
- Active job card (if any order with status pending/confirmed/on_the_way/arrived/in_progress)
- Recent earnings list (last 5 completed orders)

#### 8.3.2 MitraJobPage (Pekerjaan)
- **Incoming Orders:** realtime subscription on orders where `partner_id = currentMitraId AND status = pending`
- Incoming job card: user name, address, services ordered, total (partner_income), scheduled time
- Countdown timer: 10 minutes to respond
- Accept button → update status to `confirmed`
- Reject button → update status to `cancelled`, `cancelled_by = "partner"`
- **Active Job:** if order status is confirmed/on_the_way/arrived/in_progress:
  - Show full order detail
  - Status update buttons:
    - Status `confirmed` → "Berangkat" → `on_the_way`
    - Status `on_the_way` → "Saya Sudah Tiba" → `arrived`
    - Status `arrived` → "Mulai Pekerjaan" → `in_progress`
    - Status `in_progress` → "Selesai" → `completed` + add `partner_income` to partner balance
  - Chat button
- **Job History:** list of completed orders with date, services, partner_income earned

#### 8.3.3 MitraFinancePage (Keuangan)
- Balance display: large Rp amount
- Withdraw form:
  - Amount input (min Rp 50.000, max = current balance)
  - Bank name dropdown or text input
  - Account number input
  - Submit → create record in withdrawals (status: pending)
- Withdrawal history: list with status badges
- Earnings history: list of completed orders grouped by month

---

### 8.4 Admin Features

#### 8.4.1 AdminPage (Dashboard)
- Stats cards:
  - Total Users
  - Total Mitra (Active + Pending verification)
  - Orders today
  - Revenue today (sum of platform_fee for completed orders today)
- Navigation to: Verifikasi Mitra, Kelola Withdraw

#### 8.4.2 AdminMitraVerifyPage
- List of partners where `is_verified=false AND is_active=true`
- Each card: name, phone, NIK, KTP photo, selfie photo, bio, skills applied for
- Approve button → set `is_verified=true`
- Reject button → set `is_active=false` + optional note

#### 8.4.3 AdminWithdrawPage
- List of withdrawals where `status=pending`
- Each card: mitra name, amount (Rp), bank_name, bank_account, created date
- Approve → set status to `approved`
- Transfer Done → set status to `transferred`, set `transferred_at=now`, deduct amount from partner balance
- Reject → set status to `rejected` + admin_note

---

## 9. BUSINESS RULES

| Rule | Detail |
|---|---|
| Platform fee | Always 12% of total_price |
| Partner income | Always 88% of total_price |
| Mitra response time | Max 10 minutes — auto-cancel if exceeded |
| Mitra arrival tolerance | ±15 minutes from scheduled time |
| Minimum withdrawal | Rp 50.000 |
| Withdrawal processing | Max 2×24 hours by admin |
| Balance update | Automatic when order status → completed |
| Payment method | 100% digital via Midtrans (no cash) |
| Price snapshot | Saved in order_items at order creation time |
| Order cancellation | Only allowed from pending or confirmed status |
| Rating update | Partner rating = average of all reviews |
| Mitra KTP verification | Required before is_verified=true |

---

## 10. MONETIZATION

| Model | Description | Phase |
|---|---|---|
| Service Fee (12%) | Auto-deducted from every completed transaction | MVP |
| Mitra Premium | Monthly subscription for top placement + verified badge | Phase 2 |
| Boost & Featured | Pay for increased profile visibility in search | Phase 2 |
| Local Ads | Targeted ads for local SMEs based on user location | Phase 2 |
| User Subscription | Monthly plan: discounts + priority booking + premium mitra access | Phase 3 |

---

## 11. ROADMAP

| Phase | Timeline | Focus | Target |
|---|---|---|---|
| Phase 0 — Pre-Launch | Month 1–2 | Build MVP, recruit 15–20 mitra | App ready, mitra onboarded |
| Phase 1 — Soft Launch | Month 3 | Beta release, first 50 orders free fee | 50 transactions, rating ≥ 4.0 |
| Phase 2 — Growth | Month 4–8 | Activate commission, referral program, social media | 500 tx/month, revenue flowing |
| Phase 3 — Scale | Month 9+ | Expand to Kudus, Demak, Pati | 3+ cities, 2000 tx/month |

---

## 12. ACCEPTANCE CRITERIA (MVP)

### User Flow
- [ ] User can register with name, phone, NIK, address, KTP photo
- [ ] User can login with email or phone + password
- [ ] Token persists across app restarts (no re-login needed)
- [ ] Home page shows 6 categories from PocketBase
- [ ] User can select category and see subcategories with prices
- [ ] User can multi-select subcategories, see real-time total
- [ ] User can input address, schedule, and notes
- [ ] User can see available mitra list and select one
- [ ] User can see full order summary before payment
- [ ] User can pay via Midtrans (QRIS/transfer/e-wallet)
- [ ] User can track order status in real-time
- [ ] User can chat with mitra during active order
- [ ] User can give rating and review after order completed
- [ ] User can see order history with status filter

### Mitra Flow
- [ ] User can register as mitra from profile page
- [ ] Mitra can toggle online/offline
- [ ] Mitra receives real-time notification for incoming orders
- [ ] Mitra can accept or reject order within 10 minutes
- [ ] Mitra can update order status step by step
- [ ] Mitra balance auto-increases when order completed
- [ ] Mitra can request withdrawal (min Rp 50.000)

### Admin Flow
- [ ] Admin can see dashboard with key metrics
- [ ] Admin can verify mitra (approve/reject KTP)
- [ ] Admin can process withdrawal requests

---

## 13. TECHNICAL CONSTRAINTS

- **Web-first testing:** Chrome browser during development (no physical device required)
- **Token storage:** MUST use `shared_preferences`, NOT `flutter_secure_storage` (breaks on web)
- **Realtime:** Always unsubscribe PocketBase realtime in `dispose()`
- **Images on web:** Use `kIsWeb` check for image picker — web uses different API
- **Navigation:** ALL navigation must use GoRouter (`context.go()`, `context.push()`, `context.pop()`) — NO `Navigator.pushNamed()`
- **Assets:** Folders `assets/images/` and `assets/icons/` must exist (required by pubspec)
- **Price snapshots:** Always copy price and name to order_items at creation time
- **PocketBase URL:** `http://127.0.0.1:8090` for web/local dev

---

## 14. OUT OF SCOPE (MVP)

- iOS build (Phase 2)
- Google Sign-In
- In-app voice/video call
- AI-powered service recommendations
- Multi-language support
- Offline mode
- Dark mode
- Push notifications (Phase 2 — Firebase FCM)
- Smart matching algorithm (Phase 2 — manual selection for MVP)

---

*Document maintained by TanganKanan Team — Kelompok 1 UNISNU Jepara*
*For questions: contact Ricard Mahendra (Tech Lead)*
