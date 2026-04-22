# Neqat 🌟

Hey there! Welcome to **Neqat**, our big, bold attempt to build something life-changing! 🚀 We set out to create an app that’s not just a course project, but something we can monetize and turn into a real game changer. Picture this: an app that cuts through the noise of information overload and helps folks in Ethiopia (and beyond) trust the products and services they use. We wanted to make coding fun, level up our skills, and maybe even build a future where we don’t have to juggle side gigs to make ends meet. That’s Neqat in a nutshell built with passion, grit, and a whole lot of coffee! ☕

## Project Overview 😊

Neqat tackles two huge problems we’ve all faced:

- **Too Much Info**: Platforms like Tikvah flood users with so much content it’s hard to find what matters. Neqat curates news (especially in Amharic) into bite-sized, easy-to-digest pieces.
- **Shady Products & Services**: In Ethiopia, it’s tough to know if a product or service is legit without relying on word-of-mouth. Neqat lets you scan a product, check community reviews, and share your own to keep things transparent.

### Our Goals
- **Nail the course Projects**: Create something awesome enough to submit for all four courses. 📚
- **Get Better at Coding**: We’re coding everything ourselves (no AI copy-paste here!) to make it fun and learn tons along the way. We’re cool with using AI for research, though!
- **Build a Money-Maker**: Make an app that’s scalable and can bring in income, freeing us to focus on what we love.

## Features ✨
- **Cross-Lingual Search Magic 🔍**: Search in Amharic or English, and our system translates Amharic to English using Google Cloud Translate, then uses the Porter stemmer to nail term matching (e.g., “pollution” to “pollut”). We tested it on 845 Tikvah Telegram posts, and it rocks with a mean F1-score of 0.280! 🇪🇹➡️🇺🇸
- **Smart Retrieval Models 🧠**: We built three heavy-hitters:
  - **BM25**: Our star, balancing keywords and article length for spot-on results (e.g., F1=0.480 for “Road Accidents”).
  - **TF-IDF**: Matches queries to news using term frequency and rarity, with cosine similarity for precision.
  - **Query Likelihood Language Model (QL-LM)**: Uses fancy probability math (Dirichlet smoothing, mu=2000) to find the best articles.
- **Translation Caching ⚡**: We store English translations in the database to avoid repeat API calls, making searches super fast.
- **Amharic Localization 🇪🇹**: Use the app in Amharic for a seamless, local vibe.
- **Dark & Light Themes 🌙☀️**: Switch between modes for comfy viewing any time of day.

### Other Cool Stuff
- **Product Reviews**: Scan or snap a product to see community reviews or add your own. 🛍️
- **Curated News Feed**: Get the best bits from Tikvah Telegram channels, summarized and ready to read.
- **User Authentication**: Sign up, log in (even with Google, Facebook, or Apple), manage your profile, or reset passwords securely.
- **Cross-Platform Vibes**: Works smoothly on web, iOS, and Android. 📱💻

## Tech Stack 🛠️

- **Backend**: Django, Django REST Framework, Python 3.8+, Microsoft SQL Server (running in Docker)
- **Frontend**: Flutter, Dart, Riverpod for state management, Flutter Clean Architecture for tidy code
- **Other Goodies**: Telegram API (scraping Tikvah news), Google Cloud Translate (for search magic), scikit-learn (search indexing), joblib (index persistence), Git (keeping our code in check)

## Backend Setup 🔧

Let’s get the backend up and running! Here’s how:

### What You Need
- Python 3.8+
- Docker (for SQL Server)
- Git
- Microsoft ODBC Driver for SQL Server (for local dev)

### Steps
1. **Clone the Repo**
   ```bash
   git clone <repository-url>
   cd NeqatBackend
   ```

2. **Set Up a Virtual Environment**
   ```bash
   python -m venv venv
   .\venv\Scripts\Activate.ps1  # Windows
   source venv/bin/activate    # macOS/Linux
   ```

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Spin Up SQL Server with Docker**
   ```bash
   docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=NEQ@T2025" \
      -p 1433:1433 --name sqlserver \
      -d mcr.microsoft.com/mssql/server:2022-latest
   ```

5. **Set Up the Database**
   Copy and run the SQL script:
   ```bash
   # Copy the script to the container
   docker cp ./Create_Everything.sql sqlserver:/tmp/Create_Everything.sql

   # Connect to SQL Server
   docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "NEQ@T2025" -C

   # Run the script
   :r /tmp/Create_Everything.sql
   GO
   ```

6. **Extra Step**: Make sure the Microsoft ODBC Driver for SQL Server is installed on your machine for local database access.

7. **Apply Django Migrations**
   ```bash
   python manage.py migrate
   ```

8. **Create a Superuser (Optional)**
   ```bash
   python manage.py createsuperuser
   ```

9. **Start the Server**
   ```bash
   python manage.py runserver
   ```
   Your backend will be live at `http://127.0.0.1:8000/`. 🎉

## Frontend Setup 📱

The frontend is built with Flutter, using Riverpod for state management and Flutter Clean Architecture to keep things organized. Here’s how to get it going:

### What You Need
- Flutter 3.0+
- Dart
- Git

### Steps
1. **Clone the Frontend Repo**
   ```bash
   git clone <frontend-repository-url>
   cd NeqatFrontend
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Set Up Environment Variables**
   Create a `.env` file in the frontend root and add:
   ```
   API_URL=http://127.0.0.1:8000/api/
   ```

4. **Run the App**
   ```bash
   flutter run
   ```
   The app will launch on your emulator, device, or web at `http://localhost:3000/`. 🚀

## Advanced Search Functionality 🔍

Our search system is where Neqat really shines! 🌟 It’s a cutting-edge, cross-lingual beast designed to make finding Amharic news on Tikvah a breeze, even with Amharic’s tricky grammar (think verbs with 80+ forms!). We tested it on 845 Tikvah Telegram messages, and it’s a game-changer for cutting through info overload.

### What Makes It Awesome
- **Search in Amharic or English**: Type in Amharic or English, and we translate Amharic to English using Google Cloud Translate for super-accurate results. 🇪🇹➡️🇺🇸
- **Smart Retrieval Models**:
  - **TF-IDF**: Matches queries to news using term frequency and document rarity, with cosine similarity for pinpoint accuracy.
  - **BM25**: Our star player, balancing keywords and article length. It scored a mean F1 of 0.280 and MAP of 0.264 on queries like “Road Accidents” (F1=0.480). 🚗
  - **Query Likelihood Language Model (QL-LM)**: Uses fancy probability math (Dirichlet smoothing, mu=2000) to find articles that fit your query perfectly.
- **Translation Magic**: We cache English translations in the database to speed things up, avoiding repeat calls to Google Cloud Translate.
- **Amharic Stemmer (The Early Days)**: We tried building a custom Amharic stemmer to handle words like “gadalku” (I killed), but it struggled with complex forms, so we switched to English translations with the Porter stemmer (e.g., “pollution” to “pollut”).
- **Fast Indexing**: We process 845+ articles with scikit-learn and joblib, making searches lightning-fast. ⚡
- **Smooth Query Flow**: Queries get tokenized, stemmed, and matched against our indices, delivering the best results every time.

### How It Performs
We tested 10 queries (e.g., “Tigray Conflict,” “Fayda Mobile Money”) and found our translation-based search beats direct Amharic processing (F1: 0.280 vs. 0.243). It’s not perfect—queries like “Health Care Strike” (F1=0.140) tripped us up due to vague terms—but we’re proud of how it handles most cases! Future tweaks could include better Amharic NLP or human-checked data to push our MAP closer to 0.3-0.5.

### Behind the Scenes
- **Backend**: Django and Django REST Framework handle queries, indices, and translations, with the `TelegramMessage` model storing Amharic and English text.
- **Frontend**: Flutter’s `search_news.dart` gives you a sleek search bar and results in a `ListView` of `BlogTile` widgets, sorted by relevance and date, all managed by Riverpod and Flutter Clean Architecture.
- **Why It’s Cool**: By translating Amharic to English, we sidestep its crazy grammar and use rock-solid English tools, making Neqat a pioneer in Amharic search. 🙌

## Telegram Scraper 📰

Neqat pulls Amharic news from Tikvah’s Telegram channels using the Telegram API, turning raw posts into curated content.

### Setup
1. Grab API credentials from [my.telegram.org/auth](https://my.telegram.org/auth).
2. Add these to your backend’s environment variables:
   ```
   TELEGRAM_API_ID=your_api_id
   TELEGRAM_API_HASH=your_api_hash
   ```

### Usage
Scrape messages with these commands:
```bash
# Grab the last 100 Tikvah posts
python manage.py telegram_scraper --channel tikvahethiopia

# Get a specific number of posts
python manage.py telegram_scraper --channel tikvahethiopia --limit 50

# Keep listening for new posts
python manage.py telegram_scraper --channel tikvahethiopia --listen
```

### In the App
Head to the Telegram page in the Flutter app to browse scraped news, filter by channel, and dive into details. Riverpod keeps everything smooth and snappy. 📲

## Contributing 🤝

We’d love your help to make Neqat even better! Here’s how to jump in:
1. Fork the repo.
2. Create a feature branch (`git checkout -b feature/your-cool-idea`).
3. Commit your changes (`git commit -m "Added something awesome"`).
4. Push it up (`git push origin feature/your-cool-idea`).
5. Open a pull request.

Stick to our coding style and toss in some tests to keep things solid.

## License 📜

Neqat is licensed under the MIT License. Check out the [LICENSE](LICENSE) file for details.
